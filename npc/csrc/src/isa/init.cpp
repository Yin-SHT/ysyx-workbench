#include <isa.h>
#include <paddr.h>

// this is not consistent with uint8_t
// but it is ok since we do not access the array directly
static const uint32_t img [] = {
  0x00000297,  // auipc t0,0
  0x00028823,  // sb  zero,16(t0)
  0x0102c503,  // lbu a0,16(t0)
  0x00100073,  // ebreak (used as nemu_trap)
  0xdeadbeef,  // some data
};

static const uint32_t mrom_img [] = {
  0xffc10113,   // addi	sp,sp,-4
  0x00812023,   // sw	s0,0(sp)
  0x00410413,   // addi	s0,sp,4
  0x100007b7,   // lui	a5,0x10000
  0x04100713,   // li	a4,65
  0x00e78023,   // sb	a4,0(a5) # 10000000 <.L2+0xfffffdc>
  0x100007b7,   // lui	a5,0x10000
  0x00a00713,   // li	a4,10
  0x00e78023,   // sb	a4,0(a5) # 10000000 <.L2+0xfffffdc>
  0x0000006f,   //	j	24 <.L2>
  0x00100073,   // ebreak (used as nemu_trap, shouldn't being here) 
  0xdeadbeef,   // some data
};

static void restart() {
  /* Set the initial program counter. */
  cpu.pc = RESET_VECTOR;

  /* The zero register is always 0. */
  cpu.gpr[0] = 0;
}

void init_isa() {
  /* Load built-in image. */
  memcpy(guest_to_host(RESET_VECTOR), img, sizeof(img));

  /* Load mrom-image into mrom */
  memcpy(mrom_guest_to_host(CONFIG_MROMBASE), mrom_img, sizeof(mrom_img));

  /* Initialize this virtual computer system. */
  restart();
}
