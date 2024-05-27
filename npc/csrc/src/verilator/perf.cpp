#include <stdio.h>
#include <common.h>
#include "VysyxSoCFull__Dpi.h"

#ifdef CONFIG_FUNC
svScope sp_fetchreg;
svScope sp_decode_ctl;
svScope sp_decode;
svScope sp_regfile;
svScope sp_commit;
svScope sp_commit_reg;
#elif CONFIG_SOC
svScope sp_addr;
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
static int missing_penalty;
static uint64_t access_cnt;
static uint64_t hit_cnt;
static bool icache_start;
static int target_hit;
static int icache_cycle_start;

void perf_update() {
  if (!perf_start) return;

  nr_cycles ++;

  int idu_check;

  int compute_inst;
  int branch_inst;
  int jump_inst;
  int load_inst;
  int store_inst;
  int csr_inst;  

  int check;
  int hit;

  svSetScope(sp_decode_ctl);
  decode_event(&idu_check);
  svSetScope(sp_decode);
  type_event(&compute_inst, &branch_inst, &jump_inst, &load_inst, &store_inst, &csr_inst);
  svSetScope(sp_icache);
  icache_event(&check, &hit);

  if (idu_check) {
    nr_inst ++;
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

  if (check) {
    access_cnt ++;
    if (hit) {
      hit_cnt ++;
    }
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

  double hit_ratio = (double)hit_cnt / (double)access_cnt;

  printf("\n--------------- Cache Perf Event ---------------\n");
  printf("access_cnt: %ld\n", access_cnt);
  printf("hit_cnt: %ld\n", hit_cnt);
  printf("hit ratio: %f\n", hit_ratio);
}
#endif