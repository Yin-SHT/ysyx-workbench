`include "defines.v"

module data_expan (
  input rst,

  // Signal From Execute
  input [`ALU_OP_BUS]    alu_op_i,
  input [`MEM_ADDR_BUS]  read_offset_i,

  // Signal From Data_Mem
  input [`MEM_DATA_BUS]  rmem_data_i,

  // Signal To Write_Back
  output [`MEM_DATA_BUS] mem_data_o
);

  wire [`MEM_DATA_BUS] shift_data = ( rst == `RST_ENABLE       ) ? ( {                    `ZERO_WORD} ) :
                                   ( read_offset_i == 32'h00  ) ? ( {            rmem_data_i[31:0 ]} ) :
                                   ( read_offset_i == 32'h01  ) ? ( {{ 8{1'b0}}, rmem_data_i[31:8 ]} ) : 
                                   ( read_offset_i == 32'h02  ) ? ( {{16{1'b0}}, rmem_data_i[31:16]} ) :
                                   ( read_offset_i == 32'h03  ) ? ( {{24{1'b0}}, rmem_data_i[31:24]} ) : `ZERO_WORD;

  assign mem_data_o = ( rst      == `RST_ENABLE ) ? ( {                           `ZERO_WORD} ) :
                      ( alu_op_i == `ALU_OP_LB  ) ? ( {{24{shift_data[7 ]}}, shift_data[7 :0]} ) :
                      ( alu_op_i == `ALU_OP_LH  ) ? ( {{16{shift_data[15]}}, shift_data[15:0]} ) :
                      ( alu_op_i == `ALU_OP_LW  ) ? ( {                      shift_data[31:0]} ) : 
                      ( alu_op_i == `ALU_OP_LBU ) ? ( {{24{1'b0          }}, shift_data[7 :0]} ) :
                      ( alu_op_i == `ALU_OP_LHU ) ? ( {{16{1'b0          }}, shift_data[15:0]} ) : `ZERO_WORD; 

endmodule
