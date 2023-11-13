`include "../defines.v"

module exu_fsm (
  input    clk,
  input    rst,

  /* IDU */
  input    [`INST_TYPE_BUS]   inst_type_i,
  input    valid_pre_i,
  output   ready_pre_o,

  /* WBU */
  output   valid_post_o,
  input    ready_post_i,

  /* Address Read Channel */
  output   arvalid_o,
  input    arready_i,

  /* Data Read Channel */
  input    rvalid_i,
  input    [`INST_DATA_BUS] rresp_i,
  output   rready_o,

  output   we_o
);

  parameter idle         = 2'b00;
  parameter wait_arready = 2'b01;
  parameter wait_rvalid  = 2'b10;
  parameter wait_ready   = 2'b11;

  reg [1:0] cur_state;
  reg [1:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign we_o         = ( valid_pre_i && ready_pre_o );
  assign ready_pre_o  = ( cur_state == idle          );
  assign valid_post_o = ( cur_state == wait_ready    );
  assign arvalid_o    = ( cur_state == wait_arready  );
  assign rready_o     = ( cur_state == wait_rvalid   );


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
            idle: begin
              if ( valid_pre_i && inst_type_i == `INST_LOAD ) begin
                next_state = wait_arready;
              end else if ( valid_pre_i && inst_type_i != `INST_LOAD ) begin
                next_state = wait_ready;
              end
            end 
            wait_arready: if ( arready_i                  ) next_state = wait_rvalid;
            wait_rvalid:  if ( rvalid_i                   ) next_state = wait_ready;
            wait_ready:   if ( ready_post_i               ) next_state = idle;
          default: next_state <= cur_state;
        endcase
    end
  end

endmodule // ifu_fsm
