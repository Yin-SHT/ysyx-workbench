#ifndef __ISA_H__
#define __ISA_H__

#include <common.h>

typedef struct {
  word_t gpr[MUXDEF(CONFIG_RVE, 16, 32)];
  vaddr_t pc;
} riscv32_CPU_state;

typedef riscv32_CPU_state CPU_state;

// monitor
void init_isa();

// reg
extern CPU_state cpu;
void isa_reg_display();

#endif
