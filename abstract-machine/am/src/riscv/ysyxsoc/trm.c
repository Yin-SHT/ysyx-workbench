#include <am.h>
#include <ysyxsoc.h>

int main(const char *args);

extern char _heap_start;

Area heap = {.start = (void *)&_heap_start, .end = (void *)SDRAM_END}; 
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

static void init_uart() {
  uint8_t LCR = UART_LCR;
  outb(SERIAL_PORT + 3, LCR | 0x80);
  outb(SERIAL_PORT + 1, 0x00);
  outb(SERIAL_PORT + 0, 0x01);
  outb(SERIAL_PORT + 3, LCR & 0x7f);
}

#ifndef DATE
#define DATE 0x19491001
#endif
static void init_nvboard() {
  *(volatile uint32_t *)GPIO_DIG = DATE;
  *(volatile uint32_t *)GPIO_LED = 0xaaaa;
}

void putch(char ch) {
  while (!(UART_LSR & TX_EMPTY));
  outb(SERIAL_PORT, ch);
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code));
  // should not reach here
  while (1);
}

void _trm_init() {
  init_uart();
  init_nvboard();
  int ret = main(mainargs);
  halt(ret);
}
