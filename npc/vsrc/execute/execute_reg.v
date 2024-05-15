`include "defines.v"

module execute_reg (
  input                        clock,
  input                        reset,

  input                        we_i,        

  input [`INST_TYPE_BUS]       inst_type_i,
  input [`ALU_OP_BUS]          alu_op_i,
  input [`LSU_OP_BUS]          lsu_op_i,
  input [`CSR_OP_BUS]          csr_op_i,
  input                        wsel_i,
  input                        wena_i,
  input [`REG_ADDR_BUS]        waddr_i,
  input                        csr_wena_i,
  input [31:0]                 csr_waddr_i,
  input [`NPC_ADDR_BUS]        pc_i,
  input [`REG_DATA_BUS]        imm_i,
  input [`REG_DATA_BUS]        rdata1_i,
  input [`REG_DATA_BUS]        rdata2_i,
  input [`CSR_DATA_BUS]        csr_rdata_i,

  output reg [`INST_TYPE_BUS]  inst_type_o,
  output reg [`ALU_OP_BUS]     alu_op_o,
  output reg [`LSU_OP_BUS]     lsu_op_o,
  output reg [`CSR_OP_BUS]     csr_op_o,
  output reg                   wsel_o,
  output reg                   wena_o,
  output reg [`REG_ADDR_BUS]   waddr_o,
  output reg                   csr_wena_o,
  output reg [31:0]            csr_waddr_o,
  output reg [`NPC_ADDR_BUS]   pc_o,
  output reg [`REG_DATA_BUS]   imm_o,
  output reg [`REG_DATA_BUS]   rdata1_o,
  output reg [`REG_DATA_BUS]   rdata2_o,
  output reg [`CSR_DATA_BUS]   csr_rdata_o
);

  always @(posedge clock) begin
    if (reset) begin
      inst_type_o <= 0;               
      alu_op_o    <= 0;            
      lsu_op_o    <= 0;            
      csr_op_o    <= 0;            
      wsel_o      <= 0;          
      wena_o      <= 0;          
      waddr_o     <= 0;           
      csr_wena_o  <= 0;              
      csr_waddr_o <= 0;               
      pc_o        <= 0;        
      imm_o       <= 0;         
      rdata1_o    <= 0;            
      rdata2_o    <= 0;            
      csr_rdata_o <= 0;               
    end else if (we_i) begin
      inst_type_o <= inst_type_i;               
      alu_op_o    <= alu_op_i;            
      lsu_op_o    <= lsu_op_i;            
      csr_op_o    <= csr_op_i;            
      wsel_o      <= wsel_i;          
      wena_o      <= wena_i;          
      waddr_o     <= waddr_i;           
      csr_wena_o  <= csr_wena_i;              
      csr_waddr_o <= csr_waddr_i;
      pc_o        <= pc_i;        
      imm_o       <= imm_i;         
      rdata1_o    <= rdata1_i;            
      rdata2_o    <= rdata2_i;            
      csr_rdata_o <= csr_rdata_i;               
    end
  end

endmodule 
