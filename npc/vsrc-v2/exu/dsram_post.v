`include "../defines.v"

module dsram_post (
  input                   rst,

  input [`LSU_OP_BUS]     lsu_op_i,
  input [`INST_ADDR_BUS]  roff_i,
  input [`REG_DATA_BUS]   rdata_i,

  output [`REG_DATA_BUS]  mem_data_o
);

  wire [`MEM_DATA_BUS] shift_data;
  
  assign shift_data = ( rst      == `RST_ENABLE ) ? ({                          32'h0000_0000 }) :
                      ( roff_i   == 32'h00      ) ? ({                         rdata_i[31:0 ] }) :
                      ( roff_i   == 32'h01      ) ? ({ {  8{1'b0}},            rdata_i[31:8 ] }) : 
                      ( roff_i   == 32'h02      ) ? ({ { 16{1'b0}},            rdata_i[31:16] }) :
                      ( roff_i   == 32'h03      ) ? ({ { 24{1'b0}},            rdata_i[31:24] }) : 32'h0000_0000;

  assign mem_data_o = ( rst      == `RST_ENABLE ) ? ({                          32'h0000_0000 }) :
                      ( lsu_op_i == `LSU_OP_LB  ) ? ({ {24{shift_data[7 ]}}, shift_data[7 :0] }) :
                      ( lsu_op_i == `LSU_OP_LH  ) ? ({ {16{shift_data[15]}}, shift_data[15:0] }) :
                      ( lsu_op_i == `LSU_OP_LW  ) ? ({                       shift_data[31:0] }) : 
                      ( lsu_op_i == `LSU_OP_LBU ) ? ({ {24{1'b0          }}, shift_data[7 :0] }) :
                      ( lsu_op_i == `LSU_OP_LHU ) ? ({ {16{1'b0          }}, shift_data[15:0] }) : 32'h0000_0000; 

endmodule
