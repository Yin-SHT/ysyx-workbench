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
svScope fu;
svScope lsu;

uint32_t pc;
bool difftest;

int tick;
int inst;
int nr_fetch;
int nr_load;
int nr_store;
int nr_compute;

static void perf_display() {
    printf("TICK: %d\n", tick);
    printf("INST: %d\n", inst);
    printf("IPC:  %f\n", (double)inst / tick);
    printf("nr_fetch: %d\n", nr_fetch);
    printf("nr_load: %d\n", nr_load);
    printf("nr_store: %d\n", nr_store);
    printf("nr_compute: %d\n", nr_compute);
}

void examine_inst() {
    int pc, halt_ret, ebreak, unknown;                     
    int receive;
    int complete;

    tick ++;

    svSetScope(fetch_ctrl); 
    fetch_cnt(&complete, &nr_fetch);
    if (complete) {
        difftest = true;

        pc = cpu.pc;
        ALIGN_CPU;
    }

    svSetScope(decode_ctrl); 
    decode_cnt(&receive);        
    if (receive) {                                      
        inst ++;

        svSetScope(userreg); 
        userreg_event(&halt_ret);         
        svSetScope(decode_logic); 
        idu_log_event(&pc, &ebreak, &unknown);
        if (ebreak) {                                          
            set_npc_state(NPC_END, pc, halt_ret);          

            svSetScope(fu);
            fu_cnt(&nr_compute);

            svSetScope(lsu);
            lsu_cnt(&nr_load, &nr_store);

            perf_display();
        }
    }
}
