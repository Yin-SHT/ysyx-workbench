`include "defines.v"

module fetch_reg (
  input         clock,
  input         reset,

  input         firing,
  input         pc_we_i,       
  input         inst_we_i,       

  input         branch_en_i, 
  input  [31:0] dnpc_i,

  output [31:0] pc_o,
  output [31:0] inst_o,

  input  [31:0] rdata_i
);

  export "DPI-C" function fetchreg_event;
  function fetchreg_event;
    output int _pc;
    _pc = pc;
  endfunction

  reg [31:0] pc;
  reg [31:0] inst;

  assign pc_o = pc;
  assign inst_o = inst;

  always @(posedge clock) begin
    if (reset) begin
      pc <= 0;
    end else if (pc_we_i) begin
      if (firing) begin
        pc <= `RESET_VECTOR;
      end else if (branch_en_i) begin
        pc <= dnpc_i;
      end else begin
        pc <= pc + 4;
      end
    end 
  end

  always @(posedge clock) begin
    if (reset) begin
      inst <= 0;
    end else if (inst_we_i) begin
      inst <= rdata_i;
    end 
  end

endmodule 
