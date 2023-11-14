`include "defines.v"

module bpu (
  input rst,

  input [`BPU_OP_BUS]       bpu_op_i,

  input [`INST_ADDR_BUS]    pc_i, 
  input [`REG_DATA_BUS]     imm_i,
  input [`REG_DATA_BUS]     rdata1_i,
  input [`REG_DATA_BUS]     rdata2_i,

  output                    branch_en_o,
  output  [`INST_ADDR_BUS]  dnpc_o
);

  wire equal, signed_less_than, unsigned_less_than;

  subtract u_substract(
    .rdata1_i             ( rdata1_i           ),
    .rdata2_i             ( rdata2_i           ),
    .equal_o              ( equal              ),
    .signed_less_than_o   ( signed_less_than   ),
    .unsigned_less_than_o ( unsigned_less_than )
  );

  assign  branch_en_o = (( rst == `RST_ENABLE ) || ( bpu_op_i == `BPU_OP_NOP )) ? `BRANCH_DISABLE : 
                        (
                          ( bpu_op_i == `BPU_OP_BEQ  && equal               ) ||
                          ( bpu_op_i == `BPU_OP_BNE  && !equal              ) ||
                          ( bpu_op_i == `BPU_OP_BLT  && signed_less_than    ) ||
                          ( bpu_op_i == `BPU_OP_BGE  && !signed_less_than   ) ||
                          ( bpu_op_i == `BPU_OP_BLTU && unsigned_less_than  ) ||
                          ( bpu_op_i == `BPU_OP_BGEU && !unsigned_less_than ) ||
                          ( bpu_op_i == `BPU_OP_JAL                         ) ||
                          ( bpu_op_i == `BPU_OP_JALR                        )
                        );

  assign  dnpc_o      = ( rst == `RST_ENABLE ) ? 32'h8000_0000 : 
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_BEQ  )) ? pc_i     + imm_i :  
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_BNE  )) ? pc_i     + imm_i :  
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_BLT  )) ? pc_i     + imm_i :  
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_BGE  )) ? pc_i     + imm_i :  
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_BLTU )) ? pc_i     + imm_i :  
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_BGEU )) ? pc_i     + imm_i :  
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_JAL  )) ? pc_i     + imm_i :
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_JALR )) ? rdata1_i + imm_i :
                                                                            pc_i     + 32'h4 ;

endmodule
