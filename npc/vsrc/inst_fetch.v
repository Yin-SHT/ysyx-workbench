`include "defines.v"

module inst_fetch (
    input   clk,
    input   rst,

    // Signal From Addr_Transfer
    input   [`INST_ADDR_BUS]        next_pc,

    // Signal To Inst_Mem
    output  reg [`INST_ADDR_BUS]    pc
);

    always @( posedge clk ) begin
        if ( rst == `RST_ENABLE ) begin
            pc <= `RESET_PC;
        end else begin
            pc <= next_pc;
        end
    end

endmodule
