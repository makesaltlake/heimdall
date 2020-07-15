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
    uint8_t irq1;

    const int MIFARE_READ_CMD = 0x30;

    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, MIFARE_READ_CMD);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, block);

    heimdall_rc663_write_reg(spi, RC663_REG_IRQ0, 0x7F);
    heimdall_rc663_write_reg(spi, RC663_REG_IRQ1, 0x7F);

    heimdall_rc663_cmd(spi, RC663_CMD_TRANSCEIVE);

    while (1) {
        irq1 = heimdall_rc663_read_reg(spi, RC663_REG_IRQ1);

        if ((irq1 & 0x40) != 0) {
            break;
        }
    }

    error = heimdall_rc663_read_reg(spi, RC663_REG_ERROR);
    if (!error)
        success = true;

    for (int i = 0; i < 16; i++)
    {
        data[i] = heimdall_rc663_read_reg(spi, RC663_REG_FIFO_DATA);
    }

    return success;
}

bool heimdall_rfid_write(spi_device_handle_t spi, uint8_t block, uint8_t data[16])
{
    const int MIFARE_WRITE_CMD = 0xA0;
    uint8_t i;

    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, MIFARE_WRITE_CMD);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, block);

    heimdall_rc663_write_reg(spi, RC663_REG_IRQ0, 0x7F);
    heimdall_rc663_write_reg(spi, RC663_REG_IRQ1, 0x7F);

    heimdall_rc663_cmd(spi, RC663_CMD_TRANSCEIVE);

    for (i = 0; i < 16; i++)
    {
        heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, data[i]);
    }

    heimdall_rc663_cmd(spi, RC663_CMD_TRANSCEIVE);

    return true;

}

void heimdall_rfid_authenticate(spi_device_handle_t spi, uint8_t *serial, char *key)
{
    uint8_t status;
    uint8_t error;

    ESP_LOGV(TAG, "Attempting to authenticate");

    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0xFF);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0xFF);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0xFF);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0xFF);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0xFF);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0xFF);

    heimdall_rc663_cmd(spi, RC663_CMD_LOAD_KEY);

    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0x60);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0x00); // Sector address
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, serial[0]);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, serial[1]);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, serial[2]);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, serial[3]);

    heimdall_rc663_cmd(spi, RC663_CMD_MF_AUTHENT);

    ESP_LOGV(TAG, "Authenticating...");

    int i = 0;

    do {
        status = heimdall_rc663_read_reg(spi, RC663_REG_STATUS);
        error = heimdall_rc663_read_reg(spi, RC663_REG_ERROR);
        if (status & 0x20) {
            ESP_LOGV(TAG, "Authentication succeeded");
            break;
        }

        ESP_LOGV(TAG, "ERROR%d %x, STATUS %x", i, error, status);
        i++;
    } while (1);
}
