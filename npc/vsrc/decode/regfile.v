`include "defines.v"

module regfile(
  input         clock,
  input         reset,

  output        raw_o,

  input         commit_valid_i,
	input   		  commit_wena_i,
	input  [4:0]  commit_waddr_i,
	input  [31:0] commit_wdata_i,
	
  input         decode_valid_post,
  input         decode_ready_post,
	input   		  decode_wena_i,
	input  [4:0]  decode_waddr_i,

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

  always @(posedge clock) begin
    if (reset) begin
      Busy <= 0;
    end else if (decode_ready_post && decode_valid_post) begin
      if (decode_wena_i) begin
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

  assign rdata1_o = rena1_i ? regs[raddr1_i] : 0;
  assign rdata2_o = rena2_i ? regs[raddr2_i] : 0;

  assign raw_o = (rena1_i && Busy[raddr1_i]) || (rena2_i && Busy[raddr2_i]);

endmodule
