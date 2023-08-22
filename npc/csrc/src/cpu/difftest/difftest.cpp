#include <difftest.h>
#include <common.h>
#include <isa.h>
#include <reg.h>

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  int nr_error = 0;
  nr_error = difftest_check_reg("PC", pc, ref_r->pc, cpu.pc) ? nr_error : nr_error + 1;  
  for (int i = 0; i < RISCV_GPR_NUM; i++) {
    nr_error = difftest_check_reg(reg_name(i), pc, ref_r->gpr[i], cpu.gpr[i]) ? nr_error : nr_error + 1;
  }
  return nr_error == 0 ? true : false;
}