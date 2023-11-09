`include "../defines.v"

module pc_reg (
  input clk,
  input rst,

  /* IDU controller */
  input                       we,       // write enable 

  input [`INST_ADDR_BUS]      next_pc,

  output reg [`INST_ADDR_BUS] pc
);

  reg Reset;

  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      pc <= 32'h8000_0000;
      Reset <= 1'b1;
    end else begin
      pc <= pc;
      if ( we == `WRITE_ENABLE ) begin
        if ( Reset ) begin
          pc <= 32'h8000_0000;
          Reset <= 1'b0;
        end else begin
          pc <= next_pc;
          Reset <= 1'b0;
        end
      end
    end
  end

endmodule // pc_reg
