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
    getScope();

    // Init nvboard
#ifdef CONFIG_HAS_NVBOARD
    void nvboard_bind_all_pins(VysyxSoCFull* ysyxSoCFull);
    nvboard_bind_all_pins(top);
    nvboard_init();
#endif

    // Reset NPC Model
    RESET(10);
}
