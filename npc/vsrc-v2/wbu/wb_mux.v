`include "../defines.v"

module wb_mux (
  input   rst,
  
  input   wsel_i,
  input   [`REG_DATA_BUS]   alu_result_i,
  input   [`REG_DATA_BUS]   mem_result_i,

  output  [`REG_DATA_BUS]   wdata_o
);

  assign wdata_o = ( rst    == `RST_ENABLE   ) ? 32'h0000_0000 :
                   ( wsel_i == `SEL_ALU_DATA ) ? alu_result_i  :
                   ( wsel_i == `SEL_LSU_DATA ) ? mem_result_i  : 
                                                 32'h0000_0000 ;

endmodule
