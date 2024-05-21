#include <stdio.h>
#include <common.h>
#include "VysyxSoCFull__Dpi.h"

#ifdef CONFIG_FUNC
svScope sp_fetchreg;
svScope sp_decode;
svScope sp_regfile;
svScope sp_commit;
svScope sp_commit_reg;
#elif CONFIG_SOC
svScope sp_fetch_reg;
svScope sp_decode_ctl;
svScope sp_decode;
svScope sp_regfile;
svScope sp_icache;
#endif

bool wave_start;
bool perf_start;

#ifdef CONFIG_PEREVENT
static uint64_t nr_cycles;
static uint64_t nr_inst;

static uint64_t nr_compute;
static uint64_t nr_branch;
static uint64_t nr_jump;
static uint64_t nr_store;
static uint64_t nr_load;
static uint64_t nr_csr = 1; // last ebreak instruction
static bool cur_receive;
static bool pre_receive;

// Cache parameters
static int access_time = 2;
static int missing_penalty;
static uint64_t access_cnt;
static uint64_t hit_cnt;
static bool icache_start;
static int target_hit;
static int icache_cycle_start;

void perf_update() {
  if (!perf_start) return;

  nr_cycles ++;

  int decode_valid_pre;
  int decode_ready_pre;

  int compute_inst;
  int branch_inst;
  int jump_inst;
  int load_inst;
  int store_inst;
  int csr_inst;  

  int state;
  int master_rvalid;
  int icache_hit;

  svSetScope(sp_decode_ctl);
  decode_event(&decode_valid_pre, &decode_ready_pre);
  svSetScope(sp_decode);
  type_event(&compute_inst, &branch_inst, &jump_inst, &load_inst, &store_inst, &csr_inst);
  svSetScope(sp_icache);
  icache_event(&state, &icache_hit, &master_rvalid);

  pre_receive = cur_receive;
  if (decode_valid_pre && decode_ready_pre) {
    nr_inst ++;
    cur_receive = true;
  } else {
    cur_receive = false;
  }

  if (pre_receive) {
    if (compute_inst)     nr_compute ++;
    else if (branch_inst) nr_branch ++; 
    else if (jump_inst)   nr_jump ++;   
    else if (store_inst)  nr_store ++;  
    else if (load_inst)   nr_load ++;   
    else if (csr_inst)    nr_csr ++;    
    else {
      printf("NO way!\n");
    }
  }

  // AMAT
  if (state == 1 && !icache_start) {
    // seek_block
    access_cnt ++;
    target_hit = icache_hit;
    if (target_hit) hit_cnt ++;
    icache_cycle_start = nr_cycles;

    icache_start = true;
  }

  if (state == 4 && target_hit) {
    // wait_rready
    icache_start = false;
  } 

  if (state == 4 && !target_hit) {
    // wait_rready
    missing_penalty += (nr_cycles - icache_cycle_start + 1);
    icache_start = false;
  }
}

void perf_display() {
  uint64_t nr_total = nr_compute + nr_store + nr_load + nr_branch + nr_jump + nr_csr;
  printf("\n--------------- Perf Event ---------------\n");
  printf("Number of Inst: %ld\n", nr_inst);
  printf("Number of Cycles: %ld\n", nr_cycles);
  printf("IPC(Instruction Per Cycle): %f\n", (double)nr_inst / nr_cycles);
  printf("          %-10s%-10s%-10s%-10s%-10s%-10s%-10s\n",   "Compute", 
                                                      "Store", 
                                                      "Load", 
                                                      "Branch", 
                                                      "Jump", 
                                                      "Csr", 
                                                      "Total");
  printf("number:   %-10ld%-10ld%-10ld%-10ld%-10ld%-10ld%-10ld\n",  nr_compute, 
                                                                        nr_store, 
                                                                        nr_load, 
                                                                        nr_branch, 
                                                                        nr_jump, 
                                                                        nr_csr, 
                                                                        nr_total);

  double average_missing_penalty = (double)missing_penalty / access_cnt;
  double hit_ratio = (double)hit_cnt / access_cnt;

  printf("\n--------------- Cache Perf Event ---------------\n");
  printf("access_time: %d\n", 2);
  printf("missing_penalty: %.2f\n", average_missing_penalty);
  printf("access_cnt: %ld\n", access_cnt);
  printf("hit_cnt: %ld\n", hit_cnt);
  printf("hit ratio: %.2f\n", hit_ratio);
  printf("AMAT: %.2f\n", 2 + (1 - hit_ratio) * average_missing_penalty);
}
#endif