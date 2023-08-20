`define MSTATUS 12'h300
`define MTVEC   12'h305
`define MEPC    12'h341
`define MCAUSE  12'h342

`define ALU_DATA  1'b0
`define MEM_DATA  1'b1

`define RST_DISABLE     1'b0
`define RST_ENABLE      1'b1
`define WRITE_DISABLE   1'b0
`define WRITE_ENABLE    1'b1
`define READ_DISABLE    1'b0
`define READ_ENABLE     1'b1
`define TRAN_DISABLE    1'b0
`define TRAN_ENABLE     1'b1

`define ZERO_ADDR         32'h0000_0000
`define ZERO_WORD         32'h0000_0000
`define ZERO_REG          5'b00000
`define CSR_ZERO_REG      12'b00000
`define ZERO_BYTE_OFFSET  2'b0
`define ZERO_MASK         8'b0000_0000

`define RESET_PC        32'h8000_0000

`define MEM_ADDR_WIDTH          32
`define MEM_ADDR_BUS            31:0
`define MEM_MASK_BUS            7:0

`define MEM_DATA_WIDTH          32
`define MEM_DATA_BUS            31:0

`define INST_ADDR_WIDTH         32
`define INST_ADDR_BUS           31:0
`define INST_LENGTH             32'h0000_0004

`define INST_DATA_WIDTH         32
`define INST_DATA_BUS           31:0

`define CSR_REG_ADDR_WIDTH      12
`define CSR_REG_ADDR_BUS        11:0

`define CSR_REG_DATA_WIDTH      32
`define CSR_REG_DATA_BUS        31:0

`define REG_ADDR_WIDTH          5
`define REG_ADDR_BUS            4:0

`define REG_DATA_WIDTH          32
`define REG_DATA_BUS            31:0

`define BYTE_OFFSET_WIDTH       2
`define BYTE_OFFSET_BUS         1:0

// -------------------------------------------------
// ALU_OP
// -------------------------------------------------
`define ALU_OP_WIDTH      8
`define ALU_OP_BUS        7:0

`define ALU_OP_NOP      8'b0000_0000
`define ALU_OP_ADD      8'b0000_0001
`define ALU_OP_SUB      8'b0000_0010
`define ALU_OP_SLTIU    8'b0000_0011
`define ALU_OP_LB       8'b0000_0100
`define ALU_OP_LH       8'b0000_0101
`define ALU_OP_LW       8'b0000_0110
`define ALU_OP_LBU      8'b0000_0111
`define ALU_OP_LHU      8'b0000_1000
`define ALU_OP_SB       8'b0000_1001
`define ALU_OP_SH       8'b0000_1010
`define ALU_OP_SW       8'b0000_1011
`define ALU_OP_JUMP     8'b0000_1100
`define ALU_OP_XOR      8'b0000_1101
`define ALU_OP_OR       8'b0000_1110
`define ALU_OP_SLTU     8'b0000_1111
`define ALU_OP_AND      8'b0001_0000
`define ALU_OP_SLL      8'b0001_0001
`define ALU_OP_SRA      8'b0001_0010
`define ALU_OP_SRL      8'b0001_0011
`define ALU_OP_SLT      8'b0001_0100
`define ALU_OP_SLTI     8'b0001_0101
`define ALU_OP_ECALL    8'b0001_0110

// -------------------------------------------------
// TRAN_OP
// -------------------------------------------------
`define TRAN_OP_WIDTH      8
`define TRAN_OP_BUS        7:0

`define TRAN_OP_NOP     8'b0000_0000
`define TRAN_OP_BEQ     8'b1000_0001
`define TRAN_OP_BNE     8'b1000_0010
`define TRAN_OP_BLT     8'b1000_0011
`define TRAN_OP_BGE     8'b1000_0100
`define TRAN_OP_BLTU    8'b1000_0101
`define TRAN_OP_BGEU    8'b1000_0110
`define TRAN_OP_JAL     8'b1000_0111
`define TRAN_OP_JALR    8'b1000_1000

// -------------------------------------------------
// Instruction OPCODE
// -------------------------------------------------

// ***  Integer Compute Instructions

// ***  Register-Register Instructions
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

// **  Shift Instructions

// **  Logic Instructions

// *** Load And Store Instructions

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

// ***  Control Transfer Instructions

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

`define OPCODE_EBREAK       7'b111_0011
`define FUNCT3_EBREAK       3'b000
`define FUNCT12_EBREAK      12'b0000_0000_0001
