`include "defines.v"

module fetch_reg (
  input             clock,
  input             reset,

  input             firing,
  input             pc_we_i,       
  input             inst_we_i,       

  input             branch_en_i, 
  input  [31:0]     dnpc_i,

  output reg [31:0] pc_o,
  output reg [31:0] inst_o,

  input [31:0]      rdata_i
);

  export "DPI-C" function fetchreg_event;
  function fetchreg_event;
    output int pc;
    pc = pc_o;
  endfunction

  always @(posedge clock) begin
    if (reset) begin
      pc_o <= 0;
    end else if (branch_en_i) begin
        pc_o <= dnpc_i;
    end else if (pc_we_i | firing) begin
      if (firing) begin
        pc_o <= `RESET_VECTOR;
      end else begin
        pc_o <= pc_o + 4;
      end
    end 
  end

  always @(posedge clock) begin
    if (reset) begin
      inst_o <= `NPC_ZERO_DATA;
    end else if (inst_we_i) begin
      inst_o <= rdata_i;
    end 
  end

endmodule 
