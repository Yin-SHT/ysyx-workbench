`include "defines.v"

module icache (
  input         clock,
  input         reset,

  /** MASTER */
  /* AR: Address Read Channel */
  input         io_master_arready,
  output        io_master_arvalid,
  output [31:0] io_master_araddr ,
  output [3:0]  io_master_arid,
  output [7:0]  io_master_arlen,
  output [2:0]  io_master_arsize,
  output [1:0]  io_master_arburst,

  /*  R: Data Read Channel */
  output        io_master_rready,
  input         io_master_rvalid,
  input  [1:0]  io_master_rresp,
  input  [63:0] io_master_rdata,
  input         io_master_rlast,
  input  [3:0]  io_master_rid,

  /** SLAVE */
  /* AR: Address Read Channel */
  output        arready_o,
  input         arvalid_i,
  input [31:0]  araddr_i,

  /*  R: Data Read Channel */
  input         rready_i,
  output        rvalid_o,
  output [31:0] rdata_o
);
  
  reg[31:0] araddr;

  wire [25:0] target_tag    = araddr[31:6];
  wire [3:0]  target_index  = araddr[5:2];
  wire target_hit = (tag[target_index] == target_tag) && valid[target_index];

  reg[25:0] tag[15:0];
  reg[31:0] data[15:0];

  reg[15:0] valid;

  parameter idle         = 3'b000; 
  parameter seek_block   = 3'b001; 

  parameter wait_arready = 3'b010; 
  parameter wait_rvalid  = 3'b011; 
  parameter wait_rready  = 3'b100; 

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  // Slave
  assign arready_o = (cur_state == idle);
  assign rvalid_o  = (cur_state == wait_rready);
  assign rdata_o   = (cur_state == wait_rready) ? data[target_index] : 0;

  // Master
  assign io_master_arvalid = (cur_state == wait_arready);
  assign io_master_araddr  = (cur_state == wait_arready) ? araddr : 0;        
  assign io_master_arid    = (cur_state == wait_arready) ? 0      : 0;
  assign io_master_arlen   = (cur_state == wait_arready) ? 0      : 0;
  assign io_master_arsize  = (cur_state == wait_arready) ? 3'b010 : 0;
  assign io_master_arburst = (cur_state == wait_arready) ? 2'b01  : 0;
  assign io_master_rready  = (cur_state == wait_rvalid);

  //-----------------------------------------------------------------
  // Synchronous State - Transition always@ (posedge clock) block
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
      cur_state <= idle;
    end else begin
      cur_state <= next_state;
    end
  end

  //-----------------------------------------------------------------
  // Conditional State - Transition always@ (*) block
  //-----------------------------------------------------------------
  always @(*) begin
    if (reset) begin
      next_state = idle;  
    end else begin
        next_state = cur_state;
        case (cur_state)
            idle:         if (arvalid_i)  next_state = seek_block;
            seek_block:   if (target_hit) next_state = wait_rready; 
                          else next_state = wait_arready;
            wait_rready:  if (rready_i) next_state = idle;
            wait_arready: if (io_master_arready) next_state = wait_rvalid;
            wait_rvalid:  if (io_master_rvalid) next_state = wait_rready;
          default: next_state = cur_state;
        endcase
    end
  end

  //-----------------------------------------------------------------
  // MISCELLANEOUS
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
      araddr <= 0;   
    end else if (arvalid_i) begin
      araddr <= araddr_i;
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      for (integer i = 0; i < 16; i = i + 1) begin
        valid[i] <= 0;
        tag[i]   <= 0;
        data[i]  <= 0;
      end
    end else if (io_master_rvalid) begin
      valid[target_index] <= 1;
      tag[target_index] <= target_tag;
      if (araddr % 8 == 0) 
        data[target_index] <= io_master_rdata[31:0];
      else if (araddr % 8 == 4) 
        data[target_index] <= io_master_rdata[63:32];
      else
        $fatal("Unaligin access in ifu: 0x%08x\n", araddr);
    end
  end

endmodule
