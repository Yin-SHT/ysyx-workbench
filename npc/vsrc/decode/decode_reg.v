`include "defines.v"

module decode_reg (
    input           clock,
    input           reset,

    input           we_i,

    input  [31:0]   pc_i,
    input  [31:0]   inst_i,

    output [31:0]   pc_o,
    output [31:0]   inst_o 
);
    
    reg [31:0] pc;
    reg [31:0] inst; 

    assign pc_o   = pc;
    assign inst_o = inst;

    always @(posedge clock) begin
        if (reset) begin
            pc   <= 0;
            inst <= 0;
        end else if (we_i) begin
            pc   <= pc_i;
            inst <= inst_i;
        end
    end

endmodule 
