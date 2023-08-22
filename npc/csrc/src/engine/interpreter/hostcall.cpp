#include <utils.h>
#include <difftest.h>

void set_npc_state(int state, vaddr_t pc, int halt_ret) {
  npc_state.state = state;
  npc_state.halt_pc = pc;
  npc_state.halt_ret = halt_ret;
}

__attribute__((noinline))
void invalid_inst(uint32_t inst, vaddr_t thispc) {
  uint32_t temp[1] = {inst};
  vaddr_t pc = thispc;

  uint8_t *p = (uint8_t *)temp;
  printf("invalid opcode(PC = " FMT_WORD "):\n"
      "\t%02x %02x %02x %02x ...\n"
      "\t%08x ...\n",
      thispc, p[0], p[1], p[2], p[3], temp[0] );

  printf("There are two cases which will trigger this unexpected exception:\n"
      "1. The instruction at PC = " FMT_WORD " is not implemented.\n"
      "2. Something is implemented incorrectly.\n", thispc);
  printf("Find this PC(" FMT_WORD ") in the disassembling result to distinguish which case it is.\n\n", thispc);

  set_npc_state(NPC_ABORT, thispc, -1);
}