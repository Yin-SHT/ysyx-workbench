#include <am.h>
#include <ysyxsoc.h>

void __am_uart_rx(AM_UART_RX_T *uart_rx) {
  uart_rx->data = 0xff;

  if (UART_LSR & DATA_READY) {
    uart_rx->data = UART_RX & 0xff;
  }
}