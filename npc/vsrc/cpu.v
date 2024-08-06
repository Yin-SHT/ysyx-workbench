`include "defines.v"

module cpu (
  input   clock,
  input   reset,
  input   io_interrupt,

  /** MASTER */
  /* AW: Address Write Channel */
  input         io_master_awready,
  output        io_master_awvalid,
  output [31:0] io_master_awaddr,
  output [3:0]  io_master_awid,
  output [7:0]  io_master_awlen,
  output [2:0]  io_master_awsize,
  output [1:0]  io_master_awburst,

  /*  W: Data Write Channel */
  input         io_master_wready,
  output        io_master_wvalid,
  output [31:0] io_master_wdata,
  output [3:0]  io_master_wstrb,
  output        io_master_wlast,

  /*  B: Response Write Channel */
  output        io_master_bready,
  input         io_master_bvalid,
  input  [1:0]  io_master_bresp,
  input  [3:0]  io_master_bid,

  /* AR: Address Read Channel */
  input         io_master_arready,
  output        io_master_arvalid,
  output [31:0] io_master_araddr ,
  output [3:0]  io_master_arid,
  output [7:0]  io_master_arlen,
  output [2:0]  io_master_arsize,
  output [1:0]  io_master_arburst,

  /*  R: Data Read Channel */
  output        io_master_rready,
  input         io_master_rvalid,
  input  [1:0]  io_master_rresp,
  input  [31:0] io_master_rdata,
  input         io_master_rlast,
  input  [3:0]  io_master_rid,

  /** SLAVE */
  /* AW: Address Write Channel */
  output        io_slave_awready,
  input         io_slave_awvalid,
  input [31:0]  io_slave_awaddr,
  input [3:0]   io_slave_awid,
  input [7:0]   io_slave_awlen,
  input [2:0]   io_slave_awsize,
  input [1:0]   io_slave_awburst,

  /*  W: Data Write Channel */
  output        io_slave_wready,
  input         io_slave_wvalid,
  input [31:0]  io_slave_wdata,
  input [3:0]   io_slave_wstrb,
  input         io_slave_wlast,

  /*  B: Response Write Channel */
  input         io_slave_bready,
  output        io_slave_bvalid,
  output [1:0]  io_slave_bresp,
  output [3:0]  io_slave_bid,

  /* AR: Address Read Channel */
  output        io_slave_arready,
  input         io_slave_arvalid,
  input  [31:0] io_slave_araddr ,
  input  [3:0]  io_slave_arid,
  input  [7:0]  io_slave_arlen,
  input  [2:0]  io_slave_arsize,
  input  [1:0]  io_slave_arburst,

  /*  R: Data Read Channel */
  input         io_slave_rready,
  output        io_slave_rvalid,
  output [1:0]  io_slave_rresp,
  output [31:0] io_slave_rdata,
  output        io_slave_rlast,
  output [3:0]  io_slave_rid
);

  wire valid_ifu_idu;
  wire ready_ifu_idu;

  wire valid_idu_exu;
  wire ready_idu_exu;

  wire valid_exu_wbu;
  wire ready_exu_wbu;

  /* IDU <--> IFU */
  wire        fetch_raw;
  wire [2:0]  fetch_state;
	wire        fetch_rena1;
	wire [4:0]  fetch_raddr1;
	wire [31:0] fetch_rdata1;
	wire        fetch_rena2;
	wire [4:0]  fetch_raddr2;
	wire [31:0] fetch_rdata2;


  /* IFU --> IDU */
  wire [31:0] instpc;
  wire [31:0] inst;

  /* WBU --> IDU */
  wire        commit_valid;
  wire        commit_csr;
  wire        wena;
  wire [4:0]  waddr;
  wire [31:0] wdata;
  wire        csr_wena;
  wire [31:0] csr_waddr;
  wire [31:0] csr_wdata;

  /* IDU --> EXU */
  wire [`INST_TYPE_BUS] inst_type;
  wire [`ALU_OP_BUS]    alu_op;
  wire [`LSU_OP_BUS]    lsu_op;
  wire [`CSR_OP_BUS]    csr_op;
  wire                  wsel_idu_exu;
  wire                  wena_idu_exu;
  wire [4:0]            waddr_idu_exu;
  wire                  csr_wena_idu_exu;
  wire [31:0]           csr_waddr_idu_exu;
  wire [31:0]           pc;
  wire [31:0]           imm;
  wire [31:0]           rdata1;
  wire [31:0]           rdata2;
  wire [31:0]           csr_rdata;
  wire [31:0]           inst_idu_exu;

  /* EXU --> WBU */
  wire        wsel_exu_wbu;
  wire        wena_exu_wbu;
  wire [4:0]  waddr_exu_wbu;
  wire [31:0] alu_result;
  wire [31:0] mem_result;
  wire        csr_wena_exu_wbu;
  wire [31:0] csr_waddr_exu_wbu;
  wire [31:0] csr_wdata_exu_wbu;
  wire [31:0] pc_exu_wbu;
  wire [31:0] inst_exu_wbu;


  /* IFU & ARBITER */
  wire        ifu_awready;
  wire        ifu_awvalid;
  wire [31:0] ifu_awaddr;
  wire [3:0]  ifu_awid;
  wire [7:0]  ifu_awlen;
  wire [2:0]  ifu_awsize;
  wire [1:0]  ifu_awburst;
  wire        ifu_wready;
  wire        ifu_wvalid;
  wire [31:0] ifu_wdata;
  wire [3:0]  ifu_wstrb;
  wire        ifu_wlast;
  wire        ifu_bready;
  wire        ifu_bvalid;
  wire [1:0]  ifu_bresp;
  wire [3:0]  ifu_bid;
  wire        ifu_arready;
  wire        ifu_arvalid;
  wire [31:0] ifu_araddr;
  wire [3:0]  ifu_arid;
  wire [7:0]  ifu_arlen;
  wire [2:0]  ifu_arsize;
  wire [1:0]  ifu_arburst;
  wire        ifu_rready;
  wire        ifu_rvalid;
  wire [1:0]  ifu_rresp;
  wire [31:0] ifu_rdata;
  wire        ifu_rlast;
  wire [3:0]  ifu_rid;

  /* EXU & ARBITER */
  wire        exu_awready;
  wire        exu_awvalid;
  wire [31:0] exu_awaddr;
  wire [3:0]  exu_awid;
  wire [7:0]  exu_awlen;
  wire [2:0]  exu_awsize;
  wire [1:0]  exu_awburst;
  wire        exu_wready;
  wire        exu_wvalid;
  wire [31:0] exu_wdata;
  wire [3:0]  exu_wstrb;
  wire        exu_wlast;
  wire        exu_bready;
  wire        exu_bvalid;
  wire [1:0]  exu_bresp;
  wire [3:0]  exu_bid;
  wire        exu_arready;
  wire        exu_arvalid;
  wire [31:0] exu_araddr;
  wire [3:0]  exu_arid;
  wire [7:0]  exu_arlen;
  wire [2:0]  exu_arsize;
  wire [1:0]  exu_arburst;
  wire        exu_rready;
  wire        exu_rvalid;
  wire [1:0]  exu_rresp;
  wire [31:0] exu_rdata;
  wire        exu_rlast;
  wire [3:0]  exu_rid;

  /** SLAVE */
  assign io_slave_awready = 0;
  assign io_slave_wready  = 0;
  assign io_slave_bvalid  = 0;
  assign io_slave_bresp   = 0;
  assign io_slave_bid     = 0;
  assign io_slave_arready = 0;
  assign io_slave_rvalid  = 0;
  assign io_slave_rresp   = 0;
  assign io_slave_rdata   = 0;
  assign io_slave_rlast   = 0;
  assign io_slave_rid     = 0;

  wire        fcsr_rena;
  wire [31:0] fcsr_raddr;
  wire [31:0] fcsr_rdata;

  fetch fetch0 (
  	.reset        (reset),
    .clock        (clock),

    .valid_post_o (valid_ifu_idu),
    .ready_post_i (ready_ifu_idu),

    .commit_csr_i (commit_csr),

    .fetch_raw_i    (fetch_raw),      
    .fetch_state_o  (fetch_state),    
    .fetch_rena1_o  (fetch_rena1),    
    .fetch_raddr1_o (fetch_raddr1),    
    .fetch_rdata1_i (fetch_rdata1),    
    .fetch_rena2_o  (fetch_rena2),    
    .fetch_raddr2_o (fetch_raddr2),     
    .fetch_rdata2_i (fetch_rdata2),     

    .fcsr_rena_o    (fcsr_rena),
    .fcsr_raddr_o   (fcsr_raddr),
    .fcsr_rdata_i   (fcsr_rdata),

    .pc_o         (instpc),
    .inst_o       (inst),

    .awready_i    (ifu_awready),
    .awvalid_o    (ifu_awvalid),
    .awaddr_o     (ifu_awaddr),
    .awid_o       (ifu_awid),
    .awlen_o      (ifu_awlen),
    .awsize_o     (ifu_awsize),
    .awburst_o    (ifu_awburst),
    .wready_i     (ifu_wready),
    .wvalid_o     (ifu_wvalid),
    .wdata_o      (ifu_wdata),
    .wstrb_o      (ifu_wstrb),
    .wlast_o      (ifu_wlast),
    .bready_o     (ifu_bready),
    .bvalid_i     (ifu_bvalid),
    .bresp_i      (ifu_bresp),
    .bid_i        (ifu_bid),
    .arready_i    (ifu_arready),
    .arvalid_o    (ifu_arvalid),
    .araddr_o     (ifu_araddr),
    .arid_o       (ifu_arid),
    .arlen_o      (ifu_arlen),
    .arsize_o     (ifu_arsize),
    .arburst_o    (ifu_arburst),
    .rready_o     (ifu_rready),
    .rvalid_i     (ifu_rvalid),
    .rresp_i      (ifu_rresp),
    .rdata_i      (ifu_rdata),
    .rlast_i      (ifu_rlast),
    .rid_i        (ifu_rid)
  );
  
  wire [7:0] csr_op_wbu_idu;

  decode decode0 (
  	.clock        (clock),
    .reset        (reset),

    .commit_valid_i (commit_valid),

    .valid_pre_i  (valid_ifu_idu),
    .ready_pre_o  (ready_ifu_idu),
    .valid_post_o (valid_idu_exu),
    .ready_post_i (ready_idu_exu),

    .pc_i         (instpc),                 
    .inst_i       (inst),                   
                   
    .fetch_raw_o    (fetch_raw),      
    .fetch_state_i  (fetch_state),    
    .fetch_rena1_i  (fetch_rena1),    
    .fetch_raddr1_i (fetch_raddr1),    
    .fetch_rdata1_o (fetch_rdata1),    
    .fetch_rena2_i  (fetch_rena2),    
    .fetch_raddr2_i (fetch_raddr2),     
    .fetch_rdata2_o (fetch_rdata2),     

    .fcsr_rena_i    (fcsr_rena),
    .fcsr_raddr_i   (fcsr_raddr),
    .fcsr_rdata_o   (fcsr_rdata),

    .inst_type_o  (inst_type),                        
    .alu_op_o     (alu_op),                     
    .lsu_op_o     (lsu_op),                     
    .csr_op_o     (csr_op),                     
                   
    .wsel_o       (wsel_idu_exu),                   
    .wena_o       (wena_idu_exu),                   
    .waddr_o      (waddr_idu_exu),                    
    .csr_wena_o   (csr_wena_idu_exu),                       
    .csr_waddr_o  (csr_waddr_idu_exu),                        
                   
    .pc_o         (pc),                 
    .inst_o       (inst_idu_exu),
    .imm_o        (imm),                  
    .rdata1_o     (rdata1),                     
    .rdata2_o     (rdata2),                     
    .csr_rdata_o  (csr_rdata),                        

    .wena_i       (wena),
    .waddr_i      (waddr), 
    .wdata_i      (wdata), 
    
    .csr_op_i     (csr_op_wbu_idu),
    .csr_wena_i   (csr_wena),     
    .csr_waddr_i  (csr_waddr),     
    .csr_wdata_i  (csr_wdata)
  );
  
  wire [7:0] csr_op_exu_wbu;

  execute execute0 (
  	.clock        (clock),
    .reset        (reset),

    .valid_pre_i  (valid_idu_exu),
    .ready_pre_o  (ready_idu_exu),
    .valid_post_o (valid_exu_wbu),
    .ready_post_i (ready_exu_wbu),

    .inst_type_i  (inst_type),                        
    .alu_op_i     (alu_op),                     
    .lsu_op_i     (lsu_op),                     
    .csr_op_i     (csr_op),                     
    .wsel_i       (wsel_idu_exu),                   
    .wena_i       (wena_idu_exu),                   
    .waddr_i      (waddr_idu_exu),                    
    .csr_wena_i   (csr_wena_idu_exu),                       
    .csr_waddr_i  (csr_waddr_idu_exu),                        
    .pc_i         (pc),                 
    .inst_i       (inst_idu_exu),                 
    .imm_i        (imm),                  
    .rdata1_i     (rdata1),                     
    .rdata2_i     (rdata2),                     
    .csr_rdata_i  (csr_rdata),                        

    .pc_o         (pc_exu_wbu),                 
    .inst_o       (inst_exu_wbu),                 
    .wsel_o       (wsel_exu_wbu),
    .wena_o       (wena_exu_wbu),
    .waddr_o      (waddr_exu_wbu),
    .alu_result_o (alu_result),
    .mem_result_o (mem_result),
    .csr_op_o     (csr_op_exu_wbu),
    .csr_wena_o   (csr_wena_exu_wbu), 
    .csr_waddr_o  (csr_waddr_exu_wbu),  
    .csr_wdata_o  (csr_wdata_exu_wbu),  

    .awready_i    (exu_awready),
    .awvalid_o    (exu_awvalid),
    .awaddr_o     (exu_awaddr),
    .awid_o       (exu_awid),
    .awlen_o      (exu_awlen),
    .awsize_o     (exu_awsize),
    .awburst_o    (exu_awburst),
    .wready_i     (exu_wready),
    .wvalid_o     (exu_wvalid),
    .wdata_o      (exu_wdata),
    .wstrb_o      (exu_wstrb),
    .wlast_o      (exu_wlast),
    .bready_o     (exu_bready),
    .bvalid_i     (exu_bvalid),
    .bresp_i      (exu_bresp),
    .bid_i        (exu_bid),
    .arready_i    (exu_arready),
    .arvalid_o    (exu_arvalid),
    .araddr_o     (exu_araddr),
    .arid_o       (exu_arid),
    .arlen_o      (exu_arlen),
    .arsize_o     (exu_arsize),
    .arburst_o    (exu_arburst),
    .rready_o     (exu_rready),
    .rvalid_i     (exu_rvalid),
    .rresp_i      (exu_rresp),
    .rdata_i      (exu_rdata),
    .rlast_i      (exu_rlast),
    .rid_i        (exu_rid)
  );
  
  commit commit0 (
  	.clock        (clock),
    .reset        (reset),

    .valid_pre_i  (valid_exu_wbu),
    .ready_pre_o  (ready_exu_wbu),

    .commit_valid_o (commit_valid),
    .commit_csr_o (commit_csr),

    .pc_i         (pc_exu_wbu),                 
    .inst_i       (inst_exu_wbu),                 
    .wsel_i       (wsel_exu_wbu),
    .wena_i       (wena_exu_wbu),
    .waddr_i      (waddr_exu_wbu),
    .alu_result_i (alu_result),
    .mem_result_i (mem_result),

    .csr_op_i     (csr_op_exu_wbu),
    .csr_wena_i   (csr_wena_exu_wbu),
    .csr_waddr_i  (csr_waddr_exu_wbu),
    .csr_wdata_i  (csr_wdata_exu_wbu),

    .wena_o       (wena),
    .waddr_o      (waddr),
    .wdata_o      (wdata),

    .csr_op_o     (csr_op_wbu_idu),
    .csr_wena_o   (csr_wena),
    .csr_waddr_o  (csr_waddr),
    .csr_wdata_o  (csr_wdata)
  );

  arbiter arbiter0 (
  	.clock         (clock),
    .reset         (reset),
    
    .awready_i     (io_master_awready),
    .ifu_awready_o (ifu_awready),
    .exu_awready_o (exu_awready),
    .awvalid_o     (io_master_awvalid),
    .ifu_awvalid_i (ifu_awvalid),
    .exu_awvalid_i (exu_awvalid),
    .awaddr_o      (io_master_awaddr),
    .ifu_awaddr_i  (ifu_awaddr),
    .exu_awaddr_i  (exu_awaddr),
    .awid_o        (io_master_awid),
    .ifu_awid_i    (ifu_awid),
    .exu_awid_i    (exu_awid),
    .awlen_o       (io_master_awlen),
    .ifu_awlen_i   (ifu_awlen),
    .exu_awlen_i   (exu_awlen),
    .awsize_o      (io_master_awsize),
    .ifu_awsize_i  (ifu_awsize),
    .exu_awsize_i  (exu_awsize),
    .awburst_o     (io_master_awburst),
    .ifu_awburst_i (ifu_awburst),
    .exu_awburst_i (exu_awburst),
    .wready_i      (io_master_wready),
    .ifu_wready_o  (ifu_wready),
    .exu_wready_o  (exu_wready),
    .wvalid_o      (io_master_wvalid),
    .ifu_wvalid_i  (ifu_wvalid),
    .exu_wvalid_i  (exu_wvalid),
    .wdata_o       (io_master_wdata),
    .ifu_wdata_i   (ifu_wdata),
    .exu_wdata_i   (exu_wdata),
    .wstrb_o       (io_master_wstrb),
    .ifu_wstrb_i   (ifu_wstrb),
    .exu_wstrb_i   (exu_wstrb),
    .wlast_o       (io_master_wlast),
    .ifu_wlast_i   (ifu_wlast),
    .exu_wlast_i   (exu_wlast),
    .bready_o      (io_master_bready),
    .ifu_bready_i  (ifu_bready),
    .exu_bready_i  (exu_bready),
    .bvalid_i      (io_master_bvalid),
    .ifu_bvalid_o  (ifu_bvalid),
    .exu_bvalid_o  (exu_bvalid),
    .bresp_i       (io_master_bresp),
    .ifu_bresp_o   (ifu_bresp),
    .exu_bresp_o   (exu_bresp),
    .bid_i         (io_master_bid),
    .ifu_bid_o     (ifu_bid),
    .exu_bid_o     (exu_bid),
    .arready_i     (io_master_arready),
    .ifu_arready_o (ifu_arready),
    .exu_arready_o (exu_arready),
    .arvalid_o     (io_master_arvalid),
    .ifu_arvalid_i (ifu_arvalid),
    .exu_arvalid_i (exu_arvalid),
    .araddr_o      (io_master_araddr),
    .ifu_araddr_i  (ifu_araddr),
    .exu_araddr_i  (exu_araddr),
    .arid_o        (io_master_arid),
    .ifu_arid_i    (ifu_arid),
    .exu_arid_i    (exu_arid),
    .arlen_o       (io_master_arlen),
    .ifu_arlen_i   (ifu_arlen),
    .exu_arlen_i   (exu_arlen),
    .arsize_o      (io_master_arsize),
    .ifu_arsize_i  (ifu_arsize),
    .exu_arsize_i  (exu_arsize),
    .arburst_o     (io_master_arburst),
    .ifu_arburst_i (ifu_arburst),
    .exu_arburst_i (exu_arburst),
    .rready_o      (io_master_rready),
    .ifu_rready_i  (ifu_rready),
    .exu_rready_i  (exu_rready),
    .rvalid_i      (io_master_rvalid),
    .ifu_rvalid_o  (ifu_rvalid),
    .exu_rvalid_o  (exu_rvalid),
    .rresp_i       (io_master_rresp),
    .ifu_rresp_o   (ifu_rresp),
    .exu_rresp_o   (exu_rresp),
    .rdata_i       (io_master_rdata),
    .ifu_rdata_o   (ifu_rdata),
    .exu_rdata_o   (exu_rdata),
    .rlast_i       (io_master_rlast),
    .ifu_rlast_o   (ifu_rlast),
    .exu_rlast_o   (exu_rlast),
    .rid_i         (io_master_rid),
    .ifu_rid_o     (ifu_rid),
    .exu_rid_o     (exu_rid),

    .clint_araddr_o   (clint_araddr),
    .clint_arvalid_o  (clint_arvalid),
    .clint_arready_i  (clint_arready),
    .clint_rresp_i    (clint_rresp),
    .clint_rdata_i    (clint_rdata),
    .clint_rlast_i    (clint_rlast),
    .clint_rid_i      (clint_rid),
    .clint_rvalid_i   (clint_rvalid),
    .clint_rready_o   (clint_rready)
  );

  wire[31:0]  clint_araddr;
  wire        clint_arvalid;
  wire        clint_arready;
  wire[1:0]   clint_rresp;
  wire[31:0]  clint_rdata;
  wire        clint_rlast;
  wire[3:0]   clint_rid;
  wire        clint_rvalid;
  wire        clint_rready;

  clint clint0 (
    .clock (clock),
    .reset (reset),

    .araddr_i  (clint_araddr),
    .arvalid_i (clint_arvalid),
    .arready_o (clint_arready),

    .rdata_o   (clint_rdata),
    .rresp_o   (clint_rresp),
    .rlast_o   (clint_rlast),
    .rid_o     (clint_rid),
    .rvalid_o  (clint_rvalid),
    .rready_i  (clint_rready)
  );

endmodule
