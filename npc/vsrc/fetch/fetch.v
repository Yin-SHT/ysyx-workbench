`include "defines.v"

module fetch (
    input                      reset,
    input                      clock,

    input                      valid_pre_i,
    output                     ready_pre_o,

    output                     valid_post_o,
    input                      ready_post_i,

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

    fetch_controller controller (
        .clock        (clock),
        .reset        (reset),

        .valid_pre_i  (valid_pre_i),
        .ready_pre_o  (ready_pre_o),

        .valid_post_o (valid_post_o),
        .ready_post_i (ready_post_i),

        .branch_en_i  (branch_en_i),
        .dnpc_i       (dnpc_i),

        .pc_o         (pc_o),
        .inst_o       (inst_o),

        .awready_i    (awready_i),                                 
        .awvalid_o    (awvalid_o),                            
        .awaddr_o     (awaddr_o),                           
        .awid_o       (awid_o),                         
        .awlen_o      (awlen_o),                          
        .awsize_o     (awsize_o),                           
        .awburst_o    (awburst_o),                            

        .wready_i     (wready_i),                                 
        .wvalid_o     (wvalid_o),                           
        .wdata_o      (wdata_o),                          
        .wstrb_o      (wstrb_o),                          
        .wlast_o      (wlast_o),                          

        .bready_o     (bready_o),                           
        .bvalid_i     (bvalid_i),                                 
        .bresp_i      (bresp_i),                                 
        .bid_i        (bid_i),                                 

        .arready_i    (arready_i),                            
        .arvalid_o    (arvalid_o),                            
        .araddr_o     (araddr_o),                           
        .arid_o       (arid_o),                         
        .arlen_o      (arlen_o),                          
        .arsize_o     (arsize_o),                           
        .arburst_o    (arburst_o),                            

        .rready_o     (rready_o),                           
        .rvalid_i     (rvalid_i),                           
        .rresp_i      (rresp_i),                          
        .rdata_i      (rdata_i),                          
        .rlast_i      (rlast_i),                          
        .rid_i        (rid_i)
    );

endmodule
