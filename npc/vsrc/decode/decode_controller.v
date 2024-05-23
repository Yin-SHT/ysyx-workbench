`include "defines.v"

module decode_controller (
  input  clock,
  input  reset,

  input  raw_i,
  output [1:0] state_o,

  input  valid_pre_i,
  output valid_post_o,

  input  ready_post_i,
  output ready_pre_o,

  output we_o
);

  /* Performance Event */
  export "DPI-C" function decode_event;
  function decode_event;
      output int idu_valid_pre;
      output int idu_ready_pre;
      idu_valid_pre  = {{31{1'b0}}, valid_pre_i};
      idu_ready_pre  = {{31{1'b0}}, ready_pre_o};
  endfunction

  parameter idle       = 2'b00;
  parameter wait_ready = 2'b01;  // wait both data and execute ready

  reg [1:0] cur_state;
  reg [1:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign we_o         = (valid_pre_i && ready_pre_o);
  assign ready_pre_o  = (cur_state == idle);
  assign valid_post_o = (cur_state == wait_ready) && !raw_i;  // data is ready

  assign state_o = cur_state;

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
    next_state = cur_state;
    case (cur_state)
      idle:       if (valid_pre_i)  next_state = wait_ready;
      wait_ready: if (raw_i) next_state = wait_ready;
                  else if (ready_post_i) next_state = idle;
      default: next_state = cur_state;
    endcase
  end

endmodule 
