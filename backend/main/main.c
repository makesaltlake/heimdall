/*
 * Copyright (C) 2020 Rebecca Cran <rebecca@bsdio.com>.
 * 
 */

#include <string.h>
#include <unistd.h>

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
#include <driver/gpio.h>
#include <driver/i2c.h>
#include <driver/spi_master.h>
#include <esp_log.h>
#include <esp_wifi.h>

#include <lwip/err.h>
#include <lwip/sys.h>

#include <esp_adc_cal.h>

static const char* TAG = "heimdall";

static EventGroupHandle_t s_wifi_event_group;

//static int RED_LED_PIN = 12;
//static int GREEN_LED_PIN = 13;
// static int BUZZER_PIN = TBD;

static int s_retry_num = 0;

#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT BIT1

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
            ESP_LOGI(TAG, "retry to connect to the AP");
        } else {
            xEventGroupSetBits(s_wifi_event_group, WIFI_FAIL_BIT);
        }
        ESP_LOGI(TAG,"connect to the AP fail");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        ESP_LOGI(TAG, "got ip:" IPSTR, IP2STR(&event->ip_info.ip));
        s_retry_num = 0;
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
    }
}

esp_err_t _http_event_handle(esp_http_client_event_t *evt)
{
    switch(evt->event_id) {
        case HTTP_EVENT_ERROR:
            ESP_LOGI(TAG, "HTTP_EVENT_ERROR");
            break;
        case HTTP_EVENT_ON_CONNECTED:
            ESP_LOGI(TAG, "HTTP_EVENT_ON_CONNECTED");
            break;
        case HTTP_EVENT_HEADER_SENT:
            ESP_LOGI(TAG, "HTTP_EVENT_HEADER_SENT");
            break;
        case HTTP_EVENT_ON_HEADER:
            ESP_LOGI(TAG, "HTTP_EVENT_ON_HEADER");
            printf("%.*s", evt->data_len, (char*)evt->data);
            break;
        case HTTP_EVENT_ON_DATA:
            ESP_LOGI(TAG, "HTTP_EVENT_ON_DATA, len=%d", evt->data_len);
            if (!esp_http_client_is_chunked_response(evt->client)) {
                printf("%.*s", evt->data_len, (char*)evt->data);
            }

            break;
        case HTTP_EVENT_ON_FINISH:
            ESP_LOGI(TAG, "HTTP_EVENT_ON_FINISH");
            break;
        case HTTP_EVENT_DISCONNECTED:
            ESP_LOGI(TAG, "HTTP_EVENT_DISCONNECTED");
            break;
    }
    return ESP_OK;
}

static void heimdall_get_param(nvs_handle_t nvs, char *name, char **value)
{
	size_t required_len;

	ESP_ERROR_CHECK(nvs_get_str(nvs, name, NULL, &required_len));

	*value = malloc(required_len);
	assert(value != NULL);

	ESP_ERROR_CHECK(nvs_get_str(nvs, name, *value, &required_len));
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
        	ESP_LOGI(TAG, "Failed to connect to WiFi");
	} else {
        	ESP_LOGE(TAG, "UNEXPECTED EVENT");
	}

	/* The event will not be processed after unregister */
	ESP_ERROR_CHECK(esp_event_handler_unregister(IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_event_handler));
	ESP_ERROR_CHECK(esp_event_handler_unregister(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler));
	vEventGroupDelete(s_wifi_event_group);
}

#if 0
spi_device_handle_t spi;

static spi_device_handle_t heimdall_setup_spi(void)
{
    int RC522_SPI_MISO_PIN_NUM = 19;
    int RC522_SPI_MOSI_PIN_NUM = 18;
    int RC522_SPI_SCLK_PIN_NUM = 5;
    int RC522_SPI_CS_PIN_NUM = 4;

    spi_bus_config_t buscfg = {
        .miso_io_num = RC522_SPI_MISO_PIN_NUM,
        .mosi_io_num = RC522_SPI_MOSI_PIN_NUM,
        .sclk_io_num = RC522_SPI_SCLK_PIN_NUM,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = 0,
        .flags = SPICOMMON_BUSFLAG_MASTER
    };

    spi_device_interface_config_t devcfg = {
        .clock_speed_hz = SPI_BUS_SPEED_HZ,
        .mode = 0,
        .spics_io_num = RC522_SPI_CS_PIN_NUM,
        .queue_size = 20,
        .pre_cb = NULL,
        .command_bits=0,
        .address_bits=8,
        .flags = 0,
    };
    
    ESP_LOGI(TAG, "Setting up SPI");
    ESP_ERROR_CHECK(spi_bus_initialize(HSPI_HOST, &buscfg, 0));
    ESP_ERROR_CHECK(spi_bus_add_device(HSPI_HOST, &devcfg, &spi));

    return spi;
}
#endif


static void heimdall_setup_ui_gpio(void)
{
	gpio_config_t io_conf;

	io_conf.intr_type = GPIO_PIN_INTR_DISABLE;
	io_conf.mode = GPIO_MODE_OUTPUT;
	io_conf.pin_bit_mask = ((1ULL << 12) | (1ULL << 13));
	io_conf.pull_down_en = 1;
	io_conf.pull_up_en = 0;

	ESP_ERROR_CHECK(gpio_config(&io_conf));
}

void app_main(void)
{
	esp_err_t ret;
	nvs_handle_t nvs;
	size_t required_len;

	char *wifi_ssid;
	char *wifi_password;
	char *heimdall_url;
	char *reader_api_key;
	char *writer_api_key;
	char *tag_key;    

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
}


#if 0 
//	xTaskCreate(&blinky, "blinky", 4096, NULL, 5, NULL);

    esp_http_client_config_t config = {
	   .url = "https://httpbin.org/delay/5",
	   .event_handler = _http_event_handle,
	   .timeout_ms = 60000,
	};

//    sprintf(config.url, "%s/api/badge_readers/access_list", heimdall_url);
//    sprintf(config.url, "%s/api/badge_readers/record_scans", heimdall_url);
//    sprintf(config.url, "%s/api/badge_writers/program", heimdall_url);


    cJSON *access_list = cJSON_Parse(wifi_ssid);

	esp_http_client_handle_t client = esp_http_client_init(&config);
	ESP_LOGI(TAG, "Sending request to https://httpbin.org/delay/5");
	esp_err_t err = esp_http_client_perform(client);

	if (err == ESP_OK) {
		ESP_LOGI(TAG, "Status = %d, content_length = %d",
           esp_http_client_get_status_code(client),
           esp_http_client_get_content_length(client));
	}
#endif
