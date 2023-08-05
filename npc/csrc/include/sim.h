#ifndef __SIM_H__
#define __SIM_H__

void clean_up();
word_t get_reg(int i);
void isa_reg_display();
void single_cycle(uint32_t *cur_pc, uint32_t *cur_inst, uint32_t *next_pc, uint32_t *next_inst);
void init_verilator(int argc, char **argv);
void inst_fetch();
void update_cpu();

#endif

