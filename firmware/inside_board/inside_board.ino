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
#define KEYPAD_TIMEOUT 5000

// This will support 10,000 active badges and numeric codes; it will need to be increased if we ever run above that limit.
#define GLOBAL_ACCESS_LIST_SIZE 10000

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

#define ACCESS_RECORD_TYPE_BADGE 1
#define ACCESS_RECORD_TYPE_KEYPAD 2
#define ACCESS_RECORD_TYPE_KEYPAD_ESCAPE 3
#define ACCESS_RECORD_TYPE_KEYPAD_TIMEOUT 4

// Networking code runs on core 0 and Arduino code runs on core 1 by default.
// So, we'll use core 0 for network fetching and pushing tasks (e.g. updating the access list and pushing "a user just badged in" messages to the backend) and core 1 to talk to the physical badge reader and relays.

SemaphoreHandle_t serialSemaphore;
SemaphoreHandle_t badgeAccessListSemaphore;

QueueHandle_t badgeScanQueue;

#pragma pack(push, 1)
struct AccessRecord {
  uint8_t type;
  uint8_t length;
  uint32_t badgeNumber;
};

struct BadgeScanReport {
  uint8_t type;
  uint8_t length;
  uint32_t badgeNumber;
  uint8_t success;
};
#pragma pack(pop)

#define GLOBAL_ACCESS_LIST_SIZE_IN_BYTES (sizeof(uint32_t) + (GLOBAL_ACCESS_LIST_SIZE * sizeof(AccessRecord)))
uint8_t globalAccessListData[GLOBAL_ACCESS_LIST_SIZE_IN_BYTES];
uint32_t* globalAccessListRecordCount = (uint32_t*) globalAccessListData;
AccessRecord* globalAccessListRecords = (AccessRecord*) (globalAccessListData + sizeof(uint32_t));

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

  (*globalAccessListRecordCount) = 0;

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

  xTaskCreatePinnedToCore(wifiConnectTask, "wifiConnectTask", 16384, NULL, 1, NULL, 0);
  xTaskCreatePinnedToCore(badgeAccessListFetchTask, "badgeAccessListFetchTask", 16384, NULL, 1, NULL, 0);
  xTaskCreatePinnedToCore(badgeScanReportTask, "badgeScanReportTask", 16384, NULL, 1, NULL, 0);
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
      BinaryStream responseStream(globalAccessListData, GLOBAL_ACCESS_LIST_SIZE_IN_BYTES);
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

uint32_t keypadEnteredCode = 0;
uint8_t keypadEnteredDigits = 0;
uint32_t keypadPressedAt = 0;
bool keypadBeingPressed = false;

boolean d0PreviouslyLow = false;
boolean d1PreviouslyLow = false;

#define WIEGAND_TIME_TO_FINALIZE 50

void indicateAuthorizationFailure() {
    for (int i = 0; i < 3; i++) {
    if (i != 0) {
      vTaskDelay(250 / portTICK_PERIOD_MS);
    }

    digitalWrite(PIN_WIEGAND_LED, HIGH);
    digitalWrite(PIN_WIEGAND_BPR, HIGH);

    vTaskDelay(250 / portTICK_PERIOD_MS);

    digitalWrite(PIN_WIEGAND_LED, LOW);
    digitalWrite(PIN_WIEGAND_BPR, LOW);
  }
}

void loop() {
  while (true) {
    xSemaphoreTake(badgeAccessListSemaphore, portMAX_DELAY);
    boolean hasLoadedBadgeList = *globalAccessListRecordCount > 0;
    xSemaphoreGive(badgeAccessListSemaphore);

    if (hasLoadedBadgeList) {
      break;
    } else {
      vTaskDelay(500 / portTICK_PERIOD_MS);
      digitalWrite(PIN_WIEGAND_LED, HIGH);
      vTaskDelay(500 / portTICK_PERIOD_MS);
      digitalWrite(PIN_WIEGAND_LED, LOW);
    }
  }

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
        // Cancel any key code currently being entered
        keypadBeingPressed = false;
        keypadEnteredCode = 0;
        keypadEnteredDigits = 0;
        keypadPressedAt = 0;

        // Wiegand badge. We're ignoring the parity bits for now; that's probably fine, but it wouldn't hurt to check them in the future.
        uint32_t badgeNumber = (currentlyReadingBadgeNumber >> 1) & 0xFFFFFF;

        bool isAuthorized = false;

        xSemaphoreTake(badgeAccessListSemaphore, portMAX_DELAY);
        for(size_t i = 0; i < *globalAccessListRecordCount; i++) {
          if (globalAccessListRecords[i].type == ACCESS_RECORD_TYPE_BADGE && globalAccessListRecords[i].badgeNumber == badgeNumber) {
            isAuthorized = true;
          }
        }
        xSemaphoreGive(badgeAccessListSemaphore);

        if (isAuthorized) {
          logToSerial("Authorized!");

          BadgeScanReport badgeScanReport = {ACCESS_RECORD_TYPE_BADGE, 0, badgeNumber, true};
          xQueueSend(badgeScanQueue, &badgeScanReport, 0);

          digitalWrite(PIN_WIEGAND_LED, HIGH);
          digitalWrite(PIN_RELAY_1, HIGH);

          vTaskDelay(DOOR_OPEN_TIME / portTICK_PERIOD_MS);

          digitalWrite(PIN_WIEGAND_LED, LOW);
          digitalWrite(PIN_RELAY_1, LOW);
        } else {
          logToSerial("Not authorized.");

          BadgeScanReport badgeScanReport = {ACCESS_RECORD_TYPE_BADGE, 0, badgeNumber, false};
          xQueueSend(badgeScanQueue, &badgeScanReport, 0);

          indicateAuthorizationFailure();
        }
      } else if (currentlyReadingBadgeNumberBits == WIEGAND_KEYPAD_BITS) {
        if (currentlyReadingBadgeNumber == WIEGAND_ESCAPE_KEY) {
          BadgeScanReport badgeScanReport = {ACCESS_RECORD_TYPE_KEYPAD_ESCAPE, keypadEnteredDigits, keypadEnteredCode, false};
          xQueueSend(badgeScanQueue, &badgeScanReport, 0);

          keypadBeingPressed = false;
          keypadEnteredCode = 0;
          keypadEnteredDigits = 0;
          keypadPressedAt = 0;
        } else if (currentlyReadingBadgeNumber == WIEGAND_ENTER_KEY) {
          bool isAuthorized = false;

          xSemaphoreTake(badgeAccessListSemaphore, portMAX_DELAY);
          for(size_t i = 0; i < *globalAccessListRecordCount; i++) {
            if (globalAccessListRecords[i].type == ACCESS_RECORD_TYPE_KEYPAD && globalAccessListRecords[i].badgeNumber == keypadEnteredCode && globalAccessListRecords[i].length == keypadEnteredDigits) {
              isAuthorized = true;
            }
          }
          xSemaphoreGive(badgeAccessListSemaphore);

          if (isAuthorized) {
            logToSerial("Authorized via keypad!");

            BadgeScanReport badgeScanReport = {ACCESS_RECORD_TYPE_KEYPAD, keypadEnteredDigits, keypadEnteredCode, true};
            xQueueSend(badgeScanQueue, &badgeScanReport, 0);

            digitalWrite(PIN_WIEGAND_LED, HIGH);
            digitalWrite(PIN_RELAY_1, HIGH);
            digitalWrite(PIN_WIEGAND_BPR, HIGH);

            vTaskDelay(400 / portTICK_PERIOD_MS);

            digitalWrite(PIN_WIEGAND_BPR, LOW);

            vTaskDelay(DOOR_OPEN_TIME / portTICK_PERIOD_MS);

            digitalWrite(PIN_WIEGAND_LED, LOW);
            digitalWrite(PIN_RELAY_1, LOW);
          } else {
            logToSerial("Not authorized via keypad.");

            BadgeScanReport badgeScanReport = {ACCESS_RECORD_TYPE_KEYPAD, keypadEnteredDigits, keypadEnteredCode, false};
            xQueueSend(badgeScanQueue, &badgeScanReport, 0);

            indicateAuthorizationFailure();
          }

          keypadBeingPressed = false;
          keypadEnteredCode = 0;
          keypadEnteredDigits = 0;
          keypadPressedAt = 0;
        } else {
          keypadBeingPressed = true;
          keypadEnteredCode = (keypadEnteredCode * 10) + currentlyReadingBadgeNumber;
          keypadEnteredDigits += 1;
          keypadPressedAt = millis();
        }
      }

      currentlyReadingBadgeNumber = 0;
      currentlyReadingBadgeNumberBits = 0;
    } else if (keypadBeingPressed && millis() - keypadPressedAt > KEYPAD_TIMEOUT) {
      BadgeScanReport badgeScanReport = {ACCESS_RECORD_TYPE_KEYPAD_TIMEOUT, keypadEnteredDigits, keypadEnteredCode, false};
      xQueueSend(badgeScanQueue, &badgeScanReport, 0);

      keypadBeingPressed = false;
      keypadEnteredCode = 0;
      keypadEnteredDigits = 0;
      keypadPressedAt = 0;

      indicateAuthorizationFailure();
    }
  }
}
