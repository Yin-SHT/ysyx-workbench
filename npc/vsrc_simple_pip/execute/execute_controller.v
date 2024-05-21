`include "defines.v"

module execute_controller (
  input                      clock,
  input                      reset,

  input                      valid_pre_i,
  output                     ready_pre_o,

  output                     valid_post_o,
  input                      ready_post_i,

  input    [`INST_TYPE_BUS]  inst_type_i,

  output                     we_o,
  output                     rdata_we_o,

  // AW: Address Write Channel 
  input                      awready_i,
  output                     awvalid_o,

  //  W: Data Write Channel 
  input                      wready_i,
  output                     wvalid_o,

  //  B: Response Write Channel 
  output                     bready_o,
  input                      bvalid_i,
  input  [`AXI4_BRESP_BUS]   bresp_i,    // don't use
  input  [`AXI4_BID_BUS]     bid_i,      // don't use

  // AR: Address Read Channel
  input                      arready_i,
  output                     arvalid_o,

  //  R: Data Read Channel
  output                     rready_o,
  input                      rvalid_i,
  input  [`AXI4_RRESP_BUS]   rresp_i,    // don't use
  input                      rlast_i,    // don't use
  input  [`AXI4_RID_BUS]     rid_i       // don't use
);

  parameter idle         = 3'b000;  
  parameter wait_ready   = 3'b001;  

  parameter wait_arready = 3'b010;  
  parameter wait_rvalid  = 3'b011;  

  parameter wait_aw_w    = 3'b100;  
  parameter wait_awready = 3'b101;  
  parameter wait_wready  = 3'b110;
  parameter wait_bvalid  = 3'b111;

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign we_o         = ( valid_pre_i && ready_pre_o );
  assign rdata_we_o   = ( rvalid_i    && rready_o    );

  assign ready_pre_o  = ( cur_state   == idle        );
  assign valid_post_o = ( cur_state   == wait_ready  );

  // AW
  assign awvalid_o    = (( cur_state == wait_awready ) || ( cur_state == wait_aw_w ));

  // W
  assign wvalid_o     = (( cur_state == wait_wready  ) || ( cur_state == wait_aw_w ));

  // B
  assign bready_o     = ( cur_state == wait_bvalid   );

  // AR
  assign arvalid_o    = ( cur_state == wait_arready  );

  // R
  assign rready_o     = ( cur_state == wait_rvalid   );
   
  //-----------------------------------------------------------------
  // Synchronous State - Transition always@ ( posedge Clock ) block
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if ( reset == `RESET_ENABLE ) begin
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
        case ( cur_state )
            idle: begin
              if (( valid_pre_i ) && ( inst_type_i == `INST_LOAD )) begin
                next_state = wait_arready;
              end else if (( valid_pre_i ) && ( inst_type_i == `INST_STORE )) begin
                next_state = wait_aw_w;
              end else if (( valid_pre_i ) && ( inst_type_i != `INST_LOAD ) && ( inst_type_i != `INST_STORE )) begin
                next_state = wait_ready;
              end
            end 
            wait_arready: if ( arready_i    ) next_state = wait_rvalid;  
            wait_rvalid:  if ( rvalid_i     ) next_state = wait_ready;
            wait_aw_w:    begin
              if ( awready_i && wready_i ) begin
                next_state = wait_bvalid;
              end else if ( awready_i && !wready_i ) begin
                next_state = wait_wready; 
              end else if ( !awready_i && wready_i ) begin
                next_state = wait_awready;
              end
            end
            wait_awready: if ( awready_i    ) next_state = wait_bvalid;
            wait_wready:  if ( wready_i     ) next_state = wait_bvalid;
            wait_bvalid:  if ( bvalid_i     ) next_state = wait_ready;
            wait_ready:   if ( ready_post_i ) next_state = idle;
          default:                            next_state = cur_state;
        endcase
    end
  end

endmodule // ifu_fsm
