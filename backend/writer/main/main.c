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
#include <esp_log.h>

#include <esp_vfs_fat.h>
#include <diskio_wl.h>
#include <esp_vfs.h>

#include <cam.h>
#include <ov2640.h>
#include <board.h>
#include <sensor.h>
#include <lcd.h>

#include "clrc663.h"
#include "iso14443.h"
#include "mifare_classic.h"
#include "network.h"
#include "tag.h"

static const char* TAG = "heimdall";

const int RFID_CS_GPIO_PIN = 32;
const int CAM_CS_GPIO_PIN = 15;

extern char *heimdall_host;
extern char *reader_api_key;
extern char *writer_api_key;

char *tag_key = NULL;

extern char *wifi_ssid;
extern char *wifi_password;


#define CAM_WIDTH   (320)
#define CAM_HIGH    (240)


static void heimdall_get_param(nvs_handle_t nvs, char *name, char **value)
{
    size_t required_len;

    ESP_ERROR_CHECK(nvs_get_str(nvs, name, NULL, &required_len));

    *value = malloc(required_len);
    assert(value != NULL);

    ESP_ERROR_CHECK(nvs_get_str(nvs, name, *value, &required_len));
}


void app_main(void)
{
    esp_err_t ret;
    nvs_handle_t nvs;
    size_t required_len;

    esp_log_level_set("wifi", ESP_LOG_WARN);

    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NOT_FOUND) {
        ESP_ERROR_CHECK(ret);
    }

    ESP_ERROR_CHECK(nvs_open("heimdall", NVS_READWRITE, &nvs));

    heimdall_get_param(nvs, "wifi_ssid", &wifi_ssid);
    heimdall_get_param(nvs, "wifi_password", &wifi_password);
    heimdall_get_param(nvs, "heimdall_host", &heimdall_host);
    heimdall_get_param(nvs, "reader_api_key", &reader_api_key);
    heimdall_get_param(nvs, "writer_api_key", &writer_api_key);

    ESP_ERROR_CHECK(nvs_get_blob(nvs, "tag_key", NULL, &required_len));

    tag_key = malloc(required_len + 1);
    assert(tag_key != NULL);

    ESP_ERROR_CHECK(nvs_get_blob(nvs, "tag_key", tag_key, &required_len));
    tag_key[required_len] = 0;

    nvs_close(nvs);

    heimdall_setup_wifi(wifi_ssid, wifi_password);

    BaseType_t rtret;
    rtret = xTaskCreate(&tag_writer, "tag_writer", 4096, NULL, 5, NULL);
    if (rtret != pdPASS)
    {
        ESP_LOGE(TAG, "Failed to create tag reader thread: %d", rtret);
        assert(0);
    }
}
