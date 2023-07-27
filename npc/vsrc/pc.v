`include "defines.v"

module pc (
    input   clk,
    input   rst,

    input   [ `INST_ADDR_WIDTH - 1 : 0 ]    pc_next,
    output  reg [ `INST_ADDR_WIDTH - 1 : 0 ]    pc
);

    always @( posedge clk ) begin
        if ( rst == 1'b1 ) begin
            pc <= `PC_START;
        end else begin
            pc <= pc_next;
        end
    end
    
endmodule
