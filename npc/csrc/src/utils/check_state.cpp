#include <stdint.h>
#include <common.h>
#include <utils.h>

NPCState npc_state = { .state = NPC_STOP };
extern int is_ebreak;

word_t get_reg(int i);

void check_return_state() {
  if (npc_state.state == NPC_QUIT) return;

  uint32_t a0 = get_reg(10);
  if (!a0 && is_ebreak) {
    GREEN_PRINT("HIT GOOD TRAP!\nPASS\n");
  } else {
    RED_PRINT("HIT BAD TRAP\nFAIL\n")
  }
  return;
}