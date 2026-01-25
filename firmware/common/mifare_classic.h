

#ifndef MIFARE_CLASSIC_H__
#define MIFARE_CLASSIC_H__

bool heimdall_rfid_authenticate(uart_port_t uart_num, uint8_t *serial, char *key);
void heimdall_rfid_deauthenticate(uart_port_t uart_num);
bool heimdall_rfid_personalize(uart_port_t uart_num);
bool heimdall_rfid_read(uart_port_t uart_num, uint8_t block, uint8_t data[16]);
bool heimdall_rfid_write(uart_port_t uart_num, uint8_t block, uint8_t data[16]);

#endif /* MIFARE_CLASSIC_H__ */