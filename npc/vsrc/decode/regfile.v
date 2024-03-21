`include "defines.v"

module regfile(
  input                     clock,
  input                     reset,

	input   		  		        wena_i,
	input   [`REG_ADDR_BUS]   waddr_i,
	input   [`REG_DATA_BUS]   wdata_i,
	
	input   		  		        rena1_i,
	input   [`REG_ADDR_BUS]   raddr1_i,
	
	input   		  		        rena2_i,
	input   [`REG_ADDR_BUS]   raddr2_i,

	output  [`REG_DATA_BUS]   rdata1_o,
	output  [`REG_DATA_BUS]   rdata2_o
);

  reg [`REG_DATA_BUS] regs[31 : 0];

  /* WRITE */
  always @( posedge clock or negedge reset ) begin
    if( reset == `RESET_ENABLE ) begin
      for(integer i = 0; i < 32; i = i + 1 ) begin
          regs[i] <= 32'h0000_0000;
      end
    end else begin
      for(integer i = 0; i < 32; i = i + 1 ) begin
          regs[i] <= regs[i];;
      end
      if(( wena_i == `WRITE_ENABLE ) && ( waddr_i != `ZERO_REG )) begin
          regs[waddr_i] <= wdata_i ;
      end else begin
        for(integer i = 0; i < 32; i = i + 1 ) begin
            regs[i] <= regs[i];;
        end
      end
    end
  end

  /* READ */
  assign rdata1_o = ( 
                      ( reset    == `RESET_ENABLE ) || 
                      ( rena1_i  == `READ_DISABLE ) 
                    ) ? 32'h0000_0000 : regs[raddr1_i]; 

  assign rdata2_o = ( 
                      ( reset    == `RESET_ENABLE ) || 
                      ( rena2_i  == `READ_DISABLE )
                    ) ? 32'h0000_0000 : regs[raddr2_i]; 

endmodule
