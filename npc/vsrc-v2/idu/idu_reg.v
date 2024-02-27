`include "defines.v"

module idu_reg (
  input clock,
  input reset,

  input we_i,

  input [`NPC_ADDR_BUS] pc_i,
  input [`NPC_DATA_BUS] inst_i,

  output reg [`NPC_ADDR_BUS] pc_o,
  output reg [`NPC_DATA_BUS] inst_o 
);
    
  always @( posedge clock or negedge reset ) begin
    if ( reset == `RESET_ENABLE ) begin
      pc_o   <= 0;
      inst_o <= 0;
    end else begin
      pc_o   <= pc_o;
      inst_o <= inst_o;
      if ( we_i == `WRITE_ENABLE ) begin
        pc_o   <= pc_i;
        inst_o <= inst_i;
      end else begin
        pc_o   <= pc_o;
        inst_o <= inst_o;
      end
    end
  end

endmodule // idu_reg 
