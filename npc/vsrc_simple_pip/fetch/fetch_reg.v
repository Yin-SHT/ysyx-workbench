`include "defines.v"

module fetch_reg (
  input             clock,
  input             reset,

  input             firing,

  input [2:0]       state_i,
  input             pc_we_i,       
  input             inst_we_i,       

  input             branch_valid_i,
  input             branch_en_i, 
  input [31:0]      dnpc_i,

  input [31:0]      rdata_i,

  output reg [31:0] pc_o,
  output reg [31:0] inst_o
);

  /* Performance Event */
  export "DPI-C" function addr_event;
  function addr_event;
    output int _pc_;
    _pc_ = pc_o;
  endfunction

  always @(posedge clock) begin
    if (reset) begin
      pc_o <= 0;
    end else if (firing) begin
      pc_o <= `RESET_VECTOR;
    end else if (state_i == 3'b100) begin  // wait_branch
      if (branch_valid_i) begin
        if (branch_en_i) 
          pc_o <= dnpc_i;
        else 
          pc_o <= pc_o + 4;
      end
    end else if (state_i == 3'b001) begin  // wait_ready
      if (pc_we_i) begin
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
