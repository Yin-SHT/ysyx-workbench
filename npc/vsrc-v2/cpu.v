`include "defines.v"

module cpu (
  input   clk,
  input   rst,

  /* AR: Address Read Channel */
  output   [`INST_ADDR_BUS]  araddr_o,
  output                     arvalid_o,
  input                      arready_i,

  /*  R: Data Read Channel */
  input    [`MEM_DATA_BUS]   rdata_i,
  input    [`RRESP_DATA_BUS] rresp_i,
  input                      rvalid_i,
  output                     rready_o,

  /* AW: Address Write Channel */
  output   [`INST_ADDR_BUS]  awaddr_o,
  output                     awvalid_o,
  input                      awready_i,

  /*  W: Data Write Channel */
  output   [`MEM_DATA_BUS]   wdata_o,
  output   [`WSTRB_DATA_BUS] wstrb_o,
  output                     wvalid_o,
  input                      wready_i,

  /*  B: Response Write Channel */
  input    [`BRESP_DATA_BUS] bresp_i,
  input                      bvalid_i,
  output                     bready_o
);

  wire  valid_wbu_ifu;
  wire  ready_wbu_ifu;

  wire  valid_ifu_idu;
  wire  ready_ifu_idu;

  wire  valid_idu_exu;
  wire  ready_idu_exu;

  wire  valid_exu_wbu;
  wire  ready_exu_wbu;

  /* BPU & IFU */
  wire                      branch_en;
  wire [`INST_ADDR_BUS]     dnpc;

  /* IFU & IDU */     
  wire [`INST_DATA_BUS]     rdata;

  /* WBU & IDU */
  wire                      wena;
  wire  [`REG_ADDR_BUS]     waddr;
  wire  [`REG_DATA_BUS]     wdata;

  /* IDU & EXU */
  wire  [`INST_TYPE_BUS]    inst_type;
  wire  [`ALU_OP_BUS]       alu_op;
  wire  [`LSU_OP_BUS]       lsu_op;
  wire                      wsel_idu_exu;
  wire                      wena_idu_exu;
  wire  [`REG_ADDR_BUS]     waddr_idu_exu;
  wire  [`INST_ADDR_BUS]    pc;
  wire  [`REG_DATA_BUS]     imm;
  wire  [`REG_DATA_BUS]     rdata1;
  wire  [`REG_DATA_BUS]     rdata2;

  /* EXU & WBU */
  wire                      wsel_exu_wbu;
  wire                      wena_exu_wbu;
  wire  [`REG_ADDR_BUS]     waddr_exu_wbu;
  wire  [`REG_DATA_BUS]     alu_result;
  wire  [`REG_DATA_BUS]     mem_result;

  /* IFU & ARBITER */
  wire  [`MEM_ADDR_BUS]     ifu_araddr;
  wire                      ifu_arvalid;
  wire                      ifu_arready;
  wire  [`MEM_DATA_BUS]     ifu_rdata;
  wire  [`RRESP_DATA_BUS]   ifu_rresp;
  wire                      ifu_rvalid;
  wire                      ifu_rready;
  wire  [`MEM_ADDR_BUS]     ifu_awaddr;
  wire                      ifu_awvalid;
  wire                      ifu_awready;
  wire  [`MEM_DATA_BUS]     ifu_wdata;
  wire  [`MEM_MASK_BUS]     ifu_wstrb;
  wire                      ifu_wvalid;
  wire                      ifu_wready;
  wire  [`BRESP_DATA_BUS]   ifu_bresp;
  wire                      ifu_bvalid;
  wire                      ifu_bready;

  /* EXU & ARBITER */
  wire  [`MEM_ADDR_BUS]     exu_araddr;
  wire                      exu_arvalid;
  wire                      exu_arready;
  wire  [`MEM_DATA_BUS]     exu_rdata;
  wire  [`RRESP_DATA_BUS]   exu_rresp;
  wire                      exu_rvalid;
  wire                      exu_rready;
  wire  [`MEM_ADDR_BUS]     exu_awaddr;
  wire                      exu_awvalid;
  wire                      exu_awready;
  wire  [`MEM_DATA_BUS]     exu_wdata;
  wire  [`MEM_MASK_BUS]     exu_wstrb;
  wire                      exu_wvalid;
  wire                      exu_wready;
  wire  [`BRESP_DATA_BUS]   exu_bresp;
  wire                      exu_bvalid;
  wire                      exu_bready;

  ifu u_ifu(
  	.rst          ( rst           ),
    .clk          ( clk           ),

    .valid_pre_i  ( valid_wbu_ifu ),
    .ready_pre_o  ( ready_wbu_ifu ),
    .valid_post_o ( valid_ifu_idu ),
    .ready_post_i ( ready_ifu_idu ),

    .branch_en_i  ( branch_en     ),
    .dnpc_i       ( dnpc          ),

    .rdata_o      ( rdata         ),

    .araddr_o     ( ifu_araddr    ),
    .arvalid_o    ( ifu_arvalid   ),
    .arready_i    ( ifu_arready   ),

    .rdata_i      ( ifu_rdata     ),
    .rresp_i      ( ifu_rresp     ),
    .rvalid_i     ( ifu_rvalid    ),
    .rready_o     ( ifu_rready    ),

    .awaddr_o     ( ifu_awaddr    ),
    .awvalid_o    ( ifu_awvalid   ),
    .awready_i    ( ifu_awready   ),

    .wdata_o      ( ifu_wdata     ),
    .wstrb_o      ( ifu_wstrb     ),
    .wvalid_o     ( ifu_wvalid    ),
    .wready_i     ( ifu_wready    ),

    .bresp_i      ( ifu_bresp     ),
    .bvalid_i     ( ifu_bvalid    ),
    .bready_o     ( ifu_bready    )
  );
  
  wire [`CSR_DATA_BUS] csr;

  idu u_idu(
  	.clk          ( clk           ),
    .rst          ( rst           ),

    .valid_pre_i  ( valid_ifu_idu ),
    .ready_pre_o  ( ready_ifu_idu ),
    .valid_post_o ( valid_idu_exu ),
    .ready_post_i ( ready_idu_exu ),

    .wena_i       ( wena          ),
    .waddr_i      ( waddr         ),
    .wdata_i      ( wdata         ),

    .pc_i         ( ifu_araddr    ),
    .inst_i       ( rdata         ),

    .inst_type_o  ( inst_type     ),
    .alu_op_o     ( alu_op        ),
    .lsu_op_o     ( lsu_op        ),
    .wsel_o       ( wsel_idu_exu  ),
    .wena_o       ( wena_idu_exu  ),
    .waddr_o      ( waddr_idu_exu ),
    .pc_o         ( pc            ),
    .imm_o        ( imm           ),
    .rdata1_o     ( rdata1        ),
    .rdata2_o     ( rdata2        ),
    .csr_o        ( csr           ),

    .branch_en_o  ( branch_en     ),
    .dnpc_o       ( dnpc          ) 
  );
  
  exu u_exu(
  	.clk          ( clk           ),
    .rst          ( rst           ),

    .valid_pre_i  ( valid_idu_exu ),
    .ready_pre_o  ( ready_idu_exu ),
    .valid_post_o ( valid_exu_wbu ),
    .ready_post_i ( ready_exu_wbu ),

    .inst_type_i  ( inst_type     ),
    .alu_op_i     ( alu_op        ),
    .lsu_op_i     ( lsu_op        ),
    .wsel_i       ( wsel_idu_exu  ),
    .wena_i       ( wena_idu_exu  ),
    .waddr_i      ( waddr_idu_exu ),
    .pc_i         ( pc            ),
    .imm_i        ( imm           ),
    .rdata1_i     ( rdata1        ),
    .rdata2_i     ( rdata2        ),
    .csr_i        ( csr           ),

    .wsel_o       ( wsel_exu_wbu  ),
    .wena_o       ( wena_exu_wbu  ),
    .waddr_o      ( waddr_exu_wbu ),
    .alu_result_o ( alu_result    ),
    .mem_result_o ( mem_result    ),

    .araddr_o     ( exu_araddr    ),
    .arvalid_o    ( exu_arvalid   ),
    .arready_i    ( exu_arready   ),

    .rdata_i      ( exu_rdata     ),
    .rresp_i      ( exu_rresp     ),
    .rvalid_i     ( exu_rvalid    ),
    .rready_o     ( exu_rready    ),

    .awaddr_o     ( exu_awaddr    ),
    .awvalid_o    ( exu_awvalid   ),
    .awready_i    ( exu_awready   ),

    .wdata_o      ( exu_wdata     ),
    .wstrb_o      ( exu_wstrb     ),
    .wvalid_o     ( exu_wvalid    ),
    .wready_i     ( exu_wready    ),

    .bresp_i      ( exu_bresp     ),
    .bvalid_i     ( exu_bvalid    ),
    .bready_o     ( exu_bready    )
  );
  
  wbu u_wbu(
  	.clk          ( clk           ),
    .rst          ( rst           ),

    .valid_pre_i  ( valid_exu_wbu ),
    .ready_pre_o  ( ready_exu_wbu ),
    .valid_post_o ( valid_wbu_ifu ),
    .ready_post_i ( ready_wbu_ifu ),

    .wsel_i       ( wsel_exu_wbu  ),
    .wena_i       ( wena_exu_wbu  ),
    .waddr_i      ( waddr_exu_wbu ),
    .alu_result_i ( alu_result    ),
    .mem_result_i ( mem_result    ),

    .wena_o       ( wena          ),
    .waddr_o      ( waddr         ),
    .wdata_o      ( wdata         )
  );

  arbiter u_arbiter(
  	.clk            ( clk            ),
    .rst            ( rst            ),

    .wbu_valid_i    ( valid_wbu_ifu  ),
    .idu_valid_i    ( valid_idu_exu  ),
    .inst_type_i    ( inst_type      ),

    /* AR: Address Read Channel */
    .ifu_araddr_i   ( ifu_araddr     ),
    .exu_araddr_i   ( exu_araddr     ),
    .araddr_o       ( araddr_o       ),

    .ifu_arvalid_i  ( ifu_arvalid    ),
    .exu_arvalid_i  ( exu_arvalid    ),
    .arvalid_o      ( arvalid_o      ),

    .arready_i      ( arready_i      ),
    .ifu_arready_o  ( ifu_arready    ),
    .exu_arready_o  ( exu_arready    ),

    /*  R: Data Read Channel */
    .rdata_i        ( rdata_i        ),
    .ifu_rdata_o    ( ifu_rdata      ),
    .exu_rdata_o    ( exu_rdata      ),

    .rresp_i        ( rresp_i        ),
    .ifu_rresp_o    ( ifu_rresp      ),
    .exu_rresp_o    ( exu_rresp      ),

    .rvalid_i       ( rvalid_i       ),
    .ifu_rvalid_o   ( ifu_rvalid     ),
    .exu_rvalid_o   ( exu_rvalid     ),

    .ifu_rready_i   ( ifu_rready     ),
    .exu_rready_i   ( exu_rready     ),
    .rready_o       ( rready_o       ),

    /* AW: Address Write Channel */
    .ifu_awaddr_i   ( ifu_awaddr     ),
    .exu_awaddr_i   ( exu_awaddr     ),
    .awaddr_o       ( awaddr_o       ),

    .ifu_awvalid_i  ( ifu_awvalid    ),
    .exu_awvalid_i  ( exu_awvalid    ),
    .awvalid_o      ( awvalid_o      ),

    .awready_i      ( awready_i      ),
    .ifu_awready_o  ( ifu_awready    ),
    .exu_awready_o  ( exu_awready    ),

    /*  W: Data Write Channel */
    .ifu_wdata_i    ( ifu_wdata      ),
    .exu_wdata_i    ( exu_wdata      ),
    .wdata_o        ( wdata_o        ),

    .ifu_wstrb_i    ( ifu_wstrb      ),
    .exu_wstrb_i    ( exu_wstrb      ),
    .wstrb_o        ( wstrb_o        ),

    .ifu_wvalid_i   ( ifu_wvalid     ),
    .exu_wvalid_i   ( exu_wvalid     ),
    .wvalid_o       ( wvalid_o       ),

    .wready_i       ( wready_i       ),
    .ifu_wready_o   ( ifu_wready     ),
    .exu_wready_o   ( exu_wready     ),

    /* B: Response Write Channel */
    .bresp_i        ( bresp_i        ),
    .ifu_bresp_o    ( ifu_bresp      ),
    .exu_bresp_o    ( exu_bresp      ),

    .bvalid_i       ( bvalid_i       ),
    .ifu_bvalid_o   ( ifu_bvalid     ),
    .exu_bvalid_o   ( exu_bvalid     ),

    .ifu_bready_i   ( ifu_bready     ),
    .exu_bready_i   ( exu_bready     ),
    .bready_o       ( bready_o       )
  );

endmodule
