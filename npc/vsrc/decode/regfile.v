`include "defines.v"

module regfile(
  input         clock,
  input         reset,

  output        raw_o,
  input [1:0]   state_i,

  input         commit_valid_i,
	input   		  commit_wena_i,
	input  [4:0]  commit_waddr_i,
	input  [31:0] commit_wdata_i,
	
  input         decode_valid_post,
  input         decode_ready_post,
	input   		  decode_wena_i,
	input  [4:0]  decode_waddr_i,

  output        fetch_raw_o,
  input  [2:0]  fetch_state_i,
	input   		  fetch_rena1_i,
	input  [4:0]  fetch_raddr1_i,
	output [31:0] fetch_rdata1_o,
	input   		  fetch_rena2_i,
	input  [4:0]  fetch_raddr2_i,
	output [31:0] fetch_rdata2_o,

	input   		  rena1_i,
	input  [4:0]  raddr1_i,
	output [31:0] rdata1_o,
	
	input   		  rena2_i,
	input  [4:0]  raddr2_i,
	output [31:0] rdata2_o
);

  export "DPI-C" function regfile_event;
  function regfile_event;
    output int a0;
    a0 = regs[10];
  endfunction

  /* verilator lint_off MULTIDRIVEN */

  reg[31:0] regs[31:0];
  reg[31:0] Busy;
  wire bypass1, bypass2;
  wire raw1, raw2;
  wire fbypass1, fbypass2;  // fetch bypass for branch instruction
  wire fraw1, fraw2;        // fetch raw for branch instruction

  always @(posedge clock) begin
    if (reset) begin
      Busy <= 0;
    end else if (decode_ready_post && decode_valid_post) begin
      if (decode_wena_i && (decode_waddr_i != 0)) begin
        Busy[decode_waddr_i] <= 1;
      end
    end
  end

  always @(negedge clock) begin
    if (reset) begin
      Busy <= 0;
    end else if (commit_valid_i) begin
      if (commit_wena_i) begin
        Busy[commit_waddr_i] <= 0;
      end
    end
  end

  always @(negedge clock) begin
    if(reset) begin
      for(integer i = 0; i < 32; i = i + 1 ) begin
        regs[i] <= 0;
      end
    end else begin
      if(commit_valid_i && commit_wena_i) begin
        if (commit_waddr_i != 0) begin
          regs[commit_waddr_i] <= commit_wdata_i;
        end
      end
    end
  end

  assign bypass1 = commit_valid_i && commit_wena_i && (commit_waddr_i == raddr1_i) && (commit_waddr_i != 0);
  assign bypass2 = commit_valid_i && commit_wena_i && (commit_waddr_i == raddr2_i) && (commit_waddr_i != 0);

  assign rdata1_o = rena1_i ? (bypass1 ? commit_wdata_i : regs[raddr1_i]) : 0;
  assign rdata2_o = rena2_i ? (bypass2 ? commit_wdata_i : regs[raddr2_i]) : 0;

  assign raw1  = rena1_i && Busy[raddr1_i] && !bypass1 && (state_i == 2'b01);  // 2'b01 == wait_ready
  assign raw2  = rena2_i && Busy[raddr2_i] && !bypass2 && (state_i == 2'b01);  // 2'b01 == wait_ready
  assign raw_o = raw1 || raw2;

  assign fbypass1 = commit_valid_i && commit_wena_i && (commit_waddr_i == fetch_raddr1_i) && (commit_waddr_i != 0);
  assign fbypass2 = commit_valid_i && commit_wena_i && (commit_waddr_i == fetch_raddr2_i) && (commit_waddr_i != 0);

  assign fetch_rdata1_o = fetch_rena1_i ? (fbypass1 ? commit_wdata_i : regs[fetch_raddr1_i]) : 0;
  assign fetch_rdata2_o = fetch_rena2_i ? (fbypass2 ? commit_wdata_i : regs[fetch_raddr2_i]) : 0;

  assign fraw1 = fetch_rena1_i && Busy[fetch_raddr1_i] && !fbypass1;  // 3'b011 == wait_ready
  assign fraw2 = fetch_rena2_i && Busy[fetch_raddr2_i] && !fbypass2;  // 3'b100 == read_end
  assign fetch_raw_o = fraw1 || fraw2;

endmodule
