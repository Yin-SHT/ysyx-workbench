#ifndef __UTILS_H__
#define __UTILS_H__

#include <stdio.h>
#include <assert.h>

enum { NPC_EBREAK, NPC_QUIT, NPC_ABORT, NPC_STOP, NPC_UNKNOWN };

typedef struct npcstate {
  int state;
} NPCState;

extern NPCState npc_state;

// *** Log Write
#define log_write(...)                          \
  do {                                          \
    extern FILE* log_fp;                        \
    fprintf(log_fp, __VA_ARGS__);               \
    fflush(log_fp);                             \
  } while (0)                                   \

// *** Log Write
#define flog_write(...)                          \
  do {                                          \
    extern FILE* flog_fp;                        \
    fprintf(flog_fp, __VA_ARGS__);               \
    fflush(flog_fp);                             \
  } while (0)                                   \

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
do {                            \
  if (!cond) {  \
    RED_BOLD_PRINT(format, ##__VA_ARGS__); \
    assert(0); \
  } \
} while (0)

#define Log(format, ...) \
do {      \
  BLUE_BOLD_PRINT(format, ##__VA_ARGS__) \
} while(0); 

#endif