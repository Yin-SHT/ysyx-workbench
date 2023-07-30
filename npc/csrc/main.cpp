#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "Vtop___024root.h"

#define CONFIG_MSIZE 0x8000000
#define RED_PRINT(format, ...) \
printf("\033[0;31m"); \
printf(format, ##__VA_ARGS__); \
printf("\033[0m");

#define GREEN_PRINT(format, ...) \
printf("\033[0;32m"); \
printf(format, ##__VA_ARGS__); \
printf("\033[0m");

static VerilatedContext* contextp = NULL;
static VerilatedVcdC* tfp = NULL;
static Vtop *top = NULL;
class Vtop___024root;

char *img_file = NULL;

static uint32_t *pmem;

static const uint32_t img [] = {
  0x00000297,  // auipc t0,0
  0x00028823,  // sb  zero,16(t0)
  0x0102c503,  // lbu a0,16(t0)
  0x00100073,  // ebreak (used as nemu_trap)
  0xdeadbeef,  // some data
};

void init_mem() {
  srand(time(0));
  pmem = (uint32_t*)calloc(CONFIG_MSIZE / sizeof(pmem[0]), sizeof(uint32_t));
  for (int i = 0; i < (int) (CONFIG_MSIZE / sizeof(pmem[0])); i ++) {
    pmem[i] = rand();
  }
}

void init_isa() {
  /* Load built-in image. */
  memcpy(pmem, img, sizeof(img));
}

static long load_img() {
  if (img_file == NULL) {
    printf("No image is given. Use the default build-in image.");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  if (!fp) {
    printf("Can not open '%s'", img_file);
    assert(0);
  } 

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  printf("The image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(pmem, size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
} 

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
  init_mem();
  init_isa();
  if (argc == 2) img_file = argv[1];
  load_img();

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
      printf("PC: 0x%08x\tIdx: %d\t", top->pc, (top->pc - 0x80000000) / 4);
      top->inst_i = pmem[(top->pc - 0x80000000) / 4];
      printf( "Inst:0x%08x\n", top->inst_i );
      single_cycle();
      program_done( &done );
      if ( done ) break;
  }
  uint32_t a0 = top->rootp->top__DOT__u_regfile__DOT__regs[10];
  if (!a0) {
    printf("\033[0;32m");
    printf("\x1B[1mHIT GOOD TRAP!\x1B[0m\n");
    printf("\033[0;32m");
    printf("\x1B[1mPASS\x1B[0m\n");
    printf("\033[0m");
  } else {
    printf("\033[0;31m");
    printf("\x1B[1mHIT BAD TRAP!\x1B[0m\n");
    printf("\033[0;31m");
    printf("\x1B[1mFAIL\x1B[0m\n");
    printf("\033[0m");
  }

  tfp->close();

  delete top;
  delete contextp;
  return 0;
}
