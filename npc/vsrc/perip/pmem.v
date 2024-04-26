`include "defines.v"

module pmem (
  input         clock,
  input         reset,

  /* AW: Address Write Channel */
  output        awready_o,
  input         awvalid_i,
  input [31:0]  awaddr_i,
  input [3:0]   awid_i,
  input [7:0]   awlen_i,
  input [2:0]   awsize_i,
  input [1:0]   awburst_i,

  /*  W: Data Write Channel */
  output        wready_o,
  input         wvalid_i,
  input [63:0]  wdata_i,
  input [7:0]   wstrb_i,
  input         wlast_i,

  /*  B: Response Write Channel */
  input         bready_i,
  output        bvalid_o,
  output [1:0]  bresp_o,
  output [3:0]  bid_o,

  /* AR: Address Read Channel */
  output        arready_o,
  input         arvalid_i,
  input [31:0]  araddr_i,
  input [3:0]   arid_i,
  input [7:0]   arlen_i,
  input [2:0]   arsize_i,
  input [1:0]   arburst_i,

  /*  R: Data Read Channel */
  input         rready_i,
  output        rvalid_o,
  output [1:0]  rresp_o,
  output [63:0] rdata_o,
  output        rlast_o,
  output [3:0]  rid_o
);
  
  import "DPI-C" function void axi4_read(input int araddr, output int rdata_high, output int rdata_low, input int arsize);
  import "DPI-C" function void axi4_write(input int awaddr, input int wdata_high, input int wdata_low, input int awsize, input int wstrb);

  parameter idle         = 3'b000;  

  parameter wait_read    = 3'b010;
  parameter wait_rready  = 3'b011;  

  parameter wait_write   = 3'b100;
  parameter wait_bready  = 3'b101;
  
  reg [2:0] cur_state;
  reg [2:0] next_state;

  reg [31:0] araddr;
  reg [2:0]  arsize;
  reg [63:0] rdata;

  reg [31:0] awaddr;
  reg [2:0]  awsize;
  reg [63:0] wdata;
  reg [7 :0] wstrb;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------

  // AW
  assign awready_o = (cur_state == idle);

  // W
  assign wready_o  = (cur_state == idle);

  // B
  assign bvalid_o  = (cur_state == wait_bready);
  assign bresp_o   = 0;
  assign bid_o     = 0;

  // AR
  assign arready_o = (cur_state == idle);

  // R
  assign rvalid_o  = (cur_state == wait_rready);
  assign rresp_o   = 0;
  assign rdata_o   = rdata;
  assign rlast_o   = (cur_state == wait_rready) ? 1 : 0;
  assign rid_o     = 0;
   
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
  always @( * ) begin
    if (reset) begin
      next_state = idle;  
    end else begin
        next_state = cur_state;
        case (cur_state)
          idle:       if (arvalid_i) next_state = wait_read;
                 else if (awvalid_i) next_state = wait_write;
          wait_read:                 next_state = wait_rready;
          wait_rready: if (rready_i) next_state = idle;
          wait_write:                next_state = wait_bready;
          wait_bready: if (bready_i) next_state = idle;
          default: next_state = cur_state;
        endcase
    end
  end

  //-----------------------------------------------------------------
  // Miscellaneous
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
      awaddr <= 0;
      awsize <= 0;
      wdata  <= 0;
      wstrb  <= 0;
      araddr <= 0;
      arsize <= 0;
    end else if (awvalid_i && wvalid_i) begin
      awaddr <= awaddr_i;
      awsize <= awsize_i;
      wdata  <= wdata_i;
      wstrb  <= wstrb_i;
    end else if (arvalid_i) begin
      araddr <= araddr_i;
      arsize <= arsize_i;
    end
  end

  always @(posedge clock) begin
    if (cur_state == wait_read) begin
      axi4_read(araddr, rdata[63:32], rdata[31:0], {29'h0, arsize});
    end else if (cur_state == wait_write) begin
      axi4_write(awaddr, wdata[63:32], wdata[31:0], {29'h0, awsize}, {24'h0, wstrb});
    end
  end

endmodule
