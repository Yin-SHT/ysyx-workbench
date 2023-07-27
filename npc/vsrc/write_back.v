`include "defines.v"

module write_back (
    input  rst,

    input   [ `INST_ADDR_WIDTH - 1 : 0 ]    pc_i,
    output  [ `INST_ADDR_WIDTH - 1 : 0 ]    pc_o,

    input  [ `REG_WIDTH      - 1 : 0 ]     result_i,
    input  [ `REG_ADDR_WIDTH - 1 : 0 ]     waddr_i,
    input                                  wena_i,

    output [ `REG_WIDTH      - 1 : 0 ]     wdata_o,
    output [ `REG_ADDR_WIDTH - 1 : 0 ]     waddr_o,
    output                                 wena_o
);

    assign pc_o = pc_i;

    assign wdata_o =  ( rst == 1'b1 ) ? `ZERO_WORD : result_i;
    assign waddr_o  = ( rst == 1'b1 ) ? 5'b0       : waddr_i;
    assign wena_o   = ( rst == 1'b1 ) ? 1'b0       : wena_i;
    
endmodule
