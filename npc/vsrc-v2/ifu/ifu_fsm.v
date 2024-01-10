`include "defines.v"

module ifu_fsm (
  input    clk,
  input    rst,

  /* WBU */
  input    valid_pre_i,
  output   ready_pre_o,

  /* IDU */
  output   valid_post_o,
  input    ready_post_i,

  /* AR: Address Read Channel */
  input                      arready_i,
  output                     arvalid_o,
//output [31:0]              araddr_o,    ifu.v
  output [3:0]               arid_o,
  output [7:0]               arlen_o,
//output [2:0]               arsize_o,    ifu.v
  output [1:0]               arburst_o,

  /*  R: Data Read Channel */
  output                     rready_o,
  input                      rvalid_i,
  input  [1:0]               rresp_i,
//input  [63:0]              rdata_i,     ifu.v
  input                      rlast_i,
  input  [3:0]               rid_i,

  output                     we_o
);

  parameter idle         = 3'b000;

  /* States with read operation */
  parameter wait_arready = 3'b001;
  parameter wait_rvalid  = 3'b010;

  parameter wait_ready   = 3'b011;

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign we_o         = ( valid_pre_i && ready_pre_o  );

  assign ready_pre_o  = ( cur_state   == idle         );
  assign valid_post_o = ( cur_state   == wait_ready   ) || 
                        (( cur_state  == wait_rvalid  ) && ( rvalid_i == 1'b1 ));

  /* Read */
  assign arvalid_o    = ( cur_state   == wait_arready );    // ARC
  assign arid_o       = 0;
  assign arlen_o      = 0;
  assign arburst_o    = 0;

  assign rready_o     = ( cur_state   == wait_rvalid  );    //  RC

  //-----------------------------------------------------------------
  // Synchronous State - Transition always@ ( posedge Clock ) block
  //-----------------------------------------------------------------
  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      cur_state <= idle;
    end else begin
      cur_state <= next_state;
    end
  end


  //-----------------------------------------------------------------
  // Conditional State - Transition always@ ( * ) block
  //-----------------------------------------------------------------
  always @( * ) begin
    if ( rst == `RST_ENABLE ) begin
      next_state = idle;  
    end else begin
        next_state = cur_state;
        case ( cur_state )
            idle:         if ( valid_pre_i  ) next_state = wait_arready;
            wait_arready: if ( arready_i    ) next_state = wait_rvalid;  
            wait_rvalid:  if ( rvalid_i && ready_post_i ) next_state = idle; 
                          else if ( rvalid_i && !ready_post_i ) next_state = wait_ready;
            wait_ready:   if ( ready_post_i ) next_state = idle;
          default:                            next_state = cur_state;
        endcase
    end
  end

endmodule // ifu_fsm
