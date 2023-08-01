#ifndef __SIM_H__
#define __SIM_H__

void clean_up();
word_t get_reg(int i);
void isa_reg_display();
void single_cycle();
void init_verilator(int argc, char **argv);
void inst_fetch();
vaddr_t top_pc();
word_t top_inst();
void update_cpu();

#endif
