`include "defines.v"

module ifu (
  input                      reset,
  input                      clock,

  input                      valid_pre_i,
  output                     ready_pre_o,

  output                     valid_post_o,
  input                      ready_post_i,

  input                      branch_en_i,
  input  [`NPC_ADDR_BUS]     dnpc_i,

  output [`NPC_DATA_BUS]     rdata_o,

  // AW: Address Write Channel 
  input                      awready_i,
  output                     awvalid_o,
  output [`AXI4_AWADDR_BUS]  awaddr_o,
  output [`AXI4_AWID_BUS]    awid_o,
  output [`AXI4_AWLEN_BUS]   awlen_o,
  output [`AXI4_AWSIZE_BUS]  awsize_o,
  output [`AXI4_AWBURST_BUS] awburst_o,

  //  W: Data Write Channel 
  input                      wready_i,
  output                     wvalid_o,
  output [`AXI4_WDATA_BUS]   wdata_o,
  output [`AXI4_WSTRB_BUS]   wstrb_o,
  output                     wlast_o,

  //  B: Response Write Channel 
  output                     bready_o,
  input                      bvalid_i,
  input  [`AXI4_BRESP_BUS]   bresp_i,
  input  [`AXI4_BID_BUS]     bid_i,

  // AR: Address Read Channel
  input                      arready_i,
  output                     arvalid_o,
  output [`AXI4_ARADDR_BUS]  araddr_o,
  output [`AXI4_ARID_BUS]    arid_o,
  output [`AXI4_ARLEN_BUS]   arlen_o,
  output [`AXI4_ARSIZE_BUS]  arsize_o,
  output [`AXI4_ARBURST_BUS] arburst_o,

  //  R: Data Read Channel
  output                     rready_o,
  input                      rvalid_i,
  input  [`AXI4_RRESP_BUS]   rresp_i,
  input  [`AXI4_RDATA_BUS]   rdata_i,
  input                      rlast_i,
  input  [`AXI4_RID_BUS]     rid_i
);

  wire pc_we;
  wire rdata_we;
  wire [`NPC_ADDR_BUS] pc;
  wire [`NPC_ADDR_BUS] snpc;
  wire [`NPC_ADDR_BUS] next_pc;
  wire [`NPC_DATA_BUS] rdata;

  assign rdata    = rdata_i[`NPC_DATA_BUS];

  assign araddr_o = pc;

  assign awvalid_o = 0;
  assign awaddr_o  = 0;
  assign awid_o    = 0;
  assign awlen_o   = 0;
  assign awsize_o  = 0;
  assign awburst_o = 0;
  assign wvalid_o  = 0;
  assign wdata_o   = 0;
  assign wstrb_o   = 0;
  assign wlast_o   = 0;
  assign bready_o  = 0;

  ifu_mux u_ifu_mux(
  	.reset       ( reset       ),
    .branch_en_i ( branch_en_i ),
    .dnpc_i      ( dnpc_i      ),
    .snpc_i      ( snpc        ),
    .next_pc_o   ( next_pc     )
  );
  
  ifu_reg u_ifu_reg(
  	.clock      ( clock     ),
    .reset      ( reset     ),
    .pc_we_i    ( pc_we     ),
    .rdata_we_i ( rdata_we  ),
    .rdata_i    ( rdata     ),
    .next_pc_i  ( next_pc   ),
    .snpc_o     ( snpc      ),
    .pc_o       ( pc        ),
    .arid_o     ( arid_o    ),
    .arlen_o    ( arlen_o   ),
    .arsize_o   ( arsize_o  ),
    .arburst_o  ( arburst_o ),
    .rdata_o    ( rdata_o   )
  );
  
  ifu_fsm u_ifu_fsm(
  	.clock        ( clock        ),
    .reset        ( reset        ),
    .valid_pre_i  ( valid_pre_i  ),
    .ready_pre_o  ( ready_pre_o  ),
    .valid_post_o ( valid_post_o ),
    .ready_post_i ( ready_post_i ),
    .pc_we_o      ( pc_we        ),
    .rdata_we_o   ( rdata_we     ),
    .arready_i    ( arready_i    ),
    .arvalid_o    ( arvalid_o    ),
    .rready_o     ( rready_o     ),
    .rvalid_i     ( rvalid_i     ),
    .rresp_i      ( rresp_i      ),
    .rlast_i      ( rlast_i      ),
    .rid_i        ( rid_i        )
  );

  always @( * ) begin
    if ( awready_i && wready_i && bvalid_i 
        && &bresp_i && &bid_i && &rdata_i ) begin
          // do nothing
        end
  end

endmodule
