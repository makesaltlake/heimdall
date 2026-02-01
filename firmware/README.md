ESP32 based 13.56 MHz RFID access control system
===

Components
---
See the KiCad schematics in [boards/inside_board](/boards/inside_board) and [boards/outside_board](/boards/outside_board) for the components required.<br>
The RFID reader/writer module the outside board interfaces to is the [CLEV6630ARD](https://www.nxp.com/design/development-boards/freedom-development-boards/mcu-boards/clev6630ard-nfc-frontend-clrc663-iplus-i-arduino-interface-board:BLE-NFC).

Connection Details
---

The card reader (i.e. door/machinery control) doesn't use the level converter or LCD.<br>
The card writer (i.e. badge programmer) doesn't use the LEDs, buzzer, resistors or relay.


Building
--------

Install the ESP-IDF by following the steps at https://docs.espressif.com/projects/esp-idf/en/release-v4.2/get-started/index.html#installation-step-by-step .
If you clone the esp-idf repository via Git, you should checkout the version with tag `v4.2`.

Once installed, set up your environment by running `. export.sh` (`export.bat` on Windows). Then, you can run `idf.py menuconfig` to configure the BSP (Board Support Package, or `idf.py build` to build the project.

You can upload the build to the ESP32 by running `idf.py flash`, or later `idf.py app-flash` to save the second flashing the bootloader.
To write the NVS data to flash, first edit nvs\_data.csv to fill in your WiFi SSID, WiFi password, URL, RFID Reader API key, RFID Writer API key, and the Tag Key. Then, run `gen_nvs_part.sh` (`gen_nvs_part.cmd` on Windows) to generate the binary file, followed by `write_nvs_part.sh` (`write_nvs_part.cmd` on Windows) to write that file to flash.

Run `idf.py monitor` to cause the ESP32 to reset and attach the serial console.

You can combine steps: for example `idf.py app-flash monitor` to flash the code then monitor the output.


