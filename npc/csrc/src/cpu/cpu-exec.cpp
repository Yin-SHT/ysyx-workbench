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
int ebreak;
int unknown = 0;
static uint32_t cur_pc;
static uint32_t cur_inst;
static uint32_t next_pc;
static uint32_t next_inst;
static bool g_print_step = false;
static char cur_logbuf[512] = { 0 };
static char next_logbuf[512] = { 0 };

// *** Export "DPI-C" Functions
// DPI export at vsrc/inst_decode.v:50:12
svLogic inst_ebreak(int* _ebreak);
// DPI export at vsrc/inst_decode.v:56:12
svLogic inst_unknown(int* _unknown);

int decode_stage(uint32_t inst, vaddr_t pc);
void difftest_step(vaddr_t npc);

void translate_inst(uint32_t pc, uint32_t inst, char *buf) {
  char *p = buf;
  p += snprintf(p, 512, "0x%08x:", pc);
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
  disassemble(p, buf + 512 - p, pc, (uint8_t *)&inst, ilen);
}

void exec_once() {
  single_cycle(&cur_pc, &cur_inst, &next_pc, &next_inst);

  decode_stage(cur_inst, cur_pc);
  if (g_print_step) {
    BLUE_PRINT("0x%08x: %08x\n", cur_pc, cur_inst);
  }

  // *** Inst Trace
  translate_inst(cur_pc, cur_inst, cur_logbuf);
}

void cpu_exec(uint64_t n) {
  g_print_step = (n < MAX_INST_TO_PRINT);

  const svScope scope_pd = svGetScopeFromName("TOP.top.u_inst_decode");
  assert(scope_pd); // Check for nullptr if scope not found
  svSetScope(scope_pd);

  for (; n > 0; n --) {
    exec_once();

    // *** Trace
    log_write("%s\n", cur_logbuf);

    // *** Examine unknown instruction
    inst_unknown(&unknown);
    if (unknown) {
      translate_inst(next_pc, next_inst, next_logbuf);
      log_write("%s\n", next_logbuf);
      npc_state.state = NPC_UNKNOWN;
      return;
    }

    // diff test
    difftest_step(next_pc);
    if (npc_state.state == NPC_ABORT) {
      RED_PRINT("ABORT INST:   ");
      puts(cur_logbuf);
      break;
    }

    // *** Examine ebreak instruction
    inst_ebreak(&ebreak);
    if (ebreak) {
      translate_inst(next_pc, next_inst, cur_logbuf);
      log_write("%s\n", cur_logbuf);
      npc_state.state = NPC_EBREAK;
      return;
    }

  }
}
