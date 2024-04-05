.section entry, "ax"
.globl _start
.type _start, @function

_start:
  mv s0, zero
  la sp, 0x0f002000  // Stack in sram
  jal _trm_init
