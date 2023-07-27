`include "defines.v"

module regfile(
    input                               clk,
    input                               rst,

	input [ `REG_WIDTH      - 1 : 0 ] 	wdata_i,
	input [ `REG_ADDR_WIDTH - 1 : 0 ]   waddr_i,
	input   		  		            wena_i,
	
	input [ `REG_ADDR_WIDTH - 1 : 0 ]               raddr1_i,
	input   		  		            rena1_i,
	
	input [ `REG_ADDR_WIDTH - 1 : 0 ]               raddr2_i,
	input   		  		            rena2_i,

	output reg [ `REG_WIDTH - 1 : 0 ]               rf_data1_o,
	output reg [ `REG_WIDTH - 1 : 0 ] 	            rf_data2_o
);

    integer i ;

    reg [ `REG_WIDTH - 1 : 0 ] regs [31 : 0];

    always @(posedge clk ) begin
        if( rst == 1'b1 ) begin
            regs[0] <= `ZERO_WORD ;
            for(i=1; i<32; i=i+1) begin
                regs[i] <= `ZERO_WORD ;
            end
        end else begin
            if( ( wena_i == 1'b1 ) && ( waddr_i != 0 ) ) begin
                regs[waddr_i] <= wdata_i ;
            end
        end
    end

    always @( * ) begin
        if( rst == 1'b1 ) begin
            rf_data1_o = `ZERO_WORD ;
        end
        else if( rena1_i ) begin
            rf_data1_o = regs[raddr1_i];
        end else begin
            rf_data1_o = `ZERO_WORD;
        end
    end

    always @(*) begin
        if (rst == 1'b1)
            rf_data2_o = `ZERO_WORD;
        else if (rena2_i == 1'b1)
            rf_data2_o = regs[raddr2_i];
        else
            rf_data2_o = `ZERO_WORD;
    end

endmodule

