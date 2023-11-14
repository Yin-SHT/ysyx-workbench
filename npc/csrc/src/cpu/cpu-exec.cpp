#include <common.h>
#include <isa.h>
#include <utils.h>
#include <sim.h>
#include <cpu.h>
#include <difftest.h>
#include <device.h>

#define MAX_INST_TO_PRINT 10

CPU_state cpu = {};
uint32_t cur_pc;
uint32_t pre_pc;
uint32_t cur_inst;
static bool g_print_step = false;
static char logbuf[512] = { 0 };
extern bool pre_wbu_valid;
extern bool first_wbu_valid;

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

  log_write("%s\n", buf);
}

static void trace_and_difftest(vaddr_t pc, vaddr_t dnpc) {
#ifdef CONFIG_ITRACE
  translate_inst(cur_pc, cur_inst, logbuf);
  if (g_print_step) { BLUE_PRINT("0x%08x: %08x\n", cur_pc, cur_inst);}
#endif
#ifdef CONFIG_FTRACE
  int decode_ftrace(uint32_t inst, vaddr_t pc);
  decode_ftrace(cur_inst, cur_pc);
#endif
  if (pre_wbu_valid) {
    if (first_wbu_valid == false) {
      IFDEF(CONFIG_DIFFTEST, difftest_step(pc, dnpc));
    }
    first_wbu_valid = false;
  }
}

void exec_once() {
  single_cycle();
  trace_and_difftest(pre_pc, cpu.pc);
  IFDEF(CONFIG_DEVICE, device_update());
}

static void execute(uint64_t n) {
  for (;n > 0; n --) {
    exec_once();
    if (npc_state.state != NPC_RUNNING) break;
  }
}

void cpu_exec(uint64_t n) {
  g_print_step = (n < MAX_INST_TO_PRINT);
  switch (npc_state.state) {
    case NPC_END: case NPC_ABORT:
      printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
      return;
    default: npc_state.state = NPC_RUNNING;
  }

  execute(n);

  switch (npc_state.state) {
    case NPC_RUNNING: npc_state.state = NPC_STOP; break;

    case NPC_END: case NPC_ABORT:
      Log("npc: %s at pc = " FMT_WORD,
          (npc_state.state == NPC_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) :
           (npc_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
            ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
          npc_state.halt_pc);
      // fall through
    case NPC_QUIT: return;
  }
}
