`include "defines.v"

module exu_reg (
  input clk,
  input rst,

  /* EXU controller */
  input                         we_i,        // write enable 

  input  [`INST_TYPE_BUS]       inst_type_i,
  input  [`ALU_OP_BUS]          alu_op_i,
  input  [`LSU_OP_BUS]          lsu_op_i,
  input                         wsel_i,
  input                         wena_i,
  input  [`REG_ADDR_BUS]        waddr_i,
  input  [`INST_ADDR_BUS]       pc_i,
  input  [`REG_DATA_BUS]        imm_i,
  input  [`REG_DATA_BUS]        rdata1_i,
  input  [`REG_DATA_BUS]        rdata2_i,
  input  [`CSR_DATA_BUS]        csr_i,

  output reg [`INST_TYPE_BUS]   inst_type_o,
  output reg [`ALU_OP_BUS]      alu_op_o,
  output reg [`LSU_OP_BUS]      lsu_op_o,
  output reg                    wsel_o,
  output reg                    wena_o,
  output reg [`REG_ADDR_BUS]    waddr_o,
  output reg [`INST_ADDR_BUS]   pc_o,
  output reg [`REG_DATA_BUS]    imm_o,
  output reg [`REG_DATA_BUS]    rdata1_o,
  output reg [`REG_DATA_BUS]    rdata2_o,
  output reg [`CSR_DATA_BUS]    csr_o
);

  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      inst_type_o <= 0;
      alu_op_o    <= 0;
      lsu_op_o    <= 0;
      wsel_o      <= 0;
      wena_o      <= 0;
      waddr_o     <= 0;
      pc_o        <= 0;
      imm_o       <= 0;
      rdata1_o    <= 0;
      rdata2_o    <= 0;
      csr_o       <= 0;
    end else begin
      inst_type_o <= inst_type_o;
      alu_op_o    <= alu_op_o;
      lsu_op_o    <= lsu_op_o;
      wsel_o      <= wsel_o;
      wena_o      <= wena_o;
      waddr_o     <= waddr_o;
      pc_o        <= pc_o;
      imm_o       <= imm_o;
      rdata1_o    <= rdata1_o;
      rdata2_o    <= rdata2_o;
      csr_o       <= csr_o;
      if ( we_i == `WRITE_ENABLE ) begin
          inst_type_o <= inst_type_i;
          alu_op_o    <= alu_op_i;
          lsu_op_o    <= lsu_op_i;
          wsel_o      <= wsel_i;
          wena_o      <= wena_i;
          waddr_o     <= waddr_i;
          pc_o        <= pc_i;
          imm_o       <= imm_i;
          rdata1_o    <= rdata1_i;
          rdata2_o    <= rdata2_i;
          csr_o       <= csr_i;
        end else begin
          inst_type_o <= inst_type_o;
          alu_op_o    <= alu_op_o;
          lsu_op_o    <= lsu_op_o;
          wsel_o      <= wsel_o;
          wena_o      <= wena_o;
          waddr_o     <= waddr_o;
          pc_o        <= pc_o;
          imm_o       <= imm_o;
          rdata1_o    <= rdata1_o;
          rdata2_o    <= rdata2_o;
          csr_o       <= csr_o;
        end
    end
  end

endmodule // pc_reg
