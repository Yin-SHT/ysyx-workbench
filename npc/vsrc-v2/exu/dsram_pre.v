`include "../defines.v"

module dsram_pre (
  input                   rst,

  input [`INST_TYPE_BUS]  inst_type_i,
  input [`LSU_OP_BUS]     lsu_op_i,

  input [`REG_DATA_BUS]   imm_i,
  input [`REG_DATA_BUS]   rdata1_i,
  input [`REG_DATA_BUS]   rdata2_i,

  output [`MEM_ADDR_BUS]  araddr_o,
  output [`MEM_ADDR_BUS]  roff_o,

  output [`MEM_ADDR_BUS]  awaddr_o,
  output [`MEM_DATA_BUS]  wdata_o,
  output [`MEM_MASK_BUS]  wstrb_o
);

  wire [`INST_ADDR_BUS] woff;

  /* READ */
  assign araddr_o = ( rst         == `RST_ENABLE ) ? 32'h0000_0000                       : 
                    ( inst_type_i == `INST_LOAD  ) ? rdata1_i + imm_i                    : 32'h0000_0000; 
                    
  assign roff_o   = ( rst         == `RST_ENABLE ) ? 32'h0000_0000                       :
                    ( inst_type_i == `INST_LOAD  ) ? araddr_o - araddr_o & 32'hFFFF_FFFC : 32'h0000_0000; 
 
  /* WRITE */
  assign awaddr_o = ( rst         == `RST_ENABLE ) ? 32'h0000_0000                       : 
                    ( inst_type_i == `INST_STORE ) ? rdata1_i + imm_i                    : 32'h0000_0000; 

  assign wdata_o  = ( rst         == `RST_ENABLE ) ? 32'h0000_0000                       : 
                    ( inst_type_i == `INST_STORE ) ? rdata2_i                            : 32'h0000_0000; 

  assign woff     = ( rst         == `RST_ENABLE ) ? 32'h0000_0000                       :
                    ( inst_type_i == `INST_STORE ) ? awaddr_o - awaddr_o & 32'hFFFF_FFFC : 32'h0000_0000; 

  assign wstrb_o  = ( rst         == `RST_ENABLE ) ? 8'b0000_0000: 
                    ( woff        == 32'h00      ) ? (( lsu_op_i == `LSU_OP_SB ) ? 8'b0000_0001 : 
                                                      ( lsu_op_i == `LSU_OP_SH ) ? 8'b0000_0011 :
                                                      ( lsu_op_i == `LSU_OP_SW ) ? 8'b0000_1111 : 8'b0000_0000 ) :
                    ( woff        == 32'h01      ) ? (( lsu_op_i == `LSU_OP_SB ) ? 8'b0000_0010 : 
                                                      ( lsu_op_i == `LSU_OP_SH ) ? 8'b0000_0110 : 8'b0000_0000 ) :
                    ( woff        == 32'h02      ) ? (( lsu_op_i == `LSU_OP_SB ) ? 8'b0000_0100 : 
                                                      ( lsu_op_i == `LSU_OP_SH ) ? 8'b0000_1100 : 8'b0000_0000 ) :
                    ( woff        == 32'h03      ) ? (( lsu_op_i == `LSU_OP_SB ) ? 8'b0000_1000 : 8'b0000_0000 ) : 8'b0000_0000;
endmodule
