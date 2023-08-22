#include <common.h>
#include <assert.h>

#define R(i) npc_regs(i)

void ftrace_call(vaddr_t pc, vaddr_t dnpc);
void ftrace_ret(vaddr_t pc, vaddr_t dnpc);
word_t npc_regs(int i);

enum {
  TYPE_I, TYPE_U, TYPE_S,
  TYPE_N, TYPE_J, TYPE_R,
  TYPE_B,
};

#define src1R() do { *src1 = R(rs1); } while (0)
#define src2R() do { *src2 = R(rs2); } while (0)
#define immI() do { *imm = SEXT(BITS(i, 31, 20), 12); } while(0)
#define immU() do { *imm = SEXT(BITS(i, 31, 12), 20) << 12; } while(0)
#define immS() do { *imm = (SEXT(BITS(i, 31, 25), 7) << 5) | BITS(i, 11, 7); } while(0)
#define immB() do { *imm = (SEXT(BITS(i, 31, 31), 1) << 12) | BITS(i, 7, 7) << 11 | BITS(i, 30, 25) << 5 | BITS(i, 11, 8) << 1; } while(0)
#define immJ() do { *imm = (SEXT(BITS(i, 31, 31), 1) << 20) | BITS(i, 19, 12) << 12 | BITS(i, 20, 20) << 11 | BITS(i, 30, 25) << 5 | BITS(i, 24, 21) << 1; } while(0)

static void decode_operand(uint32_t inst, int *rd, word_t *src1, word_t *src2, word_t *imm, int type) {
  uint32_t i = inst;
  int rs1 = BITS(i, 19, 15);
  int rs2 = BITS(i, 24, 20);
  *rd     = BITS(i, 11, 7);
  switch (type) {
    case TYPE_I: src1R();          immI(); break;
    case TYPE_U:                   immU(); break;
    case TYPE_S: src1R(); src2R(); immS(); break;
    case TYPE_J:                   immJ(); break;
    case TYPE_R: src1R(); src2R();         break;
    case TYPE_B: src1R(); src2R(); immB(); break;
    case TYPE_N:                           break;
    default: assert(0);
  }
}

int decode_ftrace(uint32_t inst, vaddr_t pc) {
  vaddr_t snpc = pc + 4;
  vaddr_t dnpc = pc + 4;
  int rd = 0;
  word_t src1 = 0, src2 = 0, imm = 0;

  int rs1 = BITS(inst, 19, 15);

  uint32_t opcode = inst & 0x0000007F;
  uint32_t funct3 = inst & 0x00007000;

  if (opcode == 0x0000006F) {
    decode_operand(inst, &rd, &src1, &src2, &imm, TYPE_J);
    dnpc = pc + imm;
    if (rd != 0) {
      ftrace_call(pc, dnpc);
    }
  } else if (opcode == 0x67 && funct3 == 0) {
    decode_operand(inst, &rd, &src1, &src2, &imm, TYPE_I);
    dnpc = ((src1 + imm) & (~1));
    if (rd == 0 && rs1 == 1 && imm == 0) {
      ftrace_ret(pc, dnpc);
    } else if (rd != 0) {
      ftrace_call(pc, dnpc);
    }
  }

  return 0;
}
