#include <nvboard.h>
#include <common.h>
#include <difftest.h>
#include <utils.h>
#include <isa.h>
#include <cpu.h>
#include <sim.h>
#include "VysyxSoCFull.h"
#include "verilated_vcd_c.h"
#include "VysyxSoCFull__Dpi.h"
#include "VysyxSoCFull___024root.h"

static VerilatedContext* contextp;
static VerilatedVcdC* tfp;
static VysyxSoCFull *ysyxSoCFull;

svScope sp_fetchreg;
svScope sp_decode;
svScope sp_regfile;
svScope sp_csr;
svScope sp_wback;

uint32_t cur_pc;
uint32_t pre_pc;
int pre_wbvalid;
static int wbvalid;

static bool wave_start;

void simulation_quit() {
#ifdef CONFIG_WAVEFORM
  tfp->close();
  IFDEF(CONFIG_WAVEFORM, delete tfp);
  delete ysyxSoCFull;
  delete contextp;
#endif
  IFDEF(CONFIG_PEREVENT, perf_display());
}

void single_cycle() {
  /* Advance one clock */
  ysyxSoCFull->clock = 0; CIRCUIT_EVAL(1);
  ysyxSoCFull->clock = 1; CIRCUIT_EVAL(1);

  /* Check ebreak or invalid instruction */
  int a0;
  svSetScope(sp_fetchreg); fetchreg_event((int *)&cur_pc);
  svSetScope(sp_regfile);  regfile_event(&a0);
  NPCTRAP(cur_pc, a0);

  /* Update processor state */
#ifdef CONFIG_DIFFTEST
  int wbready;
  pre_wbvalid = wbvalid;
  svSetScope(sp_wback); wback_event(&wbvalid, &wbready);
  if (pre_wbvalid) {PROCESSOR_ALIGN(cur_pc);}
  if (wbvalid) pre_pc = cur_pc;
#endif

  /* Update nvboard state */
  IFDEF(CONFIG_NVBOARD, nvboard_update());

  /* Miscellaneous */
  IFDEF(CONFIG_SOC, {if (cur_pc == 0xa0000000) wave_start = true;});
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
#ifdef CONFIG_FUNC
  sp_fetchreg = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.fetch0.u_reg");
  sp_decode   = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.u_decode");
  sp_regfile  = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.u_regfile");
  sp_csr      = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.u_csrs");
  sp_wback    = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.wback0.controller");
#else 
  sp_fetchreg = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.fetch0.u_reg");
  sp_decode   = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.u_decode");
  sp_regfile  = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.u_regfile");
  sp_csr      = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.u_csrs");
  sp_wback    = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.wback0.controller");
#endif
  assert(sp_fetchreg && sp_decode && sp_regfile && sp_csr && sp_wback);

  // Init nvboard
  void nvboard_bind_all_pins(VysyxSoCFull* ysyxSoCFull);
  IFDEF(CONFIG_NVBOARD, nvboard_bind_all_pins(ysyxSoCFull));
  IFDEF(CONFIG_NVBOARD, nvboard_init());

  // Miscellaneous
  IFDEF(CONFIG_FUNC, wave_start = true);

  // Reset NPC Model
  RESET(10);
}
