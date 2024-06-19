#include <common.h>
#include <utils.h>
#include <isa.h>
#include <cpu.h>
#include <sim.h>

VysyxSoCFull *top;
VerilatedVcdC* tfp;
VerilatedContext* ctxp;

svScope idu_reg, idu_log, wbu_ctl, \
        userreg;

int last_idu_wena = 0, curr_idu_wena = 0;
int last_commit = 0, curr_commit = 0;
int curr_pc;

void examine_inst() {
    int pc, halt_ret, ebreak, unknown;                     

    last_idu_wena = curr_idu_wena;
    svSetScope(idu_reg); idu_reg_event(&curr_idu_wena);        
    if (last_idu_wena) {                                      
        svSetScope(userreg); userreg_event(&halt_ret);         
        svSetScope(idu_log); idu_log_event(&pc, &ebreak, &unknown);
        if (ebreak) {                                          
            set_npc_state(NPC_END, pc, halt_ret);          
        }
    }

    last_commit = curr_commit;
    svSetScope(wbu_ctl); wbu_ctl_event(&curr_commit);
    if (last_commit) {
        curr_pc = cpu.pc;
        ALIGN_CPU;
    }
}

void single_cycle() {
    top->clock = 0; ADVANCE_CYCLE;
    top->clock = 1; ADVANCE_CYCLE;
    examine_inst();
}

void init_verilator(int argc, char **argv) {
    ctxp = new VerilatedContext;
    ctxp->commandArgs(argc, argv);
    top = new VysyxSoCFull{ctxp};

    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99); 
    IFDEF(CONFIG_WAVEFORM, tfp->open("./build/output/sim.vcd"));

    idu_reg = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.reg0");
    idu_log = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.decode_log0");
    userreg = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.userreg0");
    wbu_ctl = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.commit0.controller0");
    assert(idu_reg && idu_log && wbu_ctl && userreg);

    // Reset NPC Model
    RESET(10);
}
