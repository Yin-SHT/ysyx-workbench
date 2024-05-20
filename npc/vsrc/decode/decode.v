`include "defines.v"

module decode (
  input                       clock,
  input                       reset,

  input                       valid_pre_i,
  output                      ready_pre_o,

  output                      valid_post_o,
  input                       ready_post_i,

  input   [`NPC_ADDR_BUS]     pc_i,
  input   [`NPC_DATA_BUS]     inst_i,

  // decode -> execute
  output  [`INST_TYPE_BUS]    inst_type_o,
  output  [`ALU_OP_BUS]       alu_op_o,
  output  [`LSU_OP_BUS]       lsu_op_o,
  output  [`CSR_OP_BUS]       csr_op_o,

  output                      wsel_o,
  output                      wena_o,
  output  [`REG_ADDR_BUS]     waddr_o,
  output                      csr_wena_o,
  output  [31:0]              csr_waddr_o,

  output  [`NPC_ADDR_BUS]     pc_o,
  output  [`REG_DATA_BUS]     imm_o,
  output  [`REG_DATA_BUS]     rdata1_o,
  output  [`REG_DATA_BUS]     rdata2_o,
  output  [`CSR_DATA_BUS]     csr_rdata_o,
  
  // decode -> fetch
  output                      fencei_o,
  output                      branch_valid_o,
  output                      branch_en_o,
  output  [`NPC_ADDR_BUS]     dnpc_o,

  // commit -> decode
  input                       wena_i,
  input   [`REG_ADDR_BUS]     waddr_i,
  input   [`REG_DATA_BUS]     wdata_i,

  input                       csr_wena_i,
  input   [31:0]              csr_waddr_i,
  input   [31:0]              csr_wdata_i
);

  wire                  fencei;
  wire [`BPU_OP_BUS]    bpu_op;
  wire                  we;
  wire [`NPC_ADDR_BUS]  pc;
  wire [`NPC_DATA_BUS]  inst;
  wire                  rena1;
  wire                  rena2;
  wire [`REG_ADDR_BUS]  raddr1;
  wire [`REG_ADDR_BUS]  raddr2;
  wire                  csr_rena;
  wire [31:0]           csr_raddr;

  assign fencei_o = fencei & valid_post_o && ready_post_i;

  decode_controller controller (
    .clock        (clock),
    .reset        (reset),

    .valid_pre_i  (valid_pre_i),
    .valid_post_o (valid_post_o),
    .ready_post_i (ready_post_i),
    .ready_pre_o  (ready_pre_o),

    .we_o         (we),

    .branch_valid_o (branch_valid_o)
  );

  decode_reg reg0 (
  	.clock        (clock),
    .reset        (reset),
    .we_i         (we),
    .pc_i         (pc_i),
    .inst_i       (inst_i),
    .pc_o         (pc),
    .inst_o       (inst)
  );
   
  decode_log decode_log0 (
    .pc_i         (pc),
    .inst_i       (inst),

    .inst_type_o  (inst_type_o),
    .alu_op_o     (alu_op_o),
    .lsu_op_o     (lsu_op_o),
    .bpu_op_o     (bpu_op),
    .csr_op_o     (csr_op_o),
    .pc_o         (pc_o),
    .imm_o        (imm_o),

    .wsel_o       (wsel_o),
    .wena_o       (wena_o),
    .waddr_o      (waddr_o),
    .csr_wena_o   (csr_wena_o),
    .csr_waddr_o  (csr_waddr_o),

    .rena1_o      (rena1),
    .rena2_o      (rena2),
    .raddr1_o     (raddr1),
    .raddr2_o     (raddr2),

    .csr_rena_o   (csr_rena),
    .csr_raddr_o  (csr_raddr),

    .fencei_o     (fencei)
  );
  
  branch_log branch_log0 (
    .reset         (reset),                           

    .bpu_op_i      (bpu_op),                     
    .csr_op_i      (csr_op_o),                     

    .pc_i          (pc_o),                   
    .imm_i         (imm_o),                   
    .rdata1_i      (rdata1_o),                     
    .rdata2_i      (rdata2_o),                     
    .csr_rdata_i   (csr_rdata_o),                         

    .branch_en_o   (branch_en_o),                         
    .dnpc_o        (dnpc_o)                   
  );

  regfile regfile0 (
  	.clock        (clock),
    .reset        (reset),

    .wena_i       (wena_i),
    .waddr_i      (waddr_i),
    .wdata_i      (wdata_i),

    .rena1_i      (rena1),
    .raddr1_i     (raddr1),
    .rdata1_o     (rdata1_o),

    .rena2_i      (rena2),
    .raddr2_i     (raddr2),
    .rdata2_o     (rdata2_o)
  );

  csrs csrs0 (
    .clock        (clock),
  	.reset        (reset),

    .csr_rena_i   (csr_rena),
    .csr_raddr_i  (csr_raddr),
    .csr_rdata_o  (csr_rdata_o),

    .csr_wena_i   (csr_wena_i),
    .csr_waddr_i  (csr_waddr_i),
    .csr_wdata_i  (csr_wdata_i)
  );

endmodule
