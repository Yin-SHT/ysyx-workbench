`include "defines.v"

module execute (
    input             clock,
    input             reset,

    input             valid_pre_i,
    output            ready_pre_o,

    output            valid_post_o,
    input             ready_post_i,

    input  [7:0]      inst_type_i,
    input  [7:0]      alu_op_i,
    input  [7:0]      lsu_op_i,
    input  [7:0]      csr_op_i,
    input             wsel_i,
    input             wena_i,
    input  [4:0]      waddr_i,
    input             csr_wena_i,
    input  [31:0]     csr_waddr_i,
    input  [31:0]     pc_i,
    input  [31:0]     imm_i,
    input  [31:0]     rdata1_i,
    input  [31:0]     rdata2_i,
    input  [31:0]     csr_rdata_i,
    
    output            wsel_o,
    output            wena_o,
    output [4:0]      waddr_o,
    output [31:0]     alu_result_o,
    output [31:0]     mem_result_o,
    output [7:0]      csr_op_o,
    output            csr_wena_o,
    output [31:0]     csr_waddr_o,
    output [31:0]     csr_wdata_o,

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
  
    reg        wsel;
    reg        wena;
    reg [4:0]  waddr;
    reg [7:0]  csr_op;
    reg        csr_wena;
    reg [31:0] csr_waddr;

    assign wsel_o      = wsel;
    assign wena_o      = wena;
    assign waddr_o     = waddr;     
    assign csr_op_o    = csr_op;
    assign csr_wena_o  = csr_wena;     
    assign csr_waddr_o = csr_waddr;     

    always @(posedge clock) begin
        if (reset) begin
            wsel      <= 0;
            wena      <= 0;
            waddr     <= 0;
            csr_op    <= 0;
            csr_wena  <= 0;
            csr_waddr <= 0;
        end else if (valid_pre_i && ready_pre_o) begin
            wsel      <= wsel_i;
            wena      <= wena_i;
            waddr     <= waddr_i;
            csr_op    <= csr_op_i;
            csr_wena  <= csr_wena_i;
            csr_waddr <= csr_waddr_i;
        end
    end

    wire fu_ready_pre_o, lsu_ready_pre_o;
    wire fu_valid_post_o, lsu_valid_post_o;

    assign ready_pre_o  = fu_ready_pre_o  && lsu_ready_pre_o;
    assign valid_post_o = fu_valid_post_o || lsu_valid_post_o;

    fu fu0 (
        .clock             (clock),
        .reset             (reset),
                         
        .valid_pre_i       (valid_pre_i),
        .fu_ready_pre_o    (fu_ready_pre_o),
        .lsu_ready_pre_o   (lsu_ready_pre_o),
                         
        .ready_post_i      (ready_post_i),
        .fu_valid_post_o   (fu_valid_post_o),
                         
        .inst_type_i       (inst_type_i),
        .alu_op_i          (alu_op_i),
        .csr_op_i          (csr_op_i),
        .pc_i              (pc_i),
        .imm_i             (imm_i),
        .rdata1_i          (rdata1_i),
        .rdata2_i          (rdata2_i),
        .csr_rdata_i       (csr_rdata_i),
                         
        .alu_result_o      (alu_result_o),
        .csr_wdata_o       (csr_wdata_o)
    );
    
    lsu lsu0 (
        .clock             (clock),
        .reset             (reset),
       
        .valid_pre_i       (valid_pre_i),
        .lsu_ready_pre_o   (lsu_ready_pre_o),
        .fu_ready_pre_o    (fu_ready_pre_o),
                         
        .ready_post_i      (ready_post_i),
        .lsu_valid_post_o  (lsu_valid_post_o),

        .inst_type_i       (inst_type_i),
        .lsu_op_i          (lsu_op_i),
        .imm_i             (imm_i),
        .rdata1_i          (rdata1_i),
        .rdata2_i          (rdata2_i),
        
        .mem_result_o      (mem_result_o),

        .awready_i         (awready_i),                                 
        .awvalid_o         (awvalid_o),                            
        .awaddr_o          (awaddr_o),                           
        .awid_o            (awid_o),                         
        .awlen_o           (awlen_o),                          
        .awsize_o          (awsize_o),                           
        .awburst_o         (awburst_o),                            

        .wready_i          (wready_i),                                 
        .wvalid_o          (wvalid_o),                           
        .wdata_o           (wdata_o),                          
        .wstrb_o           (wstrb_o),                          
        .wlast_o           (wlast_o),                          

        .bready_o          (bready_o),                           
        .bvalid_i          (bvalid_i),                                 
        .bresp_i           (bresp_i),                                 
        .bid_i             (bid_i),                                 

        .arready_i         (arready_i),                            
        .arvalid_o         (arvalid_o),                            
        .araddr_o          (araddr_o),                           
        .arid_o            (arid_o),                         
        .arlen_o           (arlen_o),                          
        .arsize_o          (arsize_o),                           
        .arburst_o         (arburst_o),                            

        .rready_o          (rready_o),                           
        .rvalid_i          (rvalid_i),                           
        .rresp_i           (rresp_i),                          
        .rdata_i           (rdata_i),                          
        .rlast_i           (rlast_i),                          
        .rid_i             (rid_i)
    );

endmodule
