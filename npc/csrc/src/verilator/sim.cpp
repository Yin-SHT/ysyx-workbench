#include <common.h>
#include <difftest.h>
#include <utils.h>
#include <isa.h>
#include <cpu.h>
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "Vtop__Dpi.h"
#include "Vtop___024root.h"

static VerilatedContext* contextp;
static VerilatedVcdC* tfp;
static Vtop *top;

static int _ebreak;
static int _invalid;
bool cur_wbu_valid = false;
bool pre_wbu_valid = false;
bool first_wbu_valid = true;

extern uint32_t cur_pc;
extern uint32_t pre_pc;
extern uint32_t cur_inst;

/* Signel cycle simulation in verilator */
static void update_cpu(uint32_t next_pc) {
  for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
    cpu.gpr[i] = top->rootp->top__DOT__u_idu__DOT__u_regfile__DOT__regs[i];
  }
  cpu.pc = next_pc;
}

void single_cycle() {
  static uint32_t i = 0;

  top->clk = 0; top->eval(); IFDEF(CONFIG_WAVEFORM, tfp->dump(contextp->time())); contextp->timeInc(1);
  top->clk = 1; top->eval(); IFDEF(CONFIG_WAVEFORM, tfp->dump(contextp->time())); contextp->timeInc(1);

  /* Check ebreak instruction */
  pre_pc = cur_pc;
  cur_pc = top->rootp->top__DOT__araddr;
  cur_inst = top->rootp->top__DOT__rdata;
  word_t a0 = top->rootp->top__DOT__u_idu__DOT__u_regfile__DOT__regs[10];
  NPCTRAP(cur_pc, a0);

  /* Check whether inst is within wbu stage */
  pre_wbu_valid = cur_wbu_valid;
  cur_wbu_valid = top->rootp->top__DOT__valid_wbu_ifu;

  if (pre_wbu_valid) {
    IFDEF(CONFIG_DIFFTEST, update_cpu(cur_pc));
  }
}

void init_verilator(int argc, char **argv) {
  // Construct Context Object
  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);

  // Construct Top Object
  top = new Vtop{contextp};

  // Build Trace Object
#ifdef CONFIG_WAVEFORM
  Verilated::traceEverOn( true );
  tfp = new VerilatedVcdC;
  top->trace( tfp, 99 ); // Trace 99 levels of hierarchy (or see below)
  tfp->open( "./output/sim.vcd" );
#endif

  // Prepare for DPI-C
  const svScope scope_pd = svGetScopeFromName("TOP.top.u_idu.u_decode");
  Assert(scope_pd, "scope_pd is null"); // Check for nullptr if scope not found
  svSetScope(scope_pd);

  // Reset NPC Model
  void reset(int n);
  reset( 10 );
}

/* Utilities */
void reset(int n) {
  top->rst = 0;
  while (n -- > 0) {
    top->clk = 0; top->eval(); IFDEF(CONFIG_WAVEFORM, tfp->dump(contextp->time())); contextp->timeInc(1);
    top->clk = 1; top->eval(); IFDEF(CONFIG_WAVEFORM, tfp->dump(contextp->time())); contextp->timeInc(1);
  }
  top->rst = 1;
}

void clean_up() {
  tfp->close();
  IFDEF(CONFIG_WAVEFORM, delete tfp);
  delete top;
  delete contextp;
}

int check_reg_idx(int idx) {
  assert(idx >= 0 && idx < MUXDEF(CONFIG_RVE, 16, 32));
  return idx;
}

word_t npc_regs(int i) {
  int idx =  check_reg_idx(i);
  return top->rootp->top__DOT__u_idu__DOT__u_regfile__DOT__regs[idx];
}
