`include "defines.v"

module idu_reg (
  input                       clk,
  input                       rst,

  input                       we_i,

  input      [`INST_ADDR_BUS] araddr_i,
  input      [`INST_DATA_BUS] rdata_i,

  output reg [`INST_ADDR_BUS] araddr_o,
  output reg [`INST_DATA_BUS] rdata_o
);
    
  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      araddr_o <= 32'h0000_0000;
      rdata_o  <= 32'h0000_0000;
    end else begin
      araddr_o <= araddr_o;
      rdata_o  <= rdata_o;
      if ( we_i ) begin
        araddr_o <= araddr_i;
        rdata_o  <= rdata_i;
      end else begin
          araddr_o <= araddr_o;
          rdata_o  <= rdata_o;
      end
    end
  end

endmodule // idu_reg 
