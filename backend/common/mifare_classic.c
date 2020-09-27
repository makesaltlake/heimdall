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

static const char* TAG = "heimdall-mifare-classic";


bool heimdall_rfid_personalize(spi_device_handle_t spi)
{
    const int MIFARE_PERSONALIZE_CMD = 0x40;
    const int MIFARE_PERSONALIZE_UIDF0 = 0x00;

    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, MIFARE_PERSONALIZE_CMD);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, MIFARE_PERSONALIZE_UIDF0);

    heimdall_rc663_cmd(spi, RC663_CMD_TRANSCEIVE);

    heimdall_rfid_set_timer(spi, 100);
    heimdall_wait(spi);

    return true;
}

bool heimdall_rfid_read(spi_device_handle_t spi, uint8_t block, uint8_t data[16])
{
    bool success = false;
    uint8_t error;

    const int MIFARE_READ_CMD = 0x30;

    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, MIFARE_READ_CMD);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, block);

    clear_irq(spi, 0);
    clear_irq(spi, 1);

    heimdall_rfid_set_timer(spi, 200);

    heimdall_rc663_cmd(spi, RC663_CMD_TRANSCEIVE);

    heimdall_wait(spi);

    error = heimdall_rc663_read_reg(spi, RC663_REG_ERROR);
    if (!error) {
        success = true;
    } else {
        ESP_LOGW(TAG, "RFID Read: error register contains value %d", error);
    }

    for (int i = 0; i < 16; i++)
    {
        data[i] = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA);
    }

    return success;
}

const int MIFARE_ACK = 0x0A;
const int MIFARE_NACK_INVALID_OP = 0x01;

bool heimdall_rfid_write(spi_device_handle_t spi, uint8_t block, uint8_t data[16])
{
    const int MIFARE_WRITE_CMD = 0xA0;
    uint8_t i;
    uint8_t val;

    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, MIFARE_WRITE_CMD);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, block);

    heimdall_rc663_write_reg(spi, RC663_REG_TX_CRC_PRESET, 0x18 | 1);
    heimdall_rc663_write_reg(spi, RC663_REG_RX_CRC_PRESET, 0x18 | 0);

    heimdall_rc663_write_reg(spi, RC663_REG_IRQ0, 0x7F);
    heimdall_rc663_write_reg(spi, RC663_REG_IRQ1, 0x7F);

    heimdall_rc663_cmd(spi, RC663_CMD_TRANSCEIVE);

    heimdall_rfid_set_timer(spi, 300);
    heimdall_wait(spi);

    val = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_LENGTH);
    if (val != 1) {
        return false;
    }

    val = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA);
    if (val != 0x0A) {
        return false;
    }

    for (i = 0; i < 16; i++)
    {
        heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, data[i]);
    }

    heimdall_rc663_write_reg(spi, RC663_REG_IRQ0, 0x7F);
    heimdall_rc663_write_reg(spi, RC663_REG_IRQ1, 0x7F);

    heimdall_rc663_cmd(spi, RC663_CMD_TRANSCEIVE);

    heimdall_rfid_set_timer(spi, 300);
    heimdall_wait(spi);

    val = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_LENGTH);
    if (val != 1) {
        return false;
    }

    val = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA);
    if (val != 0x0A) {
        return false;
    }

    uint8_t err = heimdall_rc663_read_reg(spi, RC663_REG_ERROR);

    heimdall_rc663_write_reg(spi, RC663_REG_TX_CRC_PRESET, 0x18 | 1);
    heimdall_rc663_write_reg(spi, RC663_REG_RX_CRC_PRESET, 0x18 | 1);

    return true;

}

bool heimdall_rfid_authenticate(spi_device_handle_t spi, uint8_t *serial, char *key)
{
    uint8_t status;
    bool success = false;

//    ESP_LOGV(TAG, "Attempting to authenticate with key %02x%02x%02x%02x%02x%02x, for UID %02x%02x%02x%02x",
//                    key[0], key[1], key[2], key[3], key[4], key[5],
//                    serial[0], serial[1], serial[2], serial[3]);

    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, key[0]);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, key[1]);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, key[2]);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, key[3]);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, key[4]);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, key[5]);

    heimdall_rc663_cmd(spi, RC663_CMD_LOAD_KEY);

    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0x60);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0x03); // Block address
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, serial[0]);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, serial[1]);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, serial[2]);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, serial[3]);

    heimdall_rc663_cmd(spi, RC663_CMD_MF_AUTHENT);

    int retries = 0;

    while (retries++ < 10)
    {
        status = heimdall_rc663_read_reg(spi, RC663_REG_STATUS);
        if (status & 0x20) {
            ESP_LOGV(TAG, "Authentication succeeded");
            success = true;
            break;
        }

        vTaskDelay(20 / portTICK_PERIOD_MS);
    }

//    uint8_t err = heimdall_rc663_read_reg(spi, RC663_REG_ERROR);
//    if (err & 0x02) {
//        printf("ProtocolErr\n");
//    } else {
//        printf("error reg: %02x\n", err);
//    }

    return success;
}

void heimdall_rfid_deauthenticate(spi_device_handle_t spi)
{
    // Turn off MIFARE Classic Crypto
    heimdall_rc663_write_reg(spi, RC663_REG_STATUS, 0);
}