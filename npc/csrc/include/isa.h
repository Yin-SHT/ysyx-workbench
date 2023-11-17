#ifndef __ISA_H__
#define __ISA_H__

#include <common.h>

typedef struct {
  word_t gpr[MUXDEF(CONFIG_RVE, 16, 32)];
  vaddr_t pc;

  // control and status registers
  word_t mstatus;
  word_t mcause;
  word_t mtvec;
  word_t mepc;
  word_t satp;
} riscv32_CPU_state;

typedef riscv32_CPU_state CPU_state;

// monitor
void init_isa();

// reg
extern CPU_state cpu;
void isa_reg_display();

#endif
