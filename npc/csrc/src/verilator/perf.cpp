#include <stdio.h>
#include <common.h>
#include "VysyxSoCFull__Dpi.h"

#ifdef CONFIG_FUNC
svScope sp_fetchreg;
svScope sp_decode;
svScope sp_regfile;
svScope sp_csr;
#elif CONFIG_SOC
svScope sp_fetchreg;
svScope sp_decode;
svScope sp_regfile;
svScope sp_fetch_ctl;
svScope sp_decode_ctl;
svScope sp_execu_ctl;
svScope sp_wback_ctl;
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

static bool inst_start = false;
static uint32_t inst_cnt = 0;

static uint64_t nr_compute;
static uint64_t nr_branch;
static uint64_t nr_jump;
static uint64_t nr_csr;
static uint64_t nr_store;

static uint64_t compute_total_cycles;
static uint64_t branch_total_cycles;
static uint64_t jump_total_cycles;
static uint64_t csr_total_cycles;
static uint64_t store_total_cycles;
static uint64_t load_total_cycles;

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

  /* Cycles to Instruction Life */
  if (fetch_arvalid_o && !inst_start) {
    inst_start = true;
    inst_cnt = 0;
  }

  if (inst_start) inst_cnt ++;

  if (wback_valid_post_o && wback_ready_post_i) {
    if (compute_inst)      compute_total_cycles += inst_cnt;
    else if (branch_inst)  branch_total_cycles += inst_cnt;
    else if (jump_inst)    jump_total_cycles += inst_cnt;
    else if (store_inst)   store_total_cycles += inst_cnt;
    else if (load_inst)    load_total_cycles += inst_cnt;
    else if (csr_inst)     csr_total_cycles += inst_cnt;

    inst_start = false;
    inst_cnt = 0;
  }

  /* Number of different kind of instructions */
  if (!decode_valid && !decode_ready) {
    if (compute_inst)      nr_compute ++;
    else if (branch_inst)  nr_branch ++;
    else if (jump_inst)    nr_jump ++;
    else if (store_inst)   nr_store ++;
    else if (csr_inst)     nr_csr ++;  
  }

  /* Cycles to Fetch One Instruction */
  if (fetch_arvalid_o && !fetch_start) {
    fetch_start = true;
    fetch_cnt = 0;

    inst_start = true;
    inst_cnt = 0;
  }

  if (inst_start) inst_cnt ++;
  if (fetch_start) fetch_cnt ++;

  if (fetch_rvalid_i && fetch_rready_o) {
    nr_fetch_cycles += fetch_cnt;
    nr_fetch ++;

    fetch_start = false;
    fetch_cnt = 0;
  }

  /* Cycles to Load Data */
  if (lsu_arvalid_o && !load_start) {
    load_start = true;
    load_cnt = 0;
  }

  if (load_start) load_cnt ++;

  if (lsu_rvalid_i && lsu_rready_o) {
    nr_load_cycles += load_cnt;
    nr_load ++;

    load_start = false;
    load_cnt = 0;
  }
}

void perf_display() {
  uint64_t nr_total = nr_compute + nr_store + nr_load + nr_branch + nr_jump + nr_csr;

  printf("\n--------------- Perf Event ---------------\n");
  printf("Number of Fetch: %ld\n", nr_fetch);
  printf("Number of Cycles: %ld\n", nr_cycles);
  printf("IPC(Instruction Per Cycle): %f\n", (double)nr_fetch / nr_cycles);
  printf("Cycles to Fetch One Instruction: %ld\n", nr_fetch_cycles / nr_fetch);
  printf("Cycles to Load Data: %ld (%ld %ld)\n", nr_load_cycles / nr_load, nr_load_cycles, nr_load);
  printf("\nCompute\t\tStore\t\tLoad\t\tBranch\t\tJump\t\tCsr\t\tTotal\n");
  printf("%ld\t\t%ld\t\t%ld\t\t%ld\t\t%ld\t\t%ld\t\t%ld\n", nr_compute, nr_store, nr_load, nr_branch, nr_jump, nr_csr, nr_total);
  printf("%.2f\t\t%.2f\t\t%.2f\t\t%.2f\t\t%.2f\t\t%.2f\n",  nr_compute ? (double)compute_total_cycles / nr_compute : 0, 
                                                            nr_store   ? (double)store_total_cycles / nr_store : 0, 
                                                            nr_load    ? (double)load_total_cycles / nr_load : 0, 
                                                            nr_branch  ? (double)branch_total_cycles / nr_branch : 0, 
                                                            nr_jump    ? (double)jump_total_cycles / nr_jump : 0, 
                                                            nr_csr     ? (double)csr_total_cycles / nr_csr : 0);
}
#endif