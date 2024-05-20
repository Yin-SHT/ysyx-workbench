`include "defines.v"

module pre_decode (
  input  [31:0] inst_i,
  output branch_inst_o
);

  wire [2:0] funct3 = inst_i[14 : 12];
  wire [6:0] opcode = inst_i[6  : 0 ];

  wire inst_beq  = (opcode == `OPCODE_BEQ ) & (funct3 == `FUNCT3_BEQ );
  wire inst_bne  = (opcode == `OPCODE_BNE ) & (funct3 == `FUNCT3_BNE );
  wire inst_blt  = (opcode == `OPCODE_BLT ) & (funct3 == `FUNCT3_BLT );
  wire inst_bge  = (opcode == `OPCODE_BGE ) & (funct3 == `FUNCT3_BGE );
  wire inst_bltu = (opcode == `OPCODE_BLTU) & (funct3 == `FUNCT3_BLTU);
  wire inst_bgeu = (opcode == `OPCODE_BGEU) & (funct3 == `FUNCT3_BGEU);
  wire inst_jal  = (opcode == `OPCODE_JAL );
  wire inst_jalr = (opcode == `OPCODE_JALR) & (funct3 == `FUNCT3_JALR);

  assign  branch_inst_o = inst_beq  |
                          inst_bne  |
                          inst_blt  |
                          inst_bge  |
                          inst_bltu |
                          inst_bgeu |
                          inst_jal  |
                          inst_jalr;

endmodule
