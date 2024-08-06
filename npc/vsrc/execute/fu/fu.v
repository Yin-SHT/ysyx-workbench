`include "defines.v"

module fu (
  input                  reset,

  input [`INST_TYPE_BUS] inst_type_i,
  input [`ALU_OP_BUS]    alu_op_i,
  input [`CSR_OP_BUS]    csr_op_i,
  input [`NPC_ADDR_BUS]  pc_i,
  input [`REG_DATA_BUS]  imm_i,
  input [`REG_DATA_BUS]  rdata1_i,
  input [`REG_DATA_BUS]  rdata2_i,
  input [`CSR_DATA_BUS]  csr_rdata_i,

  output [`REG_DATA_BUS] alu_result_o,
  output [`CSR_DATA_BUS] csr_wdata_o
);

  alu alu0 (
  .reset        (reset),

  .inst_type_i  (inst_type_i),
  .alu_op_i     (alu_op_i),
  .pc_i         (pc_i),
  .imm_i        (imm_i),
  .rdata1_i     (rdata1_i),
  .rdata2_i     (rdata2_i),
  .csr_rdata_i  (csr_rdata_i),

  .alu_result_o (alu_result_o)
  );

  csr csr0 (
  .csr_op_i     (csr_op_i),
  .rdata1_i     (rdata1_i),
  .csr_rdata_i  (csr_rdata_i),
  .pc_i         (pc_i),

  .csr_wdata_o  (csr_wdata_o)
  );

endmodule
