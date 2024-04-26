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

  export "DPI-C" function fetchreg_event;
  function fetchreg_event;
    output int pc;
    pc = pc_o;
  endfunction

  // AR
  assign arid_o    = reset ? 0 : 0;
  assign arlen_o   = reset ? 0 : 0;
  assign arsize_o  = reset ? 0 : 3'b010;
  assign arburst_o = reset ? 0 : 2'b01;

  wire[31:0] address = pc_o;
  wire[31:0] byte_lane  = address % 8;

  always @(posedge clock) begin
    pc_o <= pc_o;   // default
    if (reset) begin
      pc_o <= `RESET_VECTOR - 4;
    end else if (pc_we_i) begin
      if (branch_en_i) begin
        pc_o <= dnpc_i; 
      end else begin
        pc_o <= pc_o + 4;
      end
    end 
  end

  always @(posedge clock) begin
    inst_o <= inst_o;   // default
    if (reset) begin
      inst_o <= `NPC_ZERO_DATA;
    end else if (inst_we_i) begin
      case (byte_lane)
        0: inst_o <= rdata_i[31:0];
        4: inst_o <= rdata_i[63:32];
        default: begin
          $fatal("0x%08x is not align\n", address);
        end
      endcase
    end 
  end

endmodule // pc_reg
