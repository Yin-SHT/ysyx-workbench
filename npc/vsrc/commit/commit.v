`include "defines.v"

module commit (
  input         clock,
  input         reset,

  input         valid_pre_i,
  output        ready_pre_o,

  output        commit_valid_o,
  output        commit_csr_o,

  input  [31:0] pc_i,
  input  [31:0] inst_i,
  input         wsel_i,
  input         wena_i,
  input  [4:0]  waddr_i, 
  input  [31:0] alu_result_i,
  input  [31:0] mem_result_i,

  input  [7:0]  csr_op_i,
  input         csr_wena_i,
  input  [31:0] csr_waddr_i, 
  input  [31:0] csr_wdata_i,

  output        wena_o,
  output [4:0]  waddr_o, 
  output [31:0] wdata_o,

  output [7:0]  csr_op_o,
  output        csr_wena_o,
  output [31:0] csr_waddr_o, 
  output [31:0] csr_wdata_o
);

  wire we;
  wire is_csr;

  commit_controller controller (
  	.clock          (clock),
    .reset          (reset),

    .valid_pre_i    (valid_pre_i),
    .ready_pre_o    (ready_pre_o),

    .is_csr_i       (is_csr),

    .commit_valid_o (commit_valid_o),
    .commit_csr_o   (commit_csr_o),

    .we_o           (we)
  );
  
  commit_reg reg0 (
    .clock        (clock),           
    .reset        (reset),           
                     
    .we_i         (we),          
                     
    .pc_i         (pc_i),
    .inst_i       (inst_i),
    .wsel_i       (wsel_i),            
    .wena_i       (wena_i),            
    .waddr_i      (waddr_i),              
    .alu_result_i (alu_result_i),                  
    .mem_result_i (mem_result_i),                  
                     
    .csr_op_i     (csr_op_i),
    .csr_wena_i   (csr_wena_i),                
    .csr_waddr_i  (csr_waddr_i),
    .csr_wdata_i  (csr_wdata_i),                 
                     
    .wena_o       (wena_o),            
    .waddr_o      (waddr_o),              
    .wdata_o      (wdata_o),             

    .is_csr_o     (is_csr),               
    .csr_op_o     (csr_op_o),
    .csr_wena_o   (csr_wena_o),                
    .csr_waddr_o  (csr_waddr_o),
    .csr_wdata_o  (csr_wdata_o)                 
  );

endmodule
