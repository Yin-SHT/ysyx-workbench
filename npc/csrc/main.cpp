#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include "Vtop.h"
#include "verilated_vcd_c.h"

extern svLogic ebreak();

static VerilatedContext* contextp = NULL;
static VerilatedVcdC* tfp = NULL;
static Vtop *top = NULL;

static uint32_t mem[128] = {
  0x00108093,   // addi x1, x1, 1
  0x00210113,   // addi x2, x2, 2
  0x00320213,   // addi x3, x3, 3
  0x00430313,   // addi x4, x4, 4
  0x00100073,   // ebreak
  0x00650513,   // addi x6, x6, 6
  0x00760613,   // addi x7, x7, 7
  0x00870713,   // addi x8, x8, 8
  0x00980813,   // addi x9, x9, 9
  0x00a90913,   // addi xa, x9, 9
  0x00ba0a13,   // addi xb, x9, 9
  0x00cb0b13,   // addi xc, x9, 9
  0x00dc0c13,   // addi xd, x9, 9
  0x00ed0d13,   // addi xe, x9, 9
  0x00fe0f13,   // addi xd, x9, 9
};

void single_cycle() {
    top->clk = 0; top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1); 
    top->clk = 1; top->eval(); tfp->dump(contextp->time()); contextp->timeInc(1); 
}

void reset(int n) {
  top->rst = 1;
  while (n -- > 0) single_cycle();
  top->rst = 0;
}

extern svLogic program_done(int* done);

int main( int argc, char **argv ) {
    contextp = new VerilatedContext;
    contextp->commandArgs( argc, argv );
    top = new Vtop{ contextp };

    Verilated::traceEverOn( true );
    tfp = new VerilatedVcdC;
    top->trace( tfp, 0 ); // Trace 99 levels of hierarchy (or see below)
    tfp->open( "./sim.vcd" );

    const svScope scope = svGetScopeFromName("TOP.top.u_inst_decode");
    assert(scope); // Check for nullptr if scope not found
    svSetScope(scope);

    reset( 10 );
    int done = 0;
    while ( true ) {
        top->inst_i = mem[(top->pc - 0x80000000) / 4];
        single_cycle();
        printf( "%#08x\n", top->inst_i );
        program_done( &done );
        if ( done ) break;
    }

    tfp->close();

    delete top;
    delete contextp;
    return 0;
}
