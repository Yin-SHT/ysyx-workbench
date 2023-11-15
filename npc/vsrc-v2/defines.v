// -------------------------------------------------
// GLOBAL
// -------------------------------------------------
`define RST_PC             32'h8000_0000

`define RST_ENABLE         1'b0
`define RST_DISABLE        1'b1

`define WRITE_ENABLE       1'b1
`define WRITE_DISABLE      1'b0

`define READ_ENABLE        1'b1
`define READ_DISABLE       1'b0

`define BRANCH_ENABLE      1'b1
`define BRANCH_DISABLE     1'b0

`define INST_ADDR_BUS      31 : 0
`define INST_DATA_BUS      31 : 0

`define MEM_ADDR_BUS       31 : 0
`define MEM_DATA_BUS       31 : 0
`define MEM_MASK_BUS       7  : 0

`define REG_ADDR_BUS       4  : 0
`define REG_DATA_BUS       31 : 0

`define ALU_OP_BUS         7  : 0
`define LSU_OP_BUS         7  : 0
`define BPU_OP_BUS         7  : 0
`define INST_TYPE_BUS      7  : 0

// -------------------------------------------------
// Register File
// -------------------------------------------------
`define ZERO_REG           5'b0_0000
`define REG_A5             5'b0_1111
`define REG_A7             5'b1_0001

// -------------------------------------------------
// SRAM 
// -------------------------------------------------
`define RC_THRESHOLD       4'd1
`define WC_THRESHOLD       4'd1


// -------------------------------------------------
// Instruction OPCODE
// -------------------------------------------------
`define INST_NOP           8'b0000_0000
`define INST_RR            8'b0000_0001
`define INST_RI            8'b0000_0010
`define INST_LOAD          8'b0000_0011
`define INST_STORE         8'b0000_0110
`define INST_BRANCH        8'b0000_0111
`define INST_JAL           8'b0000_1000
`define INST_JALR          8'b0000_1001
`define INST_LUI           8'b0000_1010
`define INST_AUIPC         8'b0000_1011 
`define INST_SYSTEM        8'b0000_1100

// ***  Register-Register Instructions
`define INST_RR            8'b0000_0001
`define OPCODE_ADD         7'b011_0011
`define FUNCT3_ADD         3'b000
`define FUNCT7_ADD         7'b000_0000

`define OPCODE_SUB         7'b011_0011
`define FUNCT3_SUB         3'b000
`define FUNCT7_SUB         7'b010_0000

`define OPCODE_XOR         7'b011_0011
`define FUNCT3_XOR         3'b100
`define FUNCT7_XOR         7'b000_0000

`define OPCODE_OR          7'b011_0011
`define FUNCT3_OR          3'b110
`define FUNCT7_OR          7'b000_0000

`define OPCODE_AND         7'b011_0011
`define FUNCT3_AND         3'b111
`define FUNCT7_AND         7'b000_0000

`define OPCODE_SLL         7'b011_0011
`define FUNCT3_SLL         3'b001
`define FUNCT7_SLL         7'b000_0000

`define OPCODE_SRL         7'b011_0011
`define FUNCT3_SRL         3'b101
`define FUNCT7_SRL         7'b000_0000

`define OPCODE_SRA         7'b011_0011
`define FUNCT3_SRA         3'b101
`define FUNCT7_SRA         7'b010_0000

`define OPCODE_SLT         7'b011_0011
`define FUNCT3_SLT         3'b010
`define FUNCT7_SLT         7'b000_0000

`define OPCODE_SLTU        7'b011_0011
`define FUNCT3_SLTU        3'b011

// ***  Register-Immediate Instructions
`define OPCODE_ADDI        7'b001_0011
`define FUNCT3_ADDI        3'b000

`define OPCODE_XORI        7'b001_0011
`define FUNCT3_XORI        3'b100

`define OPCODE_ORI         7'b001_0011
`define FUNCT3_ORI         3'b110

`define OPCODE_ANDI        7'b001_0011
`define FUNCT3_ANDI        3'b111

`define OPCODE_SLLI        7'b001_0011
`define FUNCT3_SLLI        3'b001

`define OPCODE_SRLI        7'b001_0011
`define FUNCT3_SRLI        3'b101

`define OPCODE_SRAI        7'b001_0011
`define FUNCT3_SRAI        3'b101

`define OPCODE_SLTI        7'b001_0011
`define FUNCT3_SLTI        3'b010

`define OPCODE_SLTIU       7'b001_0011
`define FUNCT3_SLTIU       3'b011

// **  Load Instructions
`define OPCODE_LB           7'b000_0011
`define FUNCT3_LB           3'b000
`define OPCODE_LH           7'b000_0011
`define FUNCT3_LH           3'b001
`define OPCODE_LW           7'b000_0011
`define FUNCT3_LW           3'b010
`define OPCODE_LBU          7'b000_0011
`define FUNCT3_LBU          3'b100
`define OPCODE_LHU          7'b000_0011
`define FUNCT3_LHU          3'b101

// **  Store Instructions
`define OPCODE_SB           7'b010_0011
`define FUNCT3_SB           3'b000
`define OPCODE_SH           7'b010_0011
`define FUNCT3_SH           3'b001
`define OPCODE_SW           7'b010_0011
`define FUNCT3_SW           3'b010

// **   Conditional Branchs
`define OPCODE_BEQ          7'b110_0011
`define FUNCT3_BEQ          3'b000
`define OPCODE_BNE          7'b110_0011
`define FUNCT3_BNE          3'b001
`define OPCODE_BLT          7'b110_0011
`define FUNCT3_BLT          3'b100
`define OPCODE_BGE          7'b110_0011
`define FUNCT3_BGE          3'b101
`define OPCODE_BLTU         7'b110_0011
`define FUNCT3_BLTU         3'b110
`define OPCODE_BGEU         7'b110_0011
`define FUNCT3_BGEU         3'b111

// **   Unconditonal Jumps
`define OPCODE_JAL          7'b110_1111
`define OPCODE_JALR         7'b110_0111
`define FUNCT3_JALR         3'b000

// ***  Miscellaneous
`define OPCODE_AUIPC        7'b001_0111
`define OPCODE_LUI          7'b011_0111

// ***  CSR Instructions
`define OPCODE_CSRRW        7'b111_0011
`define FUNCT3_CSRRW        3'b001

`define OPCODE_CSRRS        7'b111_0011
`define FUNCT3_CSRRS        3'b010

`define OPCODE_MRET         7'b111_0011
`define FUNCT3_MRET         3'b000
`define FUNCT12_MRET        12'b0011_0000_0010

`define OPCODE_EBREAK       7'b111_0011
`define FUNCT3_EBREAK       3'b000
`define FUNCT12_EBREAK      12'b0000_0000_0001

`define OPCODE_ECALL        7'b111_0011
`define FUNCT3_ECALL        3'b000
`define FUNCT12_ECALL       12'b0000_0000_0000

// *** RV32M Multiply Extension
`define OPCODE_MUL         7'b011_0011
`define FUNCT3_MUL         3'b000
`define FUNCT7_MUL         7'b000_0001

`define OPCODE_MULH        7'b011_0011
`define FUNCT3_MULH        3'b001
`define FUNCT7_MULH        7'b000_0001

`define OPCODE_MULHU       7'b011_0011
`define FUNCT3_MULHU       3'b010
`define FUNCT7_MULHU       7'b000_0001

`define OPCODE_DIV         7'b011_0011
`define FUNCT3_DIV         3'b100
`define FUNCT7_DIV         7'b000_0001

`define OPCODE_DIVU        7'b011_0011
`define FUNCT3_DIVU        3'b101
`define FUNCT7_DIVU        7'b000_0001

`define OPCODE_REM         7'b011_0011
`define FUNCT3_REM         3'b110
`define FUNCT7_REM         7'b000_0001

`define OPCODE_REMU        7'b011_0011
`define FUNCT3_REMU        3'b111
`define FUNCT7_REMU        7'b000_0001


// -------------------------------------------------
// ALU_OP
// -------------------------------------------------
`define ALU_OP_NOP      8'b0000_0000

`define ALU_OP_ADD      8'b0000_0001
`define ALU_OP_SUB      8'b0000_0010
`define ALU_OP_XOR      8'b0000_0011
`define ALU_OP_OR       8'b0000_0100
`define ALU_OP_AND      8'b0001_0101
`define ALU_OP_SLL      8'b0001_0110
`define ALU_OP_SRL      8'b0001_0111
`define ALU_OP_SRA      8'b0001_1000
`define ALU_OP_SLT      8'b0001_1001
`define ALU_OP_SLTU     8'b0000_1010
`define ALU_OP_LUI      8'b0000_1011
`define ALU_OP_AUIPC    8'b0000_1100
`define ALU_OP_JUMP     8'b0000_1101

// -------------------------------------------------
// LSU_OP
// -------------------------------------------------
`define LSU_OP_NOP      8'b0000_0000

`define LSU_OP_LB       8'b0000_0001
`define LSU_OP_LH       8'b0000_0010
`define LSU_OP_LW       8'b0000_0011
`define LSU_OP_LBU      8'b0000_0100
`define LSU_OP_LHU      8'b0001_0101
`define LSU_OP_SB       8'b0001_0110
`define LSU_OP_SH       8'b0001_0111
`define LSU_OP_SW       8'b0001_1000

// -------------------------------------------------
// BPU_OP
// -------------------------------------------------
`define BPU_OP_NOP      8'b0000_0000

`define BPU_OP_BEQ      8'b0000_0001
`define BPU_OP_BNE      8'b0000_0010
`define BPU_OP_BLT      8'b0000_0011
`define BPU_OP_BGE      8'b0000_0100
`define BPU_OP_BLTU     8'b0001_0101
`define BPU_OP_BGEU     8'b0001_0110
`define BPU_OP_JAL      8'b0001_0111
`define BPU_OP_JALR     8'b0001_1000

// -------------------------------------------------
// WBU
// -------------------------------------------------
`define SEL_ALU_DATA    1'b0
`define SEL_LSU_DATA    1'b1
