#ifndef __UTILS_H__
#define __UTILS_H__

#include <stdio.h>
#include <assert.h>

enum { NPC_EBREAK, NPC_QUIT, NPC_ABORT, NPC_STOP };

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

#define Assert(format, ...) \
do {                            \
  RED_PRINT(format, ##__VA_ARGS__); \
  assert(0); \
} while (0)

#define Log(format, ...) \
do {      \
  BLUE_PRINT(format, ##__VA_ARGS__) \
} while(0); 

#endif