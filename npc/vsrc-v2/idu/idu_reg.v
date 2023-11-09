`include "../defines.v"

module idu_reg (
  input clk,
  input rst,

  input we,

  input [`INST_ADDR_BUS] raddr_i,
  input [`INST_DATA_BUS] rdata_i,

  output reg [`INST_ADDR_BUS] raddr_o,
  output reg [`INST_DATA_BUS] rdata_o
);
    
  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      raddr_o <= 32'h0000_0000;
      rdata_o <= 32'h0000_0000;
    end else begin
      if ( we ) begin
        raddr_o <= raddr_i;
        rdata_o <= rdata_i;
      end else begin
          raddr_o <= raddr_o;
          rdata_o <= rdata_o;
      end
    end
  end

endmodule // idu_reg 
