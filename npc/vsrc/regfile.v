`include "defines.v"

module regfile(
    input                           clk,
    input                           rst,

	input   [`REG_DATA_BUS] 	    wdata_i,
	input   		  		        wena_i,
	input   [`REG_ADDR_BUS]         waddr_i,
	
	input   [`REG_ADDR_BUS]         raddr1_i,
	input   		  		        rena1_i,
	
	input   [`REG_ADDR_BUS]         raddr2_i,
	input   		  		        rena2_i,

	output  reg [`REG_DATA_BUS]     data1_o,
	output  reg [`REG_DATA_BUS]     data2_o
);

    integer i ;

    reg [`REG_DATA_BUS] regs[31 : 0];

    always @( posedge clk ) begin
        if( rst == 1'b1 ) begin
            regs[0] <= `ZERO_WORD ;
            for( i = 1; i < 32; i = i + 1 ) begin
                regs[i] <= `ZERO_WORD;
            end
        end else begin
            if( ( wena_i == `WRITE_ENABLE ) && ( waddr_i != `ZERO_REG ) ) begin
                regs[waddr_i] <= wdata_i ;
            end
        end
    end

    always @( * ) begin
        if( rst == 1'b1 ) begin
            data1_o = `ZERO_WORD ;
        end else if( rena1_i == `READ_ENABLE ) begin
            data1_o = regs[raddr1_i];
        end else begin
            data1_o = `ZERO_WORD;
        end
    end

    always @( * ) begin
        if ( rst == 1'b1 ) begin
            data2_o = `ZERO_WORD;
        end else if ( rena2_i == `READ_ENABLE ) begin
            data2_o = regs[raddr2_i];
        end else begin
            data2_o = `ZERO_WORD;
        end
    end

endmodule
