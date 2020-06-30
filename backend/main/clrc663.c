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

#include "clrc663.h"

static const char *TAG = "heimdall-clrc663";


static void heimdall_rc663_write_reg(spi_device_handle_t spi, uint8_t reg, uint8_t value);
static void heimdall_rc663_cmd(spi_device_handle_t spi, uint8_t cmd);
static uint8_t heimdall_rc663_read_reg(spi_device_handle_t spi, uint8_t reg);

static void heimdall_rc663_cmd(spi_device_handle_t spi, uint8_t cmd)
{
    heimdall_rc663_write_reg(spi, RC663_REG_COMMAND, cmd);
}

static void heimdall_rc663_write_reg(spi_device_handle_t spi, uint8_t reg, uint8_t value)
{
    spi_transaction_t t = {
        .length = 8,
        .addr = reg,
        .cmd  = reg,
        .tx_buffer = &value,
    };

    ESP_ERROR_CHECK(spi_device_polling_transmit(spi, &t));
}

static uint8_t heimdall_rc663_read_reg(spi_device_handle_t spi, uint8_t reg)
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
    uint8_t version = 0;

    version = heimdall_rc663_read_reg(spi, RC663_REG_VERSION);

    return version;
}



spi_device_handle_t heimdall_rc663_init(void)
{
    spi_device_handle_t spi;

    const int RC522_SPI_MISO_PIN_NUM = 19;
    const int RC522_SPI_MOSI_PIN_NUM = 18;
    const int RC522_SPI_SCLK_PIN_NUM = 5;
    const int RC522_SPI_CS_PIN_NUM   = 4;

    spi_bus_config_t buscfg = {
        .miso_io_num = RC522_SPI_MISO_PIN_NUM,
        .mosi_io_num = RC522_SPI_MOSI_PIN_NUM,
        .sclk_io_num = RC522_SPI_SCLK_PIN_NUM,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = 0,
        .flags = SPICOMMON_BUSFLAG_MASTER
    };

    spi_device_interface_config_t devcfg = {
        .clock_speed_hz = SPI_BUS_SPEED_HZ,
        .mode = 0,
        .spics_io_num = RC522_SPI_CS_PIN_NUM,
        .queue_size = 20,
        .pre_cb = NULL,
        .command_bits=0,
        .address_bits=8,
        .flags = 0,
    };

    ESP_LOGI(TAG, "Setting up SPI");
    ESP_ERROR_CHECK(spi_bus_initialize(HSPI_HOST, &buscfg, 0));
    ESP_ERROR_CHECK(spi_bus_add_device(HSPI_HOST, &devcfg, &spi));

    return spi;
}


bool heimdall_rc663_selftest(spi_device_handle_t spi)
{
    return false;
}
