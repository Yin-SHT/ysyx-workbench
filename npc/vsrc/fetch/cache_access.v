`include "defines.v"

module cache_access (
  input          clock,
  input          reset,

  input          valid_pre_i,
  output         ready_pre_o,

  output         valid_post_o,
  input          ready_post_i,

  input          flush_i,         // flush pipeline registers, fsm reset to correct state when flush_i is 1
  input          csr_flush_i,

  input          wen_i,
  input  [2:0]   windex_i,
  input  [2:0]   wway_i,
  input  [24:0]  wtag_i,
  input  [127:0] wdata_i,

  input          pvalid_i,
  input          ptaken_i,      
  input  [31:0]  ptarget_i,     
  input  [31:0]  araddr_i,

  output         tar_hit_o,
  output         pvalid_o,
  output         ptaken_o,      
  output [31:0]  ptarget_o,     
  output [31:0]  araddr_o,
  output [127:0] buffer_o
);

  /* Performance Event */
  export "DPI-C" function icache_event;
  function icache_event;
    output int check;
    output int hit;
    check = {31'h0, valid_post_o && ready_post_i};
    hit   = {31'h0, tar_hit_o};
  endfunction
  
  /*
   * Cache Configuration
   *
   * Block    : 16 Byte
   * Way      : 8
   * Group    : 16
   * Capacity : 2048 Byte
  */

  reg         val[7:0][7:0];
  reg [24:0]  tag[7:0][7:0];
  reg [127:0] dat[7:0][7:0];

  wire [2:0]  tar_index  = araddr[6:4];
  wire [24:0] tar_tag    = araddr[31:7];

  //-----------------------------------------------------------------
  // Caching Info
  //-----------------------------------------------------------------
  reg        pvalid;
  reg        ptaken;      
  reg [31:0] ptarget;     
  reg [31:0] araddr;

  always @(posedge clock) begin
    if (reset) begin
      pvalid  <= 0;
      ptaken  <= 0;
      ptarget <= 0;
      araddr  <= 0;
    end else if (flush_i) begin
      pvalid  <= 0;
      ptaken  <= 0;
      ptarget <= 0;
      araddr  <= 0;
    end else if (csr_flush_i) begin
      pvalid  <= 0;
      ptaken  <= 0;
      ptarget <= 0;
      araddr  <= 0;
    end else if (valid_pre_i && ready_pre_o) begin
      pvalid  <= pvalid_i;
      ptaken  <= ptaken_i;
      ptarget <= ptarget_i;
      araddr  <= araddr_i;
    end
  end

  //-----------------------------------------------------------------
  // HIT Transaction
  //-----------------------------------------------------------------
  wire [2:0] hit_idx  = hit0 ? 0 : 
                        hit1 ? 1 :
                        hit2 ? 2 :
                        hit3 ? 3 :
                        hit4 ? 4 :
                        hit5 ? 5 :
                        hit6 ? 6 :
                        hit7 ? 7 : 0;

  wire hit0 = (cur_state == wait_ready) && (val[tar_index][0] == 1) && (tag[tar_index][0] == tar_tag);
  wire hit1 = (cur_state == wait_ready) && (val[tar_index][1] == 1) && (tag[tar_index][1] == tar_tag);
  wire hit2 = (cur_state == wait_ready) && (val[tar_index][2] == 1) && (tag[tar_index][2] == tar_tag);
  wire hit3 = (cur_state == wait_ready) && (val[tar_index][3] == 1) && (tag[tar_index][3] == tar_tag);
  wire hit4 = (cur_state == wait_ready) && (val[tar_index][4] == 1) && (tag[tar_index][4] == tar_tag);
  wire hit5 = (cur_state == wait_ready) && (val[tar_index][5] == 1) && (tag[tar_index][5] == tar_tag);
  wire hit6 = (cur_state == wait_ready) && (val[tar_index][6] == 1) && (tag[tar_index][6] == tar_tag);
  wire hit7 = (cur_state == wait_ready) && (val[tar_index][7] == 1) && (tag[tar_index][7] == tar_tag);

  //-----------------------------------------------------------------
  // Update Icache 
  //-----------------------------------------------------------------
  always @(negedge clock) begin
    if (reset) begin
      for (integer i = 0; i < 16; i = i + 1) begin
        for (integer j = 0; j < 8; j = j + 1) begin
          val[i][j] <= 0;
          tag[i][j] <= 0;
          dat[i][j] <= 0;
        end
      end
    end else if (wen_i) begin
      val[windex_i][wway_i] <= 1;
      tag[windex_i][wway_i] <= wtag_i;
      dat[windex_i][wway_i] <= wdata_i;
    end
  end

  //-----------------------------------------------------------------
  // FSM
  //-----------------------------------------------------------------
  parameter idle       = 3'b000; 
  parameter wait_ready = 3'b001;

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign ready_pre_o = cur_state == idle;
  assign valid_post_o = cur_state == wait_ready;

  assign tar_hit_o  = hit0 | hit1 | hit2 | hit3 | hit4 | hit5 | hit6 | hit7;
  assign pvalid_o   = pvalid;
  assign ptaken_o   = ptaken;
  assign ptarget_o  = ptarget;
  assign araddr_o   = araddr;
  assign buffer_o   = dat[tar_index][hit_idx]; 


  //-----------------------------------------------------------------
  // Synchronous State - Transition always@ (posedge clock) block
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
      cur_state <= idle;
    end else if (flush_i) begin
      cur_state <= idle;
    end else if (csr_flush_i) begin
      cur_state <= idle;
    end else begin
      cur_state <= next_state;
    end
  end

  //-----------------------------------------------------------------
  // Conditional State - Transition always@ (*) block
  //-----------------------------------------------------------------
  always @(*) begin
    if (reset) begin
      next_state = idle;  
    end else begin
      next_state = cur_state;
      case (cur_state)
        idle:       if (valid_pre_i)  next_state = wait_ready;
        wait_ready: if (ready_post_i) next_state = idle;
        default: next_state = cur_state;
      endcase
    end
  end

endmodule
