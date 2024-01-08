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

  /** SRAM */
  wire [`INST_ADDR_BUS]  sram_araddr;
  wire                   sram_arvalid;
  wire                   sram_arready;
  wire [`INST_DATA_BUS]  sram_rdata;
  wire [`RRESP_DATA_BUS] sram_rresp;
  wire                   sram_rvalid;
  wire                   sram_rready;
  wire [`MEM_ADDR_BUS]   sram_awaddr;
  wire                   sram_awvalid;
  wire                   sram_awready;
  wire [`MEM_DATA_BUS]   sram_wdata;
  wire [7:0]             sram_wstrb;
  wire                   sram_wvalid;
  wire                   sram_wready;
  wire [`BRESP_DATA_BUS] sram_bresp;
  wire                   sram_bvalid;
  wire                   sram_bready;

  /** UART */
  wire [`INST_ADDR_BUS]  uart_araddr;
  wire                   uart_arvalid;
  wire                   uart_arready;
  wire [`INST_DATA_BUS]  uart_rdata;
  wire [`RRESP_DATA_BUS] uart_rresp;
  wire                   uart_rvalid;
  wire                   uart_rready;
  wire [`MEM_ADDR_BUS]   uart_awaddr;
  wire                   uart_awvalid;
  wire                   uart_awready;
  wire [`MEM_DATA_BUS]   uart_wdata;
  wire [7:0]             uart_wstrb;
  wire                   uart_wvalid;
  wire                   uart_wready;
  wire [`BRESP_DATA_BUS] uart_bresp;
  wire                   uart_bvalid;
  wire                   uart_bready;

  /** CLINT */
  wire [`INST_ADDR_BUS]  clint_araddr;
  wire                   clint_arvalid;
  wire                   clint_arready;
  wire [`INST_DATA_BUS]  clint_rdata;
  wire [`RRESP_DATA_BUS] clint_rresp;
  wire                   clint_rvalid;
  wire                   clint_rready;
  wire [`MEM_ADDR_BUS]   clint_awaddr;
  wire                   clint_awvalid;
  wire                   clint_awready;
  wire [`MEM_DATA_BUS]   clint_wdata;
  wire [7:0]             clint_wstrb;
  wire                   clint_wvalid;
  wire                   clint_wready;
  wire [`BRESP_DATA_BUS] clint_bresp;
  wire                   clint_bvalid;
  wire                   clint_bready;

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
  
  xbar u_xbar(
  	.clk             ( clk             ),
    .rst             ( rst             ),
    .cpu_araddr_i    ( araddr          ),
    .cpu_arvalid_i   ( arvalid         ),
    .cpu_arready_o   ( arready         ),
    .cpu_rdata_o     ( rdata           ),
    .cpu_rresp_o     ( rresp           ),
    .cpu_rvalid_o    ( rvalid          ),
    .cpu_rready_i    ( rready          ),
    .cpu_awaddr_i    ( awaddr          ),
    .cpu_awvalid_i   ( awvalid         ),
    .cpu_awready_o   ( awready         ),
    .cpu_wdata_i     ( wdata           ),
    .cpu_wstrb_i     ( wstrb           ),
    .cpu_wvalid_i    ( wvalid          ),
    .cpu_wready_o    ( wready          ),
    .cpu_bresp_o     ( bresp           ),
    .cpu_bvalid_o    ( bvalid          ),
    .cpu_bready_i    ( bready          ),
    .sram_araddr_o   ( sram_araddr     ),
    .sram_arvalid_o  ( sram_arvalid    ),
    .sram_arready_i  ( sram_arready    ),
    .sram_rdata_i    ( sram_rdata      ),
    .sram_rresp_i    ( sram_rresp      ),
    .sram_rvalid_i   ( sram_rvalid     ),
    .sram_rready_o   ( sram_rready     ),
    .sram_awaddr_o   ( sram_awaddr     ),
    .sram_awvalid_o  ( sram_awvalid    ),
    .sram_awready_i  ( sram_awready    ),
    .sram_wdata_o    ( sram_wdata      ),
    .sram_wstrb_o    ( sram_wstrb      ),
    .sram_wvalid_o   ( sram_wvalid     ),
    .sram_wready_i   ( sram_wready     ),
    .sram_bresp_i    ( sram_bresp      ),
    .sram_bvalid_i   ( sram_bvalid     ),
    .sram_bready_o   ( sram_bready     ),
    .uart_araddr_o   ( uart_araddr     ),
    .uart_arvalid_o  ( uart_arvalid    ),
    .uart_arready_i  ( uart_arready    ),
    .uart_rdata_i    ( uart_rdata      ),
    .uart_rresp_i    ( uart_rresp      ),
    .uart_rvalid_i   ( uart_rvalid     ),
    .uart_rready_o   ( uart_rready     ),
    .uart_awaddr_o   ( uart_awaddr     ),
    .uart_awvalid_o  ( uart_awvalid    ),
    .uart_awready_i  ( uart_awready    ),
    .uart_wdata_o    ( uart_wdata      ),
    .uart_wstrb_o    ( uart_wstrb      ),
    .uart_wvalid_o   ( uart_wvalid     ),
    .uart_wready_i   ( uart_wready     ),
    .uart_bresp_i    ( uart_bresp      ),
    .uart_bvalid_i   ( uart_bvalid     ),
    .uart_bready_o   ( uart_bready     ),
    .clint_araddr_o  ( clint_araddr    ),
    .clint_arvalid_o ( clint_arvalid   ),
    .clint_arready_i ( clint_arready   ),
    .clint_rdata_i   ( clint_rdata     ),
    .clint_rresp_i   ( clint_rresp     ),
    .clint_rvalid_i  ( clint_rvalid    ),
    .clint_rready_o  ( clint_rready    ),
    .clint_awaddr_o  ( clint_awaddr    ),
    .clint_awvalid_o ( clint_awvalid   ),
    .clint_awready_i ( clint_awready   ),
    .clint_wdata_o   ( clint_wdata     ),
    .clint_wstrb_o   ( clint_wstrb     ),
    .clint_wvalid_o  ( clint_wvalid    ),
    .clint_wready_i  ( clint_wready    ),
    .clint_bresp_i   ( clint_bresp     ),
    .clint_bvalid_i  ( clint_bvalid    ),
    .clint_bready_o  ( clint_bready    )
  );

  sram u_sram(
  	.clk       ( clk            ),
    .rst       ( rst            ),
    .araddr_i  ( sram_araddr    ),
    .arvalid_i ( sram_arvalid   ),
    .arready_o ( sram_arready   ),
    .rdata_o   ( sram_rdata     ),
    .rresp_o   ( sram_rresp     ),
    .rvalid_o  ( sram_rvalid    ),
    .rready_i  ( sram_rready    ),
    .awaddr_i  ( sram_awaddr    ),
    .awvalid_i ( sram_awvalid   ),
    .awready_o ( sram_awready   ),
    .wdata_i   ( sram_wdata     ),
    .wstrb_i   ( sram_wstrb     ),
    .wvalid_i  ( sram_wvalid    ),
    .wready_o  ( sram_wready    ),
    .bresp_o   ( sram_bresp     ),
    .bvalid_o  ( sram_bvalid    ),
    .bready_i  ( sram_bready    )
  );
  
  uart u_uart(
  	.clk       ( clk            ),
    .rst       ( rst            ),
    .araddr_i  ( uart_araddr    ),
    .arvalid_i ( uart_arvalid   ),
    .arready_o ( uart_arready   ),
    .rdata_o   ( uart_rdata     ),
    .rresp_o   ( uart_rresp     ),
    .rvalid_o  ( uart_rvalid    ),
    .rready_i  ( uart_rready    ),
    .awaddr_i  ( uart_awaddr    ),
    .awvalid_i ( uart_awvalid   ),
    .awready_o ( uart_awready   ),
    .wdata_i   ( uart_wdata     ),
    .wstrb_i   ( uart_wstrb     ),
    .wvalid_i  ( uart_wvalid    ),
    .wready_o  ( uart_wready    ),
    .bresp_o   ( uart_bresp     ),
    .bvalid_o  ( uart_bvalid    ),
    .bready_i  ( uart_bready    )
  );

  clint u_clint(
  	.clk       ( clk            ),
    .rst       ( rst            ),
    .araddr_i  ( clint_araddr    ),
    .arvalid_i ( clint_arvalid   ),
    .arready_o ( clint_arready   ),
    .rdata_o   ( clint_rdata     ),
    .rresp_o   ( clint_rresp     ),
    .rvalid_o  ( clint_rvalid    ),
    .rready_i  ( clint_rready    ),
    .awaddr_i  ( clint_awaddr    ),
    .awvalid_i ( clint_awvalid   ),
    .awready_o ( clint_awready   ),
    .wdata_i   ( clint_wdata     ),
    .wstrb_i   ( clint_wstrb     ),
    .wvalid_i  ( clint_wvalid    ),
    .wready_o  ( clint_wready    ),
    .bresp_o   ( clint_bresp     ),
    .bvalid_o  ( clint_bvalid    ),
    .bready_i  ( clint_bready    )
  );

endmodule
