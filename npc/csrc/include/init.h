#ifndef __INIT_H__
#define __INIT_H__
#include <stdint.h>

// calculate the length of an array
#define ARRLEN(arr) (int)(sizeof(arr) / sizeof(arr[0]))
#define CONFIG_MSIZE 0x8000000
#define RED_BOLD_PRINT(format, ...)         \
printf("\033[0;31m");                       \
printf("\x1B[1m");                          \
printf(format, ##__VA_ARGS__);              \
printf("\x1B[0m");                          \
printf("\033[0m");

#define GREEN_BOLD_PRINT(format, ...) \
printf("\033[0;32m");                       \
printf("\x1B[1m");                          \
printf(format, ##__VA_ARGS__);              \
printf("\x1B[0m");                          \
printf("\033[0m");

void init_mem();
void init_isa();
long load_img(int argc, char **argv, char *img_file);
void single_cycle();
void reset(int n);
void sim_env_setup(int argc, char **argv);
void trace_env_setup();

extern uint32_t *pmem;
extern uint32_t img[];

#endif