#include <common.h>
#include <nvboard.h>
#include <utils.h>
#include <cpu.h>
#include <sim.h>
#include <perf.h>

void single_cycle() {
    top->clock = 0; ADVANCE_CYCLE;
    top->clock = 1; ADVANCE_CYCLE;
    examine_inst();

    // update nvboard state 
    IFDEF(CONFIG_HAS_NVBOARD, nvboard_update());
}

void init_verilator(int argc, char **argv) {
    ctxp = new VerilatedContext;
    ctxp->commandArgs(argc, argv);
    top = new VysyxSoCFull{ctxp};

    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99); 
    IFDEF(CONFIG_WAVEFORM, tfp->open("./build/output/sim.vcd"));

#ifdef CONFIG_FAST_SIMULATION
    ifu_reg = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.fetch0.controller");
    idu_reg = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.reg0");
    idu_log = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.decode_log0");
    userreg = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.userreg0");
    assert(ifu_reg && idu_reg && idu_log && userreg);
#else 
    fetch_ctrl = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.fetch0.controller");
    decode_ctrl = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.decode0.controller");
    decode_logic = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.decode0.decode_log0");
    userreg = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.decode0.userreg0");
    fu = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.execute0.fu0");
    lsu = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.execute0.lsu0");
    assert(fetch_ctrl && decode_ctrl && decode_logic && userreg && fu && lsu);
#endif

    // Init nvboard
#ifdef CONFIG_HAS_NVBOARD
    void nvboard_bind_all_pins(VysyxSoCFull* ysyxSoCFull);
    nvboard_bind_all_pins(top);
    nvboard_init();
#endif

    // Reset NPC Model
    RESET(10);
}
