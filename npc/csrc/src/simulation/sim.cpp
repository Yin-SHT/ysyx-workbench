#include <common.h>
#include <utils.h>
#include <paddr.h>
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include "Vtop___024root.h"

static VerilatedContext* contextp;
static VerilatedVcdC* tfp;
static Vtop *top;

static const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

// *** Utilities
void clean_up() {
  tfp->close();
  delete top;
  delete contextp;
}

static int check_reg_idx(int idx) {
  assert(idx >= 0 && idx < MUXDEF(CONFIG_RVE, 16, 32));
  return idx;
}

void isa_reg_display() {
  for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
    word_t reg_val = top->rootp->top__DOT__u_regfile__DOT__regs[i];
    if (i % 4 == 0) printf("\n");
    GREEN_PRINT("%-3s:\t",regs[i]);
    BLUE_PRINT("0x%08x\t", reg_val);
  }
  printf("\n");
}

word_t get_reg(int i) {
  int idx =  check_reg_idx(i);
  return  top->rootp->top__DOT__u_regfile__DOT__regs[idx];
}

vaddr_t top_pc() {
  return top->pc;
}

word_t top_inst() {
  return top->inst_i;
}

void inst_fetch() {
  top->inst_i = paddr_read(top->pc, 4);
}

void single_cycle() {
  top->clk = 0; top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1);
  top->clk = 1; top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1);
}

static void reset(int n) {
  top->rst = 1;
  while (n -- > 0) single_cycle();
  top->rst = 0;
}

void init_verilator(int argc, char **argv) {
  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new Vtop{contextp};

  // trace setup
  Verilated::traceEverOn( true );
  tfp = new VerilatedVcdC;
  top->trace( tfp, 0 ); // Trace 99 levels of hierarchy (or see below)
  tfp->open( "./sim.vcd" );

  reset( 10 );
}

