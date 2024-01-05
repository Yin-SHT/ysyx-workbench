`include "defines.v"

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

  /* AR: Address Read Channel */
  output   arvalid_o,
  input    arready_i,

  /*  R: Data Read Channel */
  /* verilator lint_off UNUSEDSIGNAL */
  input    [`RRESP_DATA_BUS] rresp_i,
  input    rvalid_i,
  output   rready_o,

  /* WR: Address Write Channel */
  output   awvalid_o,
  input    awready_i,

  /*  W: Data Write Channel */
  output   wvalid_o,
  input    wready_i,

  /*  B: Response Write Channel */
  input    [`BRESP_DATA_BUS] bresp_i,
  input    bvalid_i,
  output   bready_o,

  output   we_o
);

  parameter idle         = 3'b000;
  parameter wait_ready   = 3'b001;

  parameter wait_arready = 3'b010;
  parameter wait_rvalid  = 3'b011;

  parameter wait_awr_wr  = 3'b100;
  parameter wait_awready = 3'b101;
  parameter wait_wready  = 3'b110;
  parameter wait_bvalid  = 3'b111;

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign we_o         = ( valid_pre_i && ready_pre_o  );

  assign ready_pre_o  = ( cur_state   == idle         );
  assign valid_post_o = ( cur_state   == wait_ready   ) || 
                        (( cur_state  == wait_rvalid  ) && ( rvalid_i )) ||
                        (( cur_state  == wait_bvalid  ) && ( bvalid_i ));

  /* Read */
  assign arvalid_o    = ( cur_state   == wait_arready );    // ARC
  assign rready_o     = ( cur_state   == wait_rvalid  );    //  RC

  /* Write */
  assign awvalid_o    = ( cur_state   == wait_awready ) || ( cur_state == wait_awr_wr );    // AWC
  assign wvalid_o     = ( cur_state   == wait_wready  ) || ( cur_state == wait_awr_wr );    //  WC
  assign bready_o     = ( cur_state   == wait_bvalid  );    //  BC


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
              if (( valid_pre_i ) && ( inst_type_i == `INST_LOAD )) begin
                next_state = wait_arready;
              end else if (( valid_pre_i ) && ( inst_type_i == `INST_STORE )) begin
                next_state = wait_awr_wr;
              end else if (( valid_pre_i ) && ( inst_type_i != `INST_LOAD ) && ( inst_type_i != `INST_STORE )) begin
                next_state = wait_ready;
              end
            end 
            wait_arready: if ( arready_i    ) next_state = wait_rvalid;  
            wait_rvalid:  if ( rvalid_i && ready_post_i ) next_state = idle; 
                          else if ( rvalid_i && !ready_post_i ) next_state = wait_ready;
            wait_awr_wr:  if ( awready_i && wready_i ) next_state = wait_bvalid;
                          else if ( awready_i && !wready_i ) next_state = wait_wready;
                          else if ( !awready_i && wready_i ) next_state = wait_awready;
            wait_awready: if ( awready_i    ) next_state = wait_bvalid;
            wait_wready:  if ( wready_i     ) next_state = wait_bvalid;
            wait_bvalid:  if ( bvalid_i && ready_post_i ) next_state = idle;
                          else if ( bvalid_i && !ready_post_i ) next_state = wait_ready;
            wait_ready:   if ( ready_post_i ) next_state = idle;
          default:                            next_state = cur_state;
        endcase
    end
  end

endmodule // ifu_fsm
