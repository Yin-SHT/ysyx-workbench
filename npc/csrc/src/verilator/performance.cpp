#include <utils.h>
#include <nvboard.h>
#include <cpu.h>
#include <perf.h>
#include <isa.h>
#include <sim.h>

VysyxSoCFull *top;
VerilatedVcdC* tfp;
VerilatedContext* ctxp;

svScope fetch_ctrl; 
svScope decode_ctrl;
svScope decode_logic;
svScope userreg;

uint32_t pc;
bool difftest;

void examine_inst() {
    int pc, halt_ret, ebreak, unknown;                     
    int receive;
    int complete;

    svSetScope(decode_ctrl); 
    decode_cnt(&receive);        
    if (receive) {                                      
        svSetScope(userreg); 
        userreg_event(&halt_ret);         
        svSetScope(decode_logic); 
        idu_log_event(&pc, &ebreak, &unknown);
        if (ebreak) {                                          
            set_npc_state(NPC_END, pc, halt_ret);          
        }
    }

    svSetScope(fetch_ctrl); 
    fetch_cnt(&complete);
    if (complete) {
        difftest = true;

        pc = cpu.pc;
        ALIGN_CPU;
    }
}
