`include "defines.v"

module top (
  input   clk,
  input   rst
);


  wire    valid_pre_wbu_ifu;
  wire    ready_pre_wbu_ifu;
  wire    valid_post_wbu_ifu;
  wire    ready_post_wbu_ifu;
  wire    valid_pre_ifu_idu;
  wire    ready_pre_ifu_idu;
  wire    valid_post_ifu_idu;
  wire    ready_post_ifu_idu;
  wire    valid_pre_idu_exu;
  wire    ready_pre_idu_exu;
  wire    valid_post_idu_exu;
  wire    ready_post_idu_exu;
  wire    valid_pre_exu_wbu;
  wire    ready_pre_exu_wbu;
  wire    valid_post_exu_wbu;
  wire    ready_post_exu_wbu;

  wire                   branch_en;
  wire [`INST_ADDR_BUS]  dnpc;
  wire [`INST_ADDR_BUS]  araddr;
  wire [`INST_DATA_BUS]  rdata;

  ifu u_ifu(
  	.rst          ( rst                ),
    .clk          ( clk                ),
    .branch_en_i  ( branch_en          ),
    .dnpc_i       ( dnpc               ),
    .valid_pre_i  ( valid_pre_wbu_ifu  ),
    .ready_pre_o  ( ready_pre_wbu_ifu  ),
    .valid_post_o ( valid_post_wbu_ifu ),
    .ready_post_i ( ready_post_wbu_ifu ),
    .araddr_o     ( araddr             ),
    .rdata_o      ( rdata              )
  );
  

  idu u_idu(
  	.clk          (clk          ),
    .rst          (rst          ),
    .valid_pre_i  (valid_pre_i  ),
    .ready_pre_o  (ready_pre_o  ),
    .valid_post_o (valid_post_o ),
    .ready_post_i (ready_post_i ),
    .wena_i       (wena_i       ),
    .waddr_i      (waddr_i      ),
    .wdata_i      (wdata_i      ),
    .pc_i         (pc_i         ),
    .inst_i       (inst_i       ),
    .inst_type_o  (inst_type_o  ),
    .alu_op_o     (alu_op_o     ),
    .lsu_op_o     (lsu_op_o     ),
    .wsel_o       (wsel_o       ),
    .wena_o       (wena_o       ),
    .waddr_o      (waddr_o      ),
    .pc_o         (pc_o         ),
    .imm_o        (imm_o        ),
    .rdata1_o     (rdata1_o     ),
    .rdata2_o     (rdata2_o     ),
    .branch_en_o  (branch_en_o  ),
    .dnpc_o       (dnpc_o       )
  );
    

endmodule
