`include "../defines.v"

module ifu_reg (
  input clk,
  input rst,

  /* IDU controller */
  input                       we_i,       // write enable 

  input  [`INST_ADDR_BUS]     next_pc_i,

  output reg [`INST_ADDR_BUS] araddr_o
);

  reg Reset;

  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      araddr_o <= `RST_PC;
      Reset    <= 1'b1;
    end else begin
      araddr_o <= araddr_o;
      if ( we_i == `WRITE_ENABLE ) begin
        if ( Reset ) begin
          araddr_o <= `RST_PC;
          Reset    <= 1'b0;
        end else begin
          araddr_o <= next_pc_i;
          Reset    <= 1'b0;
        end
      end
    end
  end

endmodule // pc_reg
