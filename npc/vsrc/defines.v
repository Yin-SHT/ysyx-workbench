
`define WRITE_DISABLE   1'b0
`define WRITE_ENABLE    1'b1
`define READ_DISABLE    1'b0
`define READ_ENABLE     1'b1

`define ZERO_WORD       32'h0000_0000
`define ZERO_REG        5'b00000

`define PC_START        32'h8000_0000

`define MEM_ADDR_WIDTH          32
`define MEM_ADDR_BUS            31:0

`define MEM_DATA_WIDTH          32
`define MEM_DATA_BUS            31:0

`define INST_ADDR_WIDTH         32
`define INST_ADDR_BUS           31:0

`define INST_DATA_WIDTH         32
`define INST_DATA_BUS           31:0

`define REG_ADDR_WIDTH          5
`define REG_ADDR_BUS            4:0

`define REG_DATA_WIDTH          32
`define REG_DATA_BUS            31:0

// -------------------------------------------------
// ALU_OP
// -------------------------------------------------
`define ALU_OP_WIDTH      8
`define ALU_OP_BUS        7:0

`define ALU_OP_NOP      8'b0000_0000
`define ALU_OP_ADD      8'b0000_0010
`define ALU_OP_JAL      8'b0000_0011
`define ALU_OP_JALR     8'b0000_0100

// -------------------------------------------------
// Instruction OPCODE
// -------------------------------------------------

// *** I Type
`define OPCODE_ADDI         7'b001_0011
`define FUNCT3_ADDI         3'b000
`define OPCODE_JALR         7'b110_0111
`define FUNCT3_JALR         3'b000

// *** U Type
`define OPCODE_AUIPC        7'b001_0111
`define OPCODE_LUI          7'b011_0111

// *** J Type
`define OPCODE_JAL          7'b110_1111

// *** S Type
`define OPCODE_SW           7'b010_0011
`define FUNCT3_SW           3'b010


// *** System Type
`define OPCODE_EBREAK       7'b111_0011
`define FUNCT3_EBREAK       3'b000
`define FUNCT12_EBREAK      12'b0000_0000_0001
