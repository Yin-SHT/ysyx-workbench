#ifndef __REG_H__
#define __REG_H__

#include <common.h>
#include <assert.h>

static inline int check_reg_idx(int idx) {
  assert(idx >= 0 && idx < MUXDEF(CONFIG_RVE, 16, 32));
  return idx;
}

#define gpr(idx) (cpu.gpr[check_reg_idx(idx)])

static inline const char* reg_name(int idx) {
  extern const char* regs[];
  return regs[check_reg_idx(idx)];
}

void isa_reg_display();

#endif
