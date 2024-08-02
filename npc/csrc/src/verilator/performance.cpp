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
int nr_fetch, fetch_tick;
int nr_load, load_tick;
int nr_store, store_tick;
int nr_compute;

static void perf_display() {
    printf("TICK: %d\n", tick);
    printf("INST: %d\n", inst);
    printf("IPC:  %f\n", (double)inst / tick);
    printf("nr_fetch: %d fetch_tick: %d %: %f\n", nr_fetch, fetch_tick, (double)fetch_tick / tick);
    printf("nr_load: %d load_tick: %d %: %f\n", nr_load, load_tick, (double)load_tick / tick);
    printf("nr_store: %d store_tick: %d %: %f\n", nr_store, store_tick, (double)store_tick / tick);
    printf("nr_load_store: %d load_store_tick: %d %: %f\n", nr_store + nr_load, load_tick + store_tick, ((double)(load_tick + store_tick)) / tick);
    printf("nr_compute: %d\n", nr_compute);
}

void examine_inst() {
    int pc, halt_ret, ebreak, unknown;                     
    int receive;
    int complete;

    tick ++;

    svSetScope(fetch_ctrl); 
    fetch_cnt(&complete, &nr_fetch, &fetch_tick);
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
            lsu_cnt(&nr_load, &nr_store, &load_tick, &store_tick);

            perf_display();
        }
    }
}
