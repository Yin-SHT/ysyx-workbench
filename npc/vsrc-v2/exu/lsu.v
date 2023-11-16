`include "defines.v"

module lsu (
  input                     clk,
  input                     rst,

  input [`INST_TYPE_BUS]    inst_type_i,
  input [`LSU_OP_BUS]       lsu_op_i,

  input [`REG_DATA_BUS]     imm_i,
  input [`REG_DATA_BUS]     rdata1_i,
  input [`REG_DATA_BUS]     rdata2_i,

  /* ARC: Address Read Channel */
  input                     arvalid_i,
  output                    arready_o,

  /*  RC: Data Read Channel */
  output  [`INST_DATA_BUS]  rresp_o,

  output                    rvalid_o,
  input                     rready_i,

  /* AWC: Address Write Channel */
  input                     awvalid_i,
  output                    awready_o,

  /*  WC: Data Write Channel */
  input                     wvalid_i,
  output                    wready_o,

  /*  BC: Response Write Channel */
  output  [`INST_DATA_BUS]  bresp_o,

  output                    bvalid_o,
  input                     bready_i,

  output  [`INST_DATA_BUS]  mem_result_o
);
  
  wire [`MEM_ADDR_BUS] araddr;
  wire [`MEM_ADDR_BUS] roff;
  wire [`MEM_ADDR_BUS] awaddr;
  wire [`MEM_DATA_BUS] wdata;
  wire [`MEM_MASK_BUS] wstrb;
  wire [`MEM_DATA_BUS] rdata;

  dsram_pre u_dsram_pre(
  	.rst         ( rst         ),

    .inst_type_i ( inst_type_i ),
    .lsu_op_i    ( lsu_op_i    ),
    .imm_i       ( imm_i       ),
    .rdata1_i    ( rdata1_i    ),
    .rdata2_i    ( rdata2_i    ),

    .araddr_o    ( araddr      ),
    .roff_o      ( roff        ),
    .awaddr_o    ( awaddr      ),
    .wdata_o     ( wdata       ),
    .wstrb_o     ( wstrb       )
  );
  
  dsram u_dsram(
  	.clk         ( clk         ),
    .rst         ( rst         ),

    .araddr_i    ( araddr      ),
    .arvalid_i   ( arvalid_i   ),
    .arready_o   ( arready_o   ),

    .rdata_o     ( rdata       ),
    .rresp_o     ( rresp_o     ),
    .rvalid_o    ( rvalid_o    ),
    .rready_i    ( rready_i    ),

    .awaddr_i    ( awaddr      ),
    .awvalid_i   ( awvalid_i   ),
    .awready_o   ( awready_o   ),

    .wdata_i     ( wdata       ),
    .wstrb_i     ( wstrb       ),
    .wvalid_i    ( wvalid_i    ),
    .wready_o    ( wready_o    ),

    .bresp_o     ( bresp_o     ),
    .bvalid_o    ( bvalid_o    ),
    .bready_i    ( bready_i    )
  );
   
  dsram_post u_dsram_post(
  	.rst           ( rst          ),
    .lsu_op_i      ( lsu_op_i     ),
    .roff_i        ( roff         ),
    .rdata_i       ( rdata        ),
    .mem_result_o  ( mem_result_o )
  );
  
endmodule
