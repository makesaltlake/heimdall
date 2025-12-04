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
#include <esp_log.h>

#include <driver/gpio.h>

#include "clrc663.h"
#include "iso14443.h"
#include "mifare_classic.h"
#include "tag.h"
#include "network.h"

#include "../ESP32-NeoPixel-WS2812-RMT/ws2812_control.h"


extern const int LED_GPIO_PIN;
extern const int BUZZER_GPIO_PIN;
extern const int RELAY1_GPIO_PIN;
extern const int RELAY2_GPIO_PIN;
extern const int RELAY3_GPIO_PIN;

const int DOOR_OPEN_TIME_SECONDS = 5;

void heimdall_access_allowed(void)
{
    struct led_state led;

    gpio_set_level(RELAY1_GPIO_PIN, 1);
    gpio_set_level(RELAY2_GPIO_PIN, 1);
    gpio_set_level(RELAY3_GPIO_PIN, 1);

    led.leds[0] = 0x00FF00;
    ws2812_write_leds(led);

    sleep(DOOR_OPEN_TIME_SECONDS);

    gpio_set_level(RELAY1_GPIO_PIN, 0);
    gpio_set_level(RELAY2_GPIO_PIN, 0);
    gpio_set_level(RELAY3_GPIO_PIN, 0);

    led.leds[0] = 0x0;
    ws2812_write_leds(led);
}

void heimdall_access_denied(void)
{
    struct led_state led;

    led.leds[0] = 0xFF0000;
    ws2812_write_leds(led);

    sleep(DOOR_OPEN_TIME_SECONDS);

    led.leds[0] = 0x0;
    ws2812_write_leds(led);
}

void heimdall_access_error(void)
{
    
}
