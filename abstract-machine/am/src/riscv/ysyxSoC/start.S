.section entry, "ax"
.globl _start
.type _start, @function

_start:
  mv s0, zero
  la sp, 0xf002000
  jal _trm_init
