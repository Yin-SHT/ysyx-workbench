`include "defines.v"

module execute (
    input                      rst,

    input   [`INST_ADDR_BUS]   snpc_i,
    input   [`ALU_OP_BUS]      alu_op_i,
    input   [`REG_DATA_BUS]    operand1_i,
    input   [`REG_DATA_BUS]    operand2_i,
    input                      wena_i,
    input   [`REG_ADDR_BUS]    waddr_i,

    input   [`REG_DATA_BUS]    j_target_i,

    output  [`REG_DATA_BUS]    result_o,
    output                     wena_o,
    output  [`REG_ADDR_BUS]    waddr_o,
    output  [`INST_ADDR_BUS]   dnpc_o
);

    assign  dnpc_o      =   ( rst == 1'b1 )                                             ? `PC_START  :
                            ( alu_op_i == `ALU_OP_JAL  ) | ( alu_op_i == `ALU_OP_JALR ) ? j_target_i : snpc_i;         

    assign  result_o    =   ( rst == 1'b1              ) ?   `ZERO_WORD              :
                            ( alu_op_i == `ALU_OP_ADD  ) ?   operand1_i + operand2_i :   
                            ( alu_op_i == `ALU_OP_JAL  ) ?                operand2_i : 
                            ( alu_op_i == `ALU_OP_JALR ) ?                operand2_i :  
                            ( alu_op_i == `ALU_OP_NOP  ) ?   `ZERO_WORD              : `ZERO_WORD;

    assign  waddr_o = waddr_i;
    assign  wena_o  = wena_i;

endmodule
