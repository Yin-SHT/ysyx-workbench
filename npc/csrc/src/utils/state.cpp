#include <utils.h>
#include "VysyxSoCFull.h"
#include "verilated_vcd_c.h"
#include "VysyxSoCFull__Dpi.h"
#include "VysyxSoCFull___024root.h"

extern VysyxSoCFull *top;
extern VerilatedVcdC* tfp;
extern VerilatedContext* ctxp;

NPCState npc_state = { .state = NPC_STOP };

int is_exit_status_bad() {
    for (int i = 0; i < 5; i ++) {
        top->clock = 0; 
        do {                                                 
            top->eval();                                     
            IFDEF(CONFIG_WAVEFORM, tfp->dump(ctxp->time())); 
            ctxp->timeInc(1);                                
        } while (0);                                         
        top->clock = 1; 
        do {                                                 \
            top->eval();                                     \
            IFDEF(CONFIG_WAVEFORM, tfp->dump(ctxp->time())); \
            ctxp->timeInc(1);                                \
        } while (0);                                         
    }
    tfp->close();                                      
    delete tfp;                                         
    delete top;                                
    delete ctxp;                                   
    int good = (npc_state.state == NPC_END && npc_state.halt_ret == 0) ||
        (npc_state.state == NPC_QUIT);
    return !good;
}