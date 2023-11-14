`include "defines.v"

module wbu_reg (
  input                        clk,
  input                        rst,

  input                        we_i,

  input                        wena_i,
  input                        wsel_i,
  input   [`REG_ADDR_BUS]      waddr_i, 
  input   [`REG_DATA_BUS]      alu_result_i,
  input   [`REG_DATA_BUS]      mem_result_i,

  output  reg                  wena_o,
  output  reg [`REG_ADDR_BUS]  waddr_o, 
  output  reg [`REG_DATA_BUS]  wdata_o
);

  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      wena_o     <= 1'b0;
      waddr_o    <= 5'b0;
      wdata_o    <= 32'h0000_0000;
    end else begin
      wena_o     <= wena_o;
      waddr_o    <= waddr_o;
      wdata_o    <= wdata_o;
      if ( we_i ) begin
        wena_o     <= wena_i;
        waddr_o    <= waddr_i;
        if ( wsel_i == `SEL_ALU_DATA ) begin
          wdata_o  <= alu_result_i;
        end else begin
          wdata_o  <= mem_result_i;   
        end
      end else begin
        wena_o     <= wena_o;
        waddr_o    <= waddr_o;
        wdata_o    <= wdata_o;
      end     
    end
  end
    
endmodule //wb_reg 
