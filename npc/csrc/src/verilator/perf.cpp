#include <stdio.h>
#include <common.h>
#include "VysyxSoCFull__Dpi.h"

#ifdef CONFIG_FUNC
svScope sp_fetchreg;
svScope sp_decode;
svScope sp_regfile;
svScope sp_commit;
#elif CONFIG_SOC
svScope sp_fetchreg;
svScope sp_decode;
svScope sp_regfile;
svScope sp_fetch_ctl;
svScope sp_decode_ctl;
svScope sp_execu_ctl;
svScope sp_wback_ctl;
svScope sp_icache;
#endif

bool wave_start;
bool perf_start;

#ifdef CONFIG_PEREVENT
static uint64_t nr_cycles;

static uint64_t nr_fetch;
static uint64_t nr_fetch_cycles;
static uint32_t fetch_cnt = 0;
static bool fetch_start = false;

static uint64_t nr_load;
static uint64_t nr_load_cycles;
static uint32_t load_cnt = 0;
static bool load_start = false;
static bool store_start = false;

static bool inst_start = false;
static uint32_t inst_cnt = 0;

static uint64_t nr_compute;
static uint64_t nr_branch;
static uint64_t nr_jump;
static uint64_t nr_store;
static uint64_t nr_csr = 1; // last ebreak instruction

static uint64_t compute_total_cycles;
static uint64_t branch_total_cycles;
static uint64_t jump_total_cycles;
static uint64_t csr_total_cycles = 35;  // last ebreak instruction
static uint64_t store_total_cycles;
static uint64_t load_total_cycles;

static uint64_t cycle_start;
static uint64_t load_cycle_start;
static uint64_t store_cycle_start;

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

  int fetch_arvalid_o;
  int fetch_rready_o;
  int fetch_rvalid_i;

  int lsu_arvalid_o;
  int lsu_rready_o;
  int lsu_rvalid_i;

  int wback_valid_post_o;
  int wback_ready_post_i;

  int decode_valid;
  int decode_ready;

  int compute_inst;
  int branch_inst;
  int jump_inst;
  int load_inst;
  int store_inst;
  int csr_inst;  

  int state;
  int master_rvalid;
  int icache_hit;

  svSetScope(sp_fetch_ctl);
  fetch_event(&fetch_arvalid_o, &fetch_rvalid_i, &fetch_rready_o);
  svSetScope(sp_execu_ctl);
  lsu_event(&lsu_arvalid_o, &lsu_rready_o, &lsu_rvalid_i);
  svSetScope(sp_wback_ctl);
  wback_event(&wback_valid_post_o, &wback_ready_post_i);
  svSetScope(sp_decode_ctl);
  decode_event(&decode_valid, &decode_ready);
  svSetScope(sp_decode);
  type_event(&compute_inst, &branch_inst, &jump_inst, &load_inst, &store_inst, &csr_inst);
  svSetScope(sp_icache);
  icache_event(&state, &icache_hit, &master_rvalid);

  if (fetch_arvalid_o && !inst_start && !fetch_start) {
    inst_start = true;
    fetch_start = true;
    cycle_start = nr_cycles;
  }

  if (fetch_rvalid_i && fetch_rready_o && fetch_start) {
    nr_fetch ++;
    nr_fetch_cycles += (nr_cycles - cycle_start + 1);

    fetch_start = false;
  }

  if (wback_valid_post_o && wback_ready_post_i && inst_start) {
    if (compute_inst)      {compute_total_cycles += (nr_cycles - cycle_start + 1); nr_compute ++;}
    else if (branch_inst)  {branch_total_cycles  += (nr_cycles - cycle_start + 1); nr_branch ++; }
    else if (jump_inst)    {jump_total_cycles    += (nr_cycles - cycle_start + 1); nr_jump ++;   }
    else if (store_inst)   {store_total_cycles   += (nr_cycles - cycle_start + 1); nr_store ++;  }
    else if (load_inst)    {load_total_cycles    += (nr_cycles - cycle_start + 1); nr_load ++;   }
    else if (csr_inst)     {csr_total_cycles     += (nr_cycles - cycle_start + 1); nr_csr ++;    }

    inst_start = false;
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
  uint64_t all_cycles =   compute_total_cycles +
                          store_total_cycles +
                          load_total_cycles +
                          branch_total_cycles +
                          jump_total_cycles +
                          csr_total_cycles;
  printf("\n--------------- Perf Event ---------------\n");
  printf("Number of Fetch: %ld\n", nr_fetch);
  printf("Number of Cycles: %ld\n", nr_cycles);
  printf("IPC(Instruction Per Cycle): %f\n", (double)nr_fetch / nr_cycles);
  printf("Cycles to Fetch One Instruction: %ld (%ld / %ld)\n", nr_fetch_cycles / nr_fetch, nr_fetch_cycles, nr_fetch);
  printf("Fetch Cycle Percentage: %.2f\n\n", (double)nr_fetch_cycles / nr_cycles);
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
  printf("cycles:   %-10ld%-10ld%-10ld%-10ld%-10ld%-10ld%-10ld\n",  compute_total_cycles,
                                                                        store_total_cycles,
                                                                        load_total_cycles,
                                                                        branch_total_cycles,
                                                                        jump_total_cycles,
                                                                        csr_total_cycles,
                                                                        all_cycles);
  printf("%(cycles):%-10.2f%-10.2f%-10.2f%-10.2f%-10.2f%-10.2f\n",   nr_compute ? (double)compute_total_cycles / nr_cycles: 0, 
                                                                        nr_store   ? (double)store_total_cycles / nr_cycles : 0, 
                                                                        nr_load    ? (double)load_total_cycles / nr_cycles : 0, 
                                                                        nr_branch  ? (double)branch_total_cycles / nr_cycles : 0, 
                                                                        nr_jump    ? (double)jump_total_cycles / nr_cycles : 0, 
                                                                        nr_csr     ? (double)csr_total_cycles / nr_cycles : 0);

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