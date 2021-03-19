#include <WiFi.h>
#include <HTTPClient.h>

const char* WIFI_SSID = "Make Salt Lake";
const char* WIFI_PASSWORD = "makerspace";

const char* HEIMDALL_HOST = "10.0.2.184:5000";
const bool HEIMDALL_SSL = false;

const char* HEIMDALL_BADGE_READER_API_TOKEN = "89e18cda81d5727d06ccf6819f63c6da0fb5dc63";

// Constants and other fun stuff

#define WIFI_RECONNECT_INTERVAL 20000
#define BADGE_ACCESS_LIST_FETCH_INTERVAL 10000
#define DOOR_OPEN_TIME 10000

// This will support ~8,000 active badges; it will need to be increased if we ever run above that limit.
#define GLOBAL_BADGE_ACCESS_LIST_SIZE_IN_BYTES 40000

#define WIEGAND_KEYPAD_BITS 4
#define WIEGAND_ENTER_KEY 11
#define WIEGAND_ESCAPE_KEY 10

#define PIN_WIEGAND_LED 13
#define PIN_WIEGAND_BPR 14
#define PIN_WIEGAND_D1 39
#define PIN_WIEGAND_D0 36

#define PIN_RELAY_1 17
#define PIN_RELAY_2 16
#define PIN_RELAY_3 4

// Networking code runs on core 0 and Arduino code runs on core 1 by default.
// So, we'll use core 0 for network fetching and pushing tasks (e.g. updating the access list and pushing "a user just badged in" messages to the backend) and core 1 to talk to the physical badge reader and relays.

SemaphoreHandle_t serialSemaphore;
SemaphoreHandle_t badgeAccessListSemaphore;

QueueHandle_t badgeScanQueue;

uint8_t globalBadgeAccessListData[GLOBAL_BADGE_ACCESS_LIST_SIZE_IN_BYTES];
uint32_t* globalBadgeAccessListBadgeCount = (uint32_t*) globalBadgeAccessListData;
uint32_t* globalBadgeAccessListBadges = (uint32_t*) globalBadgeAccessListData + 1;

class BinaryStream: public Stream {
  size_t bufferSize;
  
  public:
    uint8_t* buffer;
    size_t length;

    BinaryStream(uint8_t* buffer, size_t bufferSize) {
      this->buffer = buffer;
      this->bufferSize = bufferSize;
      this->length = 0;
    }
  
    size_t write(const uint8_t* buffer, size_t size) override {
      size_t amountToCopy = min(size, bufferSize - length);
      memcpy(this->buffer + this->length, buffer, amountToCopy);
      this->length += amountToCopy;
    }

    size_t write(uint8_t data) override {
      write(&data, 1);
    }

    // dummy implementations; HTTPClient doesn't use these, so don't worry about making them do anything useful.
    int available() {
      return 0;
    }

    int read() {
      return 0;
    }

    int peek() {
      return 0;
    }

    void flush() {
    }
};

struct BadgeScanReport {
  uint32_t badgeNumber;
  uint8_t success;
};

String generateUrl(const char* apiCall) {
  String result = "http";
  if (HEIMDALL_SSL) {
    result += "s";
  }
  result += "://";
  result += HEIMDALL_HOST;
  result += "/api/badge_readers/";
  result += apiCall;
  return result;
}

String generateAuthorizationHeader() {
  String result = "Bearer ";
  result += HEIMDALL_BADGE_READER_API_TOKEN;
  return result;
}

void logToSerial(const char* data) {
  xSemaphoreTake(serialSemaphore, portMAX_DELAY);
  Serial.println(data);
  xSemaphoreGive(serialSemaphore);
}

void setup() {
  serialSemaphore = xSemaphoreCreateBinary();
  xSemaphoreGive(serialSemaphore);
  
  badgeAccessListSemaphore = xSemaphoreCreateBinary();
  xSemaphoreGive(badgeAccessListSemaphore);

  badgeScanQueue = xQueueCreate(200, sizeof(BadgeScanReport));

  ((uint32_t*) globalBadgeAccessListData)[0] = 0;
  
  pinMode(2, OUTPUT);
  pinMode(PIN_WIEGAND_LED, OUTPUT);
  pinMode(PIN_WIEGAND_BPR, OUTPUT);
  pinMode(PIN_WIEGAND_D0, INPUT_PULLUP);
  pinMode(PIN_WIEGAND_D1, INPUT_PULLUP);
  pinMode(PIN_RELAY_1, OUTPUT);
  pinMode(PIN_RELAY_2, OUTPUT);
  pinMode(PIN_RELAY_3, OUTPUT);
  digitalWrite(PIN_WIEGAND_LED, LOW);
  digitalWrite(PIN_WIEGAND_BPR, LOW);
  digitalWrite(PIN_RELAY_1, LOW);
  digitalWrite(PIN_RELAY_2, LOW);
  digitalWrite(PIN_RELAY_3, LOW);
  Serial.begin(115200);

  xTaskCreatePinnedToCore(wifiConnectTask, "wifiConnectTask", 4096, NULL, 1, NULL, 0);
  xTaskCreatePinnedToCore(badgeAccessListFetchTask, "badgeAccessListFetchTask", 4096, NULL, 1, NULL, 0);
  xTaskCreatePinnedToCore(badgeScanReportTask, "badgeScanReportTask", 4096, NULL, 1, NULL, 0);
}

void wifiConnectTask(void* parameter) {
  while (true) {
    if (WiFi.status() != WL_CONNECTED) {
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
      logToSerial("Connecting to WiFi");
    } else {
      logToSerial("Already connected to WiFi");
    }
    vTaskDelay(WIFI_RECONNECT_INTERVAL / portTICK_PERIOD_MS);
  } 
}

void badgeAccessListFetchTask(void* parameter) {  
  while (true) {
    // Wait until WiFi is connected before fetching badges
    while (WiFi.status() != WL_CONNECTED) {
      vTaskDelay(1000 / portTICK_PERIOD_MS);
    }

    HTTPClient client;
    client.begin(generateUrl("binary_access_list"));
    client.addHeader("Authorization", generateAuthorizationHeader());
    int responseCode = client.GET();
    if (responseCode == 200) {
      logToSerial("Badge access list reloaded");

      xSemaphoreTake(badgeAccessListSemaphore, portMAX_DELAY);
      BinaryStream responseStream(globalBadgeAccessListData, GLOBAL_BADGE_ACCESS_LIST_SIZE_IN_BYTES);
      client.writeToStream(&responseStream);
      xSemaphoreGive(badgeAccessListSemaphore);
    } else {
      logToSerial("Couldn't reload badge access list");
    }

    vTaskDelay(BADGE_ACCESS_LIST_FETCH_INTERVAL / portTICK_PERIOD_MS);
  }
}

void badgeScanReportTask(void* parameter) {
  while (true) {
    BadgeScanReport badgeScanReport;
    
    if (xQueuePeek(badgeScanQueue, &badgeScanReport, portMAX_DELAY) == pdFALSE) {
      // shouldn't happen since we instruct xQueueReceive to wait forever, but just in case
      logToSerial("Whoa, failed to retrieve a queued badge scan. WTF");
      continue;
    }

    logToSerial("About to report a badge scan");

    if (WiFi.status() != WL_CONNECTED) {
      vTaskDelay(1000 / portTICK_PERIOD_MS);
      continue;
    }

    HTTPClient client;
    client.begin(generateUrl("record_binary_scan"));
    client.addHeader("Authorization", generateAuthorizationHeader());
    client.addHeader("Content-Type", "application/octet-stream");

    int responseCode = client.POST(((uint8_t*) &badgeScanReport), sizeof(badgeScanReport));

    if (responseCode != 200) {
      logToSerial("Couldn't record badge scan, trying again in a few moments");
      vTaskDelay(5000 / portTICK_PERIOD_MS);
      continue;
    }

    logToSerial("Badge scan reported");

    xQueueReceive(badgeScanQueue, &badgeScanReport, portMAX_DELAY);
  }
}

uint32_t currentlyReadingBadgeNumber = 0;
uint8_t currentlyReadingBadgeNumberBits = 0;
uint32_t currentlyReadingBadgeNumberLastBitAt = 0;
boolean d0PreviouslyLow = false;
boolean d1PreviouslyLow = false;

#define WIEGAND_TIME_TO_FINALIZE 50

void loop() {
  if (digitalRead(PIN_WIEGAND_D0) == LOW && !d0PreviouslyLow) {
    d0PreviouslyLow = true;
    currentlyReadingBadgeNumber = currentlyReadingBadgeNumber << 1;
    currentlyReadingBadgeNumberBits += 1;
    currentlyReadingBadgeNumberLastBitAt = millis();
  } else if (digitalRead(PIN_WIEGAND_D1) == LOW && !d1PreviouslyLow) {
    d1PreviouslyLow = true;
    currentlyReadingBadgeNumber = (currentlyReadingBadgeNumber << 1) | 1;
    currentlyReadingBadgeNumberBits += 1;
    currentlyReadingBadgeNumberLastBitAt = millis();
  } else if (digitalRead(PIN_WIEGAND_D0) == HIGH && digitalRead(PIN_WIEGAND_D1) == HIGH) {
    d0PreviouslyLow = false;
    d1PreviouslyLow = false;

    if (millis() - currentlyReadingBadgeNumberLastBitAt > 50 && currentlyReadingBadgeNumberBits > 0) {
      // Successfully read a badge scan or keypad press.
      if (currentlyReadingBadgeNumberBits == 26) {
        // Wiegand badge. We're ignoring the parity bits for now; that's probably fine, but it wouldn't hurt to check them in the future.
        uint32_t badgeNumber = (currentlyReadingBadgeNumber >> 1) & 0xFFFFFF;

        bool isAuthorized = false;

        xSemaphoreTake(badgeAccessListSemaphore, portMAX_DELAY);
        for(size_t i = 0; i < *globalBadgeAccessListBadgeCount; i++) {
          if (globalBadgeAccessListBadges[i] == badgeNumber) {
            isAuthorized = true;
          }
        }
        xSemaphoreGive(badgeAccessListSemaphore);

        if (isAuthorized) {
          logToSerial("Authorized!");

          BadgeScanReport badgeScanReport = {badgeNumber, true};
          xQueueSend(badgeScanQueue, &badgeScanReport, 0);
          
          digitalWrite(PIN_WIEGAND_LED, HIGH);
          digitalWrite(PIN_RELAY_1, HIGH);

          vTaskDelay(DOOR_OPEN_TIME / portTICK_PERIOD_MS);

          digitalWrite(PIN_WIEGAND_LED, LOW);
          digitalWrite(PIN_RELAY_1, LOW);
        } else {
          logToSerial("Not authorized.");

          BadgeScanReport badgeScanReport = {badgeNumber, false};
          xQueueSend(badgeScanQueue, &badgeScanReport, 0);

          for (int i = 0; i < 3; i++) {
            digitalWrite(PIN_WIEGAND_LED, HIGH);
            digitalWrite(PIN_WIEGAND_BPR, HIGH);

            vTaskDelay(250 / portTICK_PERIOD_MS);

            digitalWrite(PIN_WIEGAND_LED, LOW);
            digitalWrite(PIN_WIEGAND_BPR, LOW);

            vTaskDelay(250 / portTICK_PERIOD_MS);
          }
        }
      } else if (currentlyReadingBadgeNumberBits == WIEGAND_KEYPAD_BITS) {
        // TODO: do something more useful with keypad presses
        // Serial.println("Read keypad press:");
        // Serial.println(currentlyReadingBadgeNumber);
      }
      
      currentlyReadingBadgeNumber = 0;
      currentlyReadingBadgeNumberBits = 0;
    }
  }
}
