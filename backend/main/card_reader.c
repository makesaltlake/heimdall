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

#include <esp_system.h>
#include <esp_event.h>
#include <driver/gpio.h>
#include <driver/adc.h>
#include <driver/i2c.h>
#include <driver/spi_master.h>
#include <esp_log.h>
#include <esp_adc_cal.h>

#include "clrc663.h"
#include "iso14443.h"
#include "mifare_classic.h"


static const char* TAG = "heimdall-card";

enum MIFARE_CARD_TYPE
{
    MIFARE_CLASSIC_1K = 0x08,
    MIFARE_CLASSIC_4K = 0x18,
    MIFARE_DESFIRE_LIGHT = 0x20
};

void tag_writer(void *param)
{
     //   heimdall_rfid_personalize(spi);
     //   ESP_LOGV(TAG, "Personalization complete");
}

void tag_reader(void *param)
{
    spi_device_handle_t spi;
    bool got_card;
    uint8_t *uid = NULL;
    uint8_t len = 0;
    uint8_t bcc = 0;
    uint8_t sak;
    uint8_t data[16];

    spi = heimdall_rfid_init();

    while (1) {

        got_card = heimdall_rfid_reqa(spi);
        if (!got_card)
        {
            vTaskDelay(100 / portTICK_PERIOD_MS);
            continue;
        }

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


        // MIFARE card types:
        // MIFARE DESfire light: ATQA 0x0344, SAK 0x20
        // MIFARE Classic 1K (S50): ATQA 0x0004, SAK 0x08
        // MIFARE Classic 4K (S70): ATQA 0x0002, SAK 0x18

        enum MIFARE_CARD_TYPE card = sak;

        switch (card)
        {
            case MIFARE_DESFIRE_LIGHT:
                ESP_LOGI(TAG, "Found MIFARE DESFire Light card");
                heimdall_rfid_send_rats(spi);
                break;
            case MIFARE_CLASSIC_1K:
                ESP_LOGI(TAG, "Found MIFARE Classic 1K card");
                break;
            case MIFARE_CLASSIC_4K:
                ESP_LOGI(TAG, "Found MIFARE Classic 4K card");
                break;
            default:
                ESP_LOGI(TAG, "Unknown card found");
                break;
        }

        if (card == MIFARE_CLASSIC_1K)
        {
            memset(data, 0, 16);

            if (heimdall_rfid_authenticate(spi, uid, ""))
            {

                if (heimdall_rfid_read(spi, 1, &data))
                {
                    ESP_LOGV(TAG, "DATA: %x %x %x %x %x %x %x %x %x %x %x %x %x %x %x %x",
                    data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15]);
                } else {
                    ESP_LOGW(TAG, "Failed to read data");
                }

                heimdall_rfid_deauthenticate(spi);
            }
            heimdall_rc663_cmd(spi, RC663_CMD_IDLE);
        }

        // Delay to allow other tasks to run
        vTaskDelay(100 / portTICK_PERIOD_MS);
    }
}