#ifndef __CPU_H__
#define __CPU_H__

#include <common.h>

void cpu_exec(uint64_t n);

void set_npc_state(int state, vaddr_t pc, int halt_ret);

void simulation_quit();
void update_cpu(uint32_t next_pc);

#endif