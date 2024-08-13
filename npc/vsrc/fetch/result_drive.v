`include "defines.v"

module result_drive (
  input         clock,
  input         reset,

  input         valid_pre_i,
  output        ready_pre_o,

  output        valid_post_o,
  input         ready_post_i,

  input         commit_csr_i,

  output        flush_o,
  output        csr_flush_o,
  output [31:0] csr_target_o,

  input         tar_hit_i,
  input         pvalid_i,
  input         ptaken_i,      
  input [31:0]  ptarget_i,     
  input [31:0]  araddr_i,
  input [127:0] buffer_i,

  output        wen_o,
  output [2:0]  windex_o,
  output [2:0]  wway_o,
  output [24:0] wtag_o,
  output [127:0]wdata_o,

  output        pvalid_o,
  output        ptaken_o,      
  output [31:0] ptarget_o,     
  output [31:0] pc_o,
  output [31:0] inst_o,

  output [2:0]  fetch_state_o,
  input         fetch_raw_i,
  input         is_branch_i,
  input         is_csr_i,
  input         fail_i,      // 0: not-taken 1: taken
  input         csr_flush_i,
  input  [31:0] csr_target_i,

  // AR: Address Read Channel 
  input         io_master_arready,
  output        io_master_arvalid,
  output [31:0] io_master_araddr ,
  output [3:0]  io_master_arid,
  output [7:0]  io_master_arlen,
  output [2:0]  io_master_arsize,
  output [1:0]  io_master_arburst,

  //  R: Data Read Channel
  output        io_master_rready,
  input         io_master_rvalid,
  input  [1:0]  io_master_rresp,          // don't use for now
  input  [31:0] io_master_rdata,
  input         io_master_rlast,
  input  [3:0]  io_master_rid             // don't use for now
);

  /* Performance Event */
  export "DPI-C" function drive_event;
  function drive_event;
    output int check;
    output int is_branch;
    output int succ;
    check     = {31'h0, valid_post_o && ready_post_i};
    is_branch = {31'h0, is_branch_i};
    succ      = {31'h0, !fail_i};
  endfunction

  reg         pvalid;
  reg         ptaken;
  reg [31:0]  ptarget;
  reg [31:0]  araddr;
  reg [127:0] buffer;
  reg [7:0]   rec_cnt;     // receive count
  reg [2:0]   rand_way;    // random selected way number

  wire [24:0] tar_tag    = araddr[31:7];
  wire [2:0]  tar_index  = araddr[6:4];
  wire [3:0]  tar_offset = araddr[3:0];

  always @(posedge clock) begin
    if (reset) begin
      pvalid  <= 0;
      ptaken  <= 0;
      ptarget <= 0;
      araddr  <= 0;
      buffer  <= 0;
      rec_cnt <= 0;
    end else if (valid_pre_i && ready_pre_o) begin   // Caching Info
      pvalid  <= pvalid_i;
      ptaken  <= ptaken_i;
      ptarget <= ptarget_i;
      araddr  <= araddr_i;
      buffer  <= buffer_i;
    end else if (io_master_rvalid && io_master_rready) begin
      case (rec_cnt)
        0: buffer[ 31: 0] <= io_master_rdata;
        1: buffer[ 63:32] <= io_master_rdata;
        2: buffer[ 95:64] <= io_master_rdata;
        3: buffer[127:96] <= io_master_rdata;
        default: buffer <= 0;
      endcase
      if (io_master_rlast)
        rec_cnt <= 0;
      else
        rec_cnt <= rec_cnt + 1;
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      rand_way <= 0;
    end else if (io_master_arvalid && io_master_arready) begin
      rand_way <= {{$random()} % 8}[2:0];
    end
  end

  //-----------------------------------------------------------------
  // FSM
  //-----------------------------------------------------------------
  parameter idle         = 3'b000; 
  parameter wait_arready = 3'b001; 
  parameter wait_rvalid  = 3'b010; 
  parameter wait_ready   = 3'b011; 
  parameter read_end     = 3'b100; 
  parameter single_cycle = 3'b101;    // single cycle mode: wait until csr instruction done

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign ready_pre_o  = cur_state == idle;
  assign valid_post_o = (cur_state == wait_ready || cur_state == read_end) ? (is_branch_i ? !fetch_raw_i : 1) : 0;

  assign flush_o = valid_post_o && ready_post_i && is_branch_i && fail_i;  // decode stage receives a taken instruction
  assign csr_flush_o = valid_post_o && ready_post_i && csr_flush_i;        // csr flush only used for ecall and mret
  assign csr_target_o = csr_target_i;

  assign wen_o    = cur_state == read_end && valid_post_o && ready_post_i;
  assign windex_o = tar_index;
  assign wway_o   = rand_way;
  assign wtag_o   = tar_tag;
  assign wdata_o  = buffer;

  assign fetch_state_o = cur_state;  

  assign pvalid_o  = pvalid;
  assign ptaken_o  = ptaken;
  assign ptarget_o = ptarget;
  assign pc_o   = araddr;
  assign inst_o = tar_offset == 0  ? buffer[ 31: 0] :
                  tar_offset == 4  ? buffer[ 63:32] :
                  tar_offset == 8  ? buffer[ 95:64] :
                  tar_offset == 12 ? buffer[127:96] : 0;


  // Master
  assign io_master_arvalid = (cur_state == wait_arready);
  assign io_master_araddr  = (cur_state == wait_arready) ? (araddr & 32'hfffffff0) : 0;    // Mask is related to block size
  assign io_master_arid    = (cur_state == wait_arready) ? 0 : 0;
  assign io_master_arlen   = (cur_state == wait_arready) ? 3 : 0;                          // Len is related to block size
  assign io_master_arsize  = (cur_state == wait_arready) ? 3'b010 : 0;                     // Size is related to word width
  assign io_master_arburst = (cur_state == wait_arready) ? 2'b01 : 0;
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
        idle:         if (valid_pre_i) begin
                        if (tar_hit_i)
                          next_state = wait_ready;
                        else 
                          next_state = wait_arready;
                      end
        wait_ready:   if (is_branch_i) begin
                        if (!fetch_raw_i && ready_post_i) begin
                          next_state = idle;        
                        end
                      end else if (is_csr_i) begin
                        if (ready_post_i) begin
                          next_state = single_cycle;
                        end
                      end else begin
                        if (ready_post_i) begin
                          next_state = idle;
                        end
                      end
        wait_arready: if (io_master_arready) next_state = wait_rvalid;
        wait_rvalid:  if (io_master_rlast)   next_state = read_end;
        read_end:     if (is_branch_i) begin
                        if (!fetch_raw_i && ready_post_i) begin
                          next_state = idle;        
                        end
                      end else if (is_csr_i) begin
                        if (ready_post_i) begin
                          next_state = single_cycle;
                        end
                      end else begin
                        if (ready_post_i) begin
                          next_state = idle;
                        end
                      end
        single_cycle: if (commit_csr_i) next_state = idle;    // csr instruction done
        default: next_state = cur_state;
      endcase
    end
  end

endmodule
