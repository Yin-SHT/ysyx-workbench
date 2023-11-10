`include "defines.v"

module wbu_reg (
  input   clk,
  input   rst,
  input   we,

  input   wen_i,
  input   wsel_i,
  input   [`REG_ADDR_BUS]   waddr_i, 
  input   [`REG_DATA_BUS]   alu_result_i,
  input   [`REG_DATA_BUS]   mem_result_i,

  output  [`REG_DATA_BUS]   wdata_o
);

  reg                 wen;
  reg                 wsel;
  reg [`REG_ADDR_BUS] waddr;
  reg [`REG_DATA_BUS] alu_result;
  reg [`REG_DATA_BUS] mem_result;

  assign wdata_o = ( wsel == 1'b0 ) ? alu_result : mem_result;

  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      wen        <= 1'b0;
      wsel       <= 1'b0;
      waddr      <= 5'b0;
      alu_result <= 32'b0;
      mem_result <= 32'b0;
    end else begin
      wen        <= wen;
      wsel       <= wsel;
      waddr      <= waddr;
      alu_result <= alu_result;
      mem_result <= mem_result;
      if ( we ) begin
        wen        <= wen_i;
        wsel       <= wsel_i;
        waddr      <= waddr_i;
        alu_result <= alu_result_i;
        mem_result <= mem_result_i;
      end else begin
        wen        <= 1'b0;
        wsel       <= 1'b0;
        waddr      <= 5'b0;
        alu_result <= 32'b0;
        mem_result <= 32'b0;
      end     
    end
  end
    
endmodule //wb_reg 
