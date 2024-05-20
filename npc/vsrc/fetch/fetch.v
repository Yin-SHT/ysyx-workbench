`include "defines.v"

module fetch (
  input                      reset,
  input                      clock,

  input                      flush_i,

  output                     valid_post_o,
  input                      ready_post_i,

  input                      branch_valid_i,
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
  wire arvalid;
  wire arready;

  wire rvalid;
  wire rready;
  wire [31:0] rdata;

  wire branch_inst;

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

  reg[127:0] fire;
  wire       firing = (fire == 1);
  wire [2:0] state;

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

    .valid_post_o (valid_post_o),
    .ready_post_i (ready_post_i),

    .branch_valid_i (branch_valid_i),

    .branch_inst_i (branch_inst),

    .state_o      (state),
    .pc_we_o      (pc_we),
    .inst_we_o    (inst_we),

    .arready_i    (arready),
    .arvalid_o    (arvalid),
    .rready_o     (rready),
    .rvalid_i     (rvalid),

    .firing       (firing)
  );

  fetch_reg reg0 (
    .clock        (clock),
    .reset        (reset),

    .firing       (firing),

    .state_i      (state),
    .pc_we_i      (pc_we),
    .inst_we_i    (inst_we),

    .branch_valid_i (branch_valid_i),
    .branch_en_i  (branch_en_i),
    .dnpc_i       (dnpc_i),

    .pc_o         (pc_o),
    .inst_o       (inst_o),

    .rdata_i      (rdata)
  );

  pre_decode pre_decode0 (
    .inst_i (inst_o),
    .branch_inst_o (branch_inst)
  );

  icache icache0 (
    .clock              (clock),                      
    .reset              (reset),                      

    .flush_i            (flush_i),

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
    .io_master_rid      (rid_i),                              

    .arready_o          (arready),                          
    .arvalid_i          (arvalid),                          
    .araddr_i           (pc_o),                         

    .rready_i           (rready),                         
    .rvalid_o           (rvalid),                         
    .rdata_o            (rdata)                        
  );

endmodule
