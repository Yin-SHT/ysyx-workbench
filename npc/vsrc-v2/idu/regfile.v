`include "../defines.v"

module regfile(
  input                     clk,
  input                     rst,

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
  always @( posedge clk or negedge rst ) begin
    if( rst == `RST_ENABLE ) begin
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
                      ( rst      == `RST_ENABLE   ) || 
                      ( rena1_i  == `READ_DISABLE ) || 
                      ( raddr1_i == `ZERO_REG     ) 
                    ) ? 32'h0000_0000 : regs[raddr1_i]; 

  assign rdata2_o = ( 
                      ( rst      == `RST_ENABLE   ) || 
                      ( rena2_i  == `READ_DISABLE ) || 
                      ( raddr2_i == `ZERO_REG     ) 
                    ) ? 32'h0000_0000 : regs[raddr2_i]; 

endmodule
