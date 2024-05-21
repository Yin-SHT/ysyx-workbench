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

int cur_pc;
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
  int a0;
  svSetScope(sp_fetchreg); fetchreg_event((int *)&cur_pc);
  svSetScope(sp_regfile);  regfile_event(&a0);
  NPCTRAP(cur_pc, a0);

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
  IFDEF(CONFIG_SOC, {if (cur_pc == 0xa0000000) wave_start = true;});
  IFDEF(CONFIG_SOC, {if (cur_pc == 0xa0000000) perf_start = true;});
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
  sp_fetchreg = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.fetch0.reg0");
  sp_decode   = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.decode_log0");
  sp_regfile  = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.regfile0");
  sp_commit   = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.commit0.controller");
  sp_commit_reg = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.commit0.reg0");
  assert(sp_fetchreg && sp_decode && sp_regfile && sp_commit && sp_commit_reg);
#elif CONFIG_SOC
  sp_fetchreg   = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.fetch0.reg0");
  sp_decode     = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.decode_log0");
  sp_regfile    = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.regfile0");
  sp_fetch_ctl  = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.fetch0.controller");
  sp_decode_ctl = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.controller");
  sp_execu_ctl  = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.execute0.controller");
  sp_wback_ctl  = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.commit0.controller");
  sp_icache     = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.fetch0.icache0");
  assert(sp_fetchreg && sp_decode && sp_regfile && sp_fetch_ctl && sp_decode_ctl && sp_execu_ctl && sp_wback_ctl && sp_icache);
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
