#include <common.h>
#include <difftest.h>
#include <utils.h>
#include <isa.h>
#include <cpu.h>
#include "VysyxSoCFull.h"
#include "verilated_vcd_c.h"
#include "VysyxSoCFull__Dpi.h"
#include "VysyxSoCFull___024root.h"

static VerilatedContext* contextp;
static VerilatedVcdC* tfp;
static VysyxSoCFull *ysyxSoCFull;

static int _ebreak;
static int _invalid;
bool cur_wbu_valid = false;
bool pre_wbu_valid = false;
bool first_wbu_valid = true;

extern uint32_t cur_pc;
extern uint32_t pre_pc;
extern uint32_t cur_inst;

void clean_up();

/* Signel cycle simulation in verilator */
static void update_cpu(uint32_t next_pc) {
  for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
    cpu.gpr[i] = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_regfile__DOT__regs[i];
  }
  cpu.pc = next_pc;

  cpu.mstatus = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_csrs__DOT__mstatus;
  cpu.mcause = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_csrs__DOT__mcause;
  cpu.mtvec = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_csrs__DOT__mtvec;
  cpu.mepc = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_csrs__DOT__mepc;
}

void single_cycle() {
  ysyxSoCFull->clock = 0; ysyxSoCFull->eval(); IFDEF(CONFIG_WAVEFORM, tfp->dump(contextp->time())); contextp->timeInc(1);
  ysyxSoCFull->clock = 1; ysyxSoCFull->eval(); IFDEF(CONFIG_WAVEFORM, tfp->dump(contextp->time())); contextp->timeInc(1);

  /* Check ebreak instruction */
  cur_pc = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__instpc;
  cur_inst = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__inst;

  word_t a0 = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_regfile__DOT__regs[10];
  NPCTRAP(cur_pc, a0);

  pre_wbu_valid = cur_wbu_valid;
  cur_wbu_valid = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__valid_wbu_ifu;

  if (pre_wbu_valid) {
    IFDEF(CONFIG_DIFFTEST, update_cpu(cur_pc));
  }
}

void init_verilator(int argc, char **argv) {
  // Construct Context Object
  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);

  // Construct Top Object
  ysyxSoCFull = new VysyxSoCFull{contextp};

  // Build Trace Object
#ifdef CONFIG_WAVEFORM
  Verilated::traceEverOn( true );
  tfp = new VerilatedVcdC;
  ysyxSoCFull->trace( tfp, 99 ); // Trace 99 levels of hierarchy (or see below)
  tfp->open( "./build/output/sim.vcd" );
#endif

  // Prepare for DPI-C
  const svScope scope_pd = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.u_decode");
  Assert(scope_pd, "scope_pd is null"); // Check for nullptr if scope not found
  svSetScope(scope_pd);

  // Reset NPC Model
  void reset(int n);
  reset( 10 );
}

/* Utilities */
void reset(int n) {
  ysyxSoCFull->reset = 1;
  while (n -- > 0) {
    ysyxSoCFull->clock = 0; ysyxSoCFull->eval(); IFDEF(CONFIG_WAVEFORM, tfp->dump(contextp->time())); contextp->timeInc(1);
    ysyxSoCFull->clock = 1; ysyxSoCFull->eval(); IFDEF(CONFIG_WAVEFORM, tfp->dump(contextp->time())); contextp->timeInc(1);
  }
  ysyxSoCFull->reset = 0;
}

void clean_up() {
#ifdef CONFIG_WAVEFORM
  tfp->close();
  IFDEF(CONFIG_WAVEFORM, delete tfp);
  delete ysyxSoCFull;
  delete contextp;
#endif
}

int check_reg_idx(int idx) {
  assert(idx >= 0 && idx < MUXDEF(CONFIG_RVE, 16, 32));
  return idx;
}

word_t npc_regs(int i) {
  int idx =  check_reg_idx(i);
  return ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_regfile__DOT__regs[idx];
}
