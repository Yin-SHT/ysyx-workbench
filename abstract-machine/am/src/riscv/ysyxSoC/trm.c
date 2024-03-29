#include <am.h>
#include <klib-macros.h>
#include <riscv/riscv.h>

//extern char _heap_start;
int main(const char *args);

Area heap = {.start = (void *)0x0f000000, .end = (void *)0xf002000}; // 8 KB
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

// Temp Device Addr, these will be changed in the future !!!
//#define DEVICE_BASE 0xa0000000
#define SERIAL_PORT 0x10000000  // uart16550

extern char _rodata_end;
extern char _data_start, _data_end;
extern char _bss_start, _bss_end;

static bool uart_init = false;

void putch(char ch) {
  if (!uart_init) {
    uint8_t lcr = inb(SERIAL_PORT + 3);
    outb(SERIAL_PORT + 3, lcr | 0x80);
    outb(SERIAL_PORT + 1, 0x00);
    outb(SERIAL_PORT + 0, 0x01);
    outb(SERIAL_PORT + 3, lcr & 0x7f);
    uart_init = true;
  }

  uint8_t lsr = inb(SERIAL_PORT + 5);
  while (lsr & 0x02) {
    lsr = inb(SERIAL_PORT + 5);
  }
  outb(SERIAL_PORT, ch);
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code));
  // should not reach here
  while (1);
}

void _trm_init() {
  char *src = &_rodata_end;
  char *dst = &_data_start;

  while (dst < &_data_end) {
    *dst++ = *src++;
  }

  for (dst = &_bss_start; dst < &_bss_end; dst++) {
    *dst = 0;
  }

  int ret = main(mainargs);
  halt(ret);
}
