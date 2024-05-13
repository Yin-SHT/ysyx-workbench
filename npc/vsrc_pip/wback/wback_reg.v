`include "defines.v"

module wback_reg (
  input             clock,
  input             reset,

  input             we_i,

  input             wsel_i,
  input             wena_i,
  input [4:0]       waddr_i, 
  input [31:0]      alu_result_i,
  input [31:0]      mem_result_i,

  input             csr_wena_i,
  input [31:0]      csr_waddr_i, 
  input [31:0]      csr_wdata_i,

  output reg        wena_o,
  output reg [4:0]  waddr_o, 
  output reg [31:0] wdata_o,

  output reg        csr_wena_o,
  output reg [31:0] csr_waddr_o, 
  output reg [31:0] csr_wdata_o
);

  always @(posedge clock) begin
    if (reset) begin
      wena_o  <= 0;
      waddr_o <= 0;
      wdata_o <= 0;
    end else begin
      if (we_i) begin
        wena_o     <= wena_i;
        waddr_o    <= waddr_i;
        if (wsel_i == `SEL_ALU_DATA) begin
          wdata_o  <= alu_result_i;
        end else begin
          wdata_o  <= mem_result_i;   
        end
        csr_wena_o  <= csr_wena_i;
        csr_waddr_o <= csr_waddr_i;
        csr_wdata_o <= csr_wdata_i;
      end     
    end
  end
    
endmodule 
