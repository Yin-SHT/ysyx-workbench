`include "defines.v"

module decode_reg (
  input clock,
  input reset,

  input we_i,

  input [31:0] pc_i,
  input [31:0] inst_i,

  output reg [31:0] pc_o,
  output reg [31:0] inst_o 
);
    
  always @(posedge clock) begin
    if (reset) begin
      pc_o   <= 0;
      inst_o <= 0;
    end else begin
      if (we_i) begin
        pc_o   <= pc_i;
        inst_o <= inst_i;
      end
    end
  end

endmodule 
