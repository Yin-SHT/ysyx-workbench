`include "defines.v"

module inst_mem (
  input   rst,

  // Signal From Inst_Fetch
  input   [`INST_ADDR_BUS] pc_i,

  // Signal To Inst_Decode
  output  [`INST_DATA_BUS] inst_o
);

  import "DPI-C" function int paddr_read(input int raddr, input int len);

  reg [`INST_DATA_BUS] rdata;

  always @( * ) begin
    if ( rst == `RST_ENABLE ) begin
      rdata = `ZERO_WORD;
    end else begin
      rdata = paddr_read( pc_i, 4 );
    end
  end

  assign inst_o = rdata;

endmodule
