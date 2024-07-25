`include "defines.v"

module arbiter (
  input                      clock,
  input                      reset,

  /* AW: Address Write Channel */
  input                      awready_i,
  output                     ifu_awready_o,
  output                     exu_awready_o,

  output                     awvalid_o,
  input                      ifu_awvalid_i,
  input                      exu_awvalid_i,

  output [31:0]              awaddr_o,
  input  [31:0]              ifu_awaddr_i,
  input  [31:0]              exu_awaddr_i,

  output [3:0]               awid_o,
  input  [3:0]               ifu_awid_i,
  input  [3:0]               exu_awid_i,

  output [7:0]               awlen_o,
  input  [7:0]               ifu_awlen_i,
  input  [7:0]               exu_awlen_i,

  output [2:0]               awsize_o,
  input  [2:0]               ifu_awsize_i,
  input  [2:0]               exu_awsize_i,

  output [1:0]               awburst_o,
  input  [1:0]               ifu_awburst_i,
  input  [1:0]               exu_awburst_i,

  /*  W: Data Write Channel */
  input                      wready_i,
  output                     ifu_wready_o,
  output                     exu_wready_o,

  output                     wvalid_o,
  input                      ifu_wvalid_i,
  input                      exu_wvalid_i,

  output [63:0]              wdata_o,
  input  [63:0]              ifu_wdata_i,
  input  [63:0]              exu_wdata_i,

  output [7:0]               wstrb_o,
  input  [7:0]               ifu_wstrb_i,
  input  [7:0]               exu_wstrb_i,

  output                     wlast_o,
  input                      ifu_wlast_i,
  input                      exu_wlast_i,

  /*  B: Response Write Channel */
  output                     bready_o,
  input                      ifu_bready_i,
  input                      exu_bready_i,

  input                      bvalid_i,
  output                     ifu_bvalid_o,
  output                     exu_bvalid_o,

  input  [1:0]               bresp_i,
  output [1:0]               ifu_bresp_o,
  output [1:0]               exu_bresp_o,

  input  [3:0]               bid_i,
  output [3:0]               ifu_bid_o,
  output [3:0]               exu_bid_o,

  /* AR: Address Read Channel */
  input                      arready_i,
  output                     ifu_arready_o,
  output                     exu_arready_o,

  output                     arvalid_o,
  input                      ifu_arvalid_i,
  input                      exu_arvalid_i,

  output [31:0]              araddr_o,
  input  [31:0]              ifu_araddr_i,
  input  [31:0]              exu_araddr_i,

  output [3:0]               arid_o,
  input  [3:0]               ifu_arid_i,
  input  [3:0]               exu_arid_i,

  output [7:0]               arlen_o,
  input  [7:0]               ifu_arlen_i,
  input  [7:0]               exu_arlen_i,

  output [2:0]               arsize_o,
  input  [2:0]               ifu_arsize_i,
  input  [2:0]               exu_arsize_i,

  output [1:0]               arburst_o,
  input  [1:0]               ifu_arburst_i,
  input  [1:0]               exu_arburst_i,

  /*  R: Data Read Channel */
  output                     rready_o,
  input                      ifu_rready_i,
  input                      exu_rready_i,

  input                      rvalid_i,
  output                     ifu_rvalid_o,
  output                     exu_rvalid_o,

  input  [1:0]               rresp_i,
  output [1:0]               ifu_rresp_o,
  output [1:0]               exu_rresp_o,

  input  [63:0]              rdata_i,
  output [63:0]              ifu_rdata_o,
  output [63:0]              exu_rdata_o,

  input                      rlast_i,
  output                     ifu_rlast_o,
  output                     exu_rlast_o,

  input  [3:0]               rid_i,
  output [3:0]               ifu_rid_o,
  output [3:0]               exu_rid_o,

  /* CLINT */ 
  /* AR: Address Read Channel */
  output[31:0]               clint_araddr_o,
  output                     clint_arvalid_o,
  input                      clint_arready_i,

  /*  R: Data Read Channel */
  input  [1:0]               clint_rresp_i,
  input  [63:0]              clint_rdata_i,
  input                      clint_rlast_i,
  input  [3:0]               clint_rid_i,
  input                      clint_rvalid_i,
  output                     clint_rready_o
);

  parameter idle            = 4'b0000;
  parameter ifu_read        = 4'b0001;
  parameter exu_read        = 4'b0010;
  parameter exu_write       = 4'b0011;
  parameter clint_read      = 4'b0100;

  wire in_clint;

  reg [3:0] cur_state;
  reg [3:0] next_state;

  //-----------------------------------------------------------------
  // CLINT
  //-----------------------------------------------------------------
  assign in_clint        = (exu_araddr_i >= 32'h0200_0000) && (exu_araddr_i <= 32'h0200_ffff);
  assign clint_araddr_o  = (cur_state == clint_read) ? exu_araddr_i  : 0;
  assign clint_arvalid_o = (cur_state == clint_read) ? exu_arvalid_i : 0;
  assign clint_rready_o  = (cur_state == clint_read) ? exu_rready_i  : 0;


  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  /* AW: Address Write Channel */
  assign awvalid_o     = (cur_state == exu_write) ? exu_awvalid_i : 0;
  assign awaddr_o      = (cur_state == exu_write) ? exu_awaddr_i  : 0;
  assign awid_o        = (cur_state == exu_write) ? exu_awid_i    : 0;
  assign awlen_o       = (cur_state == exu_write) ? exu_awlen_i   : 0;
  assign awsize_o      = (cur_state == exu_write) ? exu_awsize_i  : 0;
  assign awburst_o     = (cur_state == exu_write) ? exu_awburst_i : 0;
  assign exu_awready_o = (cur_state == exu_write) ? awready_i     : 0;
  assign ifu_awready_o = 0;

  /*  W: Data Write Channel */
  assign wvalid_o      = (cur_state == exu_write) ? exu_wvalid_i  : 0;
  assign wdata_o       = (cur_state == exu_write) ? exu_wdata_i   : 0;
  assign wstrb_o       = (cur_state == exu_write) ? exu_wstrb_i   : 0;
  assign wlast_o       = (cur_state == exu_write) ? exu_wlast_i   : 0;
  assign exu_wready_o  = (cur_state == exu_write) ? wready_i      : 0;
  assign ifu_wready_o  = 0;
  
  /*  B: Response Write Channel */
  assign bready_o      = (cur_state == exu_write) ? exu_bready_i  : 0;
  assign exu_bvalid_o  = (cur_state == exu_write) ? bvalid_i      : 0;
  assign exu_bresp_o   = (cur_state == exu_write) ? bresp_i       : 0;
  assign exu_bid_o     = (cur_state == exu_write) ? bid_i         : 0;
  assign ifu_bvalid_o  = 0;
  assign ifu_bresp_o   = 0;
  assign ifu_bid_o     = 0;

  /* AR: Address Read Channel */
  assign arvalid_o     = (cur_state == ifu_read) ? ifu_arvalid_i : ((cur_state == exu_read) ? exu_arvalid_i : 0);
  assign araddr_o      = (cur_state == ifu_read) ? ifu_araddr_i  : ((cur_state == exu_read) ? exu_araddr_i  : 0);
  assign arid_o        = (cur_state == ifu_read) ? ifu_arid_i    : ((cur_state == exu_read) ? exu_arid_i    : 0);
  assign arlen_o       = (cur_state == ifu_read) ? ifu_arlen_i   : ((cur_state == exu_read) ? exu_arlen_i   : 0);
  assign arsize_o      = (cur_state == ifu_read) ? ifu_arsize_i  : ((cur_state == exu_read) ? exu_arsize_i  : 0);
  assign arburst_o     = (cur_state == ifu_read) ? ifu_arburst_i : ((cur_state == exu_read) ? exu_arburst_i : 0);
  assign exu_arready_o = (cur_state == exu_read) ? arready_i     : ((cur_state == clint_read) ? clint_arready_i : 0);
  assign ifu_arready_o = (cur_state == ifu_read) ? arready_i     : 0;

  /*  R: Data Read Channel */
  assign rready_o      = (cur_state == ifu_read) ? ifu_rready_i : ((cur_state == exu_read  ) ? exu_rready_i   : 0);
  assign exu_rvalid_o  = (cur_state == exu_read) ? rvalid_i     : ((cur_state == clint_read) ? clint_rvalid_i : 0);
  assign exu_rresp_o   = (cur_state == exu_read) ? rresp_i      : ((cur_state == clint_read) ? clint_rresp_i  : 0);
  assign exu_rdata_o   = (cur_state == exu_read) ? rdata_i      : ((cur_state == clint_read) ? clint_rdata_i  : 0);
  assign exu_rlast_o   = (cur_state == exu_read) ? rlast_i      : ((cur_state == clint_read) ? clint_rlast_i  : 0);
  assign exu_rid_o     = (cur_state == exu_read) ? rid_i        : ((cur_state == clint_read) ? clint_rid_i    : 0);
  assign ifu_rvalid_o  = (cur_state == ifu_read) ? rvalid_i     : 0;
  assign ifu_rresp_o   = (cur_state == ifu_read) ? rresp_i      : 0;
  assign ifu_rdata_o   = (cur_state == ifu_read) ? rdata_i      : 0;
  assign ifu_rlast_o   = (cur_state == ifu_read) ? rlast_i      : 0;
  assign ifu_rid_o     = (cur_state == ifu_read) ? rid_i        : 0;


  //-----------------------------------------------------------------
  // Synchronous State - Transition always@ ( posedge Clock ) block
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
      cur_state <= idle;
    end else begin
      cur_state <= next_state;
    end
  end


  //-----------------------------------------------------------------
  // Conditional State - Transition always@ ( * ) block
  //-----------------------------------------------------------------
  always @(*) begin
    if (reset) begin
      next_state = idle;  
    end else begin
      next_state = cur_state;
      case (cur_state)
        idle: if (exu_arvalid_i && !in_clint ) next_state = exu_read;
              else if (exu_arvalid_i &&  in_clint ) next_state = clint_read;
              else if (exu_awvalid_i ) next_state = exu_write;
              else if (ifu_arvalid_i ) next_state = ifu_read;
        ifu_read: if (ifu_rready_i && rvalid_i) next_state = idle;
        exu_read: if (exu_rready_i && rvalid_i) next_state = idle;
        exu_write: if (exu_bready_i && bvalid_i ) next_state = idle;
        clint_read: if (exu_rready_i && clint_rvalid_i && clint_rlast_i) next_state = idle;
        default: next_state = cur_state;
      endcase
    end
  end

endmodule
