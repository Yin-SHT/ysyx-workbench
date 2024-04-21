`include "defines.v"

module clint (
  input         clock,
  input         reset,

  /* AR */
  input[31:0]   araddr_i,
  input         arvalid_i,
  output        arready_o,

  /* R  */
  output[63:0]  rdata_o,
  output[1:0]   rresp_o,
  output        rlast_o,
  output[3:0]   rid_o,
  output        rvalid_o,
  input         rready_i
);

assign rlast_o = 1;
assign rid_o   = 0;

/* MTIME REGISTER */
reg[63:0] mtime;

always @(posedge clock or negedge reset) begin
  if (reset) begin
    mtime <= 0;
  end else begin
    mtime <= mtime + 1;
  end
end
 
/* AXI-LITE PROTOCOL */
wire in_clint = (araddr_i >= 32'h0200_0000) && (araddr_i <= 32'h0200_ffff);

parameter idle         = 3'b001; 
parameter wait_rready  = 3'b010; 

reg[2:0] cur_state;
reg[2:0] next_state;

reg[31:0] araddr;

always @(posedge clock or negedge reset) begin
  if (reset) begin
    araddr <= 0;
  end else begin
    if (arvalid_i && in_clint) begin
      araddr <= araddr_i;
    end
  end
end

//-----------------------------------------------------------------
// Outputs 
//-----------------------------------------------------------------
// AR
assign arready_o = (cur_state == idle);

//  R
assign rresp_o   = 0;
assign rdata_o   = (cur_state == wait_rready) && (araddr[3:0] == 4'h0) ? {32'h0, mtime[31: 0]} :
                   (cur_state == wait_rready) && (araddr[3:0] == 4'h4) ? {32'h0, mtime[63:32]} : 0;
assign rvalid_o  = cur_state == wait_rready;

//-----------------------------------------------------------------
// Synchronous State - Transition always@ ( posedge Clock ) block
//-----------------------------------------------------------------
always @(posedge clock or negedge reset) begin
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
        idle:         if (arvalid_i && in_clint) next_state = wait_rready;
        wait_rready:  if (rready_i)  next_state = idle;  
      default:                       next_state = cur_state;
    endcase
  end
end
 
endmodule
