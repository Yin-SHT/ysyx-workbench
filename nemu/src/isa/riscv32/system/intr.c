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

MUXDEF(CONFIG_ISA64, uint64_t, uint32_t) CSRs[4096] = {0};

word_t isa_raise_intr(word_t NO, vaddr_t epc) {
  CSRs[MEPC] = epc;
  CSRs[MCAUSE] = NO;
  return CSRs[MTVEC];
}

word_t isa_query_intr() {
  return INTR_EMPTY;
}
