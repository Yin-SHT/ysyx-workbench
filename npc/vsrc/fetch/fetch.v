`include "defines.v"

module fetch (
    input             reset,
    input             clock,

    input             valid_pre_i,
    output            ready_pre_o,

    output            valid_post_o,
    input             ready_post_i,

    input             branch_en_i,
    input  [31:0]     dnpc_i,

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

    wire request_valid;
    wire request_ready;

    wire response_ready;
    wire response_valid;

    wire [31:0] pc;

    fetch_controller controller (
        .clock        (clock),
        .reset        (reset),

        .valid_pre_i  (valid_pre_i),
        .ready_pre_o  (ready_pre_o),

        .valid_post_o (valid_post_o),
        .ready_post_i (ready_post_i),

        .request_valid_o  (request_valid),      
        .request_ready_i  (request_ready),      
                           
        .response_ready_o (response_ready),
        .response_valid_i (response_valid),       

        .branch_en_i  (branch_en_i),
        .dnpc_i       (dnpc_i),

        .pc_o         (pc)
    );

    icache icache0 (
        .clock        (clock),
        .reset        (reset),

        .request_valid_i  (request_valid),      
        .request_ready_o  (request_ready),      
                           
        .response_ready_i (response_ready),
        .response_valid_o (response_valid),       

        .pc_i         (pc),

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
