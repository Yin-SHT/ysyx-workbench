`include "defines.v"

module csr (
    input  [`CSR_OP_BUS]   csr_op_i,
    input  [`REG_DATA_BUS] rdata1_i,
    input  [`CSR_DATA_BUS] csr_rdata_i,
    input  [31:0]          pc_i,

    output [`CSR_DATA_BUS] csr_wdata_o 
);

    assign csr_wdata_o  =   (csr_op_i == `CSR_OP_CSRRW) ? rdata1_i :
                            (csr_op_i == `CSR_OP_CSRRS) ? rdata1_i | csr_rdata_i :
                            (csr_op_i == `CSR_OP_ECALL) ? pc_i : 0;

endmodule
