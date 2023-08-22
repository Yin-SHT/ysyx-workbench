#ifndef __CPU_H__
#define __CPU_H__

#include <common.h>

void cpu_exec(uint64_t n);

void set_npc_state(int state, vaddr_t pc, int halt_ret);
void invalid_inst(uint32_t inst, vaddr_t thispc);

#define INV(cur_inst, cur_pc) \
do { \
  inst_invalid(&_invalid); \
  if (_invalid) { \
    invalid_inst(cur_inst, cur_pc); \
    return; \
  } \
} while(0)

#define NPCTRAP(cur_pc, a0) \
do { \
  inst_ebreak(&_ebreak); \
  if(_ebreak) { \
    difftest_skip_ref(); \
    set_npc_state(NPC_END, cur_pc, a0); \
    return; \
  } \
} while(0)

#endif