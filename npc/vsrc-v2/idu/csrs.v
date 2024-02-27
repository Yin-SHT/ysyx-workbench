`include "defines.v"

`define MSTATUS      32'h0000_0300
`define MTVEC        32'h0000_0305
`define MEPC         32'h0000_0341
`define MCAUSE       32'h0000_0342
`define ECALL_FROM_M 32'h0000_000b

module csrs (
  input                  reset,

  input [`CSR_OP_BUS]    csr_op_i,
  input [`NPC_ADDR_BUS]  pc_i,
  input [`REG_DATA_BUS]  imm_i,
  input [`REG_DATA_BUS]  rdata1_i,
  
  output [`CSR_DATA_BUS] csr_o,
  output [`CSR_DATA_BUS] csr_pc_o
);

  reg [`CSR_DATA_BUS] mstatus = 32'h0000_0000;
  reg [`CSR_DATA_BUS] mtvec   = 32'h0000_0000;
  reg [`CSR_DATA_BUS] mepc    = 32'h0000_0000;
  reg [`CSR_DATA_BUS] mcause  = 32'h0000_0000;

  /* CSRRW & CSRRS */
  assign  csr_o = (( reset == `RESET_DISABLE ) && (( csr_op_i == `CSR_OP_CSRRW ) || ( csr_op_i == `CSR_OP_CSRRS )) && ( imm_i == `MSTATUS )) ? mstatus       :
                  (( reset == `RESET_DISABLE ) && (( csr_op_i == `CSR_OP_CSRRW ) || ( csr_op_i == `CSR_OP_CSRRS )) && ( imm_i == `MTVEC   )) ? mtvec         :
                  (( reset == `RESET_DISABLE ) && (( csr_op_i == `CSR_OP_CSRRW ) || ( csr_op_i == `CSR_OP_CSRRS )) && ( imm_i == `MEPC    )) ? mepc          :
                  (( reset == `RESET_DISABLE ) && (( csr_op_i == `CSR_OP_CSRRW ) || ( csr_op_i == `CSR_OP_CSRRS )) && ( imm_i == `MCAUSE  )) ? mcause        :
                                                                                                                                               0             ;
  always @( * ) begin
    if (( reset == `RESET_DISABLE ) && ( csr_op_i == `CSR_OP_CSRRW )) begin
      case ( imm_i )
        `MSTATUS: mstatus = rdata1_i;
        `MTVEC:   mtvec   = rdata1_i;
        `MEPC:    mepc    = rdata1_i;
        `MCAUSE:  mcause  = rdata1_i;
      endcase     
    end else if (( reset == `RESET_DISABLE ) && ( csr_op_i == `CSR_OP_CSRRW )) begin
      case ( imm_i )
        `MSTATUS: mstatus = rdata1_i | mstatus;
        `MTVEC:   mtvec   = rdata1_i | mtvec;
        `MEPC:    mepc    = rdata1_i | mepc;
        `MCAUSE:  mcause  = rdata1_i | mcause;
      endcase     
    end else if (( reset == `RESET_DISABLE ) && ( csr_op_i == `CSR_OP_ECALL )) begin
        mepc    = pc_i;
        mcause  = 11;
    end 
  end

  /* ECALL */
  assign csr_pc_o = ( reset == `RESET_DISABLE ) && ( csr_op_i == `CSR_OP_ECALL ) ?  mtvec         :
                    ( reset == `RESET_DISABLE ) && ( csr_op_i == `CSR_OP_MRET  ) ?  mepc          :
                                                                                    0             ;
 

endmodule
