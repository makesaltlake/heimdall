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

#include <driver/ledc.h>
#include <soc/ledc_reg.h>

#include <esp_vfs_fat.h>
#include <diskio_wl.h>
#include <esp_vfs.h>

#include "clrc663.h"
#include "iso14443.h"
#include "mifare_classic.h"
#include "tag.h"
#include "network.h"
#include "../ESP32-NeoPixel-WS2812-RMT/ws2812_control.h"


static const char* TAG = "heimdall";

const int LED_GPIO_PIN = 22;
const int BUZZER_GPIO_PIN = 23;
const int RELAY1_GPIO_PIN = 17;
const int RELAY2_GPIO_PIN = 16;
const int RELAY3_GPIO_PIN = 4;
const int TAMPER_SWITCH_GPIO_PIN = 18;

const int RFID_CS_GPIO_PIN = 32;
const int CAM_CS_GPIO_PIN = 15;

extern char *heimdall_host;
extern char *reader_api_key;
extern char *writer_api_key;

char *tag_key = NULL;

cJSON *access_list = NULL;

extern char *wifi_ssid;
extern char *wifi_password;

static void set_buzzer_duty(uint32_t duty)
{
    ledc_set_duty(LEDC_HIGH_SPEED_MODE, LEDC_CHANNEL_0, duty);
    ledc_update_duty(LEDC_HIGH_SPEED_MODE, LEDC_CHANNEL_0);
}

static void heimdall_setup_buzzer(void)
{
    // Configure the buzzer
    const ledc_timer_config_t buzzer_timer = {LEDC_HIGH_SPEED_MODE, {LEDC_TIMER_10_BIT}, LEDC_TIMER_0, 2670, LEDC_AUTO_CLK};
    const ledc_channel_config_t channel = {BUZZER_GPIO_PIN, LEDC_HIGH_SPEED_MODE, LEDC_CHANNEL_0, LEDC_INTR_DISABLE, LEDC_TIMER_0, 0, LEDC_HPOINT_HSCH1_S};

    ESP_ERROR_CHECK(ledc_timer_config(&buzzer_timer));
    ESP_ERROR_CHECK(ledc_channel_config(&channel));

    // Test the buzzer.
    ESP_LOGI(TAG, "Testing the buzzer");
    set_buzzer_duty(512);
    sleep(1);
    set_buzzer_duty(0);
}

static void heimdall_setup_led(void)
{
    // Set up the RMT driver to control the LED
    ws2812_control_init();

    ESP_LOGI(TAG, "Testing the LED");

    struct led_state led;

    // Red
    led.leds[0] = 0xFF0000;
    ws2812_write_leds(led);
    sleep(1);

    // Green
    led.leds[0] = 0x00FF00;
    ws2812_write_leds(led);
    sleep(1);

    // Blue
    led.leds[0] = 0x0000FF;
    ws2812_write_leds(led);
    sleep(1);

    // Off
    led.leds[0] = 0x000000;
    ws2812_write_leds(led);
}

static void heimdall_setup_ui_gpio(void)
{
    gpio_config_t io_conf;

    esp_err_t err;

    // Set up output GPIOs
    io_conf.intr_type = GPIO_PIN_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;

    io_conf.pin_bit_mask =  (1ULL << RELAY1_GPIO_PIN) |
                            (1ULL << RELAY2_GPIO_PIN) |
                            (1ULL << RELAY3_GPIO_PIN);

    io_conf.pull_down_en = 1;
    io_conf.pull_up_en = 0;

    ESP_ERROR_CHECK(gpio_config(&io_conf));

    // And set up input GPIOs
    io_conf.intr_type = GPIO_PIN_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_INPUT;

    io_conf.pin_bit_mask =  (1ULL << TAMPER_SWITCH_GPIO_PIN);
    io_conf.pull_up_en = 0;

    ESP_ERROR_CHECK(gpio_config(&io_conf));

    ESP_LOGI(TAG, "Testing the RELAY1");
    gpio_set_level(RELAY1_GPIO_PIN, 1);
    sleep(1);
    gpio_set_level(RELAY1_GPIO_PIN, 0);

    sleep(1);

    ESP_LOGI(TAG, "Testing the RELAY2");
    gpio_set_level(RELAY2_GPIO_PIN, 1);
    sleep(1);
    gpio_set_level(RELAY2_GPIO_PIN, 0);

    sleep(1);

    ESP_LOGI(TAG, "Testing the RELAY3");
    gpio_set_level(RELAY3_GPIO_PIN, 1);
    sleep(1);
    gpio_set_level(RELAY3_GPIO_PIN, 0);

    heimdall_setup_buzzer();
    heimdall_setup_led();
}


static void heimdall_get_param(nvs_handle_t nvs, char *name, char **value)
{
    size_t required_len;

    ESP_ERROR_CHECK(nvs_get_str(nvs, name, NULL, &required_len));

    *value = malloc(required_len);
    assert(value != NULL);

    ESP_ERROR_CHECK(nvs_get_str(nvs, name, *value, &required_len));
}


static void heimdall_setup_badge_scans_file(void)
{
    esp_err_t ret;

    // We don't build the BSP (Board Support Package) with long filenames,
    // so we're limited to MS-DOS style 8.3.
    const char * const BADGE_SCANS_FILENAME = "/spiflash/heimdall.txt";

    wl_handle_t wl_handle;
    FILE *f;

    esp_vfs_fat_mount_config_t mntconf = {
        .max_files = 8,
        .format_if_mount_failed = true,
        .allocation_unit_size = CONFIG_WL_SECTOR_SIZE,
    };

    // Note: this function is marked in the docs as for examples. I'm using
    // it here because it does exactly what we want, but I suppose it might
    // go away in future.
    ret = esp_vfs_fat_spiflash_mount("/spiflash", "mslfat", &mntconf, &wl_handle);
    ESP_ERROR_CHECK(ret);

    f = fopen(BADGE_SCANS_FILENAME, "r+");
    if (f == NULL) {
        ESP_LOGI(TAG, "Failed to open %s -- trying to create it", BADGE_SCANS_FILENAME);
        f = fopen(BADGE_SCANS_FILENAME, "w+");
        if (f == NULL) {
            ESP_LOGE(TAG, "Failed to create %s -- not caching badge scans to permament storage", BADGE_SCANS_FILENAME);
        }
    }

    // TODO
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

    heimdall_setup_badge_scans_file();
    heimdall_setup_wifi(wifi_ssid, wifi_password);
    heimdall_setup_ui_gpio();
    heimdall_setup_websocket();

    BaseType_t rtret;
    rtret = xTaskCreate(&access_list_fetcher_thread, "access_list_fetcher", 4096, NULL, 5, NULL);
    if (rtret != pdPASS) {
        ESP_LOGE(TAG, "Failed to create access list fetcher thread: %d", rtret);
        assert(0);
    }

    rtret = xTaskCreate(&tag_reader, "tag_reader", 4096, NULL, 5, NULL);
    if (rtret != pdPASS)
    {
        ESP_LOGE(TAG, "Failed to create tag reader thread: %d", rtret);
        assert(0);
    }
}
