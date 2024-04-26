`include "defines.v"

module fetch (
  input                      reset,
  input                      clock,

  input                      valid_pre_i,
  output                     ready_pre_o,

  output                     valid_post_o,
  input                      ready_post_i,

  input                      branch_en_i,
  input  [`NPC_ADDR_BUS]     dnpc_i,

  output [`NPC_ADDR_BUS]     pc_o,
  output [`NPC_DATA_BUS]     inst_o,

  // AW: Address Write Channel 
  input                      awready_i,     // don't use
  output                     awvalid_o,
  output [`AXI4_AWADDR_BUS]  awaddr_o,
  output [`AXI4_AWID_BUS]    awid_o,
  output [`AXI4_AWLEN_BUS]   awlen_o,
  output [`AXI4_AWSIZE_BUS]  awsize_o,
  output [`AXI4_AWBURST_BUS] awburst_o,

  //  W: Data Write Channel 
  input                      wready_i,      // don't use
  output                     wvalid_o,
  output [`AXI4_WDATA_BUS]   wdata_o,
  output [`AXI4_WSTRB_BUS]   wstrb_o,
  output                     wlast_o,

  //  B: Response Write Channel 
  output                     bready_o,
  input                      bvalid_i,      // don't use 
  input  [`AXI4_BRESP_BUS]   bresp_i,       // don't use
  input  [`AXI4_BID_BUS]     bid_i,         // don't use

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
  wire inst_we;

  // AW: Address Write Channel 
  assign awvalid_o = 0;
  assign awaddr_o  = 0;
  assign awid_o    = 0;
  assign awlen_o   = 0;
  assign awsize_o  = 0;
  assign awburst_o = 0;

  //  W: Data Write Channel 
  assign wvalid_o  = 0;
  assign wdata_o   = 0;
  assign wstrb_o   = 0;
  assign wlast_o   = 0;

  //  B: Response Write Channel 
  assign bready_o  = 0;

  // AR: Address Read Channel
  assign araddr_o  = pc_o;

  reg[127:0] fire;
  wire       firing = (fire == 1);

  always @(posedge clock) begin
    if (reset) begin
      fire <= 0;
    end else begin
      fire <= fire + 1;
    end
  end

  fetch_controller controller (
    .clock        (clock),
    .reset        (reset),

    .valid_pre_i  (valid_pre_i | firing),
    .ready_pre_o  (ready_pre_o),
    .valid_post_o (valid_post_o),
    .ready_post_i (ready_post_i),

    .pc_we_o      (pc_we),
    .inst_we_o    (inst_we),

    // AR,
    .arready_i    (arready_i),
    .arvalid_o    (arvalid_o),

    // R,
    .rready_o     (rready_o),
    .rvalid_i     (rvalid_i),
    .rresp_i      (rresp_i),
    .rlast_i      (rlast_i),
    .rid_i        (rid_i)
  );

  fetch_reg u_reg (
    .clock        (clock),
    .reset        (reset),

    .pc_we_i      (pc_we),
    .inst_we_i    (inst_we),

    .branch_en_i  (branch_en_i),
    .dnpc_i       (dnpc_i),

    .pc_o         (pc_o),
    .inst_o       (inst_o),

    .arid_o       (arid_o), 
    .arlen_o      (arlen_o),   
    .arsize_o     (arsize_o),   
    .arburst_o    (arburst_o),

    .rdata_i      (rdata_i)
  );


endmodule
