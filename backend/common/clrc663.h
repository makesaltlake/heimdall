#ifndef __CLRC533_H__
#define __CLRC533_H__

/*
 * Copyright (C) 2020 Rebecca Cran <rebecca@bsdio.com>.
 *
 */

#include <driver/spi_master.h>

// Registers, commands and interaction taken from the following document,
// which can (as of 2020-06-19) be found
// at https://www.nxp.com/docs/en/data-sheet/CLRC663.pdf

// CLRC663
// High performance multi-protocol NFC frontend CLRC663 and
// CLRC663 plus
// Rev 4.8 -- 28 October 2019
// 171148



#define SPI_BUS_SPEED_HZ 100000

enum RC663_REG {

    RC663_REG_COMMAND           = 0x00,
    RC663_REG_HOST_CTRL         = 0x01,
    RC663_REG_FIFO_CONTROL      = 0x02,
    RC663_REG_WATER_LEVEL       = 0x03,
    RC663_REG_FIFO_LENGTH       = 0x04,
    RC663_REG_FIFO_DATA         = 0x05,
    RC663_REG_IRQ0              = 0x06,
    RC663_REG_IRQ1              = 0x07,
    RC663_REG_IRQ0_EN           = 0x08,
    RC663_REG_IRQ1_EN           = 0x09,
    RC663_REG_ERROR             = 0x0A,
    RC663_REG_STATUS            = 0x0B,
    RC663_REG_RX_BIT_CTRL       = 0x0C,
    RC663_REG_RX_COLL           = 0x0D,
    RC663_REG_T_CONTROL         = 0x0E,
    RC663_REG_T0_CONTROL        = 0x0F,
    RC663_REG_T0_RELOAD_HI      = 0x10,
    RC663_REG_T0_RELOAD_LO      = 0x11,
    RC663_REG_T0_COUNTER_VAL_HI = 0x12,
    RC663_REG_T0_COUNTER_VAL_LO = 0x13,
    RC663_REG_T1_CONTROL        = 0x14,
    RC663_REG_T1_RELOAD_HI      = 0x15,
    RC663_REG_T1_RELOAD_LO      = 0x16,
    RC663_REG_T1_COUNTER_VAL_HI = 0x17,
    RC663_REG_T1_COUNTER_VAL_LO = 0x18,
    RC663_REG_T2_CONTROL        = 0x19,
    RC663_REG_T2_RELOAD_HI      = 0x1A,
    RC663_REG_T2_RELOAD_LO      = 0x1B,
    RC663_REG_T2_COUNTER_VAL_HI = 0x1C,
    RC663_REG_T2_COUNTER_VAL_LO = 0x1D,
    RC663_REG_T3_CONTROL        = 0x1E,
    RC663_REG_T3_RELOAD_HI      = 0x1F,
    RC663_REG_T3_RELOAD_LO      = 0x20,
    RC663_REG_T3_COUNTER_VAL_HI = 0x21,
    RC663_REG_T3_COUNTER_VAL_LO = 0x22,
    RC663_REG_T4_CONTROL        = 0x23,
    RC663_REG_T4_RELOAD_HI      = 0x24,
    RC663_REG_T4_RELOAD_LO      = 0x25,
    RC663_REG_T4_COUNTER_VAL_HI = 0x26,
    RC663_REG_T4_COUNTER_VAL_LO = 0x27,
    RC663_REG_DRV_MODE          = 0x28,
    RC663_REG_TX_AMP            = 0x29,
    RC663_REG_DRV_CON           = 0x2A,
    RC663_REG_TXL               = 0x2B,
    RC663_REG_TX_CRC_PRESET     = 0x2C,
    RC663_REG_RX_CRC_PRESET     = 0x2D,
    RC663_REG_TX_DATA_NUM       = 0x2E,
    RC663_REG_TX_MOD_WIDTH      = 0x2F,
    RC663_REG_TX_SYM10_BURST_LEN = 0x30,
    RC663_REG_TX_WAIT_CTRL      = 0x31,
    RC663_REG_TX_WAIT_LO        = 0x32,
    RC663_REG_FRAME_CON         = 0x33,
    RC663_REG_RX_SOF_D          = 0x34,
    RC663_REG_RX_CTRL           = 0x35,
    RC663_REG_RX_WAIT           = 0x36,
    RC663_REG_RX_THRESHOLD      = 0x37,
    RC663_REG_RCV               = 0x38,
    RC663_REG_RX_ANA            = 0x39,
    RC663_REG_LPCD_OPTIONS      = 0x3A,
    RC663_REG_SERIAL_SPEED      = 0x3B,
    RC663_REG_LFO_TRIMM         = 0x3C,
    RC663_REG_PLL_CTRL          = 0x3D,
    RC663_REG_PLL_DIV_OUT       = 0x3E,
    RC663_REG_LPCD_Q_MIN        = 0x3F,
    RC663_REG_LPCD_Q_MAX        = 0x40,
    RC663_REG_LPCD_I_MIN        = 0x41,
    RC663_REG_LPCD_I_RESULT     = 0x42,
    RC663_REG_LPCD_Q_RESULT     = 0x43,
    RC663_REG_PAD_EN            = 0x44,
    RC663_REG_PAD_OUT           = 0x45,
    RC663_REG_PAD_IN            = 0x46,
    RC663_REG_SIG_OUT           = 0x47,
    RC663_REG_TX_BIT_MOD        = 0x48,
    RC663_REG_RFU               = 0x49,
    RC663_REG_TX_DATA_CON       = 0x4A,
    RC663_REG_TX_DATA_MOD       = 0x4B,
    RC663_REG_TX_SYM_FREQ       = 0x4C,
    RC663_REG_TX_SYM0_H         = 0x4D,
    RC663_REG_TX_SYM0_L         = 0x4E,
    RC663_REG_TX_SYM_1H         = 0x4F,
    RC663_REG_TX_SYM_1L         = 0x50,
    RC663_REG_TX_SYM2           = 0x51,
    RC663_REG_TX_SYM3           = 0x52,
    RC663_REG_TX_SYM10_LEN      = 0x53,
    RC663_REG_TX_SYM32_LEN      = 0x54,
    RC663_REG_TX_SYM10_BURST_CTRL = 0x55,
    RC663_REG_TX_SYM10_MOD      = 0x56,
    RC663_REG_TX_SYM32_MOD      = 0x57,
    RC663_REG_RX_BIT_MOD        = 0x58,
    RC663_REG_RX_EOF_SYM        = 0x59,
    RC663_REG_RX_SYNC_VAL_H     = 0x5A,
    RC663_REG_RX_SYNC_VAL_L     = 0x5B,
    RC663_REG_RX_SYNC_MOD       = 0x5C,
    RC663_REG_RX_MOD            = 0x5D,
    RC663_REG_RX_CORR           = 0x5E,
    RC663_REG_FAB_CAL           = 0x5F,
    RC663_REG_VERSION           = 0x7F,
};

enum RC522_CMD
{
    RC663_CMD_IDLE = 0x00,
    RC663_CMD_LPCD = 0x01,
    RC663_CMD_LOAD_KEY = 0x02,
    RC663_CMD_MF_AUTHENT = 0x03,
    RC663_CMD_ACK_REQ = 0x04,
    RC663_CMD_RECEIVE = 0x05,
    RC663_CMD_TRANSMIT = 0x06,
    RC663_CMD_TRANSCEIVE = 0x07,
    RC663_CMD_WRITE_E2 = 0x08,
    RC663_CMD_WRITE_E2_PAGE = 0x09,
    RC663_CMD_READ_E2 = 0x0A,
    RC663_CMD_LOAD_REG = 0x0C,
    RC663_CMD_LOAD_PROTOCOL = 0x0D,
    RC663_CMD_LOAD_KEY_E2 = 0x0E,
    RC663_CMD_STORE_KEY_E2 = 0xF,
    RC663_CMD_READ_RNR = 0x1C,
    RC663_CMD_SOFT_RESET = 0x1F
};


spi_device_handle_t heimdall_rfid_init(bool rfid_reader);
uint8_t heimdall_rc663_get_version(spi_device_handle_t spi);
bool heimdall_rfid_read(spi_device_handle_t spi, uint8_t block, uint8_t data[16]);

void heimdall_rc663_write_reg(spi_device_handle_t spi, uint8_t reg, uint8_t value);
void heimdall_rc663_cmd(spi_device_handle_t spi, uint8_t cmd);
uint8_t heimdall_rc663_read_reg(spi_device_handle_t spi, uint8_t reg);
void clear_irq(spi_device_handle_t spi, int irq);
void heimdall_rfid_set_timer(spi_device_handle_t spi, int milliseconds);
bool heimdall_wait(spi_device_handle_t spi);


#endif /* CLRC663 */
