`include "defines.v"

module ifu_reg (
  input clock,
  input reset,

  input pc_we_i,       
  input rdata_we_i,       

  input [`NPC_ADDR_BUS] next_pc_i,

  output reg [`NPC_ADDR_BUS] snpc_o,

  output reg [`NPC_ADDR_BUS] pc_o,
  output reg [`NPC_DATA_BUS] rdata_o,

  // AR
  output [`AXI4_ARID_BUS]    arid_o,       // identifier tag
  output [`AXI4_ARLEN_BUS]   arlen_o,      // length of data transfer
  output [`AXI4_ARSIZE_BUS]  arsize_o,     // number of bytes in one data transfer
  output [`AXI4_ARBURST_BUS] arburst_o,    // burst type

  // R
  input [`NPC_DATA_BUS] rdata_i
);

  assign arid_o    = 0;
  assign arlen_o   = 0;
  assign arsize_o  = ( reset == `RESET_ENABLE ) ? 0 : 3'b010;
  assign arburst_o = ( reset == `RESET_ENABLE ) ? 0 : 2'b01;

  always @( posedge clock or negedge reset ) begin
    pc_o   <= pc_o;
    snpc_o <= snpc_o;
    if ( reset == `RESET_ENABLE ) begin
      pc_o   <= `RESET_VECTOR;
      snpc_o <= `RESET_VECTOR;
    end else if ( pc_we_i == `WRITE_ENABLE ) begin
      pc_o   <= next_pc_i;
      snpc_o <= next_pc_i + 4;
    end else begin
      pc_o   <= pc_o;
      snpc_o <= snpc_o;
    end
  end

  always @( posedge clock or negedge reset ) begin
    rdata_o <= rdata_o;
    if ( reset == `RESET_ENABLE ) begin
      rdata_o <= `NPC_ZERO_DATA;
    end else if ( rdata_we_i == `WRITE_ENABLE ) begin
      rdata_o <= rdata_i;
    end else begin
      rdata_o <= rdata_o;
    end
  end

endmodule // pc_reg
