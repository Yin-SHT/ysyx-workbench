#ifndef __CPU_H__
#define __CPU_H__

#include <common.h>

void cpu_exec(uint64_t n);

void set_npc_state(int state, vaddr_t pc, int halt_ret);

void simulation_quit();
void update_cpu(uint32_t next_pc);

#define CHECKINST \
  do { \
    int idu_check; svSetScope(sp_decode_ctl); decode_event(&idu_check); \
    int pc, inst, ebreak, unknown; svSetScope(sp_decode); check_inst(&pc, &inst, &ebreak, &unknown); \
    int a0; svSetScope(sp_regfile); regfile_event(&a0); \
    if (idu_check) { \
      if (ebreak) { \
        simulation_quit();  \
        difftest_skip_ref();  \
        set_npc_state(NPC_END, pc, a0);  \
        return; \
      }  \
      if (unknown) { \
        RED_BOLD_PRINT("Unknown 0x%08x at pc 0x%08x\n", inst, pc); \
        simulation_quit();  \
        set_npc_state(NPC_QUIT, pc, a0);  \
        return; \
      } \
    } \
  } while (0);

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