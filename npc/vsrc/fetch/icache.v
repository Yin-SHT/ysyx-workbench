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
    hit = {{31{1'b0}}, tar_hit};
    master_rvalid = {{31{1'b0}}, io_master_rvalid};
  endfunction
  
  /*
   * Cache Configuration
   *
   * Block    : 16 Byte
   * Way      : 8
   * Group    : 16
   * Capacity : 2048 Byte
  */

  reg         val[15:0][7:0];
  reg [23:0]  tag[15:0][7:0];
  reg [127:0] dat[15:0][7:0];
  reg [127:0] buffer;
  reg [7:0]   rec_cnt;     // receive count

  wire [3:0]  tar_offset = araddr[3:0];
  wire [3:0]  tar_index  = araddr[7:4];
  wire [23:0] tar_tag    = araddr[31:8];

  //-----------------------------------------------------------------
  // Caching Request Araddr 
  //-----------------------------------------------------------------
  reg [31:0] araddr;

  always @(posedge clock) begin
    if (reset) begin
      araddr <= 0;
    end else if (cur_state == idle && arvalid_i) begin
      araddr <= araddr_i;
    end else if (cur_state == idle && !arvalid_i) begin
      araddr <= 0;
    end
  end

  //-----------------------------------------------------------------
  // Request Data
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
      buffer  <= 0;
      rec_cnt <= 0;
    end else if (cur_state == seek && tar_hit) begin
      buffer <= dat[tar_index][hit_idx];   // Cacheb hit
    end else if (cur_state == await) begin
      if (io_master_rvalid && io_master_rready) begin
        case (rec_cnt)
          0: buffer[ 31: 0] <= io_master_rdata[31:0];
          1: buffer[ 63:32] <= io_master_rdata[63:32];
          2: buffer[ 95:64] <= io_master_rdata[31:0];
          3: buffer[127:96] <= io_master_rdata[63:32];
          default: buffer <= 0;
        endcase
        rec_cnt <= rec_cnt + 1;
      end
    end else if (cur_state == idle) begin
      buffer  <= 0;
      rec_cnt <= 0;
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

  wire tar_hit  = hit0 | hit1 | hit2 | hit3 | hit4 | hit5 | hit6 | hit7;

  wire hit0 = (cur_state == seek) && (val[tar_index][0] == 1) && (tag[tar_index][0] == tar_tag);
  wire hit1 = (cur_state == seek) && (val[tar_index][1] == 1) && (tag[tar_index][1] == tar_tag);
  wire hit2 = (cur_state == seek) && (val[tar_index][2] == 1) && (tag[tar_index][2] == tar_tag);
  wire hit3 = (cur_state == seek) && (val[tar_index][3] == 1) && (tag[tar_index][3] == tar_tag);
  wire hit4 = (cur_state == seek) && (val[tar_index][4] == 1) && (tag[tar_index][4] == tar_tag);
  wire hit5 = (cur_state == seek) && (val[tar_index][5] == 1) && (tag[tar_index][5] == tar_tag);
  wire hit6 = (cur_state == seek) && (val[tar_index][6] == 1) && (tag[tar_index][6] == tar_tag);
  wire hit7 = (cur_state == seek) && (val[tar_index][7] == 1) && (tag[tar_index][7] == tar_tag);

  //-----------------------------------------------------------------
  // Miss Transaction
  //-----------------------------------------------------------------
  reg [2:0]   rand_idx;

  always @(posedge clock) begin
    if (reset | flush_i) begin
      for (integer i = 0; i < 16; i = i + 1) begin
        for (integer j = 0; j < 8; j = j + 1) begin
          val[i][j] <= 0;
          tag[i][j] <= 0;
          dat[i][j] <= 0;
        end
      end
    end else if (cur_state == miss) begin
      rand_idx <= {{$random()} % 8}[2:0];
    end else if (cur_state == resp) begin
      val[tar_index][rand_idx] <= 1;
      tag[tar_index][rand_idx] <= tar_tag;
      dat[tar_index][rand_idx] <= buffer;
    end
  end

  //-----------------------------------------------------------------
  // FSM
  //-----------------------------------------------------------------
  parameter idle  = 3'b000; 
  parameter seek  = 3'b001; 
  parameter hit   = 3'b010; 
  parameter miss  = 3'b011; 
  parameter await = 3'b100; 
  parameter resp  = 3'b101;

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  // Slave
  assign arready_o = (cur_state == idle);
  assign rvalid_o  = (cur_state == hit ) || (cur_state == resp);
  assign rdata_o   = (cur_state == hit ) || (cur_state == resp) ? 
                     (
                      tar_offset == 0  ? buffer[ 31: 0] :
                      tar_offset == 4  ? buffer[ 63:32] :
                      tar_offset == 8  ? buffer[ 95:64] :
                      tar_offset == 12 ? buffer[127:96] : 0
                     ) : 0;

  // Master
  assign io_master_arvalid = (cur_state == miss);
  assign io_master_araddr  = (cur_state == miss) ? (araddr & 32'hfffffff0) : 0;    // Mask is related to block size
  assign io_master_arid    = (cur_state == miss) ? 0 : 0;
  assign io_master_arlen   = (cur_state == miss) ? 3 : 0;                          // Len is related to block size
  assign io_master_arsize  = (cur_state == miss) ? 3'b010 : 0;                     // Size is related to word width
  assign io_master_arburst = (cur_state == miss) ? 2'b01 : 0;
  assign io_master_rready  = (cur_state == await);

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
        idle: if (arvalid_i) next_state = seek;
        seek: if (tar_hit) next_state = hit;
              else next_state = miss;
        hit:  if (rready_i) next_state = idle;
        miss: if (io_master_arready) next_state = await;
        await:if (io_master_rlast) next_state = resp;
        resp: if (rready_i) next_state = idle;
        default: next_state = cur_state;
      endcase
    end
  end

endmodule
