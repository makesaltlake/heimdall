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



void heimdall_rc663_init(spi_device_handle_t spi)
{


}


bool heimdall_rc663_selftest(spi_device_handle_t spi)
{

    return false;
}
