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

  wire cout;
  wire [`REG_DATA_BUS] result;

  assign { cout, result } = {1'b0, operand1_i} + ({1'b0, ~operand2_i}) + 1;

  wire Of = ((operand1_i[31]) & (!operand2_i[31]) & (!result[31])) | ((!operand1_i[31]) & (operand2_i[31]) & (result[31]));
  wire Cf = cout ^ 1'b1;

  wire Sf = result[31];
  wire Zf =  ~(| result);

  /* verilator lint_off UNUSEDSIGNAL */
  wire unsigned_less_than = ( Cf == 1 );
  wire unsigned_greater_equal = ( Cf == 0 );

  wire signed_less_than = ( ( Sf ^ Of ) == 1 );
  wire signed_greater_equal = ( ( Sf ^ Of ) == 0 );

  wire transfer;

  assign transfer = ( rst       == `RST_ENABLE  ) ? ( `TRAN_DISABLE            ) :
                    ( tran_op_i == `TRAN_OP_BEQ ) ? ( Zf                       ) :
                    ( tran_op_i == `TRAN_OP_BNE ) ? ( !Zf                      ) :
                    ( tran_op_i == `TRAN_OP_BLT ) ? ( signed_less_than         ) :
                    ( tran_op_i == `TRAN_OP_BGE ) ? ( signed_greater_equal     ) :
                    ( tran_op_i == `TRAN_OP_BLTU) ? ( unsigned_less_than       ) :
                    ( tran_op_i == `TRAN_OP_BGEU) ? ( $unsigned(operand1_i) >= $unsigned(operand2_i)) :
//                    ( tran_op_i == `TRAN_OP_BGEU) ? ( unsigned_greater_equal   ) :
                    ( tran_op_i == `TRAN_OP_JAL ) ? ( `TRAN_ENABLE             ) :
                    ( tran_op_i == `TRAN_OP_JALR) ? ( `TRAN_ENABLE             ) :
                    ( tran_op_i == `TRAN_OP_MRET ) ? ( `TRAN_ENABLE             ) : 
                    ( tran_op_i == `TRAN_OP_ECALL) ? ( `TRAN_ENABLE             ) : `TRAN_DISABLE;

  assign dnpc_o = ( rst       == `RST_ENABLE   ) ? `RESET_PC           :
                  ( transfer  == `TRAN_DISABLE ) ? pc_i + `INST_LENGTH : 
                  ( tran_op_i == `TRAN_OP_BEQ  ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_BNE  ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_BLT  ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_BGE  ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_BLTU ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_BGEU ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_JAL  ) ? pc_i + imm_i        :
                  ( tran_op_i == `TRAN_OP_JALR ) ? operand1_i  + imm_i :
                  ( tran_op_i == `TRAN_OP_MRET ) ? operand1_i  + `INST_LENGTH : 
                  ( tran_op_i == `TRAN_OP_ECALL) ? operand1_i       : pc_i + `INST_LENGTH;

endmodule
