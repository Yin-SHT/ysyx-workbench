`include "defines.v"

module fetch (
  input                      reset,
  input                      clock,

  output                     valid_post_o,
  input                      ready_post_i,

  // decode -> fetch
  input                      flush_i,       // don't use  
  input                      branch_valid_i, // don't use  
  input                      branch_en_i,    // don't use  
  input  [`NPC_ADDR_BUS]     dnpc_i,         // don't use  

  // fetch -> decode
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


  addr_calculate addr_calculate0 (
    .clock        (clock),
    .reset        (reset),

    .valid_post_o (valid_addr_access),
    .ready_post_i (ready_addr_access),

    .pc_o         (pc)
  );

  cache_access cache_access0 (
    .clock        (clock),
    .reset        (reset),

    .valid_pre_i  (valid_addr_access),                     
    .ready_pre_o  (ready_addr_access),                 

    .valid_post_o (valid_access_drive),
    .ready_post_i (ready_access_drive),                

    .wen_i        (wen),        
    .windex_i     (windex),             
    .wway_i       (wway),          
    .wtag_i       (wtag),          
    .wdata_i      (wdata),            

    .araddr_i     (pc),                 

    .tar_hit_o    (tar_hit),
    .araddr_o     (araddr),            
    .buffer_o     (buffer)            
  );

  result_drive result_drive0 (
    .clock              (clock),                      
    .reset              (reset),                      

    .valid_pre_i        (valid_access_drive),                        
    .ready_pre_o        (ready_access_drive),                
                         
    .valid_post_o       (valid_post_o),                        
    .ready_post_i       (ready_post_i),                

    .tar_hit_i          (tar_hit),
    .araddr_i           (araddr),
    .buffer_i           (buffer),
                         
    .wen_o              (wen),
    .windex_o           (windex),
    .wway_o             (wway),
    .wtag_o             (wtag),
    .wdata_o            (wdata),
                         
    .pc_o               (pc_o),
    .inst_o             (inst_o),

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

endmodule
