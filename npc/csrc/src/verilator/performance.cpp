#include <common.h>
#include <nvboard.h>
#include <utils.h>
#include <cpu.h>
#include <perf.h>
#include <isa.h>
#include <sim.h>

VysyxSoCFull *top;
VerilatedVcdC* tfp;
VerilatedContext* ctxp;

#ifdef CONFIG_FAST_SIMULATION
svScope sp_fetchreg;
svScope sp_decode_ctl;
svScope sp_decode;
svScope sp_regfile;
svScope sp_commit_ctl;
svScope sp_commit;
#else
svScope sp_addr;
svScope sp_decode_ctl;
svScope sp_decode;
svScope sp_regfile;
svScope sp_icache;
svScope sp_commit_ctl;
svScope sp_commit;
svScope sp_drive;
#endif

//uint32_t pc;
//bool difftest;
//
//int tick;
//int inst;
//int nr_fetch, fetch_tick;
//int nr_load, load_tick;
//int nr_store, store_tick;
//int nr_compute;
//
//static void perf_display() {
//    printf("TICK: %d\n", tick);
//    printf("INST: %d\n", inst);
//    printf("IPC:  %f\n", (double)inst / tick);
//    printf("nr_fetch: %d fetch_tick: %d %f\n", nr_fetch, fetch_tick, (double)fetch_tick / tick);
//    printf("nr_load: %d load_tick: %d %f\n", nr_load, load_tick, (double)load_tick / tick);
//    printf("nr_store: %d store_tick: %d %f\n", nr_store, store_tick, (double)store_tick / tick);
//    printf("nr_load_store: %d load_store_tick: %d %f\n", nr_store + nr_load, load_tick + store_tick, ((double)(load_tick + store_tick)) / tick);
//    printf("nr_compute: %d\n", nr_compute);
//}

void getScope() {
#ifdef CONFIG_FAST_SIMULATION
    sp_regfile    = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.regfile0");
    sp_decode     = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.decode_log0");
    sp_decode_ctl = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.decode0.controller");
    sp_commit_ctl = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.commit0.controller");
    sp_commit     = svGetScopeFromName("TOP.ysyxSoCFull.cpu0.commit0.reg0");
    assert(sp_decode && sp_regfile && sp_decode_ctl && sp_commit_ctl && sp_commit);
#else
    sp_addr       = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.fetch0.addr_calculate0");
    sp_regfile    = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.decode0.regfile0");
    sp_decode     = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.decode0.decode_log0");
    sp_decode_ctl = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.decode0.controller");
    sp_icache     = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.fetch0.cache_access0");
    sp_commit_ctl = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.commit0.controller");
    sp_commit     = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.commit0.reg0");
    sp_drive      = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu0.fetch0.result_drive0");
    assert(sp_addr && sp_decode && sp_regfile && sp_decode_ctl && sp_icache && sp_commit_ctl && sp_commit && sp_drive);
#endif
}

void examine_inst() {
    do { \
        int idu_check; svSetScope(sp_decode_ctl); decode_event(&idu_check); 
        int wbu_check; svSetScope(sp_commit_ctl); commit_event(&wbu_check); 
        int commit_pc, commit_inst; svSetScope(sp_commit); commit_reg_event(&commit_pc, &commit_inst); 
        int pc, inst, unknown; svSetScope(sp_decode); check_inst(&pc, &inst, &unknown); 
        int a0; svSetScope(sp_regfile); regfile_event(&a0); 
        if (wbu_check) { 
            if (commit_inst == 0x00100073) { 
                set_npc_state(NPC_END, commit_pc, a0);  
                return; 
            }  
        } 
        if (idu_check) { 
            if (unknown) { 
                RED_BOLD_PRINT("Unknown 0x%08x at pc 0x%08x\n", inst, pc); 
                set_npc_state(NPC_QUIT, pc, a0);  
                return; 
            } 
        } 
    } while (0);

//    svSetScope(fetch_ctrl); 
//    fetch_cnt(&complete);
//    if (complete) {
//        difftest = true;
//
//        pc = cpu.pc;
//        ALIGN_CPU;
//    }

//    svSetScope(decode_ctrl); 
//    decode_cnt(&receive);        
//    if (receive) {                                      
//        inst ++;
//
//        svSetScope(userreg); 
//        userreg_event(&halt_ret);         
//        svSetScope(decode_logic); 
//        idu_log_event(&pc, &ebreak, &unknown);
//        if (ebreak) {                                          
//            set_npc_state(NPC_END, pc, halt_ret);          
//
//#ifdef CONFIG_DISPLAY
//            svSetScope(fu);
//            fu_cnt(&nr_compute);
//
//            svSetScope(lsu);
//            lsu_cnt(&nr_load, &nr_store, &load_tick, &store_tick);
//
//            perf_display();
//#endif
//        }
//    }
}
