`include "defines.v"

module csrs (
  input                     clk,
  input                     rst,

  input [`ALU_OP_BUS]       alu_op_i,
  input [`INST_ADDR_BUS]    pc_i,

  input [`REG_DATA_BUS]     csr_cause_i,
  input [`CSR_REG_ADDR_BUS] csr_waddr_i,
  input [`CSR_REG_DATA_BUS] csr_wdata_i,
  input                     csr_wena_i,
  input [`CSR_REG_ADDR_BUS] csr_raddr_i,
  input                     csr_rena_i,
  output reg [`CSR_REG_DATA_BUS] csr_data_o
);

  reg [`CSR_REG_DATA_BUS] CSRs[4095:0];

  // Write Logic
  always @( posedge clk ) begin
    if ( rst == `RST_ENABLE ) begin
      CSRs[`MEPC]     <= `ZERO_WORD;
      CSRs[`MTVEC]    <= `ZERO_WORD;
      CSRs[`MCAUSE]   <= `ZERO_WORD;
      CSRs[`MSTATUS]  <= `ZERO_WORD;
    end else if ( csr_wena_i == `WRITE_ENABLE ) begin
      CSRs[csr_waddr_i] <= csr_wdata_i;
    end
  end

  // Read Logic
  always @( * ) begin
    if ( rst == `RST_ENABLE ) begin
      csr_data_o = `ZERO_WORD;
    end else if ( csr_rena_i == `READ_ENABLE ) begin
      csr_data_o = CSRs[csr_raddr_i];
    end else begin
      csr_data_o = `ZERO_WORD;
    end
  end

  // verilator lint_off latch
  // Ecall Instructtion
  always @( * ) begin
    if ( rst == `RST_DISABLE ) begin
      if ( alu_op_i == `ALU_OP_ECALL ) begin
        CSRs[`MEPC] = pc_i;      
        CSRs[`MCAUSE] = csr_cause_i;
      end
    end
  end

endmodule
