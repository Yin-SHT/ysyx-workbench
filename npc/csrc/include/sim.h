#ifndef __SIM_H__
#define __SIM_H__

#include "VysyxSoCFull.h"
#include "verilated_vcd_c.h"
#include "VysyxSoCFull__Dpi.h"
#include "VysyxSoCFull___024root.h"

#define ADVANCE_CYCLE                                    \
    do {                                                 \
        top->eval();                                     \
        IFDEF(CONFIG_WAVEFORM, tfp->dump(ctxp->time())); \
        ctxp->timeInc(1);                                \
    } while (0);                                         

#define RESET(num)                                       \
    do {                                                 \
        int n = num;                                     \
        top->reset = 1;                                  \
        while (n -- > 0) {                               \
            top->clock = 0; ADVANCE_CYCLE;               \
            top->clock = 1; ADVANCE_CYCLE;               \
        }                                                \
        top->reset = 0;                                  \
    } while(0)

#define ALIGN_CPU                                                                                               \                   
    do {                                                                                                        \            
        for (int i = 0; i < 32; i ++) {                                                                         \                                        
            cpu.gpr[i] = top->rootp->ysyxSoCFull__DOT__cpu0__DOT__decode0__DOT__userreg0__DOT__UREGS[i];        \                                                                                                                 
        }                                                                                                       \             
        cpu.mstatus = top->rootp->ysyxSoCFull__DOT__cpu0__DOT__decode0__DOT__sysreg0__DOT__mstatus;             \                                                                                                             
        cpu.mcause = top->rootp->ysyxSoCFull__DOT__cpu0__DOT__decode0__DOT__sysreg0__DOT__mcause;               \                                                                                                             
        cpu.mtvec = top->rootp->ysyxSoCFull__DOT__cpu0__DOT__decode0__DOT__sysreg0__DOT__mtvec;                 \                                                                                                         
        cpu.mepc = top->rootp->ysyxSoCFull__DOT__cpu0__DOT__decode0__DOT__sysreg0__DOT__mepc;                   \                                                                                                         
        cpu.pc = top->rootp->ysyxSoCFull__DOT__cpu0__DOT__fetch0__DOT__controller__DOT__pc;                           \
    } while (0);

#endif
