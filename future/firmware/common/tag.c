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
#include "network.h"

#include "uuid.h"


static const char* TAG = "heimdall-card";
static const int MAX_UID_LEN = 11;

extern char *tag_key;

void print_card_uid(uint8_t *uid, int uid_len);

void update_uuid_lbl(const char *new_uuid);
void update_status_lbl(const char *txt);
void update_name_lbl(const char *txt, bool success);
void welcome_text(void);

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

        printf("UID: ");
        for (int i = 0; i < *uid_len; i++)
        {
            printf(TAG, "%02X", uid[i]);
        }
        printf("\n");
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
    spi_device_handle_t spi;
    uint8_t *uid = NULL;
    uint8_t uid_len;
    char mfg_default_key[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

    uint8_t badge_uuid[16];

    spi = heimdall_rfid_init(false);

    uid = malloc(MAX_UID_LEN);

    while (1) {
        memset(uid, 0, MAX_UID_LEN);

        vTaskDelay(10000 / portTICK_PERIOD_MS);
        welcome_text();

        enum MIFARE_CARD_TYPE card = wait_for_tag(spi, uid, &uid_len);
        ESP_LOGI(TAG, "Got card %d, with UID %02X%02X%02X%02X", card, uid[0], uid[1], uid[2], uid[3]);

        print_card_uid(uid, uid_len);

        update_status_lbl("Found Card. Informing Web API...");

        uuid_t badge_uuid, uu2;
        char uu_str[UUID_STR_LEN];
        int r;
        uuid_generate(badge_uuid);

       // ESP_LOG_BUFFER_HEXDUMP(TAG, badge_uuid, sizeof(uuid_t), ESP_LOG_WARN);

        uuid_unparse(badge_uuid, uu_str);
        ESP_LOGW(TAG, "UUID: %s", uu_str);

        update_uuid_lbl(uu_str);

        char name[128];
        bool success = send_badge_program(uu_str, name, 128);

        if (success)
            update_status_lbl("Web API success. Programming card...");
        else
            update_status_lbl(name);

        printf("Programming for %s\n", name);

        if (success) {
            // Actually program the badge
            if (!heimdall_rfid_authenticate(spi, uid, mfg_default_key)) {

                ESP_LOGI(TAG, "Failed to authenticate with default manufacturer key: retrying with TAG_KEY");

                wait_for_tag(spi, uid, &uid_len);
                // Retry with the TAG_KEY
                if (!heimdall_rfid_authenticate(spi, uid, tag_key)) {
                    ESP_LOGI(TAG, "Failed to authenticate tag");
                    vTaskDelay(100 / portTICK_PERIOD_MS);
                    continue;
                }
            }

            ESP_LOGI(TAG, "Writing new user UUID %02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                badge_uuid[0], badge_uuid[1], badge_uuid[2], badge_uuid[3],
                badge_uuid[4], badge_uuid[5],
                badge_uuid[6], badge_uuid[7],
                badge_uuid[8], badge_uuid[9],
                badge_uuid[10], badge_uuid[11], badge_uuid[12], badge_uuid[13], badge_uuid[14], badge_uuid[15]);
            success = heimdall_rfid_write(spi, 1, badge_uuid);
            if (!success) {
                ESP_LOGW(TAG, "Failed to write new badge UUID");
                update_status_lbl("Program card: UUID write error");
                continue;
            }

            uint8_t data[16] = {0};
            ESP_LOGI(TAG, "Reading sector trailer");
            success = heimdall_rfid_read(spi, 3, data);
            if (!success) {
                ESP_LOGW(TAG, "Failed to read existing sector trailer");

                update_status_lbl("Program card: read error");

                continue;
            }

            // Fill in the new KEY A
            memcpy(data, tag_key, 6);

            data[6] = 0xff;
            data[7] = 0x07;
            data[8] = 0x80;
            data[9] = 0x00;

            // Set KEY B to a series of random bytes
            esp_fill_random(data + 10, 6);

            ESP_LOGI(TAG, "New sector trailer:");
            for (int i = 0; i < 16; i++) {
                printf("%02x ", data[i]);
            }
            printf("\n");

            ESP_LOGI(TAG, "Writing new sector trailer");

            success = heimdall_rfid_write(spi, 3, data);
            if (!success) {
                ESP_LOGW(TAG, "Failed to write new sector trailer");
                update_status_lbl("Program card: write error");
                continue;
            }

            heimdall_rc663_cmd(spi, RC663_CMD_IDLE);
            heimdall_rfid_deauthenticate(spi);

            update_status_lbl("Program card: success");
            printf("Programmed card for %s\n", name);
            update_name_lbl(name, true);
        }
    }
}

void print_card_uid(uint8_t *uid, int uid_len)
{
    printf("Tag UID (len %d): ", uid_len);
    for (int i = 0; i < uid_len; i++)
    {
        printf("%02x", uid[i]);
    }

    printf("\n");
}

void tag_reader(void *param)
{
    spi_device_handle_t spi;
    uint8_t *uid = NULL;
    uint8_t uid_len;
    const int UUID_LEN = 37;
    uint8_t badge_uuid[UUID_LEN];

    spi = heimdall_rfid_init(true);

    uid = malloc(MAX_UID_LEN);

    while (1) {

        memset(uid, 0, MAX_UID_LEN);
        memset(badge_uuid, 0, UUID_LEN);

        enum MIFARE_CARD_TYPE card = wait_for_tag(spi, uid, &uid_len);

        if (card == MIFARE_CLASSIC_1K || card == MIFARE_CLASSIC_4K)
        {
            if (card == MIFARE_CLASSIC_1K)
                ESP_LOGI(TAG, "Found MIFARE Classic 1K card");
            else
                ESP_LOGI(TAG, "Found MIFARE Classic 4K card");

            memset(badge_uuid, 0, 16);

            print_card_uid(uid, uid_len);

            if (!heimdall_rfid_authenticate(spi, uid, tag_key)) {
                ESP_LOGW(TAG, "Failed to authenticate tag with key %02x%02x%02x%02x%02x%02x",
                    tag_key[0],tag_key[1],tag_key[2],tag_key[3],tag_key[4],tag_key[5]);
                heimdall_access_error();
                vTaskDelay(5000 / portTICK_PERIOD_MS);
                continue;
            }

            if (heimdall_rfid_read(spi, 1, badge_uuid))
            {
                const cJSON *valid_token, *tokens;
                bool access_allowed = false;

                char uu_str[UUID_STR_LEN];

                uuid_unparse(badge_uuid, uu_str);

                ESP_LOGI(TAG, "Badge Token: %s", uu_str);

                tokens = cJSON_GetObjectItem(access_list, "badge_tokens");
                cJSON_ArrayForEach(valid_token, tokens) {

                    ESP_LOGI(TAG, "valid_token=%p, type=%d", valid_token, valid_token->type);

                    ESP_LOGI(TAG, "Comparing badge against UUID %s\n", valid_token->valuestring);
                    if (strcasecmp(valid_token->valuestring, uu_str) == 0)
                    {
                        ESP_LOGI(TAG, "Found badge UUID in access list. Allowing access.");
                        access_allowed = true;
                        break;
                    }
                }

                if (access_allowed)
                {
                    ESP_LOGI(TAG, "Valid token presented. Allowing access.");
                    heimdall_access_allowed();
                }
                else
                {
                    ESP_LOGI(TAG, "Invalid token presented. Not allowing access.");
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
        vTaskDelay(2000 / portTICK_PERIOD_MS);
    }
}
