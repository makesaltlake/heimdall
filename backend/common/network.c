/*
 * Copyright (C) 2020 Rebecca Cran <rebecca@bsdio.com>.
 *
 */

#include <string.h>
#include <unistd.h>
#include <stdio.h>

#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/event_groups.h>

#include <cJSON.h>

#include <esp_system.h>
#include <esp_event.h>
#include <esp_http_client.h>

#include <esp_log.h>
#include <esp_wifi.h>

#include <lwip/err.h>
#include <lwip/sys.h>

#include <esp_websocket_client.h>

static const char* TAG = "heimdall-net";

static int s_retry_num = 0;


char *wifi_ssid;
char *wifi_password;

char *heimdall_host = NULL;
char *reader_api_key = NULL;
char *writer_api_key = NULL;

extern cJSON *access_list;

static EventGroupHandle_t s_wifi_event_group;


#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT      BIT1

/* Root cert for heimdall.makesaltlake.org, taken from heimdall_makesaltlake_org_root_cert.pem

   The PEM file was extracted from the output of this command:
   openssl s_client -showcerts -connect heimdall.makesaltlake.org:443 </dev/null

   The CA root cert is the last cert given in the chain of certs.

   To embed it in the app binary, the PEM file is named
   in the CMakeLists.txt EMBED_TXTFILES list.
*/
extern const char heimdall_dev_root_cert_pem_start[] asm("_binary_heimdall_dev_root_cert_pem_start");
extern const char heimdall_dev_root_cert_pem_end[]   asm("_binary_heimdall_dev_root_cert_pem_end");

extern const char heimdall_makesaltlake_org_root_cert_pem_start[] asm("_binary_heimdall_makesaltlake_org_root_cert_pem_start");
extern const char heimdall_makesaltlake_org_root_cert_pem_end[]   asm("_binary_heimdall_makesaltlake_org_root_cert_pem_end");



// Mostly copied from
// https://github.com/espressif/esp-idf/tree/release/v4.1/examples/wifi/getting_started/station/main
static void wifi_event_handler(void* arg, esp_event_base_t event_base,
                                int32_t event_id, void* event_data)
{
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        if (s_retry_num < 500) {
            esp_wifi_connect();
            s_retry_num++;
            ESP_LOGI(TAG, "Retrying to connect to the WiFi AP");
        } else {
            xEventGroupSetBits(s_wifi_event_group, WIFI_FAIL_BIT);
        }
        ESP_LOGW(TAG,"Failed to connect to the WiFi AP");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        ESP_LOGI(TAG, "Got IP address: " IPSTR, IP2STR(&event->ip_info.ip));
        s_retry_num = 0;
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
    }
}

static bool netif_initted = false;


// Mostly copied from
// https://github.com/espressif/esp-idf/tree/release/v4.1/examples/wifi/getting_started/station/main
void heimdall_setup_wifi(char *wifi_ssid, char *wifi_password)
{
    if (!netif_initted) {
        ESP_ERROR_CHECK(esp_netif_init());
        ESP_ERROR_CHECK(esp_event_loop_create_default());
        esp_netif_create_default_wifi_sta();
        netif_initted = true;
    }

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();

    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT,
                                               ESP_EVENT_ANY_ID,
                                               &wifi_event_handler,
                                               NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT,
                                               IP_EVENT_STA_GOT_IP,
                                               &wifi_event_handler,
                                               NULL));

    wifi_config_t wifi_config = {};

    strncpy((char*)wifi_config.sta.ssid, wifi_ssid, sizeof(wifi_config.sta.ssid));
    strncpy((char*)wifi_config.sta.password, wifi_password, sizeof(wifi_config.sta.password));
    wifi_config.sta.pmf_cfg.capable = true;
    wifi_config.sta.pmf_cfg.required = false;

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config));

    s_wifi_event_group = xEventGroupCreate();

    ESP_ERROR_CHECK(esp_wifi_start());

    esp_wifi_set_ps(WIFI_PS_NONE);

  /* Waiting until either the connection is established (WIFI_CONNECTED_BIT) or connection failed for the maximum
   * number of re-tries (WIFI_FAIL_BIT). The bits are set by event_handler() (see above) */
  EventBits_t bits = xEventGroupWaitBits(s_wifi_event_group,
            WIFI_CONNECTED_BIT | WIFI_FAIL_BIT,
            pdFALSE,
            pdFALSE,
            portMAX_DELAY);

    /* xEventGroupWaitBits() returns the bits before the call returned, hence we can test which event actually
    * happened. */
    if (bits & WIFI_CONNECTED_BIT) {
        ESP_LOGI(TAG, "Connected to WiFi");
    } else if (bits & WIFI_FAIL_BIT) {
        ESP_LOGI(TAG, "Failed to connect to WiFi");
    } else {
        ESP_LOGE(TAG, "UNEXPECTED EVENT");
    }

    /* The event will not be processed after unregister */
    ESP_ERROR_CHECK(esp_event_handler_unregister(IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_event_handler));
    ESP_ERROR_CHECK(esp_event_handler_unregister(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler));
    vEventGroupDelete(s_wifi_event_group);

}


static esp_err_t _http_event_handle(esp_http_client_event_t *evt)
{
    switch(evt->event_id) {
        case HTTP_EVENT_ERROR:
        case HTTP_EVENT_ON_CONNECTED:
        case HTTP_EVENT_HEADER_SENT:
        case HTTP_EVENT_ON_HEADER:
        case HTTP_EVENT_ON_DATA:
        case HTTP_EVENT_ON_FINISH:
        case HTTP_EVENT_DISCONNECTED:
            break;
    }
    return ESP_OK;
}



static void websocket_event_handler(void *args, esp_event_base_t base, int32_t event_id, void *event_data)
{
    esp_websocket_event_data_t *data = event_data;
    esp_websocket_client_handle_t wsclient = args;

    cJSON *message;
    const cJSON *identifier, *channel;
    const cJSON *badge_token;

    switch (event_id) {
        case WEBSOCKET_EVENT_CONNECTED:
            ESP_LOGI(TAG, "WebSocket connected.");
            char *msg = "{\"command\":\"subscribe\",\"identifier\":\"{\\\"channel\\\":\\\"BadgeReaderChannel\\\"}\"}";
            esp_websocket_client_send_text(wsclient, msg, strlen(msg), pdMS_TO_TICKS(2000));
            break;
        case WEBSOCKET_EVENT_DISCONNECTED:
            ESP_LOGW(TAG, "WebSocket disconnected.");
            esp_wifi_connect();
            break;
        case WEBSOCKET_EVENT_DATA:
            ESP_LOGI(TAG, "free Heap:%d,%d", esp_get_free_heap_size(), heap_caps_get_free_size(MALLOC_CAP_8BIT));
            message = cJSON_Parse(data->data_ptr);
            identifier = cJSON_GetObjectItem(message, "identifier");
            if (identifier != NULL) {
                char *chanmsg = identifier->valuestring;
                cJSON *foo = cJSON_Parse(chanmsg);
                if (foo != NULL) {
                    cJSON *chan = cJSON_GetObjectItem(foo, "channel");
                    if (chan != NULL) {
                        if (strcmp(chan->valuestring, "BadgeReaderChannel") == 0)
                        {
                            cJSON *type = cJSON_GetObjectItem(message, "type");
                            if (type != NULL && strcmp(type->valuestring, "confirm_subscription") == 0)
                                ESP_LOGI(TAG, "Confirmed subscription!");

                            cJSON *chan_msg = cJSON_GetObjectItem(message, "message");

                            if (chan_msg != NULL) {
                                cJSON *msg_type = cJSON_GetObjectItem(chan_msg, "type");

                                if (strcmp(msg_type->valuestring, "manual_open_request") == 0) {
                                    ESP_LOGI(TAG, "Manual Open Request");
                                    const char *response = "{\n\"command\":\"message\",\n"
                                                            "\"identifier\":\"{\\\"channel\\\":\\\"BadgeReaderChannel\\\"}\",\n"
                                                            "\"data\":\"{\\\"action\\\":\\\"report_manually_opened\\\"}\"\n}";
                                    ESP_LOGV(TAG, "Sending response: %s", response);
                                    esp_websocket_client_send_text(wsclient, response, strlen(response), pdMS_TO_TICKS(1000));
                                }
                            }
                        }
                    }
                    cJSON_Delete(foo);
                }
            }
            cJSON_Delete(message);
            break;
        case WEBSOCKET_EVENT_ERROR:
            ESP_LOGV(TAG, "WebSocket error.");
            break;
        default:
            ESP_LOGV(TAG, "Unhandled WebSocket event.");
            break;
    }
}


void heimdall_setup_websocket(void)
{
    esp_websocket_client_handle_t wsclient;
    char *wsurl;
    char *origin_header;
    uint8_t wsurl_len, origin_header_len;
    const char * const path = "/websocket?type=badge_reader&token=";

    wsurl_len = strlen("wss://") + strlen(heimdall_host) + strlen(path) + strlen(reader_api_key) + 1;
    wsurl = malloc(wsurl_len);
    assert(wsurl != NULL);

    sprintf(wsurl, "wss://%s%s%s", heimdall_host, path, reader_api_key);

    origin_header_len = strlen("Origin: https://") + strlen(heimdall_host) + 3;
    origin_header = malloc(origin_header_len);
    assert(origin_header != NULL);

    sprintf(origin_header, "Origin: https://%s\r\n", heimdall_host);

    const esp_websocket_client_config_t wscfg = {
        .uri = wsurl,
         .subprotocol = "chat, superchat",
         .headers = origin_header,
         .cert_pem = heimdall_dev_root_cert_pem_start,
    };

    wsclient = esp_websocket_client_init(&wscfg);
    ESP_LOGV(TAG, "Connecting to WebSocket URL %s", wsurl);
    esp_websocket_register_events(wsclient, WEBSOCKET_EVENT_ANY, websocket_event_handler, (void*)wsclient);

    esp_websocket_client_start(wsclient);

    memset(wsurl, 0, wsurl_len);
    memset(origin_header, 0, origin_header_len);

    free(wsurl);
    free(origin_header);
}



static void send_scan_tag(char *uid, int uid_len, char *badge_token)
{
    esp_http_client_handle_t client;

    const char * const url_path = "/api/badge_readers/record_scan";

    esp_http_client_config_t config = {
        .event_handler = _http_event_handle,
        .timeout_ms = 60000,
    };

    client = esp_http_client_init(&config);
}

void access_list_fetcher_thread(__attribute__((unused)) void *param)
{
    int http_status_code;
    int length;
    char *url;
    char authorization_value[49];
    char *buffer;
    const char * const url_path = "/api/badge_readers/access_list";

    ESP_LOGI(TAG, "Access list fetcher");

    const int MAX_BADGE_TOKENS = 500;

    buffer = malloc(MAX_BADGE_TOKENS * 40);
    assert(buffer != NULL);

    esp_http_client_config_t config = {
     .event_handler = _http_event_handle,
     .timeout_ms = 60000,
     .cert_pem = heimdall_dev_root_cert_pem_start
  };

    url = malloc(strlen("https://") + strlen(heimdall_host) + strlen(url_path) + 1);
    assert(url != NULL);

    sprintf(url, "https://%s%s", heimdall_host, url_path);
    config.url = url;

    while (1) {

        esp_http_client_handle_t client = esp_http_client_init(&config);

        sprintf(authorization_value, "Bearer %s", reader_api_key);

        esp_http_client_set_header(client, "Content-Type", "application/json");
        esp_http_client_set_header(client, "Authorization", authorization_value);
        esp_http_client_set_method(client, HTTP_METHOD_GET);

        ESP_LOGI(TAG, "Sending request to https://%s", heimdall_host);
        esp_err_t err = esp_http_client_perform(client);

        if (err == ESP_OK) {
            http_status_code = esp_http_client_get_status_code(client);
            if (http_status_code == 200) {

                memset(buffer, 0, MAX_BADGE_TOKENS * 40);

                length = esp_http_client_read(client, buffer, MAX_BADGE_TOKENS * 40);
                if (length > 0) {
                    if (access_list != NULL) {
                        cJSON_Delete(access_list);
                    }

                    access_list = cJSON_Parse(buffer);
                    const cJSON *tokens;
                    const cJSON *badge_token;

                    tokens = cJSON_GetObjectItem(access_list, "badge_tokens");
                    cJSON_ArrayForEach(badge_token, tokens) {
                        ESP_LOGI(TAG, "Token: %s", badge_token->valuestring);
                    }
                }
                else {
                    ESP_LOGW(TAG, "Zero-length HTTP read");
                }
            }
            else {
                ESP_LOGW(TAG, "HTTP request returned error %d", http_status_code);
            }
        }
        else {
            ESP_LOGW(TAG, "HTTP request failed: %d", err);
        }

        esp_http_client_cleanup(client);
        sleep(300);
    }
}
