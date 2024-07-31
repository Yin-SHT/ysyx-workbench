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
#define SDRAM_START 0xa0000000  // 
#define SDRAM_END   0xa8000000  // sdram:     0xa000_0000~0xa800_0000
#define GPIO_BASE   0x10002000
#define GPIO_LED    GPIO_BASE
#define GPIO_BUT    (GPIO_BASE + 4)
#define GPIO_DIG    (GPIO_BASE + 8)


int main(const char *args);

extern char _heap_start;

Area heap = {.start = (void *)&_heap_start, .end = (void *)SDRAM_END}; 
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

static void init_uart() {
  uint8_t lcr = inb(SERIAL_PORT + 3);
  outb(SERIAL_PORT + 3, lcr | 0x80);
  outb(SERIAL_PORT + 1, 0x00);
  outb(SERIAL_PORT + 0, 0x01);
  outb(SERIAL_PORT + 3, lcr & 0x7f);
}

#ifndef DATE
#define DATE 0x19491001
#endif
static void init_nvboard() {
  *(volatile uint32_t *)GPIO_DIG = DATE;
  *(volatile uint32_t *)GPIO_LED = 0xaaaa;
}

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
  init_uart();
  init_nvboard();
  int ret = main(mainargs);
  halt(ret);
}
