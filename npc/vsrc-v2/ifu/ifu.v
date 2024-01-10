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

  wire                   we;
  wire [`INST_ADDR_BUS]  next_pc;

  assign awvalid_o  = 0;
  assign awaddr_o   = 0;
  assign awid_o     = 0;
  assign awlen_o    = 0;
  assign awsize_o   = 0;
  assign awburst_o  = 0;
  assign wvalid_o   = 0;
  assign wdata_o    = 0;
  assign wstrb_o    = 0;
  assign wlast_o    = 0;
  assign bready_o   = 0;

  assign arsize_o = 3'b010; // 4 bytes per transfer
  assign rdata_o  = rdata_i[31:0];

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
  
  ifu_fsm u_ifu_fsm(
  	.clk          ( clk          ),
    .rst          ( rst          ),

    .valid_pre_i  ( valid_pre_i  ),
    .ready_pre_o  ( ready_pre_o  ),
    .valid_post_o ( valid_post_o ),
    .ready_post_i ( ready_post_i ),

    // AXI4 interface
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
  

endmodule
