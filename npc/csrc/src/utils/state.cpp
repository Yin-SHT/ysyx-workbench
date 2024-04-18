#include <utils.h>
#include <nvboard.h>

NPCState npc_state = { .state = NPC_STOP };

int is_exit_status_bad() {
  IFDEF(CONFIG_NVBOARD, nvboard_quit());

  int good = (npc_state.state == NPC_END && npc_state.halt_ret == 0) ||
    (npc_state.state == NPC_QUIT);
  return !good;
}