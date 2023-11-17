`include "defines.v"

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
  input  [`CSR_DATA_BUS]     csr_i,
  
  output                     wsel_o,
  output                     wena_o,
  output [`REG_ADDR_BUS]     waddr_o,
  output [`REG_DATA_BUS]     alu_result_o,
  output [`REG_DATA_BUS]     mem_result_o,

  /* AR: Address Read Channel */
  output [`MEM_ADDR_BUS]     araddr_o,

  output                     arvalid_o,
  input                      arready_i,

  /*  R: Data Read Channel */
  input  [`MEM_DATA_BUS]     rdata_i,
  input  [`INST_DATA_BUS]    rresp_i,

  input                      rvalid_i,
  output                     rready_o,

  /* WR: Address Write Channel */
  output [`MEM_ADDR_BUS]     awaddr_o,

  output                     awvalid_o,
  input                      awready_i,

  /*  W: Data Write Channel */
  output [`MEM_DATA_BUS]     wdata_o,
  output [`MEM_MASK_BUS]     wstrb_o,

  output                     wvalid_o,
  input                      wready_i,

  /*  B: Response Write Channel */
  input  [`INST_DATA_BUS]    bresp_i,

  input                      bvalid_i,
  output                     bready_o
);
  
  wire                    we;
  wire [`INST_TYPE_BUS]   inst_type;
  wire [`ALU_OP_BUS]      alu_op;
  wire [`LSU_OP_BUS]      lsu_op;
  wire [`INST_ADDR_BUS]   pc;
  wire [`REG_DATA_BUS]    imm;
  wire [`REG_DATA_BUS]    rdata1;
  wire [`REG_DATA_BUS]    rdata2;
  wire [`CSR_DATA_BUS]    csr;
  
  exu_fsm u_exu_fsm (
  	.clk          ( clk          ),
    .rst          ( rst          ),

    .inst_type_i  ( inst_type_i  ),

    .valid_pre_i  ( valid_pre_i  ),
    .ready_pre_o  ( ready_pre_o  ),
    .valid_post_o ( valid_post_o ),
    .ready_post_i ( ready_post_i ),

    .arvalid_o    ( arvalid_o    ),
    .arready_i    ( arready_i    ),

    .rresp_i      ( rresp_i      ),
    .rvalid_i     ( rvalid_i     ),
    .rready_o     ( rready_o     ),

    .awvalid_o    ( awvalid_o    ),
    .awready_i    ( awready_i    ),

    .wvalid_o     ( wvalid_o     ),
    .wready_i     ( wready_i     ),

    .bresp_i      ( bresp_i      ),
    .bvalid_i     ( bvalid_i     ),
    .bready_o     ( bready_o     ),

    .we_o         ( we           )
  );
  
  exu_reg u_exu_reg (
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
    .csr_i        ( csr_i        ),

    .inst_type_o  ( inst_type    ),
    .alu_op_o     ( alu_op       ),
    .lsu_op_o     ( lsu_op       ),
    .wsel_o       ( wsel_o       ),
    .wena_o       ( wena_o       ),
    .waddr_o      ( waddr_o      ),
    .pc_o         ( pc           ),
    .imm_o        ( imm          ),
    .rdata1_o     ( rdata1       ),
    .rdata2_o     ( rdata2       ),
    .csr_o        ( csr          )
  );
  
  fu u_fu (
  	.rst          ( rst          ),

    .inst_type_i  ( inst_type    ),
    .alu_op_i     ( alu_op       ),
    .pc_i         ( pc           ),
    .imm_i        ( imm          ),
    .rdata1_i     ( rdata1       ),
    .rdata2_i     ( rdata2       ),
    .csr_i        ( csr          ),

    .alu_result_o ( alu_result_o )
  );
  
  lsu u_lsu(
  	.rst          ( rst          ),

    .inst_type_i  ( inst_type_i  ),
    .lsu_op_i     ( lsu_op       ),
    .imm_i        ( imm_i        ),
    .rdata1_i     ( rdata1_i     ),
    .rdata2_i     ( rdata2_i     ),

    .araddr_o     ( araddr_o     ),
    .awaddr_o     ( awaddr_o     ),
    .wdata_o      ( wdata_o      ),
    .wstrb_o      ( wstrb_o      ),

    .rdata_i      ( rdata_i      ),
    .mem_result_o ( mem_result_o )
  );
   

endmodule
