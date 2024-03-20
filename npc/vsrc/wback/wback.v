`include "defines.v"

module wback (
  input                     clock,
  input                     reset,

  input                     valid_pre_i,
  output                    ready_pre_o,

  output                    valid_post_o,
  input                     ready_post_i,

  input                     wsel_i,
  input                     wena_i,
  input  [`REG_ADDR_BUS]    waddr_i,
  input  [`REG_DATA_BUS]    alu_result_i,
  input  [`REG_DATA_BUS]    mem_result_i,

  output                    wena_o,
  output [`REG_ADDR_BUS]    waddr_o,
  output [`REG_DATA_BUS]    wdata_o
);

  wire we;

  wback_controller controller (
  	.clock        ( clock        ),
    .reset        ( reset        ),

    .valid_pre_i  ( valid_pre_i  ),
    .valid_post_o ( valid_post_o ),
    .ready_post_i ( ready_post_i ),
    .ready_pre_o  ( ready_pre_o  ),

    .we_o         ( we           )
  );
  
  wback_reg u_wbu_reg(
  	.clock        ( clock        ),
    .reset        ( reset        ),

    .we_i         ( we           ),

    .wena_i       ( wena_i       ),
    .wsel_i       ( wsel_i       ),
    .waddr_i      ( waddr_i      ),
    .alu_result_i ( alu_result_i ),
    .mem_result_i ( mem_result_i ),

    .wena_o       ( wena_o       ),
    .waddr_o      ( waddr_o      ),
    .wdata_o      ( wdata_o      )
  );

endmodule