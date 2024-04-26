#ifndef __UTILS_H__
#define __UTILS_H__

#include <stdio.h>
#include <assert.h>
#include <common.h>

enum { NPC_RUNNING, NPC_STOP, NPC_END, NPC_ABORT, NPC_QUIT };

typedef struct npcstate {
  int state;
  word_t halt_pc;
  word_t halt_ret;
} NPCState;

extern NPCState npc_state;

// ----------- log -----------

#define ANSI_FG_BLACK   "\33[1;30m"
#define ANSI_FG_RED     "\33[1;31m"
#define ANSI_FG_GREEN   "\33[1;32m"
#define ANSI_FG_YELLOW  "\33[1;33m"
#define ANSI_FG_BLUE    "\33[1;34m"
#define ANSI_FG_MAGENTA "\33[1;35m"
#define ANSI_FG_CYAN    "\33[1;36m"
#define ANSI_FG_WHITE   "\33[1;37m"
#define ANSI_BG_BLACK   "\33[1;40m"
#define ANSI_BG_RED     "\33[1;41m"
#define ANSI_BG_GREEN   "\33[1;42m"
#define ANSI_BG_YELLOW  "\33[1;43m"
#define ANSI_BG_BLUE    "\33[1;44m"
#define ANSI_BG_MAGENTA "\33[1;35m"
#define ANSI_BG_CYAN    "\33[1;46m"
#define ANSI_BG_WHITE   "\33[1;47m"
#define ANSI_NONE       "\33[0m"

#define ANSI_FMT(str, fmt) fmt str ANSI_NONE

// ----------- Bold Color OUTPUT -----------
#define COLOR_BOLD  "\e[1m"
#define COLOR_OFF   "\e[m"

#define RED_BOLD_PRINT(format, ...) \
printf("\033[0;31m"); \
printf(COLOR_BOLD); \
printf(format, ##__VA_ARGS__); \
printf(COLOR_OFF); \
printf("\033[0m");

#define GREEN_BOLD_PRINT(format, ...) \
printf("\033[0;32m"); \
printf(COLOR_BOLD); \
printf(format, ##__VA_ARGS__); \
printf(COLOR_OFF); \
printf("\033[0m");

#define YELLOW_BOLD_PRINT(format, ...) \
printf("\033[0;33m"); \
printf(COLOR_BOLD); \
printf(format, ##__VA_ARGS__); \
printf(COLOR_OFF); \
printf("\033[0m");

#define BLUE_BOLD_PRINT(format, ...) \
printf("\033[0;34m"); \
printf(COLOR_BOLD); \
printf(format, ##__VA_ARGS__); \
printf(COLOR_OFF); \
printf("\033[0m");

#define PURPLE_BOLD_PRINT(format, ...) \
printf("\033[0;35m"); \
printf(COLOR_BOLD); \
printf(format, ##__VA_ARGS__); \
printf(COLOR_OFF); \
printf("\033[0m");

#define CYAN_BOLD_PRINT(format, ...) \
printf("\033[0;36m"); \
printf(COLOR_BOLD); \
printf(format, ##__VA_ARGS__); \
printf(COLOR_OFF); \
printf("\033[0m");

#define WHITE_BOLD_PRINT(format, ...) \
printf("\033[0;37m"); \
printf(COLOR_BOLD); \
printf(format, ##__VA_ARGS__); \
printf(COLOR_OFF); \
printf("\033[0m");

// ----------- Color OUTPUT -----------
#define RED_PRINT(format, ...) \
printf("\033[0;31m"); \
printf(format, ##__VA_ARGS__); \
printf("\033[0m");

#define GREEN_PRINT(format, ...) \
printf("\033[0;32m"); \
printf(format, ##__VA_ARGS__); \
printf("\033[0m");

#define YELLOW_PRINT(format, ...) \
printf("\033[0;33m"); \
printf(format, ##__VA_ARGS__); \
printf("\033[0m");

#define BLUE_PRINT(format, ...) \
printf("\033[0;34m"); \
printf(format, ##__VA_ARGS__); \
printf("\033[0m");

#define PURPLE_PRINT(format, ...) \
printf("\033[0;35m"); \
printf(format, ##__VA_ARGS__); \
printf("\033[0m");

#define CYAN_PRINT(format, ...) \
printf("\033[0;36m"); \
printf(format, ##__VA_ARGS__); \
printf("\033[0m");

#define WHITE_PRINT(format, ...) \
printf("\033[0;37m"); \
printf(format, ##__VA_ARGS__); \
printf("\033[0m");

#define Assert(cond, format, ...) \
  do { \
    if (!(cond)) { \
      MUXDEF(CONFIG_TARGET_AM, printf(ANSI_FMT(format, ANSI_FG_RED) "\n", ## __VA_ARGS__), \
        (fflush(stdout), fprintf(stderr, ANSI_FMT(format, ANSI_FG_RED) "\n", ##  __VA_ARGS__))); \
      assert(cond); \
    } \
  } while (0)

#define panic(format, ...) Assert(0, format, ## __VA_ARGS__)

#define _Log(...) \
  do { \
    printf(__VA_ARGS__); \
  } while (0)

#define Log(format, ...) \
    _Log(ANSI_FMT("[%s:%d %s] " format, ANSI_FG_BLUE) "\n", \
        __FILE__, __LINE__, __func__, ## __VA_ARGS__)

#endif