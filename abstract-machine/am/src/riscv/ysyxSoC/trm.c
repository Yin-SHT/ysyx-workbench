#include <am.h>
#include <klib-macros.h>
#include <riscv/riscv.h>

//extern char _heap_start;
int main(const char *args);

extern char _pmem_start;
#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

Area heap = {.start = (void *)0x0f000000, .end = (void *)0xf002000}; // 8 KB
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

// Temp Device Addr, these will be changed in the future !!!
//#define DEVICE_BASE 0xa0000000
#define SERIAL_PORT 0x10000000  // uart16550

void putch(char ch) {
  outb(SERIAL_PORT, ch);
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code));
  // should not reach here
  while (1);
}

void _trm_init() {
  int ret = main(mainargs);
  halt(ret);
}
