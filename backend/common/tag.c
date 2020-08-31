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
#include <cJSON.h>

#include "clrc663.h"
#include "iso14443.h"
#include "mifare_classic.h"
#include "access.h"


static const char* TAG = "heimdall-card";


extern cJSON *access_list;

enum MIFARE_CARD_TYPE
{
    MIFARE_CLASSIC_1K,
    MIFARE_CLASSIC_4K,
    MIFARE_DESFIRE_LIGHT,
    MIFARE_PLUS_X,
    UNKNOWN_CARD_TYPE
};

enum MIFARE_CARD_TYPE wait_for_tag(spi_device_handle_t spi, uint8_t *uid, uint8_t *uid_len)
{
    bool got_card = false;
    uint8_t bcc = 0;
    uint8_t sak;
    enum MIFARE_CARD_TYPE type;
    uint8_t proprietary_coding;

    while (!got_card)
    {
        got_card = heimdall_rfid_reqa(spi, &proprietary_coding);
        if (!got_card)
        {
            vTaskDelay(100 / portTICK_PERIOD_MS);
            continue;
        }

        heimdall_rfid_anticollision(spi, 1, &uid, uid_len, &bcc);
        sak = heimdall_rfid_check_sak(spi, uid, *uid_len, bcc);

        if (sak & 0x04) {
            heimdall_rfid_anticollision(spi, 2, &uid, uid_len, &bcc);
            sak = heimdall_rfid_check_sak(spi, uid, *uid_len, bcc);
        }

        if (sak & 0x04) {
            heimdall_rfid_anticollision(spi, 3, &uid, uid_len, &bcc);
            sak = heimdall_rfid_check_sak(spi, uid, *uid_len, bcc);
        }

        for (int i = 0; i < *uid_len; i++)
        {
            ESP_LOGV(TAG, "U[%d] = %x", i, uid[i]);
        }
    }

    switch (sak)
    {
        case 0x08:
            type = MIFARE_CLASSIC_1K;
            break;
        case 0x18:
            type = MIFARE_CLASSIC_4K;
            break;
        case 0x20:
            if (proprietary_coding == 3)
                type = MIFARE_DESFIRE_LIGHT;
            else
                type = MIFARE_PLUS_X;
            break;
        default:
            type = UNKNOWN_CARD_TYPE;
            break;
    }

    return type;
}

void tag_writer(void *param)
{
     //   heimdall_rfid_personalize(spi);
     //   ESP_LOGV(TAG, "Personalization complete");


    spi_device_handle_t spi;
    uint8_t *uid = NULL;
    uint8_t uid_len;

    spi = heimdall_rfid_init(false);


     bool got_card;

     while (1) {
        enum MIFARE_CARD_TYPE card = wait_for_tag(spi, uid, &uid_len);



     }
}

void tag_reader(void *param)
{
    spi_device_handle_t spi;
    uint8_t *uid = NULL;
    uint8_t uid_len;
    const int MAX_UID_LEN = 11;

    uint8_t badge_uuid[16];

    spi = heimdall_rfid_init(true);

    uid = malloc(MAX_UID_LEN);

    while (1) {

        memset(uid, 0, MAX_UID_LEN);

        enum MIFARE_CARD_TYPE card = wait_for_tag(spi, uid, &uid_len);
    
        if (card == MIFARE_CLASSIC_1K || card == MIFARE_CLASSIC_4K)
        {  
            if (card == MIFARE_CLASSIC_1K)
                ESP_LOGI(TAG, "Found MIFARE Classic 1K card");
            else
                ESP_LOGI(TAG, "Found MIFARE Classic 4K card");

            memset(badge_uuid, 0, 16);

            printf("Tag UID (len %d): ", uid_len);
            for (int i = 0; i < uid_len; i++)
            {
                printf("%02x", uid[i]);
            }

            printf("\n");

            if (!heimdall_rfid_authenticate(spi, uid, "")) {
                ESP_LOGI(TAG, "Failed to authenticate tag");
                heimdall_access_error();
                vTaskDelay(100 / portTICK_PERIOD_MS);
                continue;
            }

            if (heimdall_rfid_read(spi, 1, &badge_uuid))
            {
                const int UUID_LEN = 37;
                char badge_uuid[UUID_LEN];
                const cJSON *valid_token;
                bool access_allowed = false;

                sprintf(badge_uuid, "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                    badge_uuid[0], badge_uuid[1], badge_uuid[2], badge_uuid[3],
                    badge_uuid[4], badge_uuid[5],
                    badge_uuid[6], badge_uuid[7],
                    badge_uuid[8], badge_uuid[9],
                    badge_uuid[10], badge_uuid[11], badge_uuid[12], badge_uuid[13], badge_uuid[14], badge_uuid[15]);

                ESP_LOGI(TAG, "Badge Token: %s", badge_uuid);

                cJSON_ArrayForEach(valid_token, access_list)
                {
                    if (strcasecmp(valid_token->valuestring, badge_uuid) == 0)
                    {
                        access_allowed = true;
                        break;
                    }
                }

                if (access_allowed) 
                {
                    heimdall_access_allowed();
                }
                else
                {                    
                    heimdall_access_denied();
                }
            }
            else
            {
                heimdall_access_error();
            }
            
            heimdall_rfid_deauthenticate(spi);
            heimdall_rc663_cmd(spi, RC663_CMD_IDLE);
        }
        else if (card == MIFARE_DESFIRE_LIGHT)
        {
            ESP_LOGI(TAG, "Found MIFARE DESFire Light card");
            heimdall_rfid_send_rats(spi);
        }
        else if (card == MIFARE_PLUS_X)
        {
            ESP_LOGW(TAG, "MIFARE Plus X isn't supported.");
        }
        else
        {
            ESP_LOGW(TAG, "Unknown/unsupported card detected.");
        }

        // Delay to allow other tasks to run
        vTaskDelay(100 / portTICK_PERIOD_MS);
    }
}
