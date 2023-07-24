/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"
#include "utils.h"  // for nemu_state
#include "memory/paddr.h" // for paddr_read()

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}

static int cmd_si(char *args) {
  int step_num = 1;
  if (args) step_num = atoi(args);
  cpu_exec(step_num);
  return 0;
}

static int cmd_info(char *args) {
  if (!args) {
    CMD_FORMAT_TABLE('i');
    return 0;
  }

  if (!strcmp(args, "r")) {
    isa_reg_display();
  } else if (!strcmp(args, "w")) {
    wp_display();
  } else if (!strcmp(args, "e")) {
    func_sym_display();
  } else {
    RED_PRINT("UNSUPPORTED OPTION, TRY AGAIN!\n");
  }

  return 0;
}

static int cmd_x(char *args) {
  if (!args) {
    CMD_FORMAT_TABLE('x');
    return 0;
  }

  int value;
  paddr_t addr;

  sscanf(args, "%x %x", &value, &addr);
  for (int i = 0; i < value; i++) {
    word_t word = paddr_read(addr + i * 4, 4);
    GREEN_PRINT("0x%08x:\t", addr + i * 4); BLUE_PRINT("%08x\n", word);
  }
  return 0;
}

static int cmd_p(char *args) {
  if (!args) {
    CMD_FORMAT_TABLE('p');
    return 0;
  }

  // Assume expr is correct
  bool success = true;
  word_t result = expr(args, &success);
  if (!success) {
    RED_PRINT("Expression incorrect, PLEASE RETRY!\n");
    return 0;
  }
  GREEN_PRINT("DEC: "); BLUE_PRINT("%u\n", result);
  GREEN_PRINT("HEX: "); BLUE_PRINT("0x%08x\n", result);
  return 0;
}

static int cmd_w(char *args) {
  if (!args) {
    CMD_FORMAT_TABLE('w');
    return 0;
  }

  // Assume expr is correct
  bool success = true;
  word_t result = expr(args, &success);
  if (!success) {
    RED_PRINT("Expression incorrect, PLEASE RETRY!\n");
    return 0;
  }

  WP* wp = new_wp();
  if (!wp) {
    return 0;
  }
  strcpy(wp->e, args);
  wp->val = result;

  return 0;
}

static int cmd_d(char *args) {
  if (!args) {
    CMD_FORMAT_TABLE('d');
    return 0;
  }

  int no = atoi(args);
  WP* wp = find_wp(no);
  if (!wp) {
    RED_PRINT("NO WATCHPOINT NO:%d IN HEAD LIST\n", no);
    return 0;
  }
  free_wp(wp);
  return 0;
}

static int cmd_texpr(char *args) {
  if (!args) {
    CMD_FORMAT_TABLE('t');
    return 0;
  }

  FILE *fp = fopen(args, "r");
  if (fp == NULL) {
    RED_PRINT("Can't open %s", args);
    return 0;
  }

  char line[1024] = { 0 };
  while (fgets(line, sizeof(line), fp) != NULL) {
    word_t expected_res = 0;
    char expression[1024] = { 0 };
   
    if(sscanf(line, "%u %s", &expected_res, expression) != 2) {
      continue;
    };

    bool success;
    word_t res = expr(expression, &success);
    if (res == expected_res) {
      GREEN_PRINT("%u %u\n", expected_res, res);
    } else {
      RED_PRINT("%u %u\n", expected_res, res);
    }
    for (int i = 0; i < 1024; i++) line[i] = 0;
  }
  return 0;
}

static int cmd_shell(char *args) {
  int ret = system(args);
  if (ret) {
    RED_PRINT("shell command exe failed, TRY AGAIN!\n");
  }
  return 0;
}

static int cmd_q(char *args) {
  nemu_state.state = NEMU_QUIT;
  return -1;
}

static int cmd_help(char *args);

static struct {
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
  { "p", "Eval expression", cmd_p },
  { "w", "Watch expression", cmd_w },
  { "d", "Delete watchpoint", cmd_d },
  { "texpr", "Test expr", cmd_texpr },
  { "shell", "Exe shell command", cmd_shell },

  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
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

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

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

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
