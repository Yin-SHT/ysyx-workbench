`include "../defines.v"

module fu (
  input                       rst,

  input   [`INST_TYPE_BUS]    inst_type_i,
  input   [`ALU_OP_BUS]       alu_op_i,
  input   [`INST_ADDR_BUS]    pc_i,
  input   [`REG_DATA_BUS]     imm_i,
  input   [`REG_DATA_BUS]     rdata1_i,
  input   [`REG_DATA_BUS]     rdata2_i,

  output  [`REG_DATA_BUS]     alu_result_o
);
    
  wire [`REG_DATA_BUS] operand1;
  wire [`REG_DATA_BUS] operand2;

  assign operand1     = ( 
                          ( rst         == `RST_ENABLE ) || 
                          ( inst_type_i == `INST_NOP   ) || 
                          ( alu_op_i    == `ALU_OP_NOP )   
                        )                              ? 32'h0000_0000 :
                        ( inst_type_i == `INST_RR    ) ? rdata1_i      :
                        ( inst_type_i == `INST_RI    ) ? rdata1_i      :
                        ( inst_type_i == `INST_LUI   ) ? 32'h0000_0000 :
                        ( inst_type_i == `INST_AUIPC ) ? pc_i          : 
                        ( inst_type_i == `INST_JAL   ) ? pc_i          : 
                        ( inst_type_i == `INST_JALR  ) ? pc_i          : 32'h0000_0000;

  assign operand2     = ( 
                          ( rst         == `RST_ENABLE ) || 
                          ( inst_type_i == `INST_NOP   ) || 
                          ( alu_op_i    == `ALU_OP_NOP )   
                        )                              ? 32'h0000_0000 :
                        ( inst_type_i == `INST_RR    ) ? rdata2_i      :
                        ( inst_type_i == `INST_RI    ) ? imm_i         :
                        ( inst_type_i == `INST_LUI   ) ? imm_i         :
                        ( inst_type_i == `INST_AUIPC ) ? imm_i          : 32'h0000_0000;

  assign alu_result_o = ( 
                          ( rst         == `RST_ENABLE ) || 
                          ( inst_type_i == `INST_NOP   ) || 
                          ( alu_op_i    == `ALU_OP_NOP )   
                        )                              ?  32'h0000_0000         :
                        ( alu_op_i == `ALU_OP_ADD   )  ?  operand1  +  operand2 :
                        ( alu_op_i == `ALU_OP_SUB   )  ?  operand1  -  operand2 :
                        ( alu_op_i == `ALU_OP_XOR   )  ?  operand1  ^  operand2 :
                        ( alu_op_i == `ALU_OP_OR    )  ?  operand1  |  operand2 :
                        ( alu_op_i == `ALU_OP_AND   )  ?  operand1  &  operand2 :
                        ( alu_op_i == `ALU_OP_SLL   )  ?  operand1  << operand2 :
                        ( alu_op_i == `ALU_OP_SRL   )  ?  operand1  >> operand2 :
                        ( alu_op_i == `ALU_OP_SRA   )  ?  $signed(operand1) >> operand2 :
                        ( alu_op_i == `ALU_OP_SLT   )  ?  {{31{1'b0}}, $signed(operand1)   < $signed(operand2)}   :
                        ( alu_op_i == `ALU_OP_SLTU  )  ?  {{31{1'b0}}, $unsigned(operand1) < $unsigned(operand2)} :
                        ( alu_op_i == `ALU_OP_LUI   )  ?  operand1 + {operand2[19 : 0], 12'b0} :
                        ( alu_op_i == `ALU_OP_AUIPC )  ?  operand1 + {operand2[19 : 0], 12'b0} :
                        ( alu_op_i == `ALU_OP_JUMP  )  ?  operand1 + 32'h4                     : 32'h0000_0000;

endmodule // fu 
