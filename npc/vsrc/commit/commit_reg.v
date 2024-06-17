`include "defines.v"

module commit_reg (
  input         clock,
  input         reset,

  input         we_i,

  input         wsel_i,
  input         wena_i,
  input [4:0]   waddr_i, 
  input [31:0]  alu_result_i,
  input [31:0]  mem_result_i,
  input         csr_wena_i,
  input [31:0]  csr_waddr_i, 
  input [31:0]  csr_wdata_i,

  output        wena_o,
  output [4:0]  waddr_o, 
  output [31:0] wdata_o,
  output        csr_wena_o,
  output [31:0] csr_waddr_o, 
  output [31:0] csr_wdata_o
);

  reg        wena;
  reg [4:0]  waddr;
  reg [31:0] wdata;
  reg        csr_wena;
  reg [31:0] csr_waddr;
  reg [31:0] csr_wdata;

  assign wena_o      = wena;
  assign waddr_o     = waddr;
  assign wdata_o     = wdata;
  assign csr_wena_o  = csr_wena;
  assign csr_waddr_o = csr_waddr;
  assign csr_wdata_o = csr_wdata;

  always @(posedge clock) begin
    if (reset) begin
      wena      <= 0;
      waddr     <= 0;
      wdata     <= 0;
      csr_wena  <= 0;
      csr_waddr <= 0;
      csr_wdata <= 0;
    end else begin
      if (we_i) begin
        wena     <= wena_i;
        waddr    <= waddr_i;
        if (wsel_i == `SEL_ALU_DATA) begin
          wdata  <= alu_result_i;
        end else begin
          wdata  <= mem_result_i;   
        end
        csr_wena  <= csr_wena_i;
        csr_waddr <= csr_waddr_i;
        csr_wdata <= csr_wdata_i;
      end     
    end
  end
    
endmodule 
