`include "defines.v"

module ifu (
  input                    rst,
  input                    clk,

  input                    valid_pre_i,
  output                   ready_pre_o,

  output                   valid_post_o,
  input                    ready_post_i,

  input                    branch_en_i,
  input  [`INST_ADDR_BUS]  dnpc_i,

  output [`INST_ADDR_BUS]  araddr_o,
  output [`INST_DATA_BUS]  rdata_o
);

  wire                   we;
  wire [`INST_ADDR_BUS]  next_pc;
  wire                   arvalid;
  wire                   arready;
  wire [`INST_DATA_BUS]  rresp;
  wire                   rvalid;
  wire                   rready;
  wire                   awvalid;
  wire                   awready;
  wire                   wvalid;
  wire                   wready;
  wire [`INST_DATA_BUS]  bresp;
  wire                   bvalid;
  wire                   bready;

  ifu_fsm u_ifu_fsm(
  	.clk          ( clk          ),
    .rst          ( rst          ),

    .valid_pre_i  ( valid_pre_i  ),
    .ready_pre_o  ( ready_pre_o  ),
    .valid_post_o ( valid_post_o ),
    .ready_post_i ( ready_post_i ),

    .arvalid_o    ( arvalid      ),
    .arready_i    ( arready      ),

    .rresp_i      ( rresp        ),
    .rvalid_i     ( rvalid       ),
    .rready_o     ( rready       ),

    .awvalid_o    ( awvalid      ),
    .awready_i    ( awready      ),

    .wvalid_o     ( wvalid       ),
    .wready_i     ( wready       ),

    .bresp_i      ( bresp        ),
    .bvalid_i     ( bvalid       ),
    .bready_o     ( bready       ),

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
  
  isram u_isram(
  	.clk       ( clk       ),
    .rst       ( rst       ),

    .araddr_i  ( araddr_o  ),
    .arvalid_i ( arvalid   ),
    .arready_o ( arready   ),
    
    .rdata_o   ( rdata_o   ),
    .rresp_o   ( rresp     ),
    .rvalid_o  ( rvalid    ),
    .rready_i  ( rready    ),

    .awaddr_i  ( 32'h0     ),
    .awvalid_i ( awvalid   ),
    .awready_o ( awready   ),

    .wdata_i   ( 32'h0     ),
    .wstrb_i   ( 8'h0      ),
    .wvalid_i  ( wvalid    ),
    .wready_o  ( wready    ),

    .bresp_o   ( bresp     ),
    .bvalid_o  ( bvalid    ),
    .bready_i  ( bready    )
  );
    


endmodule
