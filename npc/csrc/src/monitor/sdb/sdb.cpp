#include <stdio.h>
#include <stdlib.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <common.h>
#include <utils.h>
#include <paddr.h>

void isa_reg_display();
void cpu_exec(uint64_t n);

static bool is_batch_mode = false;

int cmd_q(char *args) {
  npc_state.state = NPC_QUIT;
  return -1;
}

int cmd_shell(char *args) {
  return 0;
}

int cmd_c(char *args) {
  cpu_exec(-1);
  if (npc_state.state == NPC_EBREAK) return -1;
  return 0;
}

int cmd_si(char *args) {
  int step_num = 1;
  if (args) step_num = atoi(args);
  cpu_exec(step_num);
  if (npc_state.state == NPC_EBREAK) return -1;
  return 0;
}

int cmd_info(char *args) {
  if (!strcmp(args, "r")) {
    isa_reg_display();
  } else {
    printf("Unsupported %s\n", args);
  }
  return 0;
}

int cmd_x(char *args) {
  int value;
  uint32_t addr;

  sscanf(args, "%x %x", &value, &addr);
  for (int i = 0; i < value; i++) {
    word_t word = paddr_read(addr + i * 4, 4);
    GREEN_PRINT("0x%08x:\t", addr + i * 4); BLUE_PRINT("%08x\n", word);
  }
  return 0;
}

int cmd_help(char *args) {
  return 0;
}

struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  { "si", "Singlt execute", cmd_si },
  { "info", "Information about reg or mem", cmd_info },
  { "x", "Scan memory", cmd_x },
  { "shell", "Exe shell command", cmd_shell },

  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

/* We use the `readline' library to provide more flexibility to read from stdin. */
char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(npc) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cpu_exec(-1);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}