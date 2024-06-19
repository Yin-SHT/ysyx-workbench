`include "defines.v"

module userreg (
    input           clock,
    input           reset,

	input   	    wena_i,
	input  [4:0]    waddr_i,
	input  [31:0]   wdata_i,
	
	input   		rena1_i,
	input  [4:0]    raddr1_i,
	output [31:0]   rdata1_o,
	
	input   		rena2_i,
	input  [4:0]    raddr2_i,
	output [31:0]   rdata2_o
);

    export "DPI-C" function userreg_event;
    function userreg_event;
        output int halt_ret;
        halt_ret = UREGS[10];
    endfunction

    reg[31:0] UREGS[31:0];

    always @(posedge clock) begin
        if (!reset) begin
            if(wena_i && (waddr_i != 0)) begin
                UREGS[waddr_i] <= wdata_i;
            end
        end
    end

    assign rdata1_o = rena1_i ? UREGS[raddr1_i] : 0;
    assign rdata2_o = rena2_i ? UREGS[raddr2_i] : 0;

endmodule
