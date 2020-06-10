Raspberry Pi based RFID access control system
===

Components
---
(links are to Amazon, PiShop.us and AdaFruit)
- Raspberry Pi Zero W V1.1
  (C) Raspberry Pi 2017 - [Raspberry Pi Zero Wireless WH (Pre-Soldered Header)](https://www.pishop.us/product/raspberry-pi-zero-wireless-wh-pre-soldered-header/)
- uSD Card - [SanDisk Ultra 32GB MicroSDHC UHS-I Card with Adapter - 98MB/s U1 A1 - SDSQUAR-032G-GN6MA ](https://www.amazon.com/gp/product/B073JWXGNT/ref=ppx_yo_dt_b_asin_title_o07_s00?ie=UTF8&psc=1)
- RFID Reader/Writer - [SunFounder RFID Kit Mifare RC522 RFID Reader Module with S50 White Card and Key Ring for Arduino Raspberry Pi ](https://www.amazon.com/gp/product/B07KGBJ9VG/ref=ppx_yo_dt_b_asin_title_o03_s00?ie=UTF8&psc=1)
- 20x4 LCD Display - [SunFounder IIC I2C TWI Serial 2004 20x4 LCD Module Shield for Arduino R3 Mega2560 ](https://www.amazon.com/gp/product/B01GPUMP9C/ref=ppx_yo_dt_b_asin_title_o05_s00?ie=UTF8&psc=1)
- 2x 82 Ω resistors - [EDGELEC 100pcs 82 ohm Resistor 1/4w (0.25 Watt) ±1% Tolerance Metal Film Fixed Resistor, Multiple Values of Resistance Optional ](https://www.amazon.com/gp/product/B07HDG2MXW/ref=ppx_yo_dt_b_asin_title_o07_s01?ie=UTF8&psc=1)
- Logic Level Converter - [KeeYees 10pcs 4 Channels IIC I2C Logic Level Converter Bi-Directional Module 3.3V to 5V Shifter for Arduino (Pack of 10) ](https://www.amazon.com/gp/product/B07LG646VS/ref=ppx_yo_dt_b_asin_title_o05_s01?ie=UTF8&psc=1)
- 12V relay - [12v DC (12 Volt DC) Relay - DPDT PCB 8-Pin Mount - Non-Latching Non-Polarized Electronic Low Signal High Sensitivity Relay Module for DIY Electronics and Arduino ](https://www.amazon.com/gp/product/B07CP7KBYV/ref=ppx_yo_dt_b_asin_title_o04_s00?ie=UTF8&psc=1)
- Red LED - [Diffused Red 10mm LED (25 pack)](https://www.adafruit.com/product/845)
- Green LED - [Diffused Green 10mm LED (25 pack)](https://www.adafruit.com/product/844)
- Piezo Electric Tone Buzzer [6 Pack 3-24v Piezo Electric Tone Buzzer Alarm dc 3-24 v for Physics Circuits Continuous Sound ](https://www.amazon.com/gp/product/B07JDBF4V3/ref=ppx_yo_dt_b_asin_title_o07_s00?ie=UTF8&psc=1)

Connection Details
---

_Note_ All "pins" listed are shown as BOARD (Physical) pins, not BCM/GPIO pins.<br>
In the following, "Raspberry Pi" is shortened to "RPi"
```
Raspberry Pi Zero W         RPi => RFID-RC522
J8:
   3V3  (1) (2)  5V         RPi Pin   RFID-RC522
 GPIO2  (3) (4)  5V         -------   ----------
 GPIO3  (5) (6)  GND        1     --> 3.3V
 GPIO4  (7) (8)  GPIO14     6     --> GND
   GND  (9) (10) GPIO15     18    --> IRQ
GPIO17 (11) (12) GPIO18     19    --> MOSI
GPIO27 (13) (14) GND        21    --> MISO
GPIO22 (15) (16) GPIO23     22    --> RST
   3V3 (17) (18) GPIO24     23    --> SCK
GPIO10 (19) (20) GND        24    --> SDA
 GPIO9 (21) (22) GPIO25
GPIO11 (23) (24) GPIO8
   GND (25) (26) GPIO7
 GPIO0 (27) (28) GPIO1
 GPIO5 (29) (30) GND
 GPIO6 (31) (32) GPIO12
GPIO13 (33) (34) GND
GPIO19 (35) (36) GPIO16
GPIO26 (37) (38) GPIO20
   GND (39) (40) GPIO21


    RPi => Level Converter => LCD

    RPi Pin   Level Converter    LCD
    -------   ---------------    ---
    1     --> LV
    2     -------------> HV  --> VCC
    3     --> LV1 ------ HV1 --> SDA
    5     --> LV4 ------ HV4 --> SCL
    39    --> GND ------ GND --> GND

    RPi => LED/Buzzer

    RPi Pin
    -------
    37    --> 82 Ω resistor --> Green LED    --> GND
    35    --> 82 Ω resistor --> Red LED      --> GND
    33    --------------------> Piezo Buzzer --> GND
```
See https://pinout.xyz/ for more details about the Raspberry Pi pinouts