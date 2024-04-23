#include <nvboard.h>
#include <common.h>
#include <difftest.h>
#include <utils.h>
#include <isa.h>
#include <cpu.h>
#include "VysyxSoCFull.h"
#include "verilated_vcd_c.h"
#include "VysyxSoCFull__Dpi.h"
#include "VysyxSoCFull___024root.h"

void perf_update();
void perf_display();
void simulation_quit();
void update_cpu(uint32_t next_pc);
void nvboard_bind_all_pins(VysyxSoCFull* ysyxSoCFull);

extern uint32_t cur_pc;
extern uint32_t pre_pc;
extern uint32_t cur_inst;
extern uint64_t nr_cycles;

static VerilatedContext* contextp;
static VerilatedVcdC* tfp;
static VysyxSoCFull *ysyxSoCFull;
svScope sp_decode;
svScope sp_decode_ctl;
svScope sp_fetch_ctl;
svScope sp_execu_ctl;
svScope sp_wback_ctl;

static int _ebreak;
static int _invalid;
bool cur_wbu_valid = false;
bool pre_wbu_valid = false;
bool first_wbu_valid = true;
bool trace_en = false;
bool perf_en = false;

void single_cycle() {
  /* Advance one clock */
  ysyxSoCFull->clock = 0; ysyxSoCFull->eval(); if(trace_en) {IFDEF(CONFIG_WAVEFORM, tfp->dump(contextp->time())); contextp->timeInc(1);}
  ysyxSoCFull->clock = 1; ysyxSoCFull->eval(); if(trace_en) {IFDEF(CONFIG_WAVEFORM, tfp->dump(contextp->time())); contextp->timeInc(1);}
  if (perf_en) nr_cycles ++;

  /* Update Performance Event */
  IFDEF(CONFIG_PEREVENT, perf_update());

  /* Update processor state */
  pre_wbu_valid = cur_wbu_valid;
  cur_wbu_valid = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__valid_wbu_ifu;
  if (pre_wbu_valid) {IFDEF(CONFIG_DIFFTEST, update_cpu(cur_pc));}

  /* Update nvboard state */
  IFDEF(CONFIG_NVBOARD, nvboard_update());

  /* Check ebreak instruction */
  svSetScope(sp_decode);
  pre_pc = cur_pc;
  cur_pc = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__instpc;
  word_t a0 = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_regfile__DOT__regs[10];
  NPCTRAP(cur_pc, a0);

  /* Enable some trace */
  if ((cur_pc == 0xa0000000) && !trace_en)  trace_en = true;
  if ((cur_pc == 0xa0000000) && !perf_en)   perf_en = true;
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
  sp_decode = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.u_decode");
  Assert(sp_decode, "scope_decode is null"); // Check for nullptr if scope not found

  sp_decode_ctl = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.u_idu_fsm");
  Assert(sp_decode_ctl, "scope_decode_ctl is null"); // Check for nullptr if scope not found

  sp_fetch_ctl = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.fetch0.controller");
  Assert(sp_fetch_ctl, "scope_fetch_ctl is null"); // Check for nullptr if scope not found

  sp_execu_ctl = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.execute0.controller");
  Assert(sp_execu_ctl, "scope_execu_ctl is null"); // Check for nullptr if scope not found

  sp_wback_ctl = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.wback0.controller");
  Assert(sp_wback_ctl, "scope_wback_ctl is null"); // Check for nullptr if scope not found

  // Init nvboard
  IFDEF(CONFIG_NVBOARD, nvboard_bind_all_pins(ysyxSoCFull));
  IFDEF(CONFIG_NVBOARD, nvboard_init());

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

void simulation_quit() {
#ifdef CONFIG_WAVEFORM
  tfp->close();
  IFDEF(CONFIG_WAVEFORM, delete tfp);
  delete ysyxSoCFull;
  delete contextp;
#endif
  IFDEF(CONFIG_PEREVENT, perf_display());
}

int check_reg_idx(int idx) {
  assert(idx >= 0 && idx < MUXDEF(CONFIG_RVE, 16, 32));
  return idx;
}

word_t npc_regs(int i) {
  int idx =  check_reg_idx(i);
  return ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_regfile__DOT__regs[idx];
}

void update_cpu(uint32_t next_pc) {
  for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
    cpu.gpr[i] = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_regfile__DOT__regs[i];
  }
  cpu.pc = next_pc;

  cpu.mstatus = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_csrs__DOT__mstatus;
  cpu.mcause = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_csrs__DOT__mcause;
  cpu.mtvec = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_csrs__DOT__mtvec;
  cpu.mepc = ysyxSoCFull->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__u_cpu__DOT__decode0__DOT__u_csrs__DOT__mepc;
}
