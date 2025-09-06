/*
  The MIT License (MIT)

  Copyright (c) 2016 Ivor Wanders

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*/

#define MFRC630_DEBUG_PRINTF Serial.printf

#include <Arduino.h>
#include <SPI.h>
#include "mfrc630.h"

// Pin to select the hardware, the NSS pin.
#define CHIP_SELECT 10
// Pins MOSI, MISO and SCK are connected to the default pins, and are manipulated through the SPI object.
// By default that means MOSI=11, MISO=12, SCK=13.

// Implement the HAL functions on an Arduino compatible system.
void mfrc630_SPI_transfer(const uint8_t* tx, uint8_t* rx, uint16_t len) {
  for (uint16_t i=0; i < len; i++){
    rx[i] = SPI.transfer(tx[i]);
  }
}

// Select the chip and start an SPI transaction.
void mfrc630_SPI_select() {
  // SPI.beginTransaction(SPISettings(10000000, MSBFIRST, SPI_MODE0));  // gain control of SPI bus
  SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE0));  // gain control of SPI bus
  digitalWrite(CHIP_SELECT, LOW);
}

// Unselect the chip and end the transaction.
void mfrc630_SPI_unselect() {
  digitalWrite(CHIP_SELECT, HIGH);
  SPI.endTransaction();    // release the SPI bus
}

// Hex print for blocks without printf.
void print_block(uint8_t * block,uint8_t length){
    for (uint8_t i=0; i<length; i++){
        if (block[i] < 16){
          Serial.print("0");
          Serial.print(block[i], HEX);
        } else {
          Serial.print(block[i], HEX);
        }
        Serial.print(" ");
    }
}

// The example dump function adapted such that it prints with Serial.print.
void mfrc630_MF_example_dump_arduino() {
  uint16_t atqa = mfrc630_iso14443a_REQA();
  if (atqa != 0) {  // Are there any cards that answered?
    uint8_t sak;
    uint8_t uid[10] = {0};  // uids are maximum of 10 bytes long.

    // Select the card and discover its uid.
    uint8_t uid_len = mfrc630_iso14443a_select(uid, &sak);

    if (uid_len != 0) {  // did we get an UID?
      Serial.print("UID of ");
      Serial.print(uid_len);
      Serial.print(" bytes (SAK: ");
      Serial.print(sak);
      Serial.print("): ");
      print_block(uid, uid_len);
      Serial.print("\n");

      // Use the manufacturer default key...
      uint8_t FFkey[6] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

      mfrc630_cmd_load_key(FFkey);  // load into the key buffer

      // Try to athenticate block 0.
      if (mfrc630_MF_auth(uid, MFRC630_MF_AUTH_KEY_A, 0)) {
        Serial.println("Yay! We are authenticated!");

        // Attempt to read the first 4 blocks.
        uint8_t readbuf[16] = {0};
        uint8_t len;
        for (uint8_t b=0; b < 4 ; b++) {
          len = mfrc630_MF_read_block(b, readbuf);
          Serial.print("Read block 0x");
          print_block(&len,1);
          Serial.print(": ");
          print_block(readbuf, len);
          Serial.println();
        }
        mfrc630_MF_deauth();  // be sure to call this after an authentication!
        tone(33, 2000, 50);
      } else {
        Serial.print("Could not authenticate :(\n");
      }
    } else {
      Serial.print("Could not determine UID, perhaps some cards don't play");
      Serial.print(" well with the other cards? Or too many collisions?\n");
    }
  } else {
    Serial.print("No answer to REQA, no cards?\n");
  }
}

void setup(){
  pinMode(33, OUTPUT);
  Serial.begin(9600);
  delay(1000);
  
  MFRC630_PRINTF("Debug enabled - starting CLRC663 test\n");
  
  pinMode(CHIP_SELECT, OUTPUT);
  SPI.begin();
  
  uint8_t version = mfrc630_read_reg(MFRC630_REG_VERSION);
  Serial.print("Version register: 0x");
  Serial.println(version, HEX);
  
  // Check key registers after protocol load
  Serial.print("DrvMode (0x28): 0x");
  Serial.println(mfrc630_read_reg(0x28), HEX);
  Serial.print("TxAmp (0x29): 0x");
  Serial.println(mfrc630_read_reg(0x29), HEX);
  Serial.print("DrvCon (0x2A): 0x");
  Serial.println(mfrc630_read_reg(0x2A), HEX);
  Serial.print("TxL (0x2B): 0x");
  Serial.println(mfrc630_read_reg(0x2B), HEX);

  complete_clrc663_reset();
}

void debug_reqa_internals() {
  Serial.println("=== REQA Debug ===");
  
  // Check initial state
  Serial.print("Initial IRQ0: 0x");
  Serial.println(mfrc630_irq0(), HEX);
  Serial.print("Initial IRQ1: 0x");
  Serial.println(mfrc630_irq1(), HEX);
  
  // Reset state
  mfrc630_cmd_idle();
  mfrc630_flush_fifo();
  mfrc630_clear_irq0();
  mfrc630_clear_irq1();
  
  // Now try REQA
  uint16_t atqa = mfrc630_iso14443a_REQA();
  
  Serial.print("REQA result: 0x");
  Serial.println(atqa, HEX);
  Serial.print("Final IRQ0: 0x");
  Serial.println(mfrc630_irq0(), HEX);
  Serial.print("Final IRQ1: 0x");
  Serial.println(mfrc630_irq1(), HEX);
  
  // Check for specific errors
  uint8_t error_reg = mfrc630_read_reg(MFRC630_REG_ERROR);
  Serial.print("Error register: 0x");
  Serial.println(error_reg, HEX);
  
  Serial.print("Final FIFO length: ");
  Serial.println(mfrc630_fifo_length());
}

void complete_clrc663_reset() {
  // Perform a soft reset of the chip
  mfrc630_write_reg(MFRC630_REG_COMMAND, MFRC630_CMD_SOFTRESET);
  delayMicroseconds(500);  // Allow reset to complete
  
  // Reload the protocol configuration after reset
  mfrc630_AN1102_recommended_registers(MFRC630_PROTO_ISO14443A_106_MILLER_MANCHESTER);
  
  // Reapply receiver sensitivity settings
  mfrc630_write_reg(MFRC630_REG_RXANA, 0x03); //0x39 RxAna
  mfrc630_write_reg(MFRC630_REG_RXTHRESHOLD, 0x00); // 0x37 RxThreshold
  // mfrc630_write_reg(0x28, 0b10001111);  // Enhanced DrvMode for 5V
  mfrc630_write_reg(0x29, 0b11000000); //TxAmp register/
  mfrc630_write_reg(0x2A, 0b00100001); //TxCon register

  // ADD THESE NEW LINES - Improve receiver sensitivity
  mfrc630_write_reg(MFRC630_REG_RXANA, 0b00000011); // 0x39 address
  mfrc630_write_reg(MFRC630_REG_RXTHRESHOLD, 0b00000000); //0x37 address
  
  // Clear all interrupts after reconfiguration
  mfrc630_clear_irq0();
  mfrc630_clear_irq1();
  
}

void loop(){
  // MFRC630_PRINTF("Starting card detection cycle\n");

  // Reset for next read  
  complete_clrc663_reset();
  
  // debug_reqa_internals();

  mfrc630_MF_example_dump_arduino();
  // test_authentication_with_5v();
  // delay(1000);
}

