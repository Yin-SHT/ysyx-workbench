#include <am.h>
#include "./include/ysyxSoC.h"
#include "../riscv.h"

#define UART_RX_ADDR 0x10000000
#define UART_LSR_ADDR 0x10000005

void __am_uart_rx(AM_UART_RX_T *uart_rx) {
  uint8_t lsr = inb(UART_LSR_ADDR);
  while (!(lsr & 0x01)) {
    lsr = inb(UART_LSR_ADDR);
  }
  uint8_t data = inb(UART_RX_ADDR);
  uart_rx->data = data ? data : 0xff;
}