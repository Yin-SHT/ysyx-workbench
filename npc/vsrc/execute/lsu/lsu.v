`include "defines.v"

module lsu (
  input                      clock,
  input                      reset,

  input [`LSU_OP_BUS]        lsu_op_i,

  input [`REG_DATA_BUS]      imm_i,
  input [`REG_DATA_BUS]      rdata1_i,
  input [`REG_DATA_BUS]      rdata2_i,

  input                      rdata_we_i,

  // t: wbu
  output reg [`MEM_ADDR_BUS] mem_result_o,

  // AW: Address Write Channel
  output [`AXI4_AWADDR_BUS]  awaddr_o,
  output [`AXI4_AWID_BUS]    awid_o,
  output [`AXI4_AWLEN_BUS]   awlen_o,
  output [`AXI4_AWSIZE_BUS]  awsize_o,
  output [`AXI4_AWBURST_BUS] awburst_o,

  //  W: Data Write Channel
  output [`AXI4_WDATA_BUS]   wdata_o,
  output [`AXI4_WSTRB_BUS]   wstrb_o,
  output                     wlast_o,

  // AR: Address Read Channel
  output [`AXI4_ARADDR_BUS]  araddr_o,
  output [`AXI4_ARID_BUS]    arid_o,
  output [`AXI4_ARLEN_BUS]   arlen_o,
  output [`AXI4_ARSIZE_BUS]  arsize_o,
  output [`AXI4_ARBURST_BUS] arburst_o,

  //  R: Read Channel
  input  [`AXI4_RDATA_BUS]   rdata_i
);
  
  wire[31:0] address = rdata1_i + imm_i;
  
  wire[31:0] byte_lane  = address % 4;

  /* Write operation */

  assign awaddr_o   = address;
  assign awid_o     = 0;
  assign awlen_o    = 0;
  assign awsize_o   = ( lsu_op_i == `LSU_OP_SB ) ? 3'b000 :
                      ( lsu_op_i == `LSU_OP_SH ) ? 3'b001 :
                      ( lsu_op_i == `LSU_OP_SW ) ? 3'b010 : 0;
  assign awburst_o  = 2'b01;

  always @( * ) begin
    if ( lsu_op_i == `LSU_OP_SB ) begin
      case ( byte_lane )
        0: wdata_o = {24'h0, rdata2_i[7:0]}; 
        1: wdata_o = {16'h0, rdata2_i[7:0],  8'h0}; 
        2: wdata_o = { 8'h0, rdata2_i[7:0], 16'h0}; 
        3: wdata_o = {rdata2_i[7:0], 24'h0}; 
        default: wdata_o = 0;
      endcase
    end else if ( lsu_op_i == `LSU_OP_SH ) begin
      case ( byte_lane )
        0: wdata_o = {16'h0, rdata2_i[15:0]}; 
        2: wdata_o = {rdata2_i[15:0], 16'h0}; 
        default: wdata_o = 0;
      endcase
    end else if ( lsu_op_i == `LSU_OP_SW ) begin
      case ( byte_lane )
        0: wdata_o = rdata2_i; 
        default: wdata_o = 0;
      endcase
    end else begin
      wdata_o = 0;
    end
  end

  always @( * ) begin
    if ( lsu_op_i == `LSU_OP_SB ) begin
      case ( byte_lane )
        0: wstrb_o = 4'b0001;  
        1: wstrb_o = 4'b0010;  
        2: wstrb_o = 4'b0100;  
        3: wstrb_o = 4'b1000;  
        default: wstrb_o = 0;
      endcase
    end else if ( lsu_op_i == `LSU_OP_SH ) begin
      case ( byte_lane )
        0: wstrb_o = 4'b0011; 
        2: wstrb_o = 4'b1100; 
        default: wstrb_o = 0;
      endcase
    end else if ( lsu_op_i == `LSU_OP_SW ) begin
      case ( byte_lane )
        0: wstrb_o = 4'b1111; 
        default: wstrb_o = 0;
      endcase
    end else begin
      wstrb_o = 0;
    end
  end

  assign wlast_o = 1;

  /* Read operation */
  assign araddr_o   = address;
  assign arid_o     = 0;
  assign arlen_o    = 0;
  assign arsize_o   = ( lsu_op_i == `LSU_OP_LB  ) ? 3'b000 :
                      ( lsu_op_i == `LSU_OP_LBU ) ? 3'b000 :
                      ( lsu_op_i == `LSU_OP_LH  ) ? 3'b001 :
                      ( lsu_op_i == `LSU_OP_LHU ) ? 3'b001 :
                      ( lsu_op_i == `LSU_OP_LW  ) ? 3'b010 : 0;
  assign arburst_o  = 2'b01;

  always @(posedge clock) begin
    if (reset) begin
      mem_result_o <= 0;
    end else if ( rdata_we_i ) begin
      if ( lsu_op_i == `LSU_OP_LB ) begin
        case ( byte_lane )
          0: mem_result_o <= {{24{rdata_i[7 ]}}, rdata_i[7 :0 ]};
          1: mem_result_o <= {{24{rdata_i[15]}}, rdata_i[15:8 ]}; 
          2: mem_result_o <= {{24{rdata_i[23]}}, rdata_i[23:16]}; 
          3: mem_result_o <= {{24{rdata_i[31]}}, rdata_i[31:24]}; 
          default: mem_result_o <= mem_result_o;
        endcase
      end else if ( lsu_op_i == `LSU_OP_LBU ) begin
        case ( byte_lane )
          0: mem_result_o <= {24'h0, rdata_i[7 :0 ]};
          1: mem_result_o <= {24'h0, rdata_i[15:8 ]}; 
          2: mem_result_o <= {24'h0, rdata_i[23:16]}; 
          3: mem_result_o <= {24'h0, rdata_i[31:24]}; 
          default: mem_result_o <= mem_result_o;
        endcase
      end else if ( lsu_op_i == `LSU_OP_LH ) begin
        case ( byte_lane )
          0: mem_result_o <= {{16{rdata_i[15]}}, rdata_i[15:0 ]}; 
          2: mem_result_o <= {{16{rdata_i[31]}}, rdata_i[31:16]}; 
          default: mem_result_o <= mem_result_o;
        endcase
      end else if ( lsu_op_i == `LSU_OP_LHU ) begin
        case ( byte_lane )
          0: mem_result_o <= {16'h0, rdata_i[15:0 ]}; 
          2: mem_result_o <= {16'h0, rdata_i[31:16]}; 
          default: mem_result_o <= mem_result_o;
        endcase
      end else if ( lsu_op_i == `LSU_OP_LW ) begin
        case ( byte_lane )
          0: mem_result_o <= rdata_i; 
          default: mem_result_o <= mem_result_o;
        endcase
      end else begin
        mem_result_o <= mem_result_o;
      end
    end
  end

endmodule
