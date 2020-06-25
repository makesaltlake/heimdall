ESP32 based 13.56 MHz RFID access control system
===

Components
---
(links are to Amazon, AdaFruit and Mouser Electronics)

- Adafruit HUZZAH32 - [Assembled Adafruit HUZZAH32 - ESP32 Feather Board - with Stacking Headers](https://www.adafruit.com/product/3619)
- CLEV6630ARD (CLRC663 RFID reader/writer) - [NXP Semiconductors CLEV6630ARD](https://www.mouser.com/ProductDetail/NXP-Semiconductors/CLEV6630ARD?qs=%2Fha2pyFadujWtMY8yNDgyDVMb%252BUPmISJ5aW3tRgK33PclfjweBuHLg%3D%3D)
- 20x4 LCD Display - [SunFounder IIC I2C TWI Serial 2004 20x4 LCD Module Shield for Arduino R3 Mega2560 ](https://www.amazon.com/gp/product/B01GPUMP9C/ref=ppx_yo_dt_b_asin_title_o05_s00?ie=UTF8&psc=1)
- 2x 82 Ω resistors - [EDGELEC 100pcs 82 ohm Resistor 1/4w (0.25 Watt) ±1% Tolerance Metal Film Fixed Resistor, Multiple Values of Resistance Optional ](https://www.amazon.com/gp/product/B07HDG2MXW/ref=ppx_yo_dt_b_asin_title_o07_s01?ie=UTF8&psc=1)
- Logic Level Converter - [KeeYees 10pcs 4 Channels IIC I2C Logic Level Converter Bi-Directional Module 3.3V to 5V Shifter for Arduino (Pack of 10) ](https://www.amazon.com/gp/product/B07LG646VS/ref=ppx_yo_dt_b_asin_title_o05_s01?ie=UTF8&psc=1)
- 12V relay - [12v DC (12 Volt DC) Relay - DPDT PCB 8-Pin Mount - Non-Latching Non-Polarized Electronic Low Signal High Sensitivity Relay Module for DIY Electronics and Arduino ](https://www.amazon.com/gp/product/B07CP7KBYV/ref=ppx_yo_dt_b_asin_title_o04_s00?ie=UTF8&psc=1)
- Red LED - [Diffused Red 10mm LED (25 pack)](https://www.adafruit.com/product/845)
- Green LED - [Diffused Green 10mm LED (25 pack)](https://www.adafruit.com/product/844)
- Piezo Electric Tone Buzzer [6 Pack 3-24v Piezo Electric Tone Buzzer Alarm dc 3-24 v for Physics Circuits Continuous Sound ](https://www.amazon.com/gp/product/B07JDBF4V3/ref=ppx_yo_dt_b_asin_title_o07_s00?ie=UTF8&psc=1)

Beware of bad RFID-RC522 boards using fake/clone NXP RC522 chips. See [\[Collection\] Bad boards - https://github.com/miguelbalboa/rfid/issues/428](https://github.com/miguelbalboa/rfid/issues/428).

Connection Details
---

The card reader (i.e. door/machinery control) doesn't use the level converter or LCD.<br>
The card writer (i.e. badge programmer) doesn't use the LEDs, buzzer, resistors or relay.


Building
--------

Install the ESP-IDF by following the steps at https://docs.espressif.com/projects/esp-idf/en/release-v4.1/get-started/index.html#installation-step-by-step . We're using code on the branch `release/v4.1`.

Once installed, set up your shell by running `. export.sh` . Then, you can run `idf.py menuconfig` to configure the BSP (Board Support Package), or `idf.py build` to build the project.

You can upload the build to the ESP32 by running `idf.py flash`, or later `idf.py app-flash` to save the second flashing the bootloader.
To write the NVS data to flash, first edit nvs\_data.csv to fill in your WiFi SSID, WiFi password, URL, RFID Reader API key, RFID Writer API key, and the Tag Key. Then, run `gen_nvs_part.sh` to generate the binary file, followed by `write_nvs_part.sh` to write that file to flash.

Run `idf.py monitor` to cause the ESP32 to reset and attach the serial console.

You can combine steps: for example `idf.py app-flash monitor` to flash the code then monitor the output.


