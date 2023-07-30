`include "defines.v"

module write_back (
    input  rst,

    input   [`INST_ADDR_BUS]    dnpc_i,
    output  [`INST_ADDR_BUS]    dnpc_o,

    input   [`REG_DATA_BUS]     result_i,
    input                       wena_i,
    input   [`REG_ADDR_BUS]     waddr_i,

    output  [`REG_DATA_BUS]     wdata_o,
    output                      wena_o,
    output  [`REG_ADDR_BUS]     waddr_o
);

    assign dnpc_o = dnpc_i;

    assign wdata_o  =   ( rst == 1'b1 ) ?   `ZERO_WORD      : result_i;
    assign wena_o   =   ( rst == 1'b1 ) ?   `WRITE_DISABLE  : wena_i;
    assign waddr_o  =   ( rst == 1'b1 ) ?   `ZERO_REG       : waddr_i;
    
endmodule
