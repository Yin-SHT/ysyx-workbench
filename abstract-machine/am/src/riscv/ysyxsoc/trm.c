#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <riscv/riscv.h>

// Temp Device Addr, these will be changed in the future !!!
#define SERIAL_PORT 0x10000000  // uart16550: 0x1000_0000~0x1000_0fff
#define SRAM_START  0x0f000000  // 
#define SRAM_END    0x0f002000  // sram:      0x0f00_0000~0x0f00_1fff

int main(const char *args);

extern char _heap_start;

Area heap = {.start = (void *)SRAM_START, .end = (void *)SRAM_END}; 
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

void putch(char ch) {
  uint8_t lsr = inb(SERIAL_PORT + 5);
  while (!(lsr & 0x20)) {
    lsr = inb(SERIAL_PORT + 5);
  }

  outb(SERIAL_PORT, ch);
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code));
  // should not reach here
  while (1);
}

extern char _data_load_start, _data_load_end, _data_start;
extern char _bss_start, _bss_end;

void _trm_init() {
  char *src = &_data_load_start;
  char *dst = &_data_start;

  while (src < &_data_load_end) {
    *dst++ = *src++;
  }

  for (dst = &_bss_start; dst < &_bss_end; dst++) {
    *dst = 0;
  }

  uint8_t lcr = inb(SERIAL_PORT + 3);
  outb(SERIAL_PORT + 3, lcr | 0x80);
  outb(SERIAL_PORT + 1, 0x00);
  outb(SERIAL_PORT + 0, 0x01);
  outb(SERIAL_PORT + 3, lcr & 0x7f);

  int ret = main(mainargs);
  halt(ret);
}