
`define ZERO_WORD       32'h0000_0000

`define PC_START        32'h8000_0000

`define INST_ADDR_WIDTH         32
`define INST_WIDTH              32

`define REG_ADDR_WIDTH          5
`define REG_WIDTH               32

`define IMM_WIDTH              32

// -------------------------------------------------
// ALU_OP
// -------------------------------------------------
`define ALU_OP_WIDTH      8

`define ALU_OP_NOP      8'b0000_0000
`define ALU_OP_ADD      8'b0000_0010

// -------------------------------------------------
// Instruction OPCODE
// -------------------------------------------------

// *** I Type
`define OPCODE_ADDI         7'b001_0011
`define FUNCT3_ADDI         3'b000

`define OPCODE_EBREAK       7'b111_0011
`define FUNCT3_EBREAK       3'b000
`define FUNCT12_EBREAK      12'b0000_0000_0001
