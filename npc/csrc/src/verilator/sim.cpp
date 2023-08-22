#include <common.h>
#include <difftest.h>
#include <utils.h>
#include <isa.h>
#include <cpu.h>
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "Vtop__Dpi.h"
#include "Vtop___024root.h"

#define MSTATUS 0x300
#define MTVEC   0x305
#define MEPC    0x341
#define MCAUSE  0x342

static VerilatedContext* contextp;
static VerilatedVcdC* tfp;
static Vtop *top;

static int _ebreak;
static int _invalid;

extern uint32_t cur_pc;
extern uint32_t cur_inst;
extern uint32_t next_pc;
extern uint32_t next_inst;

/* Signel cycle simulation in verilator */
static void update_cpu(uint32_t next_pc) {
  for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
    cpu.gpr[i] = top->rootp->top__DOT__u_regfile__DOT__regs[i];
  }
  cpu.pc = next_pc;
}

void single_cycle() {
  top->eval();

  top->clk = 0; 
  top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1);

  cur_pc = top->rootp->top__DOT__pc___05Finst_fetch;
  cur_inst = top->rootp->top__DOT__u_inst_mem__DOT__rdata;
  word_t a0 = top->rootp->top__DOT__u_regfile__DOT__regs[10];

  if (cur_pc == 0x80000468 || cur_pc == 0x800004f0) {
    printf("CSRs[MTVEC] = 0x%08x\n", top->rootp->top__DOT__u_csrs__DOT__CSRs[MTVEC]);
    printf("CSRs[EPC] = 0x%08x\n", top->rootp->top__DOT__u_csrs__DOT__CSRs[MEPC]);
    printf("CSRs[MCAUSE] = 0x%08x\n", top->rootp->top__DOT__u_csrs__DOT__CSRs[MCAUSE]);
  }
  uint32_t mcause = top->rootp->top__DOT__u_csrs__DOT__CSRs[MCAUSE];
  uint32_t mepc = top->rootp->top__DOT__u_csrs__DOT__CSRs[MEPC];
  if (mcause == -1 ) {
    if (mepc != 0x80000440) {
      printf("curpc 0x%08x\n", cur_pc);
      assert(0);
    }
  }

  NPCTRAP(cur_pc, a0);
  INV(cur_inst, cur_pc);

  top->clk = 1; 
  top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1);

  next_pc = top->rootp->top__DOT__pc___05Finst_fetch;
  next_inst = top->rootp->top__DOT__u_inst_mem__DOT__rdata;

  /* Regfile 是同步写，异步读。
   * 因此把 update_cpu() 放在这里来获取执行完一条指令后的 regfile 的状态。
   * next_pc is the next pc that will be executed
   */
  update_cpu(next_pc);
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

  // Prepare for DPI-C
  const svScope scope_pd = svGetScopeFromName("TOP.top.u_inst_decode");
  Assert(scope_pd, "scope_pd is null"); // Check for nullptr if scope not found
  svSetScope(scope_pd);

  // Reset NPC Model
  void reset(int n);
  reset( 10 );
}

/* Utilities */
void reset(int n) {
  top->rst = 1;
  while (n -- > 0) {
    top->clk = 0; top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1);
    top->clk = 1; top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1);
  }
  top->rst = 0;
}

void clean_up() {
  tfp->close();
  delete tfp;
  delete top;
  delete contextp;
}

int check_reg_idx(int idx) {
  assert(idx >= 0 && idx < MUXDEF(CONFIG_RVE, 16, 32));
  return idx;
}

word_t npc_regs(int i) {
  int idx =  check_reg_idx(i);
  return  top->rootp->top__DOT__u_regfile__DOT__regs[idx];
}
