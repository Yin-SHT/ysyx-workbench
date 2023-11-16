`include "defines.v"

module ifu (
  input                      rst,
  input                      clk,

  input                      valid_pre_i,
  output                     ready_pre_o,

  output                     valid_post_o,
  input                      ready_post_i,

  input                      branch_en_i,
  input  [`INST_ADDR_BUS]    dnpc_i,

  output [`MEM_DATA_BUS]     rdata_o,

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

  assign  rdata_o  = rdata_i;
  assign  awaddr_o = 32'h0000_0000;
  assign  wdata_o  = 32'h0000_0000;
  assign  wstrb_o  =  8'b0000_0000;

  wire                   we;
  wire [`INST_ADDR_BUS]  next_pc;

  ifu_fsm u_ifu_fsm(
  	.clk          ( clk          ),
    .rst          ( rst          ),

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

  pc_mux u_pc_mux(
  	.rst          ( rst          ),

    .branch_en_i  ( branch_en_i  ),
    .araddr_i     ( araddr_o     ),
    .dnpc_i       ( dnpc_i       ),
    .next_pc_o    ( next_pc      )
  );
  
  ifu_reg u_ifu_reg(
  	.clk          ( clk          ),
    .rst          ( rst          ),

    .we_i         ( we           ),
    .next_pc_i    ( next_pc      ),

    .araddr_o     ( araddr_o     )
  );
  
endmodule
