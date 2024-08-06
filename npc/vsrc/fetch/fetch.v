`include "defines.v"

module fetch (
  input             reset,
  input             clock,

  output            valid_post_o,
  input             ready_post_i,

  input             commit_csr_i,

  output [2:0]      fetch_state_o,
  input             fetch_raw_i,

	output            fetch_rena1_o,
	output [4:0]      fetch_raddr1_o,
	input  [31:0]     fetch_rdata1_i,

	output            fetch_rena2_o,
	output [4:0]      fetch_raddr2_o,
	input  [31:0]     fetch_rdata2_i,

  output            fcsr_rena_o,    
  output [31:0]     fcsr_raddr_o,   
  input  [31:0]     fcsr_rdata_i,   

  output [31:0]     pc_o,
  output [31:0]     inst_o,

  input             awready_i,     
  output            awvalid_o,
  output [31:0]     awaddr_o,
  output [3:0]      awid_o,
  output [7:0]      awlen_o,
  output [2:0]      awsize_o,
  output [1:0]      awburst_o,

  input             wready_i,      
  output            wvalid_o,
  output [31:0]     wdata_o,
  output [3:0]      wstrb_o,
  output            wlast_o,

  output            bready_o,
  input             bvalid_i,      
  input  [1:0]      bresp_i,       
  input  [3:0]      bid_i,         

  input             arready_i,
  output            arvalid_o,
  output [31:0]     araddr_o,
  output [3:0]      arid_o,
  output [7:0]      arlen_o,
  output [2:0]      arsize_o,
  output [1:0]      arburst_o,

  output            rready_o,
  input             rvalid_i,
  input  [1:0]      rresp_i,
  input  [31:0]     rdata_i,
  input             rlast_i,
  input  [3:0]      rid_i
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
    .csr_flush_i  (csr_flush),
    .csr_target_i (csr_target),

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
    .csr_flush_i  (csr_flush),

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
  wire         ptaken_drive_pre;
  wire [31:0]  ptarget_drive_pre;
  wire         pvalid_drive_pre;

  wire csr_flush;
  wire [31:0] csr_target;

  wire csr_flush_pre_drive;
  wire [31:0] csr_target_pre_drive;

  wire is_csr;

  result_drive result_drive0 (
    .clock              (clock),                      
    .reset              (reset),                      

    .valid_pre_i        (valid_access_drive),                        
    .ready_pre_o        (ready_access_drive),                
                         
    .valid_post_o       (valid_post_o),                        
    .ready_post_i       (ready_post_i),                

    .commit_csr_i       (commit_csr_i),

    .flush_o            (flush),
    .csr_flush_o        (csr_flush),
    .csr_target_o       (csr_target),

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

    .pvalid_o           (pvalid_drive_pre),
    .ptaken_o           (ptaken_drive_pre),
    .ptarget_o          (ptarget_drive_pre),
    .pc_o               (pc_o),
    .inst_o             (inst_o),

    .fetch_state_o      (fetch_state_o),                             
    .fetch_raw_i        (fetch_raw_i),                      
    .is_branch_i        (is_branch),                      
    .is_csr_i           (is_csr),
    .fail_i             (fail),
    .csr_flush_i        (csr_flush_pre_drive),
    .csr_target_i       (csr_target_pre_drive),

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

  pre_decode pre_decode0 (
    .pvalid_i           (pvalid_drive_pre),
    .ptaken_i           (ptaken_drive_pre),
    .ptarget_i          (ptarget_drive_pre),
    .pc_i               (pc_o),              
    .inst_i             (inst_o),                

  	.fetch_rena1_o      (fetch_rena1_o),                       
  	.fetch_raddr1_o     (fetch_raddr1_o),                       
  	.fetch_rdata1_i     (fetch_rdata1_i),                       
                        
  	.fetch_rena2_o      (fetch_rena2_o),                       
  	.fetch_raddr2_o     (fetch_raddr2_o),                       
  	.fetch_rdata2_i     (fetch_rdata2_i),                       

    .fcsr_rena_o        (fcsr_rena_o),
    .fcsr_raddr_o       (fcsr_raddr_o),
    .fcsr_rdata_i       (fcsr_rdata_i),

    .is_branch_o        (is_branch),
    .is_csr_o           (is_csr),
    .fail_o             (fail),
    .csr_flush_o        (csr_flush_pre_drive),
    .csr_target_o       (csr_target_pre_drive),
    .wpc_o              (wpc),
    .wtaken_o           (wtaken),
    .wtarget_o          (wtarget)
  );

endmodule
