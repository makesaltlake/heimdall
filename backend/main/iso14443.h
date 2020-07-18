


#include <driver/spi_master.h>



bool heimdall_rfid_reqa(spi_device_handle_t spi);
int heimdall_rfid_anticollision(spi_device_handle_t spi, int level, uint8_t **uid, uint8_t *len, uint8_t *bcc);
uint8_t heimdall_rfid_check_sak(spi_device_handle_t spi, uint8_t *uid, uint8_t uid_len, uint8_t bcc);
void heimdall_rfid_send_rats(spi_device_handle_t spi);