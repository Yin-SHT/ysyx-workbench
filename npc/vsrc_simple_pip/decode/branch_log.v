`include "defines.v"

module branch_log (
  input               reset,

  input [`BPU_OP_BUS] bpu_op_i,
  input [`ALU_OP_BUS] csr_op_i,

  input [31:0]        pc_i, 
  input [31:0]        imm_i,
  input [31:0]        rdata1_i,
  input [31:0]        rdata2_i,
  input [31:0]        csr_rdata_i,

  output              branch_en_o,
  output [31:0]       dnpc_o
);

  wire equal, signed_less_than, unsigned_less_than;

  subtract u_substract(
    .rdata1_i             ( rdata1_i           ),
    .rdata2_i             ( rdata2_i           ),
    .equal_o              ( equal              ),
    .signed_less_than_o   ( signed_less_than   ),
    .unsigned_less_than_o ( unsigned_less_than )
  );

  assign  branch_en_o = ( reset == `RESET_ENABLE ) ? `BRANCH_DISABLE : 
                        (
                          (( bpu_op_i == `BPU_OP_BEQ   ) && ( equal                    )) ||
                          (( bpu_op_i == `BPU_OP_BNE   ) && ( !equal                   )) ||
                          (( bpu_op_i == `BPU_OP_BLT   ) && ( signed_less_than         )) ||
                          (( bpu_op_i == `BPU_OP_BGE   ) && ( !signed_less_than        )) ||
                          (( bpu_op_i == `BPU_OP_BLTU  ) && ( unsigned_less_than       )) ||
                          (( bpu_op_i == `BPU_OP_BGEU  ) && ( !unsigned_less_than      )) ||
                          (( bpu_op_i == `BPU_OP_JAL   )                                ) ||
                          (( bpu_op_i == `BPU_OP_JALR  )                                ) || 
                          (( csr_op_i == `CSR_OP_ECALL ) || ( csr_op_i == `CSR_OP_MRET ))
                        );

  assign  dnpc_o      = ( reset == `RESET_ENABLE ) ? `RESET_VECTOR : 
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_BEQ   )) ? pc_i     + imm_i :  
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_BNE   )) ? pc_i     + imm_i :  
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_BLT   )) ? pc_i     + imm_i :  
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_BGE   )) ? pc_i     + imm_i :  
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_BLTU  )) ? pc_i     + imm_i :  
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_BGEU  )) ? pc_i     + imm_i :  
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_JAL   )) ? pc_i     + imm_i :
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_JALR  )) ? rdata1_i + imm_i :
                        (( branch_en_o ) && ( csr_op_i == `CSR_OP_ECALL )) ? csr_rdata_i      :
                        (( branch_en_o ) && ( csr_op_i == `CSR_OP_MRET  )) ? csr_rdata_i      :
                        (( branch_en_o ) && ( bpu_op_i == `BPU_OP_JALR  )) ? rdata1_i + imm_i :
                                                                             pc_i     + 32'h4 ;

endmodule

module subtract (
  input [`REG_DATA_BUS]     rdata1_i,
  input [`REG_DATA_BUS]     rdata2_i,

  output equal_o,
  output signed_less_than_o, 
  output unsigned_less_than_o
);

  wire cout;
  wire [`REG_DATA_BUS] result;
  wire Of, Cf, Sf, Zf; 

  assign { cout, result } = { 1'b0, rdata1_i } + ({ 1'b0, ~rdata2_i }) + 1;
  assign Of = ((  rdata1_i[31] ) & ( !rdata2_i[31] ) & ( !result[31] )) | 
              (( !rdata1_i[31] ) & (  rdata2_i[31] ) & (  result[31] ));
  assign Cf = cout ^ 1'b1;
  assign Sf = result[31];
  assign Zf =  ~(| result);

  assign equal_o              = Zf;
  assign signed_less_than_o   = Sf ^ Of;
  assign unsigned_less_than_o = Cf;
    
endmodule // subtract 
