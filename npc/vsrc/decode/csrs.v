`include "defines.v"

module csrs (
  input         clock,
  input         reset,

  input         fcsr_rena_i,    // fetch stage
  input  [31:0] fcsr_raddr_i,   // fetch stage
  output [31:0] fcsr_rdata_o,   // fetch stage

  input         csr_rena_i,
  input  [31:0] csr_raddr_i,
  output [31:0] csr_rdata_o,

  input  [7:0]  csr_op_i,
  input         csr_wena_i,
  input  [31:0] csr_waddr_i,
  input  [31:0] csr_wdata_i
);

  reg [31:0] mstatus;
  reg [31:0] mtvec;
  reg [31:0] mepc;
  reg [31:0] mcause;
  reg [31:0] mvendorid;
  reg [31:0] marchid;

  always @(posedge clock) begin
    if (reset) begin
      mstatus   <= 32'h0000_0000;
      mtvec     <= 32'h0000_0000;
      mepc      <= 32'h0000_0000;
      mcause    <= 32'h0000_0000;
      mvendorid <= 32'h7973_7978;
      marchid   <= 32'd22060008;
    end else if (csr_wena_i) begin
      if (csr_op_i == `CSR_OP_ECALL) begin  // used for ecall
        mepc   <= csr_wdata_i;
        mcause <= `ECALL_FROM_M;
      end else begin
        case (csr_waddr_i)   // used for csrrs/csrrw
          `MSTATUS: mstatus <= csr_wdata_i;
          `MTVEC  : mtvec   <= csr_wdata_i;
          `MEPC   : mepc    <= csr_wdata_i;
          `MCAUSE : mcause  <= csr_wdata_i;
          default: $fatal("Unsupport csr 0x%08x\n", csr_waddr_i);
        endcase
      end
    end
  end

  assign  csr_rdata_o = csr_rena_i ? ((csr_raddr_i == `MSTATUS  ) ? mstatus   :
                                      (csr_raddr_i == `MTVEC    ) ? mtvec     :
                                      (csr_raddr_i == `MEPC     ) ? mepc      :
                                      (csr_raddr_i == `MCAUSE   ) ? mcause    :
                                      (csr_raddr_i == `MVENDORID) ? mvendorid :
                                      (csr_raddr_i == `MARCHID  ) ? marchid   : 0) : 0;
                                                                             
  assign  fcsr_rdata_o = fcsr_rena_i ? ((fcsr_raddr_i == `MSTATUS  ) ? mstatus   :
                                        (fcsr_raddr_i == `MTVEC    ) ? mtvec     :
                                        (fcsr_raddr_i == `MEPC     ) ? mepc      :
                                        (fcsr_raddr_i == `MCAUSE   ) ? mcause    :
                                        (fcsr_raddr_i == `MVENDORID) ? mvendorid :
                                        (fcsr_raddr_i == `MARCHID  ) ? marchid   : 0) : 0;

endmodule
