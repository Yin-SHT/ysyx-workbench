#ifndef __SIM_H__
#define __SIM_H__

void clean_up();
word_t get_reg(int i);
void isa_reg_display();
void single_cycle();
void init_verilator(int argc, char **argv);
void inst_fetch();

extern uint32_t cur_pc;
extern uint32_t pre_pc;
extern int pre_wbvalid;

#define REGS(i) (ysyxSoCFull->rootp->ysyxSoCFull__DOT__cpu0__DOT__decode0__DOT__u_regfile__DOT__regs[i])

#define PROCESSOR_ALIGN(_pc_) \
  do { \
    uint32_t pc = _pc_; \
    for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) { \
      cpu.gpr[i] = REGS(i); \
    } \
    cpu.pc = pc; \
    int mstatus, mcause, mtvec, mepc; \
    svSetScope(sp_csr);  \
    csr_event(&mstatus, &mtvec, &mepc, &mcause); \
    cpu.mstatus = mstatus; \
    cpu.mcause  = mtvec; \
    cpu.mtvec   = mepc; \
    cpu.mepc    = mcause; \
  } while(0);

#define CIRCUIT_EVAL(step) \
  { ysyxSoCFull->eval(); IFDEF(CONFIG_WAVEFORM, tfp->dump(contextp->time())); contextp->timeInc(step); }

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

