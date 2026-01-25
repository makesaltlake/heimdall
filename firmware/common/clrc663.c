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
#include <hal/uart_types.h>
#include <driver/uart.h>
#include <string.h>

#include "clrc663.h"

static const char* TAG = "heimdall-clrc663";


void heimdall_rc663_cmd(uart_port_t uart_num, uint8_t cmd)
{
    heimdall_rc663_write_reg(uart_num, RC663_REG_COMMAND, cmd);
}

void clear_irq(uart_port_t uart_num, int irq)
{
    if (irq == 0)
        heimdall_rc663_write_reg(uart_num, RC663_REG_IRQ0, 0x7F);
    else
        heimdall_rc663_write_reg(uart_num, RC663_REG_IRQ1, 0x7F);
}

void heimdall_rc663_write_reg(uart_port_t uart_num, uint8_t reg, uint8_t value)
{
    char data[2];
    data[0] = reg << 1;
    data[1] = value;
    if (uart_write_bytes(uart_num, data, 2) != 2) {
        ESP_LOGE(TAG, "Failed to write to RC663 register %x", reg);
        assert(0);
    }

    ESP_ERROR_CHECK(uart_wait_tx_done(uart_num, 100 / portTICK_PERIOD_MS));
}

void heimdall_rc663_write_data(uart_port_t uart_num, uint8_t reg, uint8_t *buffer, int length)
{
    if (uart_write_bytes(uart_num, &reg, 1) != 1) {
        ESP_LOGE(TAG, "Failed to write to RC663 register %x for data write", reg);
        assert(0);
    }
    ESP_ERROR_CHECK(uart_wait_tx_done(uart_num, 100 / portTICK_PERIOD_MS));

    if (uart_write_bytes(uart_num, (const char *)buffer, length) != length) {
        ESP_LOGE(TAG, "Failed to write data to RC663 register %x", reg);
        assert(0);
    }

    ESP_ERROR_CHECK(uart_wait_tx_done(uart_num, 100 / portTICK_PERIOD_MS));
}

uint8_t heimdall_rc663_read_reg(uart_port_t uart_num, uint8_t reg)
{
    uint8_t value = 0;
    char data[1];
    data[0] = (reg << 1) | 0x01;

//    uart_flush(uart_num);

    if (uart_write_bytes(uart_num, data, 1) != 1) {
        ESP_LOGE(TAG, "Failed to write to RC663 register %x for read", reg);
        assert(0);
    }
//    ESP_ERROR_CHECK(uart_wait_tx_done(uart_num, 100 / portTICK_PERIOD_MS));
//vTaskDelay(500 / portTICK_PERIOD_MS);
 //    size_t rxlen = 0;
//    while (rxlen == 0) {
//size_t rxlen = 0;
//        ESP_ERROR_CHECK(uart_get_buffered_data_len(uart_num, &rxlen));
//        ESP_LOGI(TAG, "Waiting for data... len=%d", rxlen);
//        vTaskDelay(500 / portTICK_PERIOD_MS);
//    }

    if (uart_read_bytes(uart_num, &value, 1, 100 / portTICK_PERIOD_MS) != 1) {
        ESP_LOGE(TAG, "Failed to read from RC663 register %x", reg);
        assert(0);
    }

  ESP_LOGI(TAG, "Read RC663 reg %x = %x", reg, value);

//    ESP_ERROR_CHECK(uart_get_buffered_data_len(uart_num, &rxlen));
//    ESP_LOGI(TAG, "buffered rx len=%d", rxlen);

 //   uart_flush(uart_num);

    return value;
}

uint8_t heimdall_rc663_get_version(uart_port_t uart_num)
{
    uint8_t version;

    version = heimdall_rc663_read_reg(uart_num, RC663_REG_VERSION);

    return version;
}


uart_port_t heimdall_rfid_init(bool rfid_reader)
{
    uint8_t clrc663_version;
    const uart_port_t uart_num = UART_NUM_1;
    const int uart_buffer_size = (1024 * 1);
    QueueHandle_t uart_queue;

    ESP_ERROR_CHECK(uart_driver_install(uart_num, uart_buffer_size, uart_buffer_size, 10, &uart_queue, 0));
    uart_config_t uart_config = {
        .baud_rate = 115200,
        .data_bits = UART_DATA_8_BITS,
        .parity    = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .rx_flow_ctrl_thresh = 0,
    };

    ESP_ERROR_CHECK(uart_param_config(uart_num, &uart_config));
    ESP_ERROR_CHECK(uart_set_pin(uart_num, 17, 18, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE));

    heimdall_rc663_cmd(uart_num, RC663_CMD_SOFT_RESET);
    vTaskDelay(500 / portTICK_PERIOD_MS);

    heimdall_rc663_write_reg(uart_num, RC663_REG_COMMAND, 0);

    ESP_LOGI(TAG, "Waiting for RC663 to complete power-up");

    while ((heimdall_rc663_read_reg(uart_num, RC663_REG_COMMAND) & 0xC0) > 0) {
        ESP_LOGI(TAG, "RC663 still powering up...");
        vTaskDelay(50 / portTICK_PERIOD_MS);
    }

    ESP_LOGI(TAG, "Power-up complete");
    vTaskDelay(1000 / portTICK_PERIOD_MS);
    clrc663_version = heimdall_rc663_read_reg(uart_num, RC663_REG_VERSION);

    switch (clrc663_version) {
        case 0x18:
            ESP_LOGI(TAG, "CLRC66x01 or CLRC66x02 found (version 0x%02X)", clrc663_version);
            break;
        case 0x1A:
            ESP_LOGI(TAG, "CLRC66x03 found (version 0x%02X)", clrc663_version);
            break;
        default:
            ESP_LOGE(TAG, "Unsupported NFC chip found (version 0x%02X)", clrc663_version);
            ESP_LOGI(TAG, "RC663 version: %02X", heimdall_rc663_read_reg(uart_num, RC663_REG_VERSION));
            ESP_LOGI(TAG, "RC663 version: %02X", heimdall_rc663_read_reg(uart_num, RC663_REG_VERSION));
            ESP_LOGI(TAG, "RC663 version: %02X", heimdall_rc663_read_reg(uart_num, RC663_REG_VERSION));
            ESP_LOGI(TAG, "RC663 version: %02X", heimdall_rc663_read_reg(uart_num, RC663_REG_VERSION));
            ESP_LOGI(TAG, "RC663 version: %02X", heimdall_rc663_read_reg(uart_num, RC663_REG_VERSION));
            ESP_LOGI(TAG, "RC663 version: %02X", heimdall_rc663_read_reg(uart_num, RC663_REG_VERSION));
            assert(0);
    }

    // Cancels any previous executions and return to IDLE mode
    heimdall_rc663_cmd(uart_num, RC663_CMD_IDLE);

    // Flush the FIFO and define FIFO characteristics
    heimdall_rc663_write_reg(uart_num, RC663_REG_FIFO_CONTROL, 0xB0);

    // Fill the FIFO for the LoadProtocol command
    heimdall_rc663_write_reg(uart_num, RC663_REG_FIFO_DATA, 0x00); // Rx Protocol
    heimdall_rc663_write_reg(uart_num, RC663_REG_FIFO_DATA, 0x00); // Tx Protocol

    // Exec LoadProtocol. This loads protocol ISO 14443A - 106
    heimdall_rc663_cmd(uart_num, RC663_CMD_LOAD_PROTOCOL);

    // Flush FIFO and define FIFO characteristics
    heimdall_rc663_write_reg(uart_num, RC663_REG_FIFO_CONTROL, 0xB0);

    // Switch RF field on
    heimdall_rc663_write_reg(uart_num, RC663_REG_DRV_MODE, 0x8A);

    // Clear all bits in IRQ0
    heimdall_rc663_write_reg(uart_num, RC663_REG_IRQ0, 0x7F);

    // Switch CRC extension OFF for Tx
    heimdall_rc663_write_reg(uart_num, RC663_REG_TX_CRC_PRESET, 0x18);
    // Switch CRC extension OFF for Rx
    heimdall_rc663_write_reg(uart_num, RC663_REG_RX_CRC_PRESET, 0x18);
    // Only last 7 bits will be sent
    heimdall_rc663_write_reg(uart_num, RC663_REG_TX_DATA_NUM, 0x0F);

    heimdall_rc663_write_reg(uart_num, RC663_REG_IRQ0_EN, 6);
    heimdall_rc663_write_reg(uart_num, RC663_REG_IRQ1_EN, 0x00);

    heimdall_rc663_write_reg(uart_num, RC663_REG_IRQ0, 0x7F);
    heimdall_rc663_write_reg(uart_num, RC663_REG_IRQ1, 0x7F);

    return uart_num;
}

void heimdall_rfid_set_timer(uart_port_t uart_num, int milliseconds)
{
    heimdall_rc663_write_reg(uart_num, RC663_REG_T_CONTROL, 0x00);
    // Use the 211.875 KHz timer
    heimdall_rc663_write_reg(uart_num, RC663_REG_T0_CONTROL, 0x11);

    // Each tick of the 211.875 kHz timer is 5 microseconds

    // The timer supports up to 327ms
    assert(milliseconds <= 327);

    uint16_t val = (milliseconds * 1000UL) / 5;

    heimdall_rc663_write_reg(uart_num, RC663_REG_T0_RELOAD_HI, val >> 8);
    heimdall_rc663_write_reg(uart_num, RC663_REG_T0_RELOAD_LO, val & 0xFF);

    heimdall_rc663_write_reg(uart_num, RC663_REG_IRQ1_EN, 0x01);
}

bool heimdall_wait(uart_port_t uart_num)
{
    bool success = true;
    uint8_t irq1;
    uint8_t error = 0;

    while (1) {
        irq1 = heimdall_rc663_read_reg(uart_num, RC663_REG_IRQ1);

        if ((irq1 & 0x41) != 0) {
            break;
        }
    }

    if (irq1 & 0x01) {
        success = false;
    }

    if (success)
        error = heimdall_rc663_read_reg(uart_num, RC663_REG_ERROR);

    if (error) {
        ESP_LOGV(TAG, "ERROR: %x", error);
        success = false;
    }

    return success;

}
