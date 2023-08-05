#include <stdint.h>
#include <common.h>
#include <utils.h>

NPCState npc_state = { .state = NPC_STOP };
extern int ebreak;

word_t npc_regs(int i);

void check_return_state() {
  if (npc_state.state == NPC_QUIT) return;
  if (npc_state.state == NPC_ABORT) {
    RED_BOLD_PRINT("\nSomething is implemented incorrectly\n");
    return;
  }
  if (npc_state.state == NPC_UNKNOWN) {
    RED_BOLD_PRINT("UNKNOWN INST\n");
  }

  uint32_t a0 = npc_regs(10);
  if ( ebreak ) {
    if (!a0 && ebreak) {
      GREEN_BOLD_PRINT("HIT GOOD TRAP!\nPASS\n");
    } else {
      RED_BOLD_PRINT("HIT BAD TRAP\nFAIL\n")
    }
    return;
  }

  RED_BOLD_PRINT("Should not run in here\n");

  return;
}