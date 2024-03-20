#include <isa.h>
#include <paddr.h>

// this is not consistent with uint8_t
// but it is ok since we do not access the array directly
static const uint32_t img [] = {
  0x00000413,   // li	s0,0
  0x0f002137,   // lui	sp,0xf002
  0x00c000ef,   // jal	ra,20000014 <_trm_init>

  0x00000513,   // li	a0,0
  0x00008067,   // ret

  0xff410113,   // addi	sp,sp,-12 # f001ff4 <_entry_offset+0xf001ff4>
  0x00000517,   // auipc	a0,0x0
  0x01c50513,   // addi	a0,a0,28 # 20000034 <_etext>
  0x00112423,   // sw	ra,8(sp)
  0xfe9ff0ef,   // jal	ra,2000000c <main>
  0x00050513,   // mv	a0,a0
  0x00100073,   // ebreak
  0x0000006f,   // j	20000030 <_trm_init+0x1c>
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

  /* Initialize this virtual computer system. */
  restart();
}
