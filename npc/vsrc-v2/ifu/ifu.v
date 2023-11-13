`include "../defines.v"

module ifu (
  input                    rst,
  input                    clk,

  input                    branch_en_i,
  input  [`INST_ADDR_BUS]  dnpc_i,

  input                    valid_pre_i,
  output                   ready_pre_o,

  output                   valid_post_o,
  input                    ready_post_i,

  output [`INST_ADDR_BUS]  araddr_o,
  output [`INST_DATA_BUS]  rdata_o
);

  wire we;
  wire [`INST_ADDR_BUS] next_pc;
  wire arvalid;
  wire arready;
  wire [`INST_DATA_BUS] rresp;
  wire rvalid;
  wire rready;

  pc_mux u_pc_mux (
    .rst  ( rst ),
    .branch_en_i ( branch_en_i ),
    .araddr_i ( araddr_o ),
    .dnpc_i ( dnpc_i ),
    .next_pc_o ( next_pc )
  );

  ifu_reg u_ifu_reg (
    .clk  ( clk ),
    .rst  ( rst ),
    .we_i ( we ),
    .next_pc_i ( next_pc ),
    .araddr_o  ( araddr_o )
  );

  ifu_fsm u_ifu_fsm (
    .clk ( clk ),
    .rst ( rst ),
    .valid_pre_i ( valid_pre_i ),
    .ready_pre_o ( ready_pre_o ),
    .valid_post_o ( valid_post_o ),
    .ready_post_i ( ready_post_i ),
    .arvalid_o ( arvalid ),
    .arready_i ( arready ),
    .rvalid_i ( rvalid ),
    .rresp_i ( rresp ),
    .rready_o ( rready ),
    .we_o ( we )
  );

  isram u_isram (
    .clk ( clk ),
    .rst ( rst ),
    .araddr_i ( araddr_o ),
    .arvalid_i ( arvalid ),
    .arready_o ( arready ),
    .rdata_o ( rdata_o ),
    .rresp_o ( rresp ),
    .rready_i ( rready ),
    .rvalid_o ( rvalid )
  );

endmodule
