`include "defines.v"

module top (
  input   clk,
  input   rst
);

  /* AR: Address Read Channel */
  wire [`INST_ADDR_BUS]  araddr;
  wire                   arvalid;
  wire                   arready;

  /*  R: Data Read Channel */
  wire [`MEM_DATA_BUS]   rdata;
  wire [`RRESP_DATA_BUS] rresp;
  wire                   rvalid;
  wire                   rready;

  /* AW: Address Write Channel */
  wire [`INST_ADDR_BUS]  awaddr;
  wire                   awvalid;
  wire                   awready;

  /*  W: Data Write Channel */
  wire [`MEM_DATA_BUS]   wdata;
  wire [`WSTRB_DATA_BUS] wstrb;
  wire                   wvalid;
  wire                   wready;

  /*  B: Response Write Channel */
  wire [`BRESP_DATA_BUS] bresp;
  wire                   bvalid;
  wire                   bready;

  cpu u_cpu(
  	.clk       ( clk       ),
    .rst       ( rst       ),
    .araddr_o  ( araddr    ),
    .arvalid_o ( arvalid   ),
    .arready_i ( arready   ),
    .rdata_i   ( rdata     ),
    .rresp_i   ( rresp     ),
    .rvalid_i  ( rvalid    ),
    .rready_o  ( rready    ),
    .awaddr_o  ( awaddr    ),
    .awvalid_o ( awvalid   ),
    .awready_i ( awready   ),
    .wdata_o   ( wdata     ),
    .wstrb_o   ( wstrb     ),
    .wvalid_o  ( wvalid    ),
    .wready_i  ( wready    ),
    .bresp_i   ( bresp     ),
    .bvalid_i  ( bvalid    ),
    .bready_o  ( bready    )
  );
  
  sram u_sram(
  	.clk       ( clk       ),
    .rst       ( rst       ),
    .araddr_i  ( araddr    ),
    .arvalid_i ( arvalid   ),
    .arready_o ( arready   ),
    .rdata_o   ( rdata     ),
    .rresp_o   ( rresp     ),
    .rvalid_o  ( rvalid    ),
    .rready_i  ( rready    ),
    .awaddr_i  ( awaddr    ),
    .awvalid_i ( awvalid   ),
    .awready_o ( awready   ),
    .wdata_i   ( wdata     ),
    .wstrb_i   ( wstrb     ),
    .wvalid_i  ( wvalid    ),
    .wready_o  ( wready    ),
    .bresp_o   ( bresp     ),
    .bvalid_o  ( bvalid    ),
    .bready_i  ( bready    )
  );
  

endmodule
