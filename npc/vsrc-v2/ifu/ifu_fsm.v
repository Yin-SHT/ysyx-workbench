`include "defines.v"

module ifu_fsm (
  input    clock,
  input    reset,

  input    valid_pre_i,
  output   ready_pre_o,

  output   valid_post_o,
  input    ready_post_i,

  output   pc_we_o,
  output   rdata_we_o,

  // AR: Address Read Channel 
  input                      arready_i,
  output                     arvalid_o,

  //  R: Data Read Channel
  output                     rready_o,
  input                      rvalid_i,
  input  [`AXI4_RRESP_BUS]   rresp_i,      
  input                      rlast_i,      
  input  [`AXI4_RID_BUS]     rid_i         
);

  parameter idle         = 3'b000;
  parameter wait_ready   = 3'b001;

  parameter wait_arready = 3'b010;
  parameter wait_rvalid  = 3'b011;

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign pc_we_o      = ( valid_pre_i && ready_pre_o );
  assign rdata_we_o   = ( rvalid_i    && rready_o && rlast_i );

  assign ready_pre_o  = ( cur_state   == idle       );
  assign valid_post_o = ( cur_state   == wait_ready );

  // AR
  assign arvalid_o    = ( cur_state   == wait_arready );    

  //  R
  assign rready_o     = ( cur_state   == wait_rvalid  );    

  //-----------------------------------------------------------------
  // Synchronous State - Transition always@ ( posedge Clock ) block
  //-----------------------------------------------------------------
  always @( posedge clock or negedge reset ) begin
    if ( reset == `RESET_ENABLE ) begin
      cur_state <= idle;
    end else begin
      cur_state <= next_state;
    end
  end

  //-----------------------------------------------------------------
  // Conditional State - Transition always@ ( * ) block
  //-----------------------------------------------------------------
  always @( * ) begin
    if ( reset == `RESET_ENABLE ) begin
      next_state = idle;  
    end else begin
        next_state = cur_state;
        case ( cur_state )
            idle:         if ( valid_pre_i  ) next_state = wait_arready;
            wait_arready: if ( arready_i    ) next_state = wait_rvalid;  
            wait_rvalid:  if ( rvalid_i && rlast_i ) next_state = wait_ready; 
            wait_ready:   if ( ready_post_i ) next_state = idle;
          default:        next_state = cur_state;
        endcase
    end
  end

  always @( * ) begin
    if ( &rresp_i && &rid_i ) begin
      // do nothing for now
    end
  end

endmodule // ifu_fsm
