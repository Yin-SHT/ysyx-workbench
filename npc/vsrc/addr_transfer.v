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

  wire [32:0] Result = {operand1_i[31], operand1_i} + (~{operand2_i[31], operand2_i}) + 1;

  wire Zf =  ~(| Result);
  wire Of = Result[32] ^ Result[31];
  wire Sf = Result[31];
  wire Cf = Result[32] ^ 1;

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
                    ( tran_op_i == `TRAN_OP_BGEU) ? ( unsigned_greater_equal   ) :
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
