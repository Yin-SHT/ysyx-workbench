#include <common.h>
#include <utils.h>
#include <isa.h>
#include <cpu.h>
#include <sim.h>

VysyxSoCFull *top;
VerilatedVcdC* tfp;
VerilatedContext* ctxp;

svScope ifu_reg, idu_reg, idu_log, \
        userreg;

int last_idu_wena = 0, curr_idu_wena = 0;
int last_ifu_wena = 0, curr_ifu_wena = 0;
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

    last_ifu_wena = curr_ifu_wena;
    svSetScope(ifu_reg); ifu_reg_event(&curr_ifu_wena);
    if (last_ifu_wena) {
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

    ifu_reg = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.fetch0.reg0");
    idu_reg = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.reg0");
    idu_log = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.decode_log0");
    userreg = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.userreg0");
    assert(ifu_reg && idu_reg && idu_log && userreg);

    // Reset NPC Model
    RESET(10);
}
