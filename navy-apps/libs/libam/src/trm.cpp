#include <am.h>

Area heap;

#define DEVICE_BASE 0xa0000000
#define SERIAL_PORT (DEVICE_BASE + 0x00003f8)
#if defined(__ISA_NATIVE__)
# define nemu_trap(code) asm volatile ("int3" : :"a"(code))
#elif defined(__ISA_AM_NATIVE__)
# define nemu_trap(code) asm volatile ("int3" : :"a"(code))
#elif defined(__ISA_RISCV32__)
# define nemu_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))
#endif

static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }

void putch(char ch) {
  outb(SERIAL_PORT, ch);
}

void halt(int code) {
  nemu_trap(code);

  // should not reach here
  while (1);
}
