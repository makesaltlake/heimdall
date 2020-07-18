/*
 * Copyright (C) 2020 Rebecca Cran <rebecca@bsdio.com>.
 *
 */

#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

#include <esp_log.h>
#include <driver/gpio.h>
#include <freertos/queue.h>
#include <esp_err.h>
#include <driver/gpio.h>
#include <string.h>


#include "clrc663.h"

static const char* TAG = "heimdall-iso14443";


bool heimdall_rfid_reqa(spi_device_handle_t spi)
{
    uint8_t b1_b8;
    uint8_t b9_b16;
    uint8_t irq1;
    uint8_t bit_frame_anticollision;
    uint8_t uid_size;
    uint8_t error;

    clear_irq(spi, 0);
    clear_irq(spi, 1);

    // Fill FIFO with 0x26 (REQA)
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0x26);
    // Exec Transceive command
    heimdall_rc663_cmd(spi, RC663_CMD_TRANSCEIVE);
    // Wait until a card responds by checking IRQ0 register

    while (1) {
        irq1 = heimdall_rc663_read_reg(spi, RC663_REG_IRQ1);

        if ((irq1 & 0x40) != 0) {
            break;
        }
    }

    error = heimdall_rc663_read_reg(spi, RC663_REG_ERROR);
    if (error & 0x10) {
        ESP_LOGW(TAG, "REQA: failed to read tag - bad Start Of Frame");
        return false;
    }

    // Read 2 bytes from FIFO to get ATQA
    assert(heimdall_rc663_read_reg(spi, RC663_REG_FIFO_LENGTH) == 2);


    b1_b8 = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA);
    b9_b16 = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA);

    ESP_LOGV(TAG, "b1:b8: %X, b9:b16: %x", b1_b8, b9_b16);

    //bit_frame_anticollision = b1_b8 & 0x1F;
    uid_size = (b1_b8 & 0xC0) >> 5;

    // uid_size codings:
    // 0 : single
    // 1: double
    // 2: triple
    // 3: reserved for future use
    ESP_LOGV(TAG, "UID size:");

    switch (uid_size) {
        case 0:
            ESP_LOGV(TAG, "\tsingle");
            break;
        case 1:
            ESP_LOGV(TAG, "\tdouble");
            break;
        case 2:
            ESP_LOGV(TAG, "\ttriple");
            break;
        default:
            ESP_LOGV(TAG, "\treserved");
            break;
    }

    return true;
}

int heimdall_rfid_anticollision(spi_device_handle_t spi, int level, uint8_t **uid, uint8_t *len, uint8_t *bcc)
{
    uint8_t sel = 0;
    uint8_t irq1;
    uint8_t error;
    uint8_t fifo_length;
    uint8_t i, j;
    uint8_t bcc_calc, bcc_val;
    bool collision;
    uint8_t collision_bit = 0;
    uint8_t num_valid_bits = 16;
    uint8_t *p;
    uint8_t uid_start = 4 * (level - 1);
    uint8_t shift = 0;

    const int CASCADE_LEVEL_1 = 0x93;
    const int CASCADE_LEVEL_2 = 0x95;
    const int CASCADE_LEVEL_3 = 0x97;

    switch (level) {
        case 1:
            sel = CASCADE_LEVEL_1;
            break;
        case 2:
            sel = CASCADE_LEVEL_2;
            break;
        case 3:
            sel = CASCADE_LEVEL_3;
            break;
        default:
            ESP_LOGE(TAG, "Invalid cascade level");
            ESP_ERROR_CHECK(0);
    }

    const int MAX_UID_LEN = 11;

    // Disable CRC
    heimdall_rc663_write_reg(spi, RC663_REG_TX_CRC_PRESET, 0x18 | 0);
    heimdall_rc663_write_reg(spi, RC663_REG_RX_CRC_PRESET, 0x18 | 0);

    if (*uid != NULL)
        (*uid)[uid_start] = 0;

    // Since each CLx has 4 bytes at most, we have a maximum of 32 times
    // around the anti-collision loop
    for (i = 0; i < 32; i++) {

        // Fill FIFO with [ SEL - NVB ]
        heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, sel);
        heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, ((num_valid_bits / 8) << 4) + (num_valid_bits % 8));

        p = *uid;

        for (j = 0; j < ((num_valid_bits - 9) / 8); j++) {
            heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, p[uid_start + j]);
        }

        // Only last `num_valid_bits` bits will be sent to the PICC
        heimdall_rc663_write_reg(spi, RC663_REG_TX_DATA_NUM, 0x08 | (num_valid_bits % 8));

        heimdall_rc663_write_reg(spi, RC663_REG_RX_BIT_CTRL, (num_valid_bits % 8) << 4);

        clear_irq(spi, 0);
        clear_irq(spi, 1);

        // Exec Transceive command
        heimdall_rc663_cmd(spi, RC663_CMD_TRANSCEIVE);

        while (1) {
            irq1 = heimdall_rc663_read_reg(spi, RC663_REG_IRQ1);

            if ((irq1 & 0x40) != 0) {
                break;
            }
        }

        error = heimdall_rc663_read_reg(spi, RC663_REG_ERROR);
        if (error & 0x10)
            ESP_LOGW(TAG, "CL%x: Failed to read tag: got bad Start Of Frame", level);

        if (error != 0 && error != 4) {
            ESP_LOGW(TAG, "error in anti-collision: %x", error);
            return 1;
        }

        collision = heimdall_rc663_read_reg(spi, RC663_REG_RX_COLL) & 0x80;

        if (collision) {
            collision_bit = heimdall_rc663_read_reg(spi, RC663_REG_RX_COLL) & 0x7F;
            ESP_LOGW(TAG, "Collision detected at bit position %d", collision_bit);
            uint8_t irq0 = heimdall_rc663_read_reg(spi, RC663_REG_IRQ0);
            if (irq0 & 2)
                ESP_LOGW(TAG, "IRQ0 reports an error");
        }

        fifo_length = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_LENGTH);

        if (*uid == NULL) {
            *uid = malloc(MAX_UID_LEN);
            memset(*uid, 0, MAX_UID_LEN);
        }

        assert(*uid != NULL);

        p = *uid;

        uint8_t byte_start = uid_start + ((num_valid_bits - 16) / 8);
        uint8_t val;

        for (j = 0; j < fifo_length; j++) {
            val = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA);
            if ((i > 0 && j == 0) || (collision && (collision_bit / 8) == j)) {
                p[byte_start + j] |= val;
                shift = collision_bit % 8;
                if (collision)
                    num_valid_bits += (collision_bit % 8);
                else
                {
                    num_valid_bits += 8;
                }
            } else {
                p[byte_start + j] |= val;
                num_valid_bits += 8;
            }
        }

        if (collision) {
            num_valid_bits++;
        }

        if (!collision)
            break;
    }

    bcc_calc = 0;
    uint8_t start;
    if (level == 1)
        start = 0;
    else if (level == 2)
        start = 4;
    else
        start = 8;

    p = *uid;

    num_valid_bits -= 16;
    bcc_val = p[uid_start + ((num_valid_bits / 8) - 1)];
    bcc_calc = 0;

    for (j = 0; j < (num_valid_bits / 8) - 1; j++) {
        bcc_calc ^= p[uid_start + j];
    }

    *len += (num_valid_bits / 8) - 1;

    // Only last `num_valid_bits` bits will be sent to the PICC
    heimdall_rc663_write_reg(spi, RC663_REG_TX_DATA_NUM, 0x08);
    heimdall_rc663_write_reg(spi, RC663_REG_RX_BIT_CTRL, 0);

    assert(bcc_val == bcc_calc);
    *bcc = bcc_val;
    return 0;
}


// Sends a Request for Answer To Select (RATS)
void heimdall_rfid_send_rats(spi_device_handle_t spi)
{
    int max_picc_frame;
    
    // FSD 256, FSDI 8
    // CID 0
    uint8_t param = (8 << 4) | 0x00;

    const uint8_t ISO14443_CMD_RATS = 0xE0;

    heimdall_rfid_set_timer(spi, 100);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, ISO14443_CMD_RATS);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, param);

    heimdall_rc663_cmd(spi, RC663_CMD_TRANSCEIVE);

    if (heimdall_wait(spi)) {

        vTaskDelay(500 / portTICK_PERIOD_MS);

        uint8_t len = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_LENGTH);
        if (heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA) != len)
            ESP_LOGW(TAG, "ATS Length and FIFO length disagree");

        ESP_LOGV(TAG, "FIFO LEN is %d", len);

        if (len > 1) {
                uint8_t format_t0 = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA);
                bool ta = (format_t0 & 0x10);
                bool tb = (format_t0 & 0x20);
                bool tc = (format_t0 & 0x40);

                uint8_t fsdi = format_t0 & 0x0F;

                switch (fsdi) {
                    case 0x00:
                        max_picc_frame = 16;
                        break;
                    case 0x01:
                        max_picc_frame = 24;
                        break;
                    case 0x02:
                        max_picc_frame = 32;
                        break;
                    case 0x03:
                        max_picc_frame = 40;
                        break;
                    case 0x04:
                        max_picc_frame = 48;
                        break;
                    case 0x05:
                        max_picc_frame = 64;
                        break;
                    case 0x06:
                        max_picc_frame = 96;
                        break;
                    case 0x07:
                        max_picc_frame = 128;
                        break;
                    case 0x08:
                        max_picc_frame = 256;
                        break;
                    case 0x09:
                        max_picc_frame = 512;
                        break;
                    case 0x0A:
                        max_picc_frame = 1024;
                        break;
                    case 0x0B:
                        max_picc_frame = 2048;
                        break;
                    case 0x0C:
                        max_picc_frame = 4096;
                        break;
                    default:
                        ESP_LOGE(TAG, "Got reserved (RFU) FSDI value %d", fsdi);
                        assert(0);
                }

                ESP_LOGV(TAG, "PICC frame size: %d", max_picc_frame);

                if (ta)
                    ESP_LOGV(TAG, "TA: %x", heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA));
                if (tb)
                    ESP_LOGV(TAG, "TB: %x", heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA));
                if (tc)
                    ESP_LOGV(TAG, "TC: %x", heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA));

                for (int i = 0; i < heimdall_rc663_read_reg(spi, RC663_REG_FIFO_LENGTH); i++)
                {
                    ESP_LOGV(TAG, "ATS Historical byte: %x", heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA));
                }
        }
    }
}

uint8_t heimdall_rfid_check_sak(spi_device_handle_t spi, uint8_t *uid, uint8_t uid_len, uint8_t bcc)
{
    uint8_t irq1;
    uint8_t sak;
    uint8_t i;
    uint8_t sel = 0;
    uint8_t uid_start = 0;
    uint8_t error = 0;

    if (uid_len == 4) {
        sel = 0x93;
        uid_start = 0;
    } else if (uid_len == 8) {
        sel = 0x95;
        uid_start = 4;
    } else
    {
        sel = 0x97;
        uid_start = 8;
    }

    heimdall_rc663_cmd(spi, RC663_CMD_IDLE);

    heimdall_rc663_write_reg(spi, RC663_REG_IRQ0, 0x7F);
    heimdall_rc663_write_reg(spi, RC663_REG_IRQ1, 0x7F);

    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, sel);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0x70);

    for (i = uid_start; i < uid_len; i++) 
    {
        heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, uid[i]);
    }

    // Add the Block Check Character
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, bcc);

    // Enable CRCs
    heimdall_rc663_write_reg(spi, RC663_REG_TX_CRC_PRESET, 0x18 | 1);
    heimdall_rc663_write_reg(spi, RC663_REG_RX_CRC_PRESET, 0x18 | 1);

    heimdall_rc663_write_reg(spi, RC663_REG_IRQ0, 0x7F);
    heimdall_rc663_write_reg(spi, RC663_REG_IRQ1, 0x7F);

    // Exec Transceive command
    heimdall_rc663_cmd(spi, RC663_CMD_TRANSCEIVE);

    while (1) {
        irq1 = heimdall_rc663_read_reg(spi, RC663_REG_IRQ1);

        if ((irq1 & 0x40) != 0) {
            break;
        }

        vTaskDelay(10 / portTICK_PERIOD_MS);
    }

    error = heimdall_rc663_read_reg(spi, RC663_REG_ERROR);

    if (error & 0x10)
        ESP_LOGW(TAG, "SAK: Failed to read tag: got bad Start Of Frame");

    if (error) {
        ESP_LOGW(TAG, "error in SAK: %x", error);
        return 0xFF;
    }

    sak = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA);

    ESP_LOGV(TAG, "GOT SAK: %X", sak);

    return sak;
}
