#include <am.h>
#include <stdio.h>
#include <unistd.h>

Area heap;

#define DEVICE_BASE 0xa0000000
#define SERIAL_PORT (DEVICE_BASE + 0x00003f8)
#if defined(__ISA_NATIVE__)
# define nemu_trap(code) asm volatile ("int3" : :"a"(code))
#elif defined(__ISA_AM_NATIVE__)
# define nemu_trap(code) asm volatile ("int3" : :"a"(code))
#elif defined(__ISA_RISCV32__)
# define nemu_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))
#elif defined(__ISA_RISCV32E__)
# define nemu_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))
#endif

static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }

#if defined(__ISA_NATIVE__)
void putch(char ch) {
  putchar(ch);
}
#else
void putch(char ch) {
  char str[2] = {ch, 0};
  write(1, str, 1);
}
#endif

void halt(int code) {
  nemu_trap(code);

  // should not reach here
  while (1);
}
