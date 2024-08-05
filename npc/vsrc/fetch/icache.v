`include "defines.v"

module icache (
    input           clock,
    input           reset,

    input           request_valid_i,
    output          request_ready_o,

    input           response_ready_i,
    output          response_valid_o,

    input  [31:0]   pc_i,

    output [31:0]   pc_o,
    output [31:0]   inst_o,

    input           awready_i,     
    output          awvalid_o,
    output [31:0]   awaddr_o,
    output [3:0]    awid_o,
    output [7:0]    awlen_o,
    output [2:0]    awsize_o,
    output [1:0]    awburst_o,

    input           wready_i,      
    output          wvalid_o,
    output [31:0]   wdata_o,
    output [3:0]    wstrb_o,
    output          wlast_o,

    output          bready_o,
    input           bvalid_i,      
    input  [1:0]    bresp_i,       
    input  [3:0]    bid_i,         

    input           arready_i,
    output          arvalid_o,
    output [31:0]   araddr_o,
    output [3:0]    arid_o,
    output [7:0]    arlen_o,
    output [2:0]    arsize_o,
    output [1:0]    arburst_o,

    output          rready_o,
    input           rvalid_i,
    input  [1:0]    rresp_i,
    input  [31:0]   rdata_i,
    input           rlast_i,
    input  [3:0]    rid_i
);

    /*
    * Cache Configuration
    *
    * Block    : 16 Byte
    * Way      : 8
    * Group    : 8 
    * Capacity : 1024 Byte
    */

    reg         val[7:0][7:0];
    reg [24:0]  tag[7:0][7:0];
    reg [127:0] dat[7:0][7:0];
    reg [127:0] buffer;
    reg [7:0]   rec_cnt;     // receive count

    wire [3:0]  tar_offset = pc[3:0];
    wire [2:0]  tar_index  = pc[6:4];
    wire [24:0] tar_tag    = pc[31:7];

    //-----------------------------------------------------------------
    // Caching Request Araddr 
    //-----------------------------------------------------------------
    reg [31:0] pc;

    always @(posedge clock) begin
        if (reset) begin
            pc <= 0;
        end else if (cur_state == idle && request_valid_i) begin
            pc <= pc_i;
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
            buffer <= dat[tar_index][hit_idx];   
        end else if (cur_state == await) begin
            if (rvalid_i && rready_o) begin
                case (rec_cnt)
                    0: buffer[ 31: 0] <= rdata_i;
                    1: buffer[ 63:32] <= rdata_i;
                    2: buffer[ 95:64] <= rdata_i;
                    3: buffer[127:96] <= rdata_i;
                    default: buffer <= 0;
                endcase
                rec_cnt <= rec_cnt + 1;  
            end
        end else if (response_ready_i && response_valid_o) begin
            rec_cnt <= 0;
        end
    end

    reg [31:0] inst;

    always @(*) begin
        if (reset) begin
            inst = 0;
        end else begin
            case (tar_offset)
                0 : inst = buffer[ 31: 0];
                4 : inst = buffer[ 63:32];
                8 : inst = buffer[ 95:64];
                12: inst = buffer[127:96];
                default: $fatal("fuck!");
            endcase
        end
    end

    //-----------------------------------------------------------------
    // HIT Transaction
    //-----------------------------------------------------------------
    wire hit0 = (cur_state == seek) && (val[tar_index][0] == 1) && (tag[tar_index][0] == tar_tag);
    wire hit1 = (cur_state == seek) && (val[tar_index][1] == 1) && (tag[tar_index][1] == tar_tag);
    wire hit2 = (cur_state == seek) && (val[tar_index][2] == 1) && (tag[tar_index][2] == tar_tag);
    wire hit3 = (cur_state == seek) && (val[tar_index][3] == 1) && (tag[tar_index][3] == tar_tag);
    wire hit4 = (cur_state == seek) && (val[tar_index][4] == 1) && (tag[tar_index][4] == tar_tag);
    wire hit5 = (cur_state == seek) && (val[tar_index][5] == 1) && (tag[tar_index][5] == tar_tag);
    wire hit6 = (cur_state == seek) && (val[tar_index][6] == 1) && (tag[tar_index][6] == tar_tag);
    wire hit7 = (cur_state == seek) && (val[tar_index][7] == 1) && (tag[tar_index][7] == tar_tag);

    wire tar_hit  = hit0 || hit1 || hit2 || hit3 || hit4 || hit5 || hit6 || hit7;

    reg [2:0] hit_idx;

    always @(*) begin
        if (reset) begin
            hit_idx = 0;
        end else begin
            hit_idx = 0;
            if (hit0) hit_idx = 0;       
            if (hit1) hit_idx = 1;
            if (hit2) hit_idx = 2;
            if (hit3) hit_idx = 3;
            if (hit4) hit_idx = 4;
            if (hit5) hit_idx = 5;
            if (hit6) hit_idx = 6;
            if (hit7) hit_idx = 7;
        end
    end

    //-----------------------------------------------------------------
    // Miss Transaction
    //-----------------------------------------------------------------
    reg [2:0]   rand_idx;

    always @(posedge clock) begin
        if (reset) begin
        for (integer i = 0; i < 16; i = i + 1) begin
            for (integer j = 0; j < 8; j = j + 1) begin
                val[i][j] <= 0;
                tag[i][j] <= 0;
                dat[i][j] <= 0;
            end
        end
        end else if (cur_state == miss) begin
            rand_idx <= rand_num;
        end else if (response_ready_i && response_valid_o) begin
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
    assign request_ready_o  = cur_state == idle;
    assign response_valid_o = cur_state == hit || cur_state == resp;

    assign pc_o      = pc;
    assign inst_o    = inst;

    assign awvalid_o = 0;
    assign awaddr_o  = 0;
    assign awid_o    = 0;
    assign awlen_o   = 0;
    assign awsize_o  = 0;
    assign awburst_o = 0;

    assign wvalid_o  = 0;
    assign wdata_o   = 0;
    assign wstrb_o   = 0;
    assign wlast_o   = 0;

    assign bready_o  = 0;

    assign arvalid_o = cur_state == miss;
    assign araddr_o  = cur_state == miss ? (pc & 32'hfffffff0) : 0;    // Mask is related to block size
    assign arid_o    = cur_state == miss ? 0 : 0;
    assign arlen_o   = cur_state == miss ? 3 : 0;                      // Len is related to block size
    assign arsize_o  = cur_state == miss ? 3'b010 : 0;                 // Size is related to word width
    assign arburst_o = cur_state == miss ? 2'b01 : 0;

    assign rready_o  = cur_state == await;

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
                idle: if (request_valid_i) next_state = seek;
                seek: if (tar_hit) next_state = hit;
                      else next_state = miss;
                hit:  if (response_ready_i) next_state = idle;
                miss: if (arready_i) next_state = await;
                await:if (rlast_i) next_state = resp;
                resp: if (response_ready_i) next_state = idle;
                default: next_state = cur_state;
            endcase
        end
    end

    //-----------------------------------------------------------------
    // Miscellaneous
    //-----------------------------------------------------------------
    reg [2:0] lfsr;
    reg [2:0] rand_num;

    always @(*) begin
        rand_num = lfsr;
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            lfsr <= 3'b001; // 初始种子值，可以设置为其他非零值
        end else begin
            // 3-bit Galois LFSR with polynomial x^3 + x + 1
            lfsr[2] <= lfsr[1];
            lfsr[1] <= lfsr[0];
            lfsr[0] <= lfsr[2] ^ lfsr[0]; // XOR feedback
        end
    end


endmodule
