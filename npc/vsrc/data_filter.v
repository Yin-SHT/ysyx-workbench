`include "defines.v"

module data_filter (
  input rst,

  // Signal From Inst_Decode
  input  [`ALU_OP_BUS]   alu_op_i,
  input  [`REG_DATA_BUS] wmem_data_i,

  // Signal To Data_Mem
  output [`MEM_DATA_BUS] wmem_data_o
);

  assign wmem_data_o = ( rst      == `RST_ENABLE ) ? (                  `ZERO_WORD ) :
                       ( alu_op_i == `ALU_OP_SB  ) ? ( wmem_data_i & 32'h0000_00ff ) :
                       ( alu_op_i == `ALU_OP_SH  ) ? ( wmem_data_i & 32'h0000_ffff ) :
                       ( alu_op_i == `ALU_OP_SW  ) ? ( wmem_data_i & 32'hffff_ffff ) : `ZERO_WORD;

endmodule
