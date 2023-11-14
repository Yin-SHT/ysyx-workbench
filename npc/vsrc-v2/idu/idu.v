`include "../defines.v"

module idu (
  input                       clk,
  input                       rst,

  input                       valid_pre_i,
  output                      ready_pre_o,

  output                      valid_post_o,
  input                       ready_post_i,

  input                       wena_i,
  input   [`REG_ADDR_BUS]     waddr_i,
  input   [`REG_DATA_BUS]     wdata_i,

  input   [`INST_ADDR_BUS]    pc_i,
  input   [`INST_DATA_BUS]    inst_i,

  output  [`INST_TYPE_BUS]    inst_type_o,
  output  [`ALU_OP_BUS]       alu_op_o,
  output  [`LSU_OP_BUS]       lsu_op_o,
  output                      wsel_o,
  output                      wena_o,
  output  [`REG_ADDR_BUS]     waddr_o,

  output  [`INST_ADDR_BUS]    pc_o,
  output  [`REG_DATA_BUS]     imm_o,
  output  [`REG_DATA_BUS]     rdata1_o,
  output  [`REG_DATA_BUS]     rdata2_o,
  
  output                      branch_en_o,
  output  [`INST_ADDR_BUS]    dnpc_o
);

  wire                  we;
  wire [`INST_ADDR_BUS] araddr;
  wire [`INST_ADDR_BUS] rdata;
  wire                  rena1;
  wire                  rena2;
  wire [`BPU_OP_BUS]    bpu_op;
  wire [`REG_ADDR_BUS]  raddr1;
  wire [`REG_ADDR_BUS]  raddr2;

  idu_fsm  u_idu_fsm (
    .clk          ( clk          ),
    .rst          ( rst          ),

    .valid_pre_i  ( valid_pre_i  ),
    .valid_post_o ( valid_post_o ),
    .ready_post_i ( ready_post_i ),
    .ready_pre_o  ( ready_pre_o  ),

    .we_o         ( we           )
  );

  idu_reg u_idu_reg (
  	.clk          ( clk          ),
    .rst          ( rst          ),

    .we_i         ( we           ),
    .araddr_i     ( pc_i         ),
    .rdata_i      ( inst_i       ),

    .araddr_o     ( araddr       ),
    .rdata_o      ( rdata        )
  );
   
  decode u_decode (
    .rst          ( rst          ),

    .pc_i         ( araddr       ),
    .inst_i       ( rdata        ),

    .inst_type_o  ( inst_type_o  ),
    .alu_op_o     ( alu_op_o     ),
    .lsu_op_o     ( lsu_op_o     ),
    .bpu_op_o     ( bpu_op       ),
    .wsel_o       ( wsel_o       ),
    .wena_o       ( wena_o       ),
    .waddr_o      ( waddr_o      ),
    .pc_o         ( pc_o         ),
    .imm_o        ( imm_o        ),
    .rena1_o      ( rena1        ),
    .rena2_o      ( rena2        ),
    .raddr1_o     ( raddr1       ),
    .raddr2_o     ( raddr2       )
  );
  
  regfile u_regfile (
  	.clk          ( clk          ),
    .rst          ( rst          ),

    .wena_i       ( wena_i       ),
    .waddr_i      ( waddr_i      ),
    .wdata_i      ( wdata_i      ),

    .rena1_i      ( rena1        ),
    .raddr1_i     ( raddr1       ),
    .rena2_i      ( rena2        ),
    .raddr2_i     ( raddr2       ),

    .rdata1_o     ( rdata1_o     ),
    .rdata2_o     ( rdata2_o     )
  );
  
  bpu u_bpu(
  	.rst          ( rst          ),

    .bpu_op_i     ( bpu_op       ),
    .pc_i         ( pc_o         ),
    .imm_i        ( imm_o        ),
    .rdata1_i     ( rdata1_o     ),
    .rdata2_i     ( rdata2_o     ),

    .branch_en_o  ( branch_en_o  ),
    .dnpc_o       ( dnpc_o       )
  );
  
endmodule
