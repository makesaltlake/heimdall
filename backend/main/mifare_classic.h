

#include <driver/spi_master.h>

void heimdall_rfid_authenticate(spi_device_handle_t spi, uint8_t *serial, char *key);
bool heimdall_rfid_personalize(spi_device_handle_t spi);
bool heimdall_rfid_read(spi_device_handle_t spi, uint8_t block, uint8_t data[16]);
bool heimdall_rfid_write(spi_device_handle_t spi, uint8_t block, uint8_t data[16]);
