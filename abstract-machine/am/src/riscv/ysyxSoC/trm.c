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

void putch(char ch) {
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
