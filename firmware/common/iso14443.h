#ifndef ISO14443_H__
#define ISO14443_H_

bool heimdall_rfid_reqa(uart_port_t uart_num, uint8_t *proprietary_coding);
int heimdall_rfid_anticollision(uart_port_t uart_num, int level, uint8_t **uid, uint8_t *len, uint8_t *bcc);
uint8_t heimdall_rfid_check_sak(uart_port_t uart_num, uint8_t *uid, uint8_t uid_len, uint8_t bcc);
void heimdall_rfid_send_rats(uart_port_t uart_num);

#endif /* ISO14443_H__ */