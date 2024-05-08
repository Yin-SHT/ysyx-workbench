`include "defines.v"

module idu (
  input                       clock,
  input                       reset,

  input                       valid_pre_i,
  output                      ready_pre_o,

  output                      valid_post_o,
  input                       ready_post_i,

  // f: wbu
  input                       wena_i,
  input   [`REG_ADDR_BUS]     waddr_i,
  input   [`REG_DATA_BUS]     wdata_i,

  // f: ifu
  input   [`NPC_ADDR_BUS]     pc_i,
  input   [`NPC_DATA_BUS]     inst_i,

  // t: exu
  output  [`INST_TYPE_BUS]    inst_type_o,
  output  [`ALU_OP_BUS]       alu_op_o,
  output  [`LSU_OP_BUS]       lsu_op_o,
  output                      wsel_o,
  output                      wena_o,
  output  [`REG_ADDR_BUS]     waddr_o,
  output  [`NPC_ADDR_BUS]     pc_o,
  output  [`REG_DATA_BUS]     imm_o,
  output  [`REG_DATA_BUS]     rdata1_o,
  output  [`REG_DATA_BUS]     rdata2_o,
  output  [`CSR_DATA_BUS]     csr_o,
  
  // t: ifu
  output                      branch_en_o,
  output  [`NPC_ADDR_BUS]     dnpc_o,

  // t: icache
  output fencei_o
);

  wire                  we;
  wire [`NPC_ADDR_BUS]  pc;
  wire [`NPC_DATA_BUS]  inst;
  wire                  rena1;
  wire                  rena2;
  wire [`BPU_OP_BUS]    bpu_op;
  wire [`CSR_OP_BUS]    csr_op;
  wire [`REG_ADDR_BUS]  raddr1;
  wire [`REG_ADDR_BUS]  raddr2;
  wire [`CSR_DATA_BUS]  csr_pc;


  idu_fsm  u_idu_fsm (
    .clock        ( clock        ),
    .reset        ( reset        ),

    .valid_pre_i  ( valid_pre_i  ),
    .valid_post_o ( valid_post_o ),
    .ready_post_i ( ready_post_i ),
    .ready_pre_o  ( ready_pre_o  ),

    .we_o         ( we           )
  );

  idu_reg u_idu_reg (
  	.clock        ( clock        ),
    .reset        ( reset        ),
    .we_i         ( we           ),
    .pc_i         ( pc_i         ),
    .inst_i       ( inst_i       ),
    .pc_o         ( pc           ),
    .inst_o       ( inst         )
  );
   
  wire fencei;

  assign fencei_o = fencei & valid_post_o && ready_post_i;

  decode u_decode (
    .reset        ( reset        ),
    .pc_i         ( pc           ),
    .inst_i       ( inst         ),
    .inst_type_o  ( inst_type_o  ),
    .alu_op_o     ( alu_op_o     ),
    .lsu_op_o     ( lsu_op_o     ),
    .bpu_op_o     ( bpu_op       ),
    .csr_op_o     ( csr_op       ),
    .wsel_o       ( wsel_o       ),
    .wena_o       ( wena_o       ),
    .waddr_o      ( waddr_o      ),
    .pc_o         ( pc_o         ),
    .imm_o        ( imm_o        ),
    .rena1_o      ( rena1        ),
    .rena2_o      ( rena2        ),
    .raddr1_o     ( raddr1       ),
    .raddr2_o     ( raddr2       ),
    .fencei_o     ( fencei )
  );
  
  regfile u_regfile (
  	.clock        ( clock        ),
    .reset        ( reset        ),
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

  csrs u_csrs(
  	.reset    ( reset    ),
    .csr_op_i ( csr_op   ),
    .pc_i     ( pc_o     ),
    .imm_i    ( imm_o    ),
    .rdata1_i ( rdata1_o ),
    .csr_o    ( csr_o    ),
    .csr_pc_o ( csr_pc   )
  );

  bpu u_bpu(
  	.reset        ( reset        ),
    .bpu_op_i     ( bpu_op       ),
    .csr_op_i     ( csr_op       ),
    .pc_i         ( pc_o         ),
    .imm_i        ( imm_o        ),
    .rdata1_i     ( rdata1_o     ),
    .rdata2_i     ( rdata2_o     ),
    .csr_pc_i     ( csr_pc       ),
    .branch_en_o  ( branch_en_o  ),
    .dnpc_o       ( dnpc_o       )
  );
  
endmodule
