`include "defines.v"

module lsu (
  input                   rst,

  input [`INST_TYPE_BUS]  inst_type_i,
  input [`LSU_OP_BUS]     lsu_op_i,

  input [`REG_DATA_BUS]   imm_i,
  input [`REG_DATA_BUS]   rdata1_i,
  input [`REG_DATA_BUS]   rdata2_i,

  output [`MEM_ADDR_BUS]  mem_result_o,

  /* AW: Address Write Channel */
  output [`MEM_ADDR_BUS]  awaddr_o,
  output [2:0]            awsize_o,

  /*  W: Data Write Channel*/
  output [63:0]           wdata_o,
  output [`MEM_MASK_BUS]  wstrb_o,

  /* AR: Address Read Channel */
  output [`MEM_ADDR_BUS]  araddr_o,
  output [2:0]            arsize_o,

  /*  R: Read Channel */
  input  [63:0]           rdata_i
);
  
  wire [31:0] roff;
  wire [31:0] woff;
  wire [31:0] shift_data;

  /* Read operation */
  assign araddr_o = ( rst         == `RST_ENABLE ) ? 32'h0000_0000    : 
                    ( inst_type_i == `INST_LOAD  ) ? rdata1_i + imm_i : 32'h0000_0000; 
                    
  assign arsize_o = ( rst         == `RST_ENABLE ) ? 3'b000                             :
                    ((lsu_op_i    == `LSU_OP_LB) || (lsu_op_i == `LSU_OP_LBU)) ? 3'b000 :
                    ((lsu_op_i    == `LSU_OP_LH) || (lsu_op_i == `LSU_OP_LHU)) ? 3'b001 :
                    ((lsu_op_i    == `LSU_OP_LW)                             ) ? 3'b010 : 3'b000;
  
  /* Write operation */
  assign awaddr_o = ( rst         == `RST_ENABLE ) ? 32'h0000_0000    : 
                    ( inst_type_i == `INST_STORE ) ? rdata1_i + imm_i : 32'h0000_0000; 

  assign awsize_o = ( rst         == `RST_ENABLE ) ? 3'b000 :
                    ( lsu_op_i    == `LSU_OP_SB  ) ? 3'b000 :
                    ( lsu_op_i    == `LSU_OP_SH  ) ? 3'b001 :
                    ( lsu_op_i    == `LSU_OP_SW  ) ? 3'b010 : 3'b000;

  assign wdata_o  = ( rst         == `RST_ENABLE ) ?   64'h0000_0000_0000_0000   : 
                    ( inst_type_i == `INST_STORE ) ? { 32'h0000_0000, rdata2_i } : 64'h0000_0000_0000_0000; 

  assign wstrb_o  = ( rst         == `RST_ENABLE ) ? 8'b0000_0000: 
                    ( woff        == 32'h00      ) ? (( lsu_op_i == `LSU_OP_SB ) ? 8'b0000_0001 : 
                                                      ( lsu_op_i == `LSU_OP_SH ) ? 8'b0000_0011 :
                                                      ( lsu_op_i == `LSU_OP_SW ) ? 8'b0000_1111 : 8'b0000_0000 ) :
                    ( woff        == 32'h01      ) ? (( lsu_op_i == `LSU_OP_SB ) ? 8'b0000_0010 : 
                                                      ( lsu_op_i == `LSU_OP_SH ) ? 8'b0000_0110 : 8'b0000_0000 ) :
                    ( woff        == 32'h02      ) ? (( lsu_op_i == `LSU_OP_SB ) ? 8'b0000_0100 : 
                                                      ( lsu_op_i == `LSU_OP_SH ) ? 8'b0000_1100 : 8'b0000_0000 ) :
                    ( woff        == 32'h03      ) ? (( lsu_op_i == `LSU_OP_SB ) ? 8'b0000_1000 : 8'b0000_0000 ) : 8'b0000_0000;

  /* Miscellaneous */
  assign roff     = ( rst         == `RST_ENABLE ) ? 32'h0000_0000                           :
                    ( inst_type_i == `INST_LOAD  ) ? araddr_o - ( araddr_o & 32'hFFFF_FFFC ) : 32'h0000_0000; 

  assign woff     = ( rst         == `RST_ENABLE ) ? 32'h0000_0000                           :
                    ( inst_type_i == `INST_STORE ) ? awaddr_o - ( awaddr_o & 32'hFFFF_FFFC ) : 32'h0000_0000; 

  assign shift_data   = ( rst      == `RST_ENABLE ) ? ({                          32'h0000_0000 }) :
                        ( roff     == 32'h00      ) ? ({                         rdata_i[31:0 ] }) :
                        ( roff     == 32'h01      ) ? ({ {  8{1'b0}},            rdata_i[31:8 ] }) : 
                        ( roff     == 32'h02      ) ? ({ { 16{1'b0}},            rdata_i[31:16] }) :
                        ( roff     == 32'h03      ) ? ({ { 24{1'b0}},            rdata_i[31:24] }) : 32'h0000_0000;

  assign mem_result_o = ( rst      == `RST_ENABLE ) ? ({                          32'h0000_0000 }) :
                        ( lsu_op_i == `LSU_OP_LB  ) ? ({ {24{shift_data[7 ]}}, shift_data[7 :0] }) :
                        ( lsu_op_i == `LSU_OP_LH  ) ? ({ {16{shift_data[15]}}, shift_data[15:0] }) :
                        ( lsu_op_i == `LSU_OP_LW  ) ? ({                       shift_data[31:0] }) : 
                        ( lsu_op_i == `LSU_OP_LBU ) ? ({ {24{1'b0          }}, shift_data[7 :0] }) :
                        ( lsu_op_i == `LSU_OP_LHU ) ? ({ {16{1'b0          }}, shift_data[15:0] }) : 32'h0000_0000; 
endmodule
