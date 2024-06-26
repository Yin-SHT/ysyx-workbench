#ifndef ARCH_H__
#define ARCH_H__

struct Context {
  // TODO: fix the order of these members to match trap.S
  // riscve should be 16, riscv should be 32
#ifdef __riscv_e
  uintptr_t gpr[16];
#else
  uintptr_t gpr[32];
#endif
  uintptr_t mcause, mstatus, mepc;
  void *pdir;
};

#ifdef __riscv_e
#define GPR1 gpr[15] // a5
#else
#define GPR1 gpr[17] // a7
#endif

#define GPR2 gpr[10] // a0
#define GPR3 gpr[11] // a1
#define GPR4 gpr[12] // a2
#define GPRx gpr[10] // a0

#define PTE_V 0x01
#define PTE_R 0x02
#define PTE_W 0x04
#define PTE_X 0x08
#define PTE_U 0x10
#define PTE_A 0x40
#define PTE_D 0x80

#endif
