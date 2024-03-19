`include "defines.v"

module lsu (
  input                      clock,
  input                      reset,

  input [`INST_TYPE_BUS]     inst_type_i,
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
  
  wire [31:0] awoffset;
  wire [31:0] aroffset;

  assign awoffset = awaddr_o % 4;  // 4 bytes: 32 bits
  assign aroffset = araddr_o % 4;  // 4 bytes: 32 bits

  /* Write operation */
  
  // AW 
  assign awaddr_o = ( reset == `RESET_ENABLE ) ? 0 : rdata1_i + imm_i;

  assign awid_o   = 0;

  assign awlen_o  = 0;

  always @( * ) begin
    if ( reset == `RESET_ENABLE ) begin
      awsize_o = 0;
    end else begin
      case ( lsu_op_i )
        `LSU_OP_SB: awsize_o = 3'b000; 
        `LSU_OP_SH: awsize_o = 3'b001; 
        `LSU_OP_SW: awsize_o = 3'b010; 
        default: awsize_o = awsize_o;
      endcase
    end
  end

  always @( * ) begin
    if ( reset == `RESET_ENABLE ) begin
      awburst_o = 0;
    end else begin
      if ( inst_type_i == `INST_STORE ) begin
        awburst_o = 2'b01;
      end else begin
        awburst_o = 0;
      end
    end
  end


  // W
  assign wlast_o  = 1;

  always @( * ) begin
    if ( reset == `RESET_ENABLE ) begin
      wdata_o = 0;
    end else begin
      if ( inst_type_i == `INST_STORE ) begin
        if ( lsu_op_i == `LSU_OP_SB ) begin
          case ( awoffset )
            0: wdata_o = {32'h0000_0000, 24'h00_0000,  rdata2_i[7:0]             };
            1: wdata_o = {32'h0000_0000, 16'h0000,     rdata2_i[7:0], 8'h00      };
            2: wdata_o = {32'h0000_0000, 8'h0000_0000, rdata2_i[7:0], 16'h0000   };
            3: wdata_o = {32'h0000_0000,               rdata2_i[7:0], 24'h00_0000};
            default: wdata_o = wdata_o;
          endcase
        end else if ( lsu_op_i == `LSU_OP_SH ) begin
          case ( awoffset )
            0: wdata_o = {32'h0000_0000, 16'h0000, rdata2_i[15:0]          };
            2: wdata_o = {32'h0000_0000,           rdata2_i[15:0], 16'h0000};
            default: wdata_o = wdata_o;
          endcase
        end else if ( lsu_op_i == `LSU_OP_SW ) begin
          wdata_o = {32'h0000_0000, rdata2_i};
        end
      end else begin
        wdata_o = wdata_o;
      end
    end
  end

  always @( * ) begin
    if ( reset == `RESET_ENABLE ) begin
      wstrb_o = 0;
    end else begin
      if ( lsu_op_i == `LSU_OP_SB ) begin
        case ( awoffset )
          0: wstrb_o = 8'b0000_0001; 
          1: wstrb_o = 8'b0000_0010; 
          2: wstrb_o = 8'b0000_0100; 
          3: wstrb_o = 8'b0000_1000; 
          default: wstrb_o = wstrb_o;
        endcase
      end else if ( lsu_op_i == `LSU_OP_SH ) begin
        case ( awoffset )
          0: wstrb_o = 8'b0000_0011; 
          2: wstrb_o = 8'b0000_1100; 
          default: wstrb_o = wstrb_o;
        endcase
      end else if ( lsu_op_i == `LSU_OP_SW ) begin
        wstrb_o = 8'b0000_1111;
      end else begin
        wstrb_o = wstrb_o;
      end
    end
  end

  /* Read operation */
  
  // AR
  assign araddr_o = ( reset == `RESET_ENABLE ) ? 0 : rdata1_i + imm_i;

  assign arid_o   = 0;

  assign arlen_o  = 0;
                   
  always @( * ) begin
    if ( reset == `RESET_ENABLE ) begin
      arsize_o = 0;
    end else begin
      case ( lsu_op_i )
        `LSU_OP_LB:  arsize_o = 3'b000; 
        `LSU_OP_LBU: arsize_o = 3'b000; 
        `LSU_OP_LH:  arsize_o = 3'b001; 
        `LSU_OP_LHU: arsize_o = 3'b001; 
        `LSU_OP_LW:  arsize_o = 3'b010; 
        default: arsize_o = arsize_o;
      endcase
    end
  end

  always @( * ) begin
    if ( reset == `RESET_ENABLE ) begin
      arburst_o = 0;
    end else begin
      if ( inst_type_i == `INST_STORE ) begin
        arburst_o = 2'b01;
      end else begin
        arburst_o = 0;
      end
    end
  end

  
  // R
  always @( posedge clock or negedge reset ) begin
    if ( reset == `RESET_ENABLE ) begin
      mem_result_o <= 0;
    end else begin
      if ( rdata_we_i == `WRITE_ENABLE ) begin
        if ( inst_type_i == `LSU_OP_LBU ) begin
          case ( aroffset )
            0: mem_result_o <= {24'h00_0000, rdata_i[7 :0 ]};
            1: mem_result_o <= {24'h00_0000, rdata_i[15:8 ]};
            2: mem_result_o <= {24'h00_0000, rdata_i[23:16]}; 
            3: mem_result_o <= {24'h00_0000, rdata_i[31:24]};
            default: mem_result_o <= mem_result_o;
          endcase
        end if ( inst_type_i == `LSU_OP_LB  ) begin
          case ( aroffset )
            0: mem_result_o <= {{24{rdata_i[7] }}, rdata_i[7 :0 ]};
            1: mem_result_o <= {{24{rdata_i[15]}}, rdata_i[15:8 ]};
            2: mem_result_o <= {{24{rdata_i[23]}}, rdata_i[23:16]}; 
            3: mem_result_o <= {{24{rdata_i[31]}}, rdata_i[31:24]};
            default: mem_result_o <= mem_result_o;
          endcase
        end if ( inst_type_i == `LSU_OP_LHU ) begin
          case ( aroffset )
            0: mem_result_o <= {16'h0000, rdata_i[15:0 ]};
            2: mem_result_o <= {16'h0000, rdata_i[31:16]};
            default: mem_result_o <= mem_result_o;
          endcase
        end if ( inst_type_i == `LSU_OP_LH  ) begin
          case ( aroffset )
            0: mem_result_o <= {{16{rdata_i[15]}}, rdata_i[15:0 ]};
            2: mem_result_o <= {{16{rdata_i[31]}}, rdata_i[31:16]};
            default: mem_result_o <= mem_result_o;
          endcase
        end if ( inst_type_i == `LSU_OP_LW  ) begin
          mem_result_o <= rdata_i[31:0];
        end else begin
          mem_result_o <= mem_result_o;
        end
      end else begin
        mem_result_o <= mem_result_o;
      end
    end
  end

endmodule
