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

enum {
  SYS_exit, SYS_yield, SYS_open, SYS_read, 
  SYS_write, SYS_kill,  SYS_getpid, SYS_close, 
  SYS_lseek, SYS_brk, SYS_fstat, SYS_time,  
  SYS_signal, SYS_execve,  SYS_fork, SYS_link,  
  SYS_unlink, SYS_wait,  SYS_times,  SYS_gettimeofday
};

static char *syscall_names[] __attribute__((unused)) = {
  "SYS_exit", "SYS_yield", "SYS_open",  "SYS_read", 
  "SYS_write", "SYS_kill",  "SYS_getpid", "SYS_close", 
  "SYS_lseek", "SYS_brk", "SYS_fstat", "SYS_time",  
  "SYS_signal", "SYS_execve",  "SYS_fork", "SYS_link",  
  "SYS_unlink", "SYS_wait",  "SYS_times",  "SYS_gettimeofday"
};

#define NR_SYSCALL_NAMES ARRLEN(syscall_names)

word_t read_csr(word_t imm) {
  switch (imm) {
    case MSTATUS: return cpu.mstatus;
    case MCAUSE: return cpu.mcause;
    case MTVEC: return cpu.mtvec;
    case MEPC: return cpu.mepc;
    default: panic("CSRs[%d] is not immplement\n", imm);
  }
}

void write_csr(word_t imm, word_t val) {
  switch (imm) {
    case MSTATUS: cpu.mstatus = val; break;
    case MCAUSE: cpu.mcause = val; break;
    case MTVEC: cpu.mtvec = val; break;
    case MEPC: cpu.mepc = val; break;
    default: panic("CSRs[%d] is not immplement\n", imm);
  }
}

#ifdef CONFIG_ETRACE
static int syscall_count = -1;
void etrace_call(word_t NO) {
  if (NO == ECALL_FROM_M) {
    int syscall_num = MUXDEF(CONFIG_RVE, cpu.gpr[15], cpu.gpr[17]);
    assert((syscall_num == -1) || (syscall_num >= 0 && syscall_num < (NR_SYSCALL_NAMES)));
    
    etrace_write("%#08x: ", cpu.pc);
    syscall_count++;
    for (int i = 0; i < syscall_count; i++) {
      etrace_write("  ");
    }

    if (syscall_num == -1) {
      etrace_write("\t%s\n", "YIELD");
    } else {
      etrace_write("\t%s\n", syscall_names[syscall_num]);
    }
  } else {
    panic("Don't support NO\n");
  }
}
void etrace_ret() {
  etrace_write("%#08x: ", cpu.pc);
  for (int i = 0; i < syscall_count; i++) {
    etrace_write("  ");
  }
  etrace_write("\tmret\n");
  syscall_count--;
  return;
}
#else
void etrace_call(word_t NO) { }
void etrace_ret() { }
#endif

void trap_in() {
}

void trap_out() {
  cpu.mstatus = MUXDEF(CONFIG_ISA64, 0xa00001800, 0x1800);
#ifdef CONFIG_DIFFTEST
  void difftest_skip_ref();
  difftest_skip_ref();
#endif
}

word_t isa_raise_intr(word_t NO, vaddr_t epc) {
  cpu.mcause = NO;
  cpu.mepc = epc;
  return cpu.mtvec;
}

word_t isa_query_intr() {
  return INTR_EMPTY;
}
