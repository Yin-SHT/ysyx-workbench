`include "defines.v"

module fetch_reg (
  input                      clock,
  input                      reset,

  input                      pc_we_i,       
  input                      inst_we_i,       

  input                      branch_en_i, 
  input  [`NPC_ADDR_BUS]     dnpc_i,

  output reg [`NPC_ADDR_BUS] pc_o,
  output reg [`NPC_DATA_BUS] inst_o,

  // AR
  output [`AXI4_ARID_BUS]    arid_o,       
  output [`AXI4_ARLEN_BUS]   arlen_o,      
  output [`AXI4_ARSIZE_BUS]  arsize_o,     
  output [`AXI4_ARBURST_BUS] arburst_o, 

  // R
  input [`AXI4_RDATA_BUS]    rdata_i
);

  // AR
  assign arid_o    = ( reset == `RESET_ENABLE ) ? 0 : 0;
  assign arlen_o   = ( reset == `RESET_ENABLE ) ? 0 : 0;
  assign arsize_o  = ( reset == `RESET_ENABLE ) ? 0 : 3'b010;
  assign arburst_o = ( reset == `RESET_ENABLE ) ? 0 : 2'b01;

  always @( posedge clock or negedge reset ) begin
    pc_o <= pc_o;   // default
    if ( reset ) begin
      pc_o <= `RESET_VECTOR;
    end else if ( pc_we_i ) begin
      if ( branch_en_i ) begin
        pc_o <= dnpc_i; 
      end else begin
        pc_o <= pc_o + 4;
      end
    end 
  end

  always @( posedge clock or negedge reset ) begin
    inst_o <= inst_o;   // default
    if ( reset ) begin
      inst_o <= `NPC_ZERO_DATA;
    end else if ( inst_we_i ) begin
      inst_o <= rdata_i[31:0];
    end 
  end

endmodule // pc_reg
