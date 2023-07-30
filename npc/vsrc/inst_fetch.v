`include "defines.v"

module inst_fetch (
    input   clk,
    input   rst,

    input   [`INST_ADDR_BUS]        next_pc,
    output  reg [`INST_ADDR_BUS]    pc
);

    always @( posedge clk ) begin
        if ( rst == 1'b1 ) begin
            pc <= `PC_START;
        end else begin
            pc <= next_pc;
        end
    end
    
endmodule
