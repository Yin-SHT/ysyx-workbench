`include "defines.v"

module fetch_controller (
  input    clock,
  input    reset,

  output   valid_post_o,
  input    ready_post_i,

  input    firing,

  // controller -> reg
  output   pc_we_o,
  output   inst_we_o,

  // controller -> icache
  input    arready_i,
  output   arvalid_o,
  output   rready_o,
  input    rvalid_i
);

  /* Performance Event */
  export "DPI-C" function fetch_event;
  function fetch_event;
      output int fetch_arvalid_o;
      output int fetch_rvalid_i;
      output int fetch_rready_o;
      fetch_arvalid_o = {{31{1'b0}}, arvalid_o};
      fetch_rready_o  = {{31{1'b0}}, rready_o};
      fetch_rvalid_i  = {{31{1'b0}}, rvalid_i};
  endfunction

  parameter idle         = 3'b000; 
  parameter wait_ready   = 3'b001; 

  parameter wait_arready = 3'b010; 
  parameter wait_rvalid  = 3'b011; 

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign valid_post_o = cur_state == wait_ready;

  assign pc_we_o      = valid_post_o && ready_post_i;
  assign inst_we_o    = rvalid_i && rready_o   ;

  assign arvalid_o    = cur_state == wait_arready;    
  assign rready_o     = cur_state == wait_rvalid ;    

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
            idle:         if (firing)       next_state = wait_arready;
            wait_arready: if (arready_i)    next_state = wait_rvalid;  
            wait_rvalid:  if (rvalid_i)     next_state = wait_ready; 
            wait_ready:   if (ready_post_i) next_state = wait_arready;
          default:                          next_state = cur_state;
        endcase
    end
  end

endmodule // ifu_fsm
