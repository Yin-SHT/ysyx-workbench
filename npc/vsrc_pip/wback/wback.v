`include "defines.v"

module wback (
  input         clock,
  input         reset,

  input         valid_pre_i,
  output        ready_pre_o,

  output        valid_post_o,
  input         ready_post_i,

  input         wsel_i,
  input         wena_i,
  input  [4:0]  waddr_i, 
  input  [31:0] alu_result_i,
  input  [31:0] mem_result_i,

  input         csr_wena_i,
  input  [31:0] csr_waddr_i, 
  input  [31:0] csr_wdata_i,

  output        wena_o,
  output [4:0]  waddr_o, 
  output [31:0] wdata_o,

  output        csr_wena_o,
  output [31:0] csr_waddr_o, 
  output [31:0] csr_wdata_o
);

  wire we;

  wback_controller controller (
  	.clock        (clock),
    .reset        (reset),

    .valid_pre_i  (valid_pre_i),
    .valid_post_o (valid_post_o),
    .ready_post_i (ready_post_i),
    .ready_pre_o  (ready_pre_o),

    .we_o         (we)
  );
  
  wback_reg reg0 (
    .clock        (clock),           
    .reset        (reset),           
                     
    .we_i         (we),          
                     
    .wsel_i       (wsel_i),            
    .wena_i       (wena_i),            
    .waddr_i      (waddr_i),              
    .alu_result_i (alu_result_i),                  
    .mem_result_i (mem_result_i),                  
                     
    .csr_wena_i   (csr_wena_i),                
    .csr_waddr_i  (csr_waddr_i),
    .csr_wdata_i  (csr_wdata_i),                 
                     
    .wena_o       (wena_o),            
    .waddr_o      (waddr_o),              
    .wdata_o      (wdata_o),             
                     
    .csr_wena_o   (csr_wena_o),                
    .csr_waddr_o  (csr_waddr_o),
    .csr_wdata_o  (csr_wdata_o)                 
  );

endmodule
