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

  /* AW: Address Write Channel */
  input                      awready_i,
  output                     awvalid_o,
  output [31:0]              awaddr_o,
  output [3:0]               awid_o,
  output [7:0]               awlen_o,
  output [2:0]               awsize_o,
  output [1:0]               awburst_o,

  /*  W: Data Write Channel */
  input                      wready_i,
  output                     wvalid_o,
  output [63:0]              wdata_o,
  output [7:0]               wstrb_o,
  output                     wlast_o,

  /*  B: Response Write Channel */
  output                     bready_o,
  input                      bvalid_i,
  input  [1:0]               bresp_i,
  input  [3:0]               bid_i,

  /* AR: Address Read Channel */
  input                      arready_i,
  output                     arvalid_o,
  output [31:0]              araddr_o,
  output [3:0]               arid_o,
  output [7:0]               arlen_o,
  output [2:0]               arsize_o,
  output [1:0]               arburst_o,

  /*  R: Data Read Channel */
  output                     rready_o,
  input                      rvalid_i,
  input  [1:0]               rresp_i,
  input  [63:0]              rdata_i,
  input                      rlast_i,
  input  [3:0]               rid_i
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
  
  exu_reg u_exu_reg (
  	.clk          ( clk          ),
    .rst          ( rst          ),

    // from fsm
    .we_i         ( we           ),

    // from idu
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

    // to internal modules
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
  
  exu_fsm u_exu_fsm(
  	.clk          ( clk          ),
    .rst          ( rst          ),

    .valid_pre_i  ( valid_pre_i  ),
    .ready_pre_o  ( ready_pre_o  ),
    .valid_post_o ( valid_post_o ),
    .ready_post_i ( ready_post_i ),

    // form exu-regs
    .inst_type_i  ( inst_type    ),

    // AXI4 interface
    .awready_i    ( awready_i    ),
    .awvalid_o    ( awvalid_o    ),
    .awid_o       ( awid_o       ),
    .awlen_o      ( awlen_o      ),
    .awburst_o    ( awburst_o    ),

    .wready_i     ( wready_i     ),
    .wvalid_o     ( wvalid_o     ),
    .wlast_o      ( wlast_o      ),

    .bready_o     ( bready_o     ),
    .bvalid_i     ( bvalid_i     ),
    .bresp_i      ( bresp_i      ),
    .bid_i        ( bid_i        ),

    .arready_i    ( arready_i    ),
    .arvalid_o    ( arvalid_o    ),
    .arid_o       ( arid_o       ),
    .arlen_o      ( arlen_o      ),
    .arburst_o    ( arburst_o    ),

    .rready_o     ( rready_o     ),
    .rvalid_i     ( rvalid_i     ),
    .rresp_i      ( rresp_i      ),
    .rlast_i      ( rlast_i      ),
    .rid_i        ( rid_i        ),

    .we_o         ( we           )
  );
  
  fu u_fu (
  	.rst          ( rst          ),

    // from exu-regs
    .inst_type_i  ( inst_type    ),
    .alu_op_i     ( alu_op       ),
    .pc_i         ( pc           ),
    .imm_i        ( imm          ),
    .rdata1_i     ( rdata1       ),
    .rdata2_i     ( rdata2       ),
    .csr_i        ( csr          ),

    // to wbu-regs
    .alu_result_o ( alu_result_o )
  );
  
  lsu u_lsu(
  	.rst          ( rst          ),
    
    // form exu-regs
    .inst_type_i  ( inst_type    ),
    .lsu_op_i     ( lsu_op       ),
    .imm_i        ( imm          ),
    .rdata1_i     ( rdata1       ),
    .rdata2_i     ( rdata2       ),
    
    // to wbu-regs
    .mem_result_o ( mem_result_o ),

    // AXI4 interface
    .awaddr_o     ( awaddr_o     ),
    .awsize_o     ( awsize_o     ),
    .wdata_o      ( wdata_o      ),
    .wstrb_o      ( wstrb_o      ),
    .araddr_o     ( araddr_o     ),
    .arsize_o     ( arsize_o     ),
    .rdata_i      ( rdata_i      )
  );
   

endmodule
