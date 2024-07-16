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

word_t isa_raise_intr(word_t NO, vaddr_t epc) {
  if (cpu.mstatus & MIE) {
    cpu.mstatus |= MPIE;
  } else {
    cpu.mstatus &= ~MPIE;
  }
  cpu.mstatus &= ~MIE; // close interrupt
  cpu.mcause = NO;
  cpu.mepc = epc;
  return cpu.mtvec;
}

word_t isa_query_intr() {
  if (cpu.INTR == true && (cpu.mstatus & MIE)) {
    cpu.INTR = false;
    return IRQ_TIMER;
  }
  return INTR_EMPTY;
}

word_t read_csr(word_t imm) {
  switch (imm) {
    case MSTATUS: return cpu.mstatus;
    case MCAUSE: return cpu.mcause;
    case MTVEC: return cpu.mtvec;
    case MEPC: return cpu.mepc;
    case SATP: return cpu.satp;
    default: panic("CSRs[%d] is not immplement\n", imm);
  }
}

void write_csr(word_t imm, word_t val) {
  switch (imm) {
    case MSTATUS: cpu.mstatus = val; break;
    case MCAUSE: cpu.mcause = val; break;
    case MTVEC: cpu.mtvec = val; break;
    case MEPC: cpu.mepc = val; break;
    case SATP: cpu.satp = val; break;
    default: panic("CSRs[%d] is not immplement\n", imm);
  }
}
