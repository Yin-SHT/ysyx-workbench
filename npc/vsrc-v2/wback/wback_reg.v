`include "defines.v"

module wback_reg (
  input                        clock,
  input                        reset,

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

  always @( posedge clock or negedge reset ) begin
    if ( reset == `RESET_ENABLE ) begin
      wena_o     <= 0;
      waddr_o    <= 0;
      wdata_o    <= 0;
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
