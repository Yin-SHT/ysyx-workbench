`include "defines.v"

module icache (
  input         clock,
  input         reset,

  input         flush_i,

  /** MASTER */
  /* AR: Address Read Channel */
  input         io_master_arready,
  output        io_master_arvalid,
  output [31:0] io_master_araddr ,
  output [3:0]  io_master_arid,
  output [7:0]  io_master_arlen,
  output [2:0]  io_master_arsize,
  output [1:0]  io_master_arburst,

  /*  R: Data Read Channel */
  output        io_master_rready,
  input         io_master_rvalid,
  input  [1:0]  io_master_rresp,
  input  [63:0] io_master_rdata,
  input         io_master_rlast,
  input  [3:0]  io_master_rid,

  /** SLAVE */
  /* AR: Address Read Channel */
  output        arready_o,
  input         arvalid_i,
  input [31:0]  araddr_i,

  /*  R: Data Read Channel */
  input         rready_i,
  output        rvalid_o,
  output [31:0] rdata_o
);
  
  /* Performance Event */
  export "DPI-C" function icache_event;
  function icache_event;
    output int state;
    output int hit;
    output int master_rvalid;
    state = {{29{1'b0}}, cur_state};
    hit = {{31{1'b0}}, target_hit};
    master_rvalid = {{31{1'b0}}, io_master_rvalid};
  endfunction

  reg [31:0] araddr;
  reg [2:0]  rand_num;
  reg [2:0]  transfer_cnt;

  wire [7:0]  hit;
  wire [7:0]  vac; 
  wire [2:0]  hit_idx;
  wire [2:0]  vac_idx;
  wire target_hit;
  wire target_vac;
  reg  record_vac;

  wire [127:0] hit_block;
  wire [31:0]  hit_rdata;

  reg  [127:0] miss_block;
  wire [31:0]  miss_rdata;

  reg         val[15:0][7:0];   // valid
  reg [23:0]  tag[15:0][7:0];   // tag
  reg [127:0] dat[15:0][7:0];   // data (16 Bytes)
  
  wire [23:0] target_tag    = araddr[31:8];
  wire [3:0]  target_index  = araddr[7:4];
  wire [3:0]  target_offset = araddr[3:0];
  reg  [23:0] record_tag;
  reg  [3:0]  record_offset;

  assign hit[0] = val[target_index][0] && (tag[target_index][0] == target_tag);
  assign hit[1] = val[target_index][1] && (tag[target_index][1] == target_tag);
  assign hit[2] = val[target_index][2] && (tag[target_index][2] == target_tag);
  assign hit[3] = val[target_index][3] && (tag[target_index][3] == target_tag);
  assign hit[4] = val[target_index][4] && (tag[target_index][4] == target_tag);
  assign hit[5] = val[target_index][5] && (tag[target_index][5] == target_tag);
  assign hit[6] = val[target_index][6] && (tag[target_index][6] == target_tag);
  assign hit[7] = val[target_index][7] && (tag[target_index][7] == target_tag);

  assign vac[0] = ~val[target_index][0];
  assign vac[1] = ~val[target_index][1];
  assign vac[2] = ~val[target_index][2];
  assign vac[3] = ~val[target_index][3];
  assign vac[4] = ~val[target_index][4];
  assign vac[5] = ~val[target_index][5];
  assign vac[6] = ~val[target_index][6];
  assign vac[7] = ~val[target_index][7];

  assign hit_idx =  hit[0] ? 0:
                    hit[1] ? 1:
                    hit[2] ? 2:
                    hit[3] ? 3:
                    hit[4] ? 4:
                    hit[5] ? 5:
                    hit[6] ? 6:
                    hit[7] ? 7: 0;

  assign vac_idx =  vac[0] ? 0:
                    vac[1] ? 1:
                    vac[2] ? 2:
                    vac[3] ? 3:
                    vac[4] ? 4:
                    vac[5] ? 5:
                    vac[6] ? 6:
                    vac[7] ? 7: 0;

  assign target_hit = hit[0] | hit[1] | hit[2] | hit[3] | hit[4] | hit[5] | hit[6] | hit[7]; 
  assign target_vac = vac[0] | vac[1] | vac[2] | vac[3] | vac[4] | vac[5] | vac[6] | vac[7]; 

  assign hit_block  = target_hit ? dat[target_index][hit_idx] : 0;
  assign hit_rdata  = (target_offset == 4'd0 ) ? hit_block[31:0]   :
                      (target_offset == 4'd4 ) ? hit_block[63:32]  :
                      (target_offset == 4'd8 ) ? hit_block[95:64]  :
                      (target_offset == 4'd12) ? hit_block[127:96] : 0;

  assign miss_rdata = (record_offset == 4'd0 ) ? miss_block[31:0]   :
                      (record_offset == 4'd4 ) ? miss_block[63:32]  :
                      (record_offset == 4'd8 ) ? miss_block[95:64]  :
                      (record_offset == 4'd12) ? miss_block[127:96] : 0;

  //-----------------------------------------------------------------
  // FSM
  //-----------------------------------------------------------------
  parameter idle         = 3'b000; 
  parameter seek_block   = 3'b001; 
  parameter hit_rready   = 3'b010; 

  parameter wait_arready = 3'b011; 
  parameter wait_rvalid  = 3'b100; 
  parameter miss_rready  = 3'b101; 

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  // Slave
  assign arready_o = (cur_state == idle);
  assign rvalid_o  = (cur_state == hit_rready) || (cur_state == miss_rready);
  assign rdata_o   = (cur_state == hit_rready ) ? hit_rdata  :
                     (cur_state == miss_rready) ? miss_rdata : 0;

  // Master
  assign io_master_arvalid = (cur_state == wait_arready);
  assign io_master_araddr  = (cur_state == wait_arready) ? (araddr & 32'hfffffff0) : 0;        
  assign io_master_arid    = (cur_state == wait_arready) ? 0      : 0;
  assign io_master_arlen   = (cur_state == wait_arready) ? 3      : 0;    // 16 Bytes (Bus width: 8 Bytes) ==> 4 Brust transfer
  assign io_master_arsize  = (cur_state == wait_arready) ? 3'b010 : 0;    // 4 Bytes in a brust transfer
  assign io_master_arburst = (cur_state == wait_arready) ? 2'b01  : 0;    // INCR
  assign io_master_rready  = (cur_state == wait_rvalid);

  //-----------------------------------------------------------------
  // Synchronous State - Transition always@ (posedge clock) block
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
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
            idle:         if (arvalid_i)  next_state = seek_block;
            seek_block:   if (target_hit) next_state = hit_rready; 
                          else next_state = wait_arready;
            hit_rready:   if (rready_i) next_state = idle;
            wait_arready: if (io_master_arready) next_state = wait_rvalid;
            wait_rvalid:  if (io_master_rvalid && io_master_rlast) next_state = miss_rready;
            miss_rready:  if (rready_i) next_state = idle;
          default: next_state = cur_state;
        endcase
    end
  end

  //-----------------------------------------------------------------
  // MISCELLANEOUS
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
      araddr <= 0;   
    end else if (arvalid_i) begin
      araddr <= araddr_i;
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      record_vac    <= 0;
      record_tag    <= 0;
      record_offset <= 0;
    end else if (cur_state == seek_block) begin
      record_vac    <= target_vac;
      record_tag    <= target_tag;
      record_offset <= target_offset;
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      rand_num <= 0;
    end else if (cur_state == wait_arready) begin
      rand_num <= {{$random()} % 8}[2:0];
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      transfer_cnt <= 0;
    end else if (io_master_rvalid && !io_master_rlast) begin
      transfer_cnt <= transfer_cnt + 1;
    end else if (io_master_rvalid &&  io_master_rlast) begin
      transfer_cnt <= 0;
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      miss_block <= 0;
    end else if (transfer_cnt == 0 && io_master_rvalid) begin
      if (araddr % 8 == 0) miss_block[ 31: 0] <= io_master_rdata[31:0];
      else if (araddr % 8 == 4) miss_block[ 31: 0] <= io_master_rdata[63:32];
    end else if (transfer_cnt == 1 && io_master_rvalid) begin
      if ((araddr + 4) % 8 == 0) miss_block[ 63:32] <= io_master_rdata[31:0];
      else if ((araddr + 4) % 8 == 4) miss_block[ 63:32] <= io_master_rdata[63:32];
    end else if (transfer_cnt == 2 && io_master_rvalid) begin
      if ((araddr + 8)% 8 == 0) miss_block[ 95:64] <= io_master_rdata[31:0];
      else if ((araddr + 8) % 8 == 4) miss_block[ 95:64] <= io_master_rdata[63:32];
    end else if (transfer_cnt == 3 && io_master_rvalid) begin
      if ((araddr + 12) % 8 == 0) miss_block[127:96] <= io_master_rdata[31:0];
      else if ((araddr + 12) % 8 == 4) miss_block[127:96] <= io_master_rdata[63:32];
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      for (integer i = 0; i < 16; i = i + 1) begin
        for (integer j = 0; j < 8; j = j + 1) begin
          val[i][j] <= 0;
          tag[i][j] <= 0;
          dat[i][j] <= 0;
        end
      end
    end else if (flush_i) begin
      // Must in idle state !!!!!!!!
      for (integer i = 0; i < 16; i = i + 1) begin
        for (integer j = 0; j < 8; j = j + 1) begin
          val[i][j] <= 0;
          tag[i][j] <= 0;
          dat[i][j] <= 0;
        end
      end
    end else if (record_vac && cur_state == miss_rready && rready_i) begin
      val[target_index][vac_idx]  <= 1;
      tag[target_index][vac_idx]  <= record_tag;
      dat[target_index][vac_idx]  <= miss_block;    
    end else if (cur_state == miss_rready && rready_i) begin
      val[target_index][rand_num] <= 1;
      tag[target_index][rand_num] <= record_tag;
      dat[target_index][rand_num] <= miss_block;     
    end
  end

endmodule
