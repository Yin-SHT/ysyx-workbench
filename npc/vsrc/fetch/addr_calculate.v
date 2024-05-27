`include "defines.v"

module addr_calculate (
  input         clock,
  input         reset,

  output        valid_post_o,
  input         ready_post_i,

  input         flush_i,       // pc receive new correct address, fsm reset to correct state when flush_i is 1
  input  [31:0] dnpc_i,

  output [31:0] pc_o
);

  /* Performance Event */
  export "DPI-C" function addr_event;
  function addr_event;
    output int _pc_;
    _pc_ = pc_o;
  endfunction
  
  //-----------------------------------------------------------------
  // Calculate Address
  //-----------------------------------------------------------------
  reg [31:0] pc; 

  assign pc_o = pc;

  always @(posedge clock) begin
    if (reset) begin
      pc <= 0; 
    end else if (firing) begin
      pc <= `RESET_VECTOR;
    end else if (flush_i) begin
      pc <= dnpc_i;
    end else if (cur_state == calculate) begin
      pc <= pc + 4; 
    end
  end

  //-----------------------------------------------------------------
  // FSM
  //-----------------------------------------------------------------
  parameter init       = 3'b000; 
  parameter calculate  = 3'b001; 
  parameter wait_ready = 3'b010; 

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign valid_post_o = cur_state == wait_ready;

  //-----------------------------------------------------------------
  // Synchronous State - Transition always@ ( posedge Clock ) block
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
      cur_state <= init;
    end else if (flush_i) begin
      cur_state <= wait_ready;
    end else begin
      cur_state <= next_state;
    end
  end

  //-----------------------------------------------------------------
  // Conditional State - Transition always@ ( * ) block
  //-----------------------------------------------------------------
  always @( * ) begin
    if (reset) begin
      next_state = init;  
    end else begin
      next_state = cur_state;
      case (cur_state)
        init:       if (firing) next_state = wait_ready;
        calculate:  next_state = wait_ready;
        wait_ready: if (ready_post_i) next_state = calculate;
        default: next_state = cur_state;
      endcase
    end
  end

  //-----------------------------------------------------------------
  // Miscellaneous
  //-----------------------------------------------------------------
  reg[127:0] fire;
  wire       firing = (fire == 1);

  always @(posedge clock) begin
    if (reset) begin
      fire <= 0;
    end else begin
      fire <= fire + 1;
    end
  end

endmodule 
