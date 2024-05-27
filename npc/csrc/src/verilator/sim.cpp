#include <nvboard.h>
#include <common.h>
#include <difftest.h>
#include <utils.h>
#include <isa.h>
#include <cpu.h>
#include <sim.h>

static VerilatedContext* contextp;
static VerilatedVcdC* tfp;
static VysyxSoCFull *ysyxSoCFull;

int cur_commit, cur_commit_pc, cur_commit_inst;
int pre_commit, pre_commit_pc, pre_commit_inst;

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
  CHECKINST;

  /* Update processor state */
#ifdef CONFIG_DIFFTEST
  pre_commit = cur_commit;
  pre_commit_pc = cur_commit_pc;
  pre_commit_inst = cur_commit_inst;
  if (pre_commit) {PROCESSOR_ALIGN(cur_commit_pc);}
  svSetScope(sp_commit); commit_event(&cur_commit);
  svSetScope(sp_commit_reg); commit_reg_event(&cur_commit_pc, &cur_commit_inst);
#endif

  /* Update nvboard state */
  IFDEF(CONFIG_NVBOARD, nvboard_update());

  /* Miscellaneous */
  IFDEF(CONFIG_SOC, int pc; svSetScope(sp_addr); addr_event(&pc););
  IFDEF(CONFIG_SOC, {if (pc == 0xa0000000) wave_start = true;});
  IFDEF(CONFIG_SOC, {if (pc == 0xa0000000) perf_start = true;});
  IFDEF(CONFIG_SOC, IFDEF(CONFIG_PEREVENT, perf_update()));
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
  sp_regfile    = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.regfile0");
  sp_decode     = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.decode_log0");
  sp_decode_ctl = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.controller");
  assert(sp_decode && sp_regfile && sp_decode_ctl);
#elif CONFIG_SOC
  sp_addr       = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.fetch0.addr_calculate0");
  sp_regfile    = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.regfile0");
  sp_decode     = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.decode_log0");
  sp_decode_ctl = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.controller");
  sp_icache     = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.fetch0.cache_access0");
  assert(sp_addr && sp_decode && sp_regfile && sp_decode_ctl && sp_icache);
#endif

  // Init nvboard
  void nvboard_bind_all_pins(VysyxSoCFull* ysyxSoCFull);
  IFDEF(CONFIG_NVBOARD, nvboard_bind_all_pins(ysyxSoCFull));
  IFDEF(CONFIG_NVBOARD, nvboard_init());

  // Miscellaneous
  IFDEF(CONFIG_FUNC, wave_start = true);

  // Reset NPC Model
  RESET(10);
}
