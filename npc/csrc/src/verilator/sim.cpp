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

int cur_pc, pre_pc;
int commit0, commit1, commit2;

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
  pre_pc = cur_pc;
  svSetScope(sp_fetchreg); fetchreg_event(&cur_pc);
  svSetScope(sp_regfile);  regfile_event(&a0);
  NPCTRAP(cur_pc, a0);

  /* Update processor state */
#ifdef CONFIG_DIFFTEST
  commit0 = commit1;
  commit1 = commit2;
  svSetScope(sp_commit); commit_event(&commit2);
  if (commit0) {
    for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i ++) { 
      cpu.gpr[i] = ysyxSoCFull->rootp->ysyxSoCFull__DOT__cpu0__DOT__decode0__DOT__regfile0__DOT__regs[i];
    } 
    cpu.pc = cur_pc;
  }
#endif

  /* Update nvboard state */
  IFDEF(CONFIG_NVBOARD, nvboard_update());

  /* Miscellaneous */
  IFDEF(CONFIG_SOC, {if (cur_pc == 0xa0000000) wave_start = true;});
  IFDEF(CONFIG_SOC, {if (cur_pc == 0xa0000000) perf_start = true;});
  IFDEF(CONFIG_SOC, IFDEF(CONFIG_PEREVENT, perf_update()));
}

void init_verilator(int argc, char **argv) {
  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  ysyxSoCFull = new VysyxSoCFull{contextp};

#ifdef CONFIG_WAVEFORM
  Verilated::traceEverOn( true );
  tfp = new VerilatedVcdC;
  ysyxSoCFull->trace( tfp, 99 ); // Trace 99 levels of hierarchy (or see below)
  tfp->open( "./build/output/sim.vcd" );
#endif

#ifdef CONFIG_FUNC
  sp_fetchreg = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.fetch0.reg0");
  sp_decode   = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.decode_log0");
  sp_regfile  = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.regfile0");
  sp_commit   = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.commit0.controller0");
  assert(sp_fetchreg && sp_decode && sp_regfile && sp_commit);
#elif CONFIG_SOC
  sp_fetchreg   = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.fetch0.u_reg");
  sp_decode     = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.u_decode");
  sp_regfile    = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.u_regfile");
  sp_fetch_ctl  = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.fetch0.controller");
  sp_decode_ctl = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.decode0.u_idu_fsm");
  sp_execu_ctl  = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.execute0.controller");
  sp_wback_ctl  = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.wback0.controller");
  sp_icache     = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.u_cpu.fetch0.u_icache");
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
