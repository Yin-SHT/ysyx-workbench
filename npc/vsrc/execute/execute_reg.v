`include "defines.v"

module execute_reg (
    input                    clock,
    input                    reset,

    input                    we_i,        

    input [`INST_TYPE_BUS]   inst_type_i,
    input [`ALU_OP_BUS]      alu_op_i,
    input [`LSU_OP_BUS]      lsu_op_i,
    input [`CSR_OP_BUS]      csr_op_i,
    input                    wsel_i,
    input                    wena_i,
    input [`REG_ADDR_BUS]    waddr_i,
    input                    csr_wena_i,
    input [31:0]             csr_waddr_i,
    input [`NPC_ADDR_BUS]    pc_i,
    input [`REG_DATA_BUS]    imm_i,
    input [`REG_DATA_BUS]    rdata1_i,
    input [`REG_DATA_BUS]    rdata2_i,
    input [`CSR_DATA_BUS]    csr_rdata_i,

    output [`INST_TYPE_BUS]  inst_type_o,         
    output [`ALU_OP_BUS]     alu_op_o,         
    output [`LSU_OP_BUS]     lsu_op_o,         
    output [`CSR_OP_BUS]     csr_op_o,         
    output                   wsel_o,         
    output                   wena_o,         
    output [`REG_ADDR_BUS]   waddr_o,         
    output                   csr_wena_o,         
    output [31:0]            csr_waddr_o,         
    output [`NPC_ADDR_BUS]   pc_o,         
    output [`REG_DATA_BUS]   imm_o,         
    output [`REG_DATA_BUS]   rdata1_o,         
    output [`REG_DATA_BUS]   rdata2_o,         
    output [`CSR_DATA_BUS]   csr_rdata_o         
);         

    reg [`INST_TYPE_BUS]  inst_type;
    reg [`ALU_OP_BUS]     alu_op;
    reg [`LSU_OP_BUS]     lsu_op;
    reg [`CSR_OP_BUS]     csr_op;
    reg                   wsel;
    reg                   wena;
    reg [`REG_ADDR_BUS]   waddr;
    reg                   csr_wena;
    reg [31:0]            csr_waddr;
    reg [`NPC_ADDR_BUS]   pc;
    reg [`REG_DATA_BUS]   imm;
    reg [`REG_DATA_BUS]   rdata1;
    reg [`REG_DATA_BUS]   rdata2;
    reg [`CSR_DATA_BUS]   csr_rdata;

    assign inst_type_o = inst_type;
    assign alu_op_o    = alu_op;
    assign lsu_op_o    = lsu_op;
    assign csr_op_o    = csr_op;
    assign wsel_o      = wsel;
    assign wena_o      = wena;
    assign waddr_o     = waddr;
    assign csr_wena_o  = csr_wena;
    assign csr_waddr_o = csr_waddr;
    assign pc_o        = pc;
    assign imm_o       = imm;
    assign rdata1_o    = rdata1;
    assign rdata2_o    = rdata2;
    assign csr_rdata_o = csr_rdata;
    
    always @(posedge clock) begin
        if (reset) begin
            inst_type <= 0;               
            alu_op    <= 0;            
            lsu_op    <= 0;            
            csr_op    <= 0;            
            wsel      <= 0;          
            wena      <= 0;          
            waddr     <= 0;           
            csr_wena  <= 0;              
            csr_waddr <= 0;               
            pc        <= 0;        
            imm       <= 0;         
            rdata1    <= 0;            
            rdata2    <= 0;            
            csr_rdata <= 0;               
        end else if (we_i) begin
            inst_type <= inst_type_i;               
            alu_op    <= alu_op_i;            
            lsu_op    <= lsu_op_i;            
            csr_op    <= csr_op_i;            
            wsel      <= wsel_i;          
            wena      <= wena_i;          
            waddr     <= waddr_i;           
            csr_wena  <= csr_wena_i;              
            csr_waddr <= csr_waddr_i;
            pc        <= pc_i;        
            imm       <= imm_i;         
            rdata1    <= rdata1_i;            
            rdata2    <= rdata2_i;            
            csr_rdata <= csr_rdata_i;               
        end
    end

endmodule 
