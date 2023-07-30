#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include "init.h"
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include "Vtop___024root.h"

static int is_ebreak = 0;
VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;
Vtop *top = NULL;
char *img_file = NULL;
uint32_t *pmem;
uint32_t img [] = {
  0x00000297,  // auipc t0,0
  0x00028823,  // sb  zero,16(t0)
  0x0102c503,  // lbu a0,16(t0)
  0x00100073,  // ebreak (used as nemu_trap)
  0xdeadbeef,  // some data
};

svLogic program_done(int* done);

int main( int argc, char **argv ) {

  // *** Build sim environment
  init_mem();
  init_isa();
  load_img(argc, argv, img_file);
  sim_env_setup(argc, argv);
  trace_env_setup();

  // *** Set scope for DPI-C function program_done
  const svScope scope_pd = svGetScopeFromName("TOP.top.u_inst_decode");
  assert(scope_pd); // Check for nullptr if scope not found
  svSetScope(scope_pd);

  // *** Begin sim
  reset( 10 );
  while ( true ) {
      top->inst_i = pmem[(top->pc - 0x80000000) / 4];
      single_cycle();

      // Check whether the instruction is ebreak or not
      program_done( &is_ebreak );
      if ( is_ebreak ) break;
  }

  // *** Check return value ( a0 stroe the return value in riscv arch )
  uint32_t a0 = top->rootp->top__DOT__u_regfile__DOT__regs[10];
  if (!a0) {
    GREEN_BOLD_PRINT("HIT GOOD TRAP!\nPASS\n");
  } else {
    RED_BOLD_PRINT("HIT BAD TRAP\nFAIL")
  }


  // *** Dirty work for end
  tfp->close();
  free(pmem);
  delete top;
  delete contextp;
  return 0;
}
