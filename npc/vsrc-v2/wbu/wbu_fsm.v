`include "../defines.v"

module wbu_fsm (
  input    clk,
  input    rst,

  input    valid_pre_i,
  output   valid_post_o,

  input    ready_post_i,
  output   ready_pre_o,

  output   we
);

  parameter idle       = 2'b00;
  parameter wback      = 2'b01;
  parameter wait_ready = 2'b10;

  reg [7:0] wback_cnt;           // Recode number of cycles of wbacking
  reg [1:0] cur_state;
  reg [1:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign we           = ((valid_pre_i && wback_cnt == 8'b0)) ? `WRITE_ENABLE : `WRITE_DISABLE;

  assign ready_pre_o  = (cur_state == idle      ) ? 1'b1 : 1'b0;
  assign valid_post_o = (cur_state == wait_ready) ? 1'b1 : 1'b0;

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
    next_state = cur_state;
    case ( cur_state )
      idle: begin
        if ( valid_pre_i ) next_state = wback;      
      end
      wback: begin
        if ( wback_cnt >= `WBU_DELAY ) next_state = wait_ready;
      end
      wait_ready: begin
        if ( ready_post_i ) next_state = idle;
      end
      default: begin
        next_state = cur_state;
      end 
    endcase
  end

  //-----------------------------------------------------------------
  // Miscellaneous
  //-----------------------------------------------------------------
  always @( posedge clk or negedge rst ) begin
    wback_cnt <= wback_cnt;
    if ( rst == `RST_ENABLE ) begin
      wback_cnt <= 8'b0;
    end else begin
      if ( cur_state == idle ) begin
        wback_cnt <= 8'b0;
      end else if ( cur_state == wback ) begin
        wback_cnt <= wback_cnt + 8'b1;
      end
    end
  end

endmodule // wbu_fsm
