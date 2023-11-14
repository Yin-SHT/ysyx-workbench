`include "defines.v"

module top (
  input   clk,
  input   rst
);

  wire  valid_wbu_ifu;
  wire  ready_wbu_ifu;

  wire  valid_ifu_idu;
  wire  ready_ifu_idu;

  wire  valid_idu_exu;
  wire  ready_idu_exu;

  wire  valid_exu_wbu;
  wire  ready_exu_wbu;

  /* BPU & IFU */
  wire                      branch_en;
  wire [`INST_ADDR_BUS]     dnpc;

  /* IFU & IDU */     
  wire [`INST_ADDR_BUS]     araddr;
  wire [`INST_DATA_BUS]     rdata;

  /* WBU & IDU */
  wire                      wena;
  wire  [`REG_ADDR_BUS]     waddr;
  wire  [`REG_DATA_BUS]     wdata;

  /* IDU & EXU */
  wire  [`INST_TYPE_BUS]    inst_type;
  wire  [`ALU_OP_BUS]       alu_op;
  wire  [`LSU_OP_BUS]       lsu_op;
  wire                      wsel_idu_exu;
  wire                      wena_idu_exu;
  wire  [`REG_ADDR_BUS]     waddr_idu_exu;
  wire  [`INST_ADDR_BUS]    pc;
  wire  [`REG_DATA_BUS]     imm;
  wire  [`REG_DATA_BUS]     rdata1;
  wire  [`REG_DATA_BUS]     rdata2;

  /* EXU & WBU */
  wire                      wsel_exu_wbu;
  wire                      wena_exu_wbu;
  wire  [`REG_ADDR_BUS]     waddr_exu_wbu;
  wire  [`REG_DATA_BUS]     alu_result;
  wire  [`REG_DATA_BUS]     mem_result;

  ifu u_ifu(
  	.rst          ( rst           ),
    .clk          ( clk           ),

    .valid_pre_i  ( valid_wbu_ifu ),
    .ready_pre_o  ( ready_wbu_ifu ),
    .valid_post_o ( valid_ifu_idu ),
    .ready_post_i ( ready_ifu_idu ),

    .branch_en_i  ( branch_en     ),
    .dnpc_i       ( dnpc          ),

    .araddr_o     ( araddr        ),
    .rdata_o      ( rdata         )
  );
  
  idu u_idu(
  	.clk          ( clk           ),
    .rst          ( rst           ),

    .valid_pre_i  ( valid_ifu_idu ),
    .ready_pre_o  ( ready_ifu_idu ),
    .valid_post_o ( valid_idu_exu ),
    .ready_post_i ( ready_idu_exu ),

    .wena_i       ( wena          ),
    .waddr_i      ( waddr         ),
    .wdata_i      ( wdata         ),

    .pc_i         ( araddr        ),
    .inst_i       ( rdata         ),

    .inst_type_o  ( inst_type     ),
    .alu_op_o     ( alu_op        ),
    .lsu_op_o     ( lsu_op        ),
    .wsel_o       ( wsel_idu_exu  ),
    .wena_o       ( wena_idu_exu  ),
    .waddr_o      ( waddr_idu_exu ),
    .pc_o         ( pc            ),
    .imm_o        ( imm           ),
    .rdata1_o     ( rdata1        ),
    .rdata2_o     ( rdata2        ),

    .branch_en_o  ( branch_en     ),
    .dnpc_o       ( dnpc          ) 
  );
  
  exu u_exu(
  	.clk          ( clk           ),
    .rst          ( rst           ),

    .valid_pre_i  ( valid_idu_exu ),
    .ready_pre_o  ( ready_idu_exu ),
    .valid_post_o ( valid_exu_wbu ),
    .ready_post_i ( ready_exu_wbu ),

    .inst_type_i  ( inst_type     ),
    .alu_op_i     ( alu_op        ),
    .lsu_op_i     ( lsu_op        ),
    .wsel_i       ( wsel_idu_exu  ),
    .wena_i       ( wena_idu_exu  ),
    .waddr_i      ( waddr_idu_exu ),
    .pc_i         ( pc            ),
    .imm_i        ( imm           ),
    .rdata1_i     ( rdata1        ),
    .rdata2_i     ( rdata2        ),

    .wsel_o       ( wsel_exu_wbu  ),
    .wena_o       ( wena_exu_wbu  ),
    .waddr_o      ( waddr_exu_wbu ),
    .alu_result_o ( alu_result    ),
    .mem_result_o ( mem_result    )
  );
  
  wbu u_wbu(
  	.clk          ( clk           ),
    .rst          ( rst           ),

    .valid_pre_i  ( valid_exu_wbu ),
    .ready_pre_o  ( ready_exu_wbu ),
    .valid_post_o ( valid_wbu_ifu ),
    .ready_post_i ( ready_wbu_ifu ),

    .wsel_i       ( wsel_exu_wbu  ),
    .wena_i       ( wena_exu_wbu  ),
    .waddr_i      ( waddr_exu_wbu ),
    .alu_result_i ( alu_result    ),
    .mem_result_i ( mem_result    ),

    .wena_o       ( wena          ),
    .waddr_o      ( waddr         ),
    .wdata_o      ( wdata         )
  );

endmodule
