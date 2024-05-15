#include <isa.h>
#include <paddr.h>

// this is not consistent with uint8_t
// but it is ok since we do not access the array directly
static const uint32_t img [] = {
//  0x00000297,  // auipc t0,0
//  0x00028823,  // sb  zero,16(t0)
//  0x0102c503,  // lbu a0,16(t0)
//  0x00100073,  // ebreak (used as nemu_trap)
//  0xdeadbeef,  // some data
  0x00100513,    // li	a0,1
  0x00200513,    // li	a0,1
  0x00300513,    // li	a0,1
  0x00400513,    // li	a0,1
  0x00000513,    // li	a0,0
  0x00100073,    // ebreak (used as nemu_trap)
  0xdeadbeef,    // some data
};

static void restart() {
  /* Set the initial program counter. */
#ifdef CONFIG_FUNC
  cpu.pc = 0x80000000;
#else
  cpu.pc = 0x30000000;
#endif

  /* The zero register is always 0. */
  cpu.gpr[0] = 0;
}

void init_isa() {
  /* Load built-in image. */
  memcpy(guest_to_host(RESET_VECTOR), img, sizeof(img));

  /* Initialize this virtual computer system. */
  restart();
}
