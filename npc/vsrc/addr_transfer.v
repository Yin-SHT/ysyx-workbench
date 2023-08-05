`include "defines.v"

module addr_transfer (
  input                   rst,

  // Signal From Execute
  input [`INST_ADDR_BUS]  pc_i,
  input [`REG_DATA_BUS]   imm_i,
  input [`REG_DATA_BUS]   operand1_i,
  input [`REG_DATA_BUS]   operand2_i,
  input [`TRAN_OP_BUS]    tran_op_i,

  // Signal To Inst_fetch
  output [`INST_ADDR_BUS] dnpc_o
);

  wire transfer;

  assign transfer = ( rst       == `RST_ENABLE  ) ? ( `TRAN_DISABLE            ) :
                    ( tran_op_i == `TRAN_OP_BEQ ) ? ( operand1_i == operand2_i ) :
                    ( tran_op_i == `TRAN_OP_BNE ) ? ( operand1_i != operand2_i ) :
                    ( tran_op_i == `TRAN_OP_BLT ) ? ( operand1_i <  operand2_i ) :
                    ( tran_op_i == `TRAN_OP_BGE ) ? ( operand1_i >= operand2_i ) :
                    ( tran_op_i == `TRAN_OP_BLTU) ? ( operand1_i <= operand2_i ) :
                    ( tran_op_i == `TRAN_OP_BGEU) ? ( operand1_i >= operand2_i ) :
                    ( tran_op_i == `TRAN_OP_JAL ) ? ( `TRAN_ENABLE             ) :
                    ( tran_op_i == `TRAN_OP_JALR) ? ( `TRAN_ENABLE             ) : `TRAN_DISABLE;

  assign dnpc_o = ( rst       == `RST_ENABLE   ) ? `RESET_PC           :
                  ( transfer  == `TRAN_DISABLE ) ? pc_i + `INST_LENGTH : 
                  ( tran_op_i == `TRAN_OP_BEQ  ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_BNE  ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_BLT  ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_BGE  ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_BLTU ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_BGEU ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_JAL  ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_JALR ) ? operand1_i  + imm_i : pc_i + `INST_LENGTH;

endmodule
