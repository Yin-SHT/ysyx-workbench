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
  
    wire                    we;
    wire [`INST_TYPE_BUS]   inst_type;
    wire [`ALU_OP_BUS]      alu_op;
    wire [`LSU_OP_BUS]      lsu_op;
    wire [`CSR_OP_BUS]      csr_op;
    wire                    wsel;
    wire                    wena;
    wire [`REG_ADDR_BUS]    waddr;
    wire                    csr_wena;
    wire [31:0]             csr_waddr;
    wire [`NPC_ADDR_BUS]    pc;
    wire [`REG_DATA_BUS]    imm;
    wire [`REG_DATA_BUS]    rdata1;
    wire [`REG_DATA_BUS]    rdata2;
    wire [`CSR_DATA_BUS]    csr_rdata;
    wire                    access_begin;
    wire                    access_done;

    assign wsel_o      = wsel;
    assign wena_o      = wena;
    assign waddr_o     = waddr;
    assign csr_op_o    = csr_op;
    assign csr_wena_o  = csr_wena;
    assign csr_waddr_o = csr_waddr;

    execute_controller controller (
        .clock          (clock),
        .reset          (reset),

        .valid_pre_i    (valid_pre_i),
        .ready_pre_o    (ready_pre_o),

        .valid_post_o   (valid_post_o),
        .ready_post_i   (ready_post_i),

        .inst_type_i    (inst_type_i),

        .access_begin_o (access_begin),
        .access_done_i  (access_done),

        .we_o           (we)
    );
    
    execute_reg reg0 (
        .clock          (clock),
        .reset          (reset),

        .we_i           (we),

        .inst_type_i    (inst_type_i),
        .alu_op_i       (alu_op_i),
        .lsu_op_i       (lsu_op_i),
        .csr_op_i       (csr_op_i),
        .wsel_i         (wsel_i),
        .wena_i         (wena_i),
        .waddr_i        (waddr_i),
        .csr_wena_i     (csr_wena_i),
        .csr_waddr_i    (csr_waddr_i),
        .pc_i           (pc_i),
        .imm_i          (imm_i),
        .rdata1_i       (rdata1_i),
        .rdata2_i       (rdata2_i),
        .csr_rdata_i    (csr_rdata_i),

        .inst_type_o    (inst_type),
        .alu_op_o       (alu_op),
        .lsu_op_o       (lsu_op),
        .csr_op_o       (csr_op),
        .wsel_o         (wsel),
        .wena_o         (wena),
        .waddr_o        (waddr),
        .csr_wena_o     (csr_wena),
        .csr_waddr_o    (csr_waddr),
        .pc_o           (pc),
        .imm_o          (imm),
        .rdata1_o       (rdata1),
        .rdata2_o       (rdata2),
        .csr_rdata_o    (csr_rdata)
    );
    
    fu fu0 (
        .reset          (reset),
                        
        .inst_type_i    (inst_type),
        .alu_op_i       (alu_op),
        .csr_op_i       (csr_op),
        .pc_i           (pc),
        .imm_i          (imm),
        .rdata1_i       (rdata1),
        .rdata2_i       (rdata2),
        .csr_rdata_i    (csr_rdata),
                        
        .alu_result_o   (alu_result_o),
        .csr_wdata_o    (csr_wdata_o)
    );
    
    lsu lsu0 (
        .clock          (clock),
        .reset          (reset),
       
        .inst_type_i    (inst_type),
        .lsu_op_i       (lsu_op),
        .imm_i          (imm),
        .rdata1_i       (rdata1),
        .rdata2_i       (rdata2),
        
        .access_begin_i (access_begin),
        .access_done_o  (access_done),

        .mem_result_o   (mem_result_o),

        .awready_i      (awready_i),                                 
        .awvalid_o      (awvalid_o),                            
        .awaddr_o       (awaddr_o),                           
        .awid_o         (awid_o),                         
        .awlen_o        (awlen_o),                          
        .awsize_o       (awsize_o),                           
        .awburst_o      (awburst_o),                            

        .wready_i       (wready_i),                                 
        .wvalid_o       (wvalid_o),                           
        .wdata_o        (wdata_o),                          
        .wstrb_o        (wstrb_o),                          
        .wlast_o        (wlast_o),                          

        .bready_o       (bready_o),                           
        .bvalid_i       (bvalid_i),                                 
        .bresp_i        (bresp_i),                                 
        .bid_i          (bid_i),                                 

        .arready_i      (arready_i),                            
        .arvalid_o      (arvalid_o),                            
        .araddr_o       (araddr_o),                           
        .arid_o         (arid_o),                         
        .arlen_o        (arlen_o),                          
        .arsize_o       (arsize_o),                           
        .arburst_o      (arburst_o),                            

        .rready_o       (rready_o),                           
        .rvalid_i       (rvalid_i),                           
        .rresp_i        (rresp_i),                          
        .rdata_i        (rdata_i),                          
        .rlast_i        (rlast_i),                          
        .rid_i          (rid_i)
    );

endmodule
