`include "defines.v"

module commit_controller (
  input    clock,
  input    reset,

  input    valid_pre_i,
  output   ready_pre_o,

  output   commit_valid_o,

  output   we_o
);

  export "DPI-C" function commit_event;
  function commit_event;
    output int commit;
    commit = {31'h0, commit_valid_o};
  endfunction

  parameter idle  = 2'b00;
  parameter await = 2'b01;

  reg [1:0] cur_state;
  reg [1:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign we_o = valid_pre_i && ready_pre_o;
  assign ready_pre_o = cur_state == idle;
  assign commit_valid_o = cur_state == await;

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
      idle:  if (valid_pre_i)  next_state = await;
      await: next_state = idle;
      default: next_state = cur_state;
    endcase
  end

endmodule 
