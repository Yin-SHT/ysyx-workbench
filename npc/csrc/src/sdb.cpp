#include <stdio.h>
#include <stdlib.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "init.h"

int cmd_q(char *args) {
  return 0;
}

int cmd_shell(char *args) {
  return 0;
}

int cmd_c(char *args) {
  return 0;
}

int cmd_si(char *args) {
  return 0;
}

int cmd_info(char *args) {
  return 0;
}

int cmd_x(char *args) {
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