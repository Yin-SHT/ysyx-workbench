#include <stdio.h>
#include <common.h>
#include "VysyxSoCFull__Dpi.h"

#ifdef CONFIG_FUNC
svScope sp_fetchreg;
svScope sp_decode_ctl;
svScope sp_decode;
svScope sp_regfile;
svScope sp_commit_ctl;
svScope sp_commit;
#elif CONFIG_SOC
svScope sp_addr;
svScope sp_decode_ctl;
svScope sp_decode;
svScope sp_regfile;
svScope sp_icache;
svScope sp_commit_ctl;
svScope sp_commit;
svScope sp_drive;
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

// branch predicion
static uint64_t nr_predict;
static uint64_t nr_succ;

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

  int idu_check = 0;

  int compute_inst = 0;
  int branch_inst = 0;
  int jump_inst = 0;
  int load_inst = 0;
  int store_inst = 0;
  int csr_inst  = 0;

  int check = 0;
  int hit = 0;

  int drive_check = 0;
  int is_branch = 0;
  int succ = 0;

  svSetScope(sp_decode_ctl);
  decode_event(&idu_check);
  svSetScope(sp_decode);
  type_event(&compute_inst, &branch_inst, &jump_inst, &load_inst, &store_inst, &csr_inst);
  svSetScope(sp_icache);
  icache_event(&check, &hit);
  svSetScope(sp_drive);
  drive_event(&drive_check, &is_branch, &succ);

  if (drive_check) {
    if (is_branch) {
      nr_predict ++;
      if (succ) {
        nr_succ ++;
      }
    }
  }

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

  printf("\n--------------- BTB Event ---------------\n");
  printf("Predict count: %ld\n", nr_predict);
  printf("Success count: %ld\n", nr_succ);
  printf("Succ ratio: %f\n", (double)nr_succ / nr_predict);

  double hit_ratio = (double)hit_cnt / (double)access_cnt;

  printf("\n--------------- Cache Perf Event ---------------\n");
  printf("access_cnt: %ld\n", access_cnt);
  printf("hit_cnt: %ld\n", hit_cnt);
  printf("hit ratio: %f\n", hit_ratio);
}
#endif