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
#include <cpu/difftest.h>
#include "../local-include/reg.h"

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  int nr_error = 0;
  nr_error = difftest_check_reg("PC", pc, ref_r->pc, cpu.pc) ? nr_error : nr_error + 1;  
  for (int i = 0; i < RISCV_GPR_NUM; i++) {
    nr_error = difftest_check_reg(reg_name(i), pc, ref_r->gpr[i], cpu.gpr[i]) ? nr_error : nr_error + 1;
  }
  return nr_error == 0 ? true : false;
}

void isa_difftest_attach() {
}
