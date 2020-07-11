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


static void heimdall_rc663_write_reg(spi_device_handle_t spi, uint8_t reg, uint8_t value);
static void heimdall_rc663_cmd(spi_device_handle_t spi, uint8_t cmd);
static uint8_t heimdall_rc663_read_reg(spi_device_handle_t spi, uint8_t reg);
static void clear_irq(spi_device_handle_t spi, int irq);

static void heimdall_rc663_cmd(spi_device_handle_t spi, uint8_t cmd)
{
    heimdall_rc663_write_reg(spi, RC663_REG_COMMAND, cmd);
}

static void heimdall_rc663_write_reg(spi_device_handle_t spi, uint8_t reg, uint8_t value)
{
    spi_transaction_t t = {
        .length = 8,
        .addr = reg << 1,
        .cmd  = reg << 1,
        .tx_buffer = &value,
    };

    ESP_ERROR_CHECK(spi_device_polling_transmit(spi, &t));
}

static void heimdall_rc663_write_data(spi_device_handle_t spi, uint8_t reg, uint8_t *buffer, int length)
{
    spi_transaction_t t = {
        .length = 8 * length,
        .addr = reg << 1,
        .cmd  = reg << 1,
        .tx_buffer = buffer,
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
    uint8_t version;

    version = heimdall_rc663_read_reg(spi, RC663_REG_VERSION);

    return version;
}

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

static void clear_irq(spi_device_handle_t spi, int irq)
{
    if (irq == 0)
        heimdall_rc663_write_reg(spi, RC663_REG_IRQ0, 0x7F);
    else
        heimdall_rc663_write_reg(spi, RC663_REG_IRQ1, 0x7F);
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

spi_device_handle_t heimdall_rfid_init(void)
{
    spi_device_handle_t spi;
    uint8_t value;
    uint8_t clrc663_version;

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

    ESP_ERROR_CHECK(spi_bus_initialize(HSPI_HOST, &buscfg, 0));
    ESP_ERROR_CHECK(spi_bus_add_device(HSPI_HOST, &devcfg, &spi));

    // reset the CLRC663
    gpio_set_level(12, 1);
    vTaskDelay(250 / portTICK_PERIOD_MS);
    gpio_set_level(12, 0);

    heimdall_rc663_cmd(spi, RC663_CMD_SOFT_RESET);
    vTaskDelay(500 / portTICK_PERIOD_MS);

    heimdall_rc663_write_reg(spi, RC663_REG_COMMAND, 0);

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
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0x00);
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_DATA, 0x00);

    // Exec LoadProtocol. This loads protocol ISO 14443A - 106
    heimdall_rc663_cmd(spi, RC663_CMD_LOAD_PROTOCOL);

    // Flush FIFO and define FIFO characteristics
    heimdall_rc663_write_reg(spi, RC663_REG_FIFO_CONTROL, 0xB0);

    // Switch RF field on
    heimdall_rc663_write_reg(spi, RC663_REG_DRV_MODE, 0x8A);

    // Clear all bits in IRQ0
    heimdall_rc663_write_reg(spi, RC663_REG_IRQ0, 0x7F); // 7F

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

    for (i = uid_start; i < uid_len; i++) {

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

    return sak;
}
