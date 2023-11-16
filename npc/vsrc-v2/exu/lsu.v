`include "defines.v"

module lsu (
  input                      rst,

  input   [`INST_TYPE_BUS]   inst_type_i,
  input   [`LSU_OP_BUS]      lsu_op_i,

  input   [`REG_DATA_BUS]    imm_i,
  input   [`REG_DATA_BUS]    rdata1_i,
  input   [`REG_DATA_BUS]    rdata2_i,

  output  [`MEM_ADDR_BUS]    araddr_o,
  output  [`MEM_ADDR_BUS]    awaddr_o,
  output  [`MEM_DATA_BUS]    wdata_o,
  output  [`MEM_MASK_BUS]    wstrb_o,

  input   [`MEM_DATA_BUS]    rdata_i,
  output  [`INST_DATA_BUS]   mem_result_o
);
  
  wire [`MEM_ADDR_BUS] roff;

  dsram_pre u_dsram_pre(
  	.rst         ( rst         ),

    .inst_type_i ( inst_type_i ),
    .lsu_op_i    ( lsu_op_i    ),
    .imm_i       ( imm_i       ),
    .rdata1_i    ( rdata1_i    ),
    .rdata2_i    ( rdata2_i    ),

    .araddr_o    ( araddr_o    ),
    .roff_o      ( roff        ),
    .awaddr_o    ( awaddr_o    ),
    .wdata_o     ( wdata_o     ),
    .wstrb_o     ( wstrb_o     )
  );
  
  dsram_post u_dsram_post(
  	.rst           ( rst          ),
    .lsu_op_i      ( lsu_op_i     ),
    .roff_i        ( roff         ),
    .rdata_i       ( rdata_i      ),
    .mem_result_o  ( mem_result_o )
  );
  
endmodule
