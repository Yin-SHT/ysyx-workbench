#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <riscv/riscv.h>

// Temp Device Addr, these will be changed in the future !!!
#define SERIAL_PORT 0x10000000  // uart16550
#define SDRAM_END   0xa8000000  // sdram

int main(const char *args);

extern char _heap_start;

Area heap = {.start = (void *)&_heap_start, .end = (void *)SDRAM_END}; 
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

void putch(char ch) {
  // Polling
  uint8_t lsr = inb(SERIAL_PORT + 5);
  while (lsr & 0x02) {
    lsr = inb(SERIAL_PORT + 5);
    //
    // This for loop is a patch for uart.
    //
    for (int i = 0; i < 100; i ++) {
      volatile int i __attribute_maybe_unused__ = 0;
    }
  }

  outb(SERIAL_PORT, ch);
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code));
  // should not reach here
  while (1);
}

void _trm_init() {
  // Initialize uart16550
  uint8_t lcr = inb(SERIAL_PORT + 3);
  outb(SERIAL_PORT + 3, lcr | 0x80);
  outb(SERIAL_PORT + 1, 0x00);
  outb(SERIAL_PORT + 0, 0x01);
  outb(SERIAL_PORT + 3, lcr & 0x7f);

//  // Identification
//  uint32_t mvendorid = 0;
//  uint32_t marchid = 0;
//  __asm__ __volatile__(
//		"csrr %0, mvendorid;"
//    "csrr %1, marchid;" 
//		: "=r"(mvendorid), "=r"(marchid) ::               
//  );
//
//  printf("mvendorid: 0x%08x\n", mvendorid);
//  printf("marchid:   %d\n", marchid);

  int ret = main(mainargs);
  halt(ret);
}
