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
#include <nvs_flash.h>
#include <esp_http_client.h>
#include <driver/gpio.h>
#include <driver/adc.h>
#include <driver/i2c.h>
#include <driver/spi_master.h>
#include <esp_log.h>
#include <esp_wifi.h>

#include <lwip/err.h>
#include <lwip/sys.h>

#include <esp_adc_cal.h>
#include "clrc663.h"

static const char* TAG = "heimdall";

static EventGroupHandle_t s_wifi_event_group;

static int RED_LED_PIN = 12;
static int GREEN_LED_PIN = 13;
//static int BUZZER_PIN = TBD;

static int s_retry_num = 0;

char *heimdall_url   = NULL;
char *reader_api_key = NULL;
char *writer_api_key = NULL;
char *tag_key        = NULL;

cJSON *access_list = NULL;


#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT      BIT1


// Mostly copied from
// https://github.com/espressif/esp-idf/tree/release/v4.1/examples/wifi/getting_started/station/main
static void wifi_event_handler(void* arg, esp_event_base_t event_base,
                                int32_t event_id, void* event_data)
{
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        if (s_retry_num < 10) {
            esp_wifi_connect();
            s_retry_num++;
            ESP_LOGI(TAG, "Retrying to connect to the WiFi AP");
        } else {
            xEventGroupSetBits(s_wifi_event_group, WIFI_FAIL_BIT);
        }
        ESP_LOGI(TAG,"Failed to connect to the WiFi AP");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        ESP_LOGI(TAG, "got IP address:" IPSTR, IP2STR(&event->ip_info.ip));
        s_retry_num = 0;
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
    }
}


// Mostly copied from
// https://github.com/espressif/esp-idf/tree/release/v4.1/examples/wifi/getting_started/station/main
static void heimdall_setup_wifi(char *wifi_ssid, char *wifi_password)
{
    s_wifi_event_group = xEventGroupCreate();

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_sta();

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
        ESP_LOGI(TAG, "connected to WiFi");
    } else if (bits & WIFI_FAIL_BIT) {
        ESP_LOGI(TAG, "failed to connect to WiFi");
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


static void access_list_fetcher_thread(__attribute__((unused)) void *param)
{
    int http_status_code;
    int length;
    char *url;
    char authorization_value[49];
    char *buffer;
    const char * const url_path = "/api/badge_readers/access_list";

    const int MAX_BADGE_TOKENS = 500;

    buffer = malloc(MAX_BADGE_TOKENS * 40);
    assert(buffer != NULL);

    esp_http_client_config_t config = {
     .event_handler = _http_event_handle,
     .timeout_ms = 60000,
  };

    url = malloc(strlen(heimdall_url) + strlen(url_path) + 1);
    assert(url != NULL);

    sprintf(url, "%s%s", heimdall_url, url_path);
    config.url = url;

    while (1) {

        esp_http_client_handle_t client = esp_http_client_init(&config);

        sprintf(authorization_value, "Bearer %s", reader_api_key);

        esp_http_client_set_header(client, "Content-Type", "application/json");
        esp_http_client_set_header(client, "Authorization", authorization_value);
        esp_http_client_set_method(client, HTTP_METHOD_GET);

        ESP_LOGI(TAG, "Sending request to %s", heimdall_url);
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


static void heimdall_setup_ui_gpio(void)
{
    gpio_config_t io_conf;

    const int NFC_POWERDOWN_PIN = 12;
    const int NFC_IRQ_PIN = 13;

    io_conf.intr_type = GPIO_PIN_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = ((1ULL << RED_LED_PIN) | (1ULL << GREEN_LED_PIN)) | (1ULL << NFC_POWERDOWN_PIN);
    io_conf.pull_down_en = 1;
    io_conf.pull_up_en = 0;

    ESP_ERROR_CHECK(gpio_config(&io_conf));


    io_conf.intr_type = GPIO_PIN_INTR_HILEVEL;
    io_conf.mode = GPIO_MODE_INPUT;
    io_conf.pin_bit_mask = (1ULL << NFC_IRQ_PIN);
    io_conf.pull_down_en = 1;
    io_conf.pull_up_en = 0;

    ESP_ERROR_CHECK(gpio_config(&io_conf));
}


static void heimdall_get_param(nvs_handle_t nvs, char *name, char **value)
{
    size_t required_len;

    ESP_ERROR_CHECK(nvs_get_str(nvs, name, NULL, &required_len));

    *value = malloc(required_len);
    assert(value != NULL);

    ESP_ERROR_CHECK(nvs_get_str(nvs, name, *value, &required_len));
}

void tag_reader(void *param)
{
    spi_device_handle_t spi;
    bool got_card;
    uint8_t *uid = NULL;
    uint8_t len = 0;
    uint8_t bcc = 0;
    uint8_t sak;

    spi = heimdall_rfid_init();

    while (1) {
        do {
            got_card = heimdall_rfid_reqa(spi);
        } while (!got_card);

        ESP_LOGI(TAG, "Got card");

        heimdall_rfid_anticollision(spi, 1, &uid, &len, &bcc);
        sak = heimdall_rfid_check_sak(spi, uid, len, bcc);

        if (sak & 0x04) {
            heimdall_rfid_anticollision(spi, 2, &uid, &len, &bcc);
            sak = heimdall_rfid_check_sak(spi, uid, len, bcc);
        }

        if (sak & 0x04) {
            heimdall_rfid_anticollision(spi, 3, &uid, &len, &bcc);
            sak = heimdall_rfid_check_sak(spi, uid, len, bcc);
        }

        for (int i = 0; i < len; i++)
        {
            ESP_LOGV(TAG, "U[%d] = %x", i, uid[i]);
        }
    }
}

void app_main(void)
{
    esp_err_t ret;
    nvs_handle_t nvs;
    size_t required_len;

    char *wifi_ssid;
    char *wifi_password;

    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NOT_FOUND) {
        ESP_ERROR_CHECK(ret);
    }

    ESP_ERROR_CHECK(nvs_open("heimdall", NVS_READWRITE, &nvs));

    heimdall_get_param(nvs, "wifi_ssid", &wifi_ssid);
    heimdall_get_param(nvs, "wifi_password", &wifi_password);
    heimdall_get_param(nvs, "heimdall_url", &heimdall_url);
    heimdall_get_param(nvs, "reader_api_key", &reader_api_key);
    heimdall_get_param(nvs, "writer_api_key", &writer_api_key);

    ESP_ERROR_CHECK(nvs_get_blob(nvs, "tag_key", NULL, &required_len));

    tag_key = malloc(required_len + 1);
    assert(tag_key != NULL);

    ESP_ERROR_CHECK(nvs_get_blob(nvs, "tag_key", tag_key, &required_len));
    nvs_close(nvs);

    tag_key[required_len] = 0;

    heimdall_setup_wifi(wifi_ssid, wifi_password);
    heimdall_setup_ui_gpio();

    xTaskCreate(&access_list_fetcher_thread, "access_list_fetcher", 4096, NULL, 5, NULL);
    xTaskCreate(&tag_reader, "tag_reader", 4096, NULL, 5, NULL);

    while (1) { sleep(60); }
}
