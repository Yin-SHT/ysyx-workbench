#ifndef __CPU_H__
#define __CPU_H__

#include <common.h>

void cpu_exec(uint64_t n);

void set_npc_state(int state, vaddr_t pc, int halt_ret);

void simulation_quit();
void update_cpu(uint32_t next_pc);

#define CHECKINST \
  do { \
    static int pre_receive = false; \
    static int cur_receive = false; \
    int a0; \
    int pc, inst; \
    int ebreak, unknown; \
    int idu_valid_pre, idu_ready_pre; \
    svSetScope(sp_decode_ctl); \
    decode_event(&idu_valid_pre, &idu_ready_pre); \
    svSetScope(sp_decode); \
    check_inst(&pc, &inst, &ebreak, &unknown); \
    svSetScope(sp_regfile); \
    regfile_event(&a0); \
    if (ebreak) { \
      simulation_quit();  \
      difftest_skip_ref();  \
      set_npc_state(NPC_END, pc, a0);  \
      return; \
    }  \
    pre_receive = cur_receive; \
    if (idu_valid_pre && idu_ready_pre) { \
      cur_receive = true; \
    } else { \
      cur_receive = false; \
    } \
    if (pre_receive) { \
      if (unknown) { \
        RED_BOLD_PRINT("Unknown 0x%08x at pc 0x%08x\n", inst, pc); \
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