#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <riscv/riscv.h>

// Temp Device Addr, these will be changed in the future !!!
#define SERIAL_PORT 0x10000000  // uart16550: 0x1000_0000~0x1000_0fff
#define SRAM_START  0x0f000000  // 
#define SRAM_END    0x0f002000  // sram:      0x0f00_0000~0x0f00_1fff
#define PSRAM_START 0x80000000  // 
#define PSRAM_END   0x80400000  // psram:     0x8000_0000~0x8040_0000

int main(const char *args);

extern char _heap_start;

Area heap = {.start = (void *)&_heap_start, .end = (void *)PSRAM_END}; 
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

void _trm_init() {
  uint8_t lcr = inb(SERIAL_PORT + 3);
  outb(SERIAL_PORT + 3, lcr | 0x80);
  outb(SERIAL_PORT + 1, 0x00);
  outb(SERIAL_PORT + 0, 0x01);
  outb(SERIAL_PORT + 3, lcr & 0x7f);

  // ID
//  uint32_t mvendorid = 0;
//  uint32_t marchid = 0;
//  __asm__ __volatile__(
//		"csrr %0, mvendorid;"
//    "csrr %1, marchid;" 
//		: "=r"(mvendorid), "=r"(marchid) ::               
//  );
//
//  printf("mvendorid: 0x%x\n", mvendorid);
//  printf("marchid: %d\n", marchid);

  int ret = main(mainargs);
  halt(ret);
}
