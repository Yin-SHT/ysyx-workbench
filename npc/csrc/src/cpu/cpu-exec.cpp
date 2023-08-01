#include <common.h>
#include <isa.h>
#include <paddr.h>
#include <utils.h>
#include <sim.h>
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include "Vtop___024root.h"

#define MAX_INST_TO_PRINT 10

CPU_state cpu = {};
int is_ebreak;
static bool g_print_step = false;
static char logbuf[512] = { 0 };

// *** Exec fucntions
svLogic program_done(int* done);
svLogic get_inst(svBitVecVal* inst);

int decode_stage(uint32_t inst, vaddr_t pc);
void difftest_step(vaddr_t npc);

void reset_logbuf() {
  for (int i = 0; i < 512; i++) {
    logbuf[i] = 0;
  }
}

void inst_trace() {
  log_write("%s\n", logbuf);
}

void exec_once() {
  inst_fetch();
  uint32_t pc = top_pc();
  uint32_t inst = top_inst();
  decode_stage(inst, pc);
  if (g_print_step) {
    BLUE_PRINT("0x%08x: ", top_pc());
  }
  single_cycle();
  if (g_print_step) {
    uint32_t inst = 0;
    get_inst(&inst);
    YELLOW_PRINT("%08x\n", inst);
  }

  // *** Inst Trace
  char *p = logbuf;
  p += snprintf(p, sizeof(logbuf), "0x%08x:", pc);
  int ilen = 4;
  int i;
  uint8_t *pinst = (uint8_t *)&inst;
  for (i = ilen - 1; i >= 0; i --) {
    p += snprintf(p, 4, " %02x", pinst[i]);
  }
  int ilen_max = 4;
  int space_len = ilen_max - ilen;
  if (space_len < 0) space_len = 0;
  space_len = space_len * 3 + 1;
  memset(p, ' ', space_len);
  p += space_len;

  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  disassemble(p, logbuf + sizeof(logbuf) - p, pc, (uint8_t *)&inst, ilen);

}

void cpu_exec(uint64_t n) {
  g_print_step = (n < MAX_INST_TO_PRINT);

  const svScope scope_pd = svGetScopeFromName("TOP.top.u_inst_decode");
  assert(scope_pd); // Check for nullptr if scope not found
  svSetScope(scope_pd);
  for (; n > 0; n --) {
    exec_once();

    // *** Trace
    inst_trace();

    // Update cpu state
    update_cpu();
    
    // diff test
    difftest_step(top_pc());
    if (npc_state.state == NPC_ABORT) {
      RED_PRINT("ABORT INST:   ");
      puts(logbuf);
      break;
    }

    // Clean up work
    reset_logbuf();

    program_done(&is_ebreak);
    if (is_ebreak) {
      npc_state.state = NPC_EBREAK;
      break;
    }
  }
}
