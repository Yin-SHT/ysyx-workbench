`include "defines.v"

module write_back (
  input                  rst,

  // Signal From Inst_Decode
  input                  wsel_i,

  // Signal From Execute
  input [`REG_DATA_BUS]  alu_result_i,

  // Signal From Data_Expan
  input [`MEM_DATA_BUS]  mem_data_i,

  // Signal To Regfile
  output [`REG_DATA_BUS] wdata_o
);
  
  assign wdata_o = ( rst == `RST_ENABLE  ) ? `ZERO_WORD   :
                   ( wsel_i == `ALU_DATA ) ? alu_result_i :
                   ( wsel_i == `MEM_DATA ) ? mem_data_i   : `ZERO_WORD;

endmodule
