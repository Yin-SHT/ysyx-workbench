`include "defines.v"

module regfile(
  input         clock,
  input         reset,

	input   		  wena_i,
	input  [4:0]  waddr_i,
	input  [31:0] wdata_i,
	
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

  reg[31:0] regs[31:0];

  always @(posedge clock) begin
    if(reset) begin
      for(integer i = 0; i < 32; i = i + 1 ) begin
        regs[i] <= 0;
      end
    end else begin
      if(wena_i && (waddr_i != 0)) begin
        regs[waddr_i] <= wdata_i;
      end
    end
  end

  assign rdata1_o = rena1_i ? regs[raddr1_i] : 0;
  assign rdata2_o = rena2_i ? regs[raddr2_i] : 0;

endmodule
