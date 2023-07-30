#include "init.h"
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include "Vtop___024root.h"

extern VerilatedContext* contextp;
extern VerilatedVcdC* tfp;
extern Vtop *top;

// Utilities
void single_cycle() {
    top->clk = 0; top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1);
    top->clk = 1; top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1);
}

void reset(int n) {
  top->rst = 1;
  while (n -- > 0) single_cycle();
  top->rst = 0;
}

void contextp_top_setup(int argc, char **argv) {
  contextp = new VerilatedContext;
  contextp->commandArgs( argc, argv );
  top = new Vtop{ contextp };
}

void sim_env_setup(int argc, char **argv) {
  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new Vtop{contextp};
}

void trace_env_setup() {
  Verilated::traceEverOn( true );
  tfp = new VerilatedVcdC;
  top->trace( tfp, 0 ); // Trace 99 levels of hierarchy (or see below)
  tfp->open( "./sim.vcd" );
}