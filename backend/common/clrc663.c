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

static const char* TAG = "heimdall-clrc663";


void heimdall_rc663_cmd(spi_device_handle_t spi, uint8_t cmd)
{
    heimdall_rc663_write_reg(spi, RC663_REG_COMMAND, cmd);
}

void clear_irq(spi_device_handle_t spi, int irq)
{
    if (irq == 0)
        heimdall_rc663_write_reg(spi, RC663_REG_IRQ0, 0x7F);
    else
        heimdall_rc663_write_reg(spi, RC663_REG_IRQ1, 0x7F);
}

void heimdall_rc663_write_reg(spi_device_handle_t spi, uint8_t reg, uint8_t value)
{
    spi_transaction_t t = {
        .length = 8,
        .addr = reg << 1,
        .cmd  = reg << 1,
        .tx_buffer = &value,
    };

    ESP_ERROR_CHECK(spi_device_polling_transmit(spi, &t));
}

void heimdall_rc663_write_data(spi_device_handle_t spi, uint8_t reg, uint8_t *buffer, int length)
{
    spi_transaction_t t = {
        .length = 8 * length,
        .addr = reg << 1,
        .cmd  = reg << 1,
        .tx_buffer = buffer,
    };

    ESP_ERROR_CHECK(spi_device_polling_transmit(spi, &t));


}

uint8_t heimdall_rc663_read_reg(spi_device_handle_t spi, uint8_t reg)
{
    uint8_t value = 0;

    spi_transaction_t t = {
        .length = 8,
        .addr = (reg << 1) | 1,
        .cmd  = (reg << 1) | 1,
        .rx_buffer = &value,
    };

    ESP_ERROR_CHECK(spi_device_polling_transmit(spi, &t));

    return value;
}

uint8_t heimdall_rc663_get_version(spi_device_handle_t spi)
{
    uint8_t version;

    version = heimdall_rc663_read_reg(spi, RC663_REG_VERSION);

    return version;
}


spi_device_handle_t heimdall_rfid_init(bool rfid_reader)
{
    spi_device_handle_t spi;
    uint8_t clrc663_version;

    int SPI_MISO_PIN_NUM;
    int SPI_MOSI_PIN_NUM;
    int SPI_SCLK_PIN_NUM;
    int SPI_CS_PIN_NUM;

    // Pins are as specified in the KiCad project boards/inside_board
    if (rfid_reader)
    {
        SPI_MISO_PIN_NUM = 27;
        SPI_MOSI_PIN_NUM = 26;
        SPI_SCLK_PIN_NUM = 25;
        SPI_CS_PIN_NUM   = 32;

        ESP_LOGI(TAG, "Operating in RFID Reader mode");
    }
    else
    {
        // Writer
        SPI_MISO_PIN_NUM = 2;
        SPI_MOSI_PIN_NUM = 3;
        SPI_SCLK_PIN_NUM = 1;
        SPI_CS_PIN_NUM   = 4;

        ESP_LOGI(TAG, "Operating in RFID Writer mode");
    }

    spi_bus_config_t buscfg = {
        .miso_io_num = SPI_MISO_PIN_NUM,
        .mosi_io_num = SPI_MOSI_PIN_NUM,
        .sclk_io_num = SPI_SCLK_PIN_NUM,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = 0,
        .flags = SPICOMMON_BUSFLAG_MASTER
    };

    spi_device_interface_config_t devcfg = {
        .clock_speed_hz = SPI_BUS_SPEED_HZ,
        .mode = 0,
        .spics_io_num = SPI_CS_PIN_NUM,
        .queue_size = 20,
        .pre_cb = NULL,
        .command_bits=0,
        .address_bits=8,
        .flags = 0,
    };

    ESP_ERROR_CHECK(spi_bus_initialize(HSPI_HOST, &buscfg, 0));
    ESP_ERROR_CHECK(spi_bus_add_device(HSPI_HOST, &devcfg, &spi));

    heimdall_rc663_cmd(spi, RC663_CMD_SOFT_RESET);
    vTaskDelay(500 / portTICK_PERIOD_MS);

    heimdall_rc663_write_reg(spi, RC663_REG_COMMAND, 0);

    ESP_LOGI(TAG, "Waiting for RC663 to complete power-up");

    while ((heimdall_rc663_read_reg(spi, RC663_REG_COMMAND) & 0xC0) > 0) {
        vTaskDelay(50 / portTICK_PERIOD_MS);
    }

    ESP_LOGI(TAG, "Power-up complete");
    clrc663_version = heimdall_rc663_read_reg(spi, RC663_REG_VERSION);

    switch (clrc663_version) {
        case 0x18:
            ESP_LOGI(TAG, "CLRC66x01 or CLRC66x02 found (version 0x%02X)", clrc663_version);
            break;
        case 0x1A:
            ESP_LOGI(TAG, "CLRC66x03 found (version 0x%02X)", clrc663_version);
            break;
        default:
            ESP_LOGE(TAG, "Unsupported NFC chip found (version 0x%02X)", clrc663_version);
            assert(0);
    }

    // Cancels any previous executions and return to IDLE mode
    heimdall_rc663_cmd(spi, RC663_CMD_IDLE);

    // Flush the FIFO and define FIFO characteristics
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_CONTROL, 0xB0);

    // Fill the FIFO for the LoadProtocol command
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0x00); // Rx Protocol
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0x00); // Tx Protocol

    // Exec LoadProtocol. This loads protocol ISO 14443A - 106
    heimdall_rc663_cmd(spi, RC663_CMD_LOAD_PROTOCOL);

    // Flush FIFO and define FIFO characteristics
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_CONTROL, 0xB0);

    // Switch RF field on
    heimdall_rc663_write_reg(spi, RC663_REG_DRV_MODE, 0x8A);

    // Clear all bits in IRQ0
    heimdall_rc663_write_reg(spi, RC663_REG_IRQ0, 0x7F);

    // Switch CRC extension OFF for Tx
    heimdall_rc663_write_reg(spi, RC663_REG_TX_CRC_PRESET, 0x18);
    // Switch CRC extension OFF for Rx
    heimdall_rc663_write_reg(spi, RC663_REG_RX_CRC_PRESET, 0x18);
    // Only last 7 bits will be sent
    heimdall_rc663_write_reg(spi, RC663_REG_TX_DATA_NUM, 0x0F);

    heimdall_rc663_write_reg(spi, RC663_REG_IRQ0_EN, 6);
    heimdall_rc663_write_reg(spi, RC663_REG_IRQ1_EN, 0x00);

    heimdall_rc663_write_reg(spi, RC663_REG_IRQ0, 0x7F);
    heimdall_rc663_write_reg(spi, RC663_REG_IRQ1, 0x7F);

    return spi;
}

void heimdall_rfid_set_timer(spi_device_handle_t spi, int milliseconds)
{
    heimdall_rc663_write_reg(spi, RC663_REG_T_CONTROL, 0x00);
    // Use the 211.875 KHz timer
    heimdall_rc663_write_reg(spi, RC663_REG_T0_CONTROL, 0x11);

    // Each tick of the 211.875 kHz timer is 5 microseconds

    // The timer supports up to 327ms
    assert(milliseconds <= 327);

    uint16_t val = (milliseconds * 1000UL) / 5;

    heimdall_rc663_write_reg(spi, RC663_REG_T0_RELOAD_HI, val >> 8);
    heimdall_rc663_write_reg(spi, RC663_REG_T0_RELOAD_LO, val & 0xFF);

    heimdall_rc663_write_reg(spi, RC663_REG_IRQ1_EN, 0x01);
}

bool heimdall_wait(spi_device_handle_t spi)
{
    bool success = true;
    uint8_t irq1;
    uint8_t error = 0;

    while (1) {
        irq1 = heimdall_rc663_read_reg(spi, RC663_REG_IRQ1);

        if ((irq1 & 0x41) != 0) {
            break;
        }
    }

    if (irq1 & 0x01) {
        success = false;
    }

    if (success)
        error = heimdall_rc663_read_reg(spi, RC663_REG_ERROR);

    if (error) {
        ESP_LOGV(TAG, "ERROR: %x", error);
        success = false;
    }

    return success;

}
