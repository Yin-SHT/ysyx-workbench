#ifndef __SIM_H__
#define __SIM_H__

#include "VysyxSoCFull.h"
#include "verilated_vcd_c.h"
#include "VysyxSoCFull__Dpi.h"
#include "VysyxSoCFull___024root.h"

void clean_up();
word_t get_reg(int i);
void isa_reg_display();
void single_cycle();
void init_verilator(int argc, char **argv);
void inst_fetch();
void perf_update();
void perf_display();

extern int cur_pc;
extern int pre_commit, pre_commit_pc;

extern bool wave_start;
extern bool perf_start;

#ifdef CONFIG_FUNC
extern svScope sp_fetchreg;
extern svScope sp_decode;
extern svScope sp_regfile;
extern svScope sp_commit;
extern svScope sp_commit_reg;
#elif CONFIG_SOC
extern svScope sp_fetchreg;
extern svScope sp_decode;
extern svScope sp_regfile;
extern svScope sp_fetch_ctl;
extern svScope sp_decode_ctl;
extern svScope sp_execu_ctl;
extern svScope sp_wback_ctl;
extern svScope sp_icache;
#endif


#define REGS(i) (ysyxSoCFull->rootp->ysyxSoCFull__DOT__cpu0__DOT__decode0__DOT__regfile0__DOT__regs[i])

#define PROCESSOR_ALIGN(_pc_) \
  do { \
    for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) { \
      cpu.gpr[i] = REGS(i); \
    } \
  } while(0);

#define CIRCUIT_EVAL(step) \
  { ysyxSoCFull->eval(); IFDEF(CONFIG_WAVEFORM, if (wave_start) {tfp->dump(contextp->time());}); contextp->timeInc(step); }

#define RESET(num) \
do { \
  int n = num; \
  ysyxSoCFull->reset = 1; \
  while (n -- > 0) { \
    ysyxSoCFull->clock = 0; CIRCUIT_EVAL(1) \
    ysyxSoCFull->clock = 1; CIRCUIT_EVAL(1); \
  } \
  ysyxSoCFull->reset = 0; \
} while(0)

#endif

