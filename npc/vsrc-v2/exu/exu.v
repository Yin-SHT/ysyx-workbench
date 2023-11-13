`include "../defines.v"

module exu (
  input                      clk,
  input                      rst,

  input                      valid_pre_i,
  output                     ready_pre_o,

  output                     valid_post_o,
  input                      ready_post_i,

  input  [`INST_TYPE_BUS]    inst_type_i,
  input  [`ALU_OP_BUS]       alu_op_i,
  input  [`LSU_OP_BUS]       lsu_op_i,
  input                      wsel_i,
  input                      wena_i,
  input  [`REG_ADDR_BUS]     waddr_i,

  input  [`INST_ADDR_BUS]    pc_i,
  input  [`REG_DATA_BUS]     imm_i,
  input  [`REG_DATA_BUS]     rdata1_i,
  input  [`REG_DATA_BUS]     rdata2_i,
  
  output                     wsel_o,
  output                     wena_o,
  output [`REG_ADDR_BUS]     waddr_o,
  output [`REG_DATA_BUS]     alu_result_o,
  output [`REG_DATA_BUS]     mem_result_o
);
  
  wire                  arvalid;
  wire                  arready;
  wire [`INST_DATA_BUS] rresp;
  wire                  rready;
  wire                  rvalid;
  wire                  we;

  exu_fsm u_exu_fsm(
  	.clk          ( clk          ),
    .rst          ( rst          ),
    .inst_type_i  ( inst_type_i  ),
    .valid_pre_i  ( valid_pre_i  ),
    .ready_pre_o  ( ready_pre_o  ),
    .valid_post_o ( valid_post_o ),
    .ready_post_i ( ready_post_i ),
    .arvalid_o    ( arvalid      ),
    .arready_i    ( arready      ),
    .rvalid_i     ( rvalid       ),
    .rresp_i      ( rresp        ),
    .rready_o     ( rready       ),
    .we_o         ( we           )
  );
  

  wire [`INST_TYPE_BUS]   inst_type;
  wire [`ALU_OP_BUS]      alu_op;
  wire [`LSU_OP_BUS]      lsu_op;
  wire [`INST_ADDR_BUS]   pc;
  wire [`REG_DATA_BUS]    imm;
  wire [`REG_DATA_BUS]    rdata1;
  wire [`REG_DATA_BUS]    rdata2;
  
  exu_reg u_exu_reg(
  	.clk          ( clk          ),
    .rst          ( rst          ),
    .we_i         ( we           ),
    .inst_type_i  ( inst_type_i  ),
    .alu_op_i     ( alu_op_i     ),
    .lsu_op_i     ( lsu_op_i     ),
    .wsel_i       ( wsel_i       ),
    .wena_i       ( wena_i       ),
    .waddr_i      ( waddr_i      ),
    .pc_i         ( pc_i         ),
    .imm_i        ( imm_i        ),
    .rdata1_i     ( rdata1_i     ),
    .rdata2_i     ( rdata2_i     ),
    .inst_type_o  ( inst_type    ),
    .alu_op_o     ( alu_op       ),
    .lsu_op_o     ( lsu_op       ),
    .wsel_o       ( wsel_o       ),
    .wena_o       ( wena_o       ),
    .waddr_o      ( waddr_o      ),
    .pc_o         ( pc           ),
    .imm_o        ( imm          ),
    .rdata1_o     ( rdata1       ),
    .rdata2_o     ( rdata2       )
  );
  

  fu u_fu(
  	.rst          ( rst          ),
    .inst_type_i  ( inst_type    ),
    .alu_op_i     ( alu_op       ),
    .pc_i         ( pc           ),
    .imm_i        ( imm          ),
    .rdata1_i     ( rdata1       ),
    .rdata2_i     ( rdata2       ),
    .alu_result_o ( alu_result_o )
  );
  

  lsu u_lsu(
  	.clk          ( clk          ),
    .rst          ( rst          ),
    .inst_type_i  ( inst_type    ),
    .lsu_op_i     ( lsu_op       ),
    .imm_i        ( imm          ),
    .rdata1_i     ( rdata1       ),
    .rdata2_i     ( rdata2       ),
    .arvalid_i    ( arvalid      ),
    .arready_o    ( arready      ),
    .rresp_o      ( rresp        ),
    .rready_i     ( rready       ),
    .rvalid_o     ( rvalid       ),
    .mem_data_o   ( mem_result_o )
  );

endmodule
