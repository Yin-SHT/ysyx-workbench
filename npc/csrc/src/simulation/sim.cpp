#include <common.h>
#include <utils.h>
#include <isa.h>
#include <paddr.h>
#include "Vtop.h"
#include "verilated_vcd_c.h"
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

void isa_diff_reg_display(CPU_state *ref_r) {
  for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
    word_t dut_val = top->rootp->top__DOT__u_regfile__DOT__regs[i];
    word_t ref_val = ref_r->gpr[i];
    if (i != 0 && i % 4 == 0) printf("\n");
    if (dut_val != ref_val) {
      RED_PRINT("%-3s: 0x%08x\t\t%-3s: 0x%08x\n", regs[i], dut_val, regs[i], ref_val);
    } else {
      GREEN_PRINT("%-3s: 0x%08x\t\t%-3s: 0x%08x\n", regs[i], dut_val, regs[i], ref_val);
    }
  }
  printf("\n");
}

word_t npc_regs(int i) {
  int idx =  check_reg_idx(i);
  return  top->rootp->top__DOT__u_regfile__DOT__regs[idx];
}

void update_cpu() {
  for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
    cpu.gpr[i] = top->rootp->top__DOT__u_regfile__DOT__regs[i];
  }
}

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t npc) {
  for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
    if (ref_r->gpr[i] != cpu.gpr[i]) {
      return false;
    }
  }
  if (ref_r->pc != npc) return false;

  return true;
}

// *** Simulation func
void single_cycle(uint32_t *cur_pc, uint32_t *cur_inst, uint32_t *next_pc, uint32_t *next_inst) {
  top->clk = 0; top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1);

  *cur_pc = top->rootp->top__DOT__pc___05Finst_fetch;
  *cur_inst = top->rootp->top__DOT__u_inst_mem__DOT__rdata;

  top->clk = 1; top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1);

  *next_pc = top->rootp->top__DOT__pc___05Finst_fetch;
  *next_inst = top->rootp->top__DOT__u_inst_mem__DOT__rdata;
}

static void reset(int n) {
  top->rst = 1;
  while (n -- > 0) {
    top->clk = 0; top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1);
    top->clk = 1; top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1);
  }
  top->rst = 0;
}

void init_verilator(int argc, char **argv) {
  // Construct Context Object
  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);

  // Construct Top Object
  top = new Vtop{contextp};

  // Build Trace Object
  Verilated::traceEverOn( true );
  tfp = new VerilatedVcdC;
  top->trace( tfp, 99 ); // Trace 99 levels of hierarchy (or see below)
  tfp->open( "./output/sim.vcd" );

  // Reset NPC Model
  reset( 10 );
}







