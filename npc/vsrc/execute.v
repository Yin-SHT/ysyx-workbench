`include "defines.v"

module execute (
    input                                  rst,

    input   [ `INST_ADDR_WIDTH - 1 : 0 ]    pc_i,
    output  [ `INST_ADDR_WIDTH - 1 : 0 ]    pc_o,

    input  [ `ALU_OP_WIDTH - 1 : 0 ]       alu_op_i,
    input  [ `REG_WIDTH - 1 : 0 ]          operand1_i,
    input  [ `REG_WIDTH - 1 : 0 ]          operand2_i,
    input  [ `REG_ADDR_WIDTH - 1 : 0 ]     waddr_i,
    input                                  wena_i,

    output [ `REG_WIDTH - 1 : 0 ]          result_o,
    output [ `REG_ADDR_WIDTH - 1 : 0 ]     waddr_o,
    output                                 wena_o
);

    assign pc_o = pc_i + 4;

    wire [ `REG_WIDTH - 1 : 0 ] alu_result;

    assign alu_result = ( rst == 1'b1             ) ?   `ZERO_WORD              :
                        ( alu_op_i == `ALU_OP_ADD ) ?   operand1_i + operand2_i :
                                                        `ZERO_WORD              ;

    assign result_o = alu_result;
    assign waddr_o  = waddr_i;
    assign wena_o   = wena_i;

endmodule
