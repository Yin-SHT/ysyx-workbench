#ifndef __CPU_H__
#define __CPU_H__

#include <common.h>

void cpu_exec(uint64_t n);

void set_npc_state(int state, vaddr_t pc, int halt_ret);

void simulation_quit();
void update_cpu(uint32_t next_pc);

#define NPCTRAP(cur_pc, a0) \
do { \
  svSetScope(sp_decode); \
  int _ebreak; \
  inst_ebreak(&_ebreak); \
  if(_ebreak) { \
    simulation_quit(); \
    difftest_skip_ref(); \
    set_npc_state(NPC_END, cur_pc, a0); \
    return; \
  } \
} while(0)

#define FORCETRAP(cur_pc, a0) \
do { \
  if(1) { \
    simulation_quit(); \
    difftest_skip_ref(); \
    set_npc_state(NPC_END, cur_pc, a0); \
    return; \
  } \
} while(0)

#define DUMPWAVE \
do { \
    IFDEF(CONFIG_WAVEFORM, tfp->dump(contextp->time())); contextp->timeInc(1); \
} while(0)

#endif