`include "defines.v"

module fetch (
  input                      reset,
  input                      clock,

  output                     valid_post_o,
  input                      ready_post_i,

  // fetch -> decode
  output [2:0]               fetch_state_o,
  input                      fetch_raw_i,

	output                     fetch_rena1_o,
	output [4:0]               fetch_raddr1_o,
	input  [31:0]              fetch_rdata1_i,

	output                     fetch_rena2_o,
	output [4:0]               fetch_raddr2_o,
	input  [31:0]              fetch_rdata2_i,


  output [`NPC_ADDR_BUS]     pc_o,
  output [`NPC_DATA_BUS]     inst_o,

  // AW: Address Write Channel 
  input                      awready_i,      // don't use
  output                     awvalid_o,
  output [`AXI4_AWADDR_BUS]  awaddr_o,
  output [`AXI4_AWID_BUS]    awid_o,
  output [`AXI4_AWLEN_BUS]   awlen_o,
  output [`AXI4_AWSIZE_BUS]  awsize_o,
  output [`AXI4_AWBURST_BUS] awburst_o,

  //  W: Data Write Channel 
  input                      wready_i,       // don't use
  output                     wvalid_o,
  output [`AXI4_WDATA_BUS]   wdata_o,
  output [`AXI4_WSTRB_BUS]   wstrb_o,
  output                     wlast_o,

  //  B: Response Write Channel 
  output                     bready_o,
  input                      bvalid_i,       // don't use 
  input  [`AXI4_BRESP_BUS]   bresp_i,        // don't use
  input  [`AXI4_BID_BUS]     bid_i,          // don't use

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

  wire         valid_addr_access;
  wire         ready_addr_access;
  wire         valid_access_drive;
  wire         ready_access_drive;

  wire [31:0]  pc;
  wire         wen;
  wire [3:0]   windex;
  wire [2:0]   wway;
  wire [23:0]  wtag;
  wire [127:0] wdata;

  wire         tar_hit;
  wire [31:0]  araddr;
  wire [127:0] buffer;


  wire         flush;
  wire         is_branch;

  wire         ptaken_btb_access;
  wire [31:0]  ptarget_btb_access;

  wire pvalid;

  addr_calculate addr_calculate0 (
    .clock        (clock),
    .reset        (reset),

    .valid_post_o (valid_addr_access),
    .ready_post_i (ready_addr_access),

    .flush_i      (flush),
    .wtarget_i    (wtarget),

    .pvalid_i     (pvalid),
    .ptaken_i     (ptaken_btb_access),
    .ptarget_i    (ptarget_btb_access),

    .pc_o         (pc)
  );

  wire [31:0] wpc;
  wire        wtaken;
  wire [31:0] wtarget;

  btb btb0 (
    .clock        (clock),                
    .reset        (reset),                

    .pc_i         (pc),              
    .pvalid_o     (pvalid),
    .ptaken_o     (ptaken_btb_access),                        
    .ptarget_o    (ptarget_btb_access),                        

    .flush_i      (flush),                          
    .wpc_i        (wpc),                
    .wtaken_i     (wtaken),                        
    .wtarget_i    (wtarget)                        
  );

  wire         ptaken_access_drive;
  wire [31:0]  ptarget_access_drive;
  wire         pvalid_access_drive;

  cache_access cache_access0 (
    .clock        (clock),
    .reset        (reset),

    .valid_pre_i  (valid_addr_access),                     
    .ready_pre_o  (ready_addr_access),                 

    .valid_post_o (valid_access_drive),
    .ready_post_i (ready_access_drive),                

    .flush_i      (flush),

    .wen_i        (wen),        
    .windex_i     (windex),             
    .wway_i       (wway),          
    .wtag_i       (wtag),          
    .wdata_i      (wdata),            

    .pvalid_i     (pvalid),
    .ptaken_i     (ptaken_btb_access),
    .ptarget_i    (ptarget_btb_access),
    .araddr_i     (pc),                 

    .tar_hit_o    (tar_hit),
    .pvalid_o     (pvalid_access_drive),
    .ptaken_o     (ptaken_access_drive),                        
    .ptarget_o    (ptarget_access_drive),                        
    .araddr_o     (araddr),            
    .buffer_o     (buffer)            
  );

  wire         fail;
  wire         ptaken_drive_bpu;
  wire [31:0]  ptarget_drive_bpu;
  wire         pvalid_drive_bpu;

  result_drive result_drive0 (
    .clock              (clock),                      
    .reset              (reset),                      

    .valid_pre_i        (valid_access_drive),                        
    .ready_pre_o        (ready_access_drive),                
                         
    .valid_post_o       (valid_post_o),                        
    .ready_post_i       (ready_post_i),                

    .flush_o            (flush),

    .tar_hit_i          (tar_hit),
    .pvalid_i           (pvalid_access_drive),
    .ptaken_i           (ptaken_access_drive),
    .ptarget_i          (ptarget_access_drive),
    .araddr_i           (araddr),
    .buffer_i           (buffer),
                         
    .wen_o              (wen),
    .windex_o           (windex),
    .wway_o             (wway),
    .wtag_o             (wtag),
    .wdata_o            (wdata),

    .pvalid_o           (pvalid_drive_bpu),
    .ptaken_o           (ptaken_drive_bpu),
    .ptarget_o          (ptarget_drive_bpu),
    .pc_o               (pc_o),
    .inst_o             (inst_o),

    .fetch_state_o      (fetch_state_o),                             
    .fetch_raw_i        (fetch_raw_i),                      
    .is_branch_i        (is_branch),                      
    .fail_i             (fail),

    .io_master_arready  (arready_i),                                  
    .io_master_arvalid  (arvalid_o),                                  
    .io_master_araddr   (araddr_o),                                  
    .io_master_arid     (arid_o),                               
    .io_master_arlen    (arlen_o),                                
    .io_master_arsize   (arsize_o),                                 
    .io_master_arburst  (arburst_o),                                  

    .io_master_rready   (rready_o),                                 
    .io_master_rvalid   (rvalid_i),                                 
    .io_master_rresp    (rresp_i),                                
    .io_master_rdata    (rdata_i),                                
    .io_master_rlast    (rlast_i),                                
    .io_master_rid      (rid_i)
  );

  branch_log branch_log0 (
    .pvalid_i           (pvalid_drive_bpu),
    .ptaken_i           (ptaken_drive_bpu),
    .ptarget_i          (ptarget_drive_bpu),
    .pc_i               (pc_o),              
    .inst_i             (inst_o),                

  	.fetch_rena1_o      (fetch_rena1_o),                       
  	.fetch_raddr1_o     (fetch_raddr1_o),                       
  	.fetch_rdata1_i     (fetch_rdata1_i),                       
                        
  	.fetch_rena2_o      (fetch_rena2_o),                       
  	.fetch_raddr2_o     (fetch_raddr2_o),                       
  	.fetch_rdata2_i     (fetch_rdata2_i),                       

    .is_branch_o        (is_branch),
    .fail_o             (fail),
    .wpc_o              (wpc),
    .wtaken_o           (wtaken),
    .wtarget_o          (wtarget)
  );

endmodule
