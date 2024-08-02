`include "defines.v"

module lsu (
    input           clock,
    input           reset,

    input           valid_pre_i,
    output          lsu_ready_pre_o,
    input           fu_ready_pre_o,

    input           ready_post_i,
    output          lsu_valid_post_o,

    input  [7:0]    inst_type_i,
    input  [7:0]    lsu_op_i,
    input  [31:0]   imm_i,
    input  [31:0]   rdata1_i,
    input  [31:0]   rdata2_i,

    output [31:0]   mem_result_o,

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
  
    //-----------------------------------------------------------------
    // PIPELINE REG
    //-----------------------------------------------------------------
    reg [7:0]  lsu_op;
    reg [31:0] imm;
    reg [31:0] rdata1;
    reg [31:0] rdata2;

    always @(posedge clock) begin
        if (reset) begin
            lsu_op    <= 0;
            imm       <= 0;
            rdata1    <= 0;
            rdata2    <= 0;
        end else if (valid_pre_i && fu_ready_pre_o && lsu_ready_pre_o) begin
            if (inst_type_i == `INST_LOAD || inst_type_i == `INST_STORE) begin
                lsu_op    <=  lsu_op_i;
                imm       <=  imm_i;
                rdata1    <=  rdata1_i;
                rdata2    <=  rdata2_i;
            end else begin
                lsu_op    <=  0;
                imm       <=  0;
                rdata1    <=  0;
                rdata2    <=  0;
            end
        end
    end

    //-----------------------------------------------------------------
    // FSM
    //-----------------------------------------------------------------
    parameter idle         = 3'b000; 
    parameter wait_ready   = 3'b001; 

    parameter wait_arready = 3'b010; 
    parameter wait_rvalid  = 3'b011; 
    parameter wait_awready = 3'b100; 
    parameter wait_bvalid  = 3'b101; 

    reg [2:0] cur_state;
    reg [2:0] next_state;

    //-----------------------------------------------------------------
    // Outputs 
    //-----------------------------------------------------------------
    assign lsu_ready_pre_o  = cur_state == idle;
    assign lsu_valid_post_o = cur_state == wait_ready;

    assign mem_result_o  = mem_result;

    assign awvalid_o  = cur_state == wait_awready;
    assign awaddr_o   = cur_state == wait_awready ? address : 0; 
    assign awid_o     = cur_state == wait_awready ? 0       : 0; 
    assign awlen_o    = cur_state == wait_awready ? 0       : 0; 
    assign awsize_o   = cur_state == wait_awready ? awsize  : 0;
    assign awburst_o  = cur_state == wait_awready ? 2'b01   : 0;

    assign wvalid_o   = cur_state == wait_awready;
    assign wdata_o    = cur_state == wait_awready ? wdata   : 0;
    assign wstrb_o    = cur_state == wait_awready ? wstrb   : 0;
    assign wlast_o    = cur_state == wait_awready ? 1       : 0;

    assign bready_o   = cur_state == wait_bvalid;

    assign arvalid_o  = cur_state == wait_arready;
    assign araddr_o   = cur_state == wait_arready ? address : 0;
    assign arid_o     = cur_state == wait_arready ? 0       : 0;
    assign arlen_o    = cur_state == wait_arready ? 0       : 0;
    assign arsize_o   = cur_state == wait_arready ? arsize  : 0;
    assign arburst_o  = cur_state == wait_arready ? 2'b01   : 0;

    assign rready_o   = cur_state == wait_rvalid;

    //-----------------------------------------------------------------
    // Synchronous State - Transition always@ ( posedge Clock ) block
    //-----------------------------------------------------------------
    always @(posedge clock) begin
        if (reset) begin
            cur_state <= idle;
        end else begin
            cur_state <= next_state;
        end
    end

    //-----------------------------------------------------------------
    // Conditional State - Transition always@ ( * ) block
    //-----------------------------------------------------------------
    always @( * ) begin
        if (reset) begin
            next_state = idle;  
        end else begin
            next_state = cur_state;
            case (cur_state)
                idle: begin
                    if (valid_pre_i) begin
                        if (inst_type_i == `INST_LOAD)
                            next_state = wait_arready;
                        else if (inst_type_i == `INST_STORE) 
                            next_state = wait_awready;
                    end
                end         
                wait_arready: if (arready_i)    next_state = wait_rvalid;  
                wait_awready: if (awready_i)    next_state = wait_bvalid;  
                wait_rvalid:  if (rvalid_i)     next_state = wait_ready; 
                wait_bvalid:  if (bvalid_i)     next_state = wait_ready;
                wait_ready:   if (ready_post_i) next_state = idle;
                default:                        next_state = cur_state;
            endcase
        end
    end

    //-----------------------------------------------------------------
    // Error detection
    //-----------------------------------------------------------------
    always @(posedge clock) begin
        if (!reset) begin
            if (rvalid_i && rresp_i != 2'b00) begin
                $fatal("read failed in lsu\n");
            end
        end
    end

    always @(posedge clock) begin
        if (!reset) begin
            if (bvalid_i && bresp_i != 2'b00) begin
                $fatal("write failed in lsu\n");
            end
        end
    end

    //-----------------------------------------------------------------
    // Miscellaneous
    //-----------------------------------------------------------------
    wire[31:0] address   = rdata1 + imm;
    wire[31:0] byte_lane = address % 4;

    reg [31:0] wdata;
    reg [3:0]  wstrb;
    reg [2:0]  awsize;
    reg [2:0]  arsize;
    reg [31:0] mem_result;

    always @(*) begin
        if (lsu_op == `LSU_OP_SB) begin
            case (byte_lane)
                0: wdata = {24'h0, rdata2[7:0]}; 
                1: wdata = {16'h0, rdata2[7:0],  8'h0}; 
                2: wdata = { 8'h0, rdata2[7:0], 16'h0}; 
                3: wdata = {rdata2[7:0], 24'h0}; 
                default: $fatal("write address not align");
            endcase
        end else if (lsu_op == `LSU_OP_SH) begin
            case (byte_lane)
                0: wdata = {16'h0, rdata2[15:0]}; 
                2: wdata = {rdata2[15:0], 16'h0}; 
                default: $fatal("write address not align");
            endcase
        end else if (lsu_op == `LSU_OP_SW) begin
            case (byte_lane)
                0: wdata = rdata2; 
                default: $fatal("write address not align");
            endcase
        end else begin
            wdata = 0;
        end
    end

    always @(*) begin
        if (lsu_op == `LSU_OP_SB) begin
            case (byte_lane)
                0: wstrb = 4'b0001;  
                1: wstrb = 4'b0010;
                2: wstrb = 4'b0100;
                3: wstrb = 4'b1000;
                default: $fatal("write address not align");
            endcase
        end else if (lsu_op == `LSU_OP_SH) begin
            case (byte_lane)
                0: wstrb = 4'b0011;  
                2: wstrb = 4'b1100;  
                default: $fatal("write address not align");
            endcase
        end else if (lsu_op == `LSU_OP_SW) begin
            case (byte_lane)
                0: wstrb = 4'b1111;  
                default: $fatal("write address not align");
            endcase
        end else begin
            wstrb = 0;
        end
    end

    always @(*) begin
        if (lsu_op == `LSU_OP_SB) begin
            awsize = 3'b000;
        end else if (lsu_op == `LSU_OP_SH) begin
            awsize = 3'b001;
        end else if (lsu_op == `LSU_OP_SW) begin
            awsize = 3'b010;
        end else begin
            awsize = 0;
        end
    end

    always @(*) begin
        if (lsu_op == `LSU_OP_LB || lsu_op == `LSU_OP_LBU) begin
            arsize = 3'b000;
        end else if (lsu_op == `LSU_OP_LH || lsu_op == `LSU_OP_LHU) begin
            arsize = 3'b001;
        end else if (lsu_op == `LSU_OP_LW) begin
            arsize = 3'b010;
        end else begin
            arsize = 0;
        end
    end

    always @(posedge clock) begin
        if (reset) begin
            mem_result <= 0;
        end else if (cur_state == wait_rvalid && rvalid_i) begin
            if (lsu_op == `LSU_OP_LB) begin
                case (byte_lane)
                    0: mem_result <= {{24{rdata_i[7 ]}}, rdata_i[7 :0 ]};
                    1: mem_result <= {{24{rdata_i[15]}}, rdata_i[15:8 ]}; 
                    2: mem_result <= {{24{rdata_i[23]}}, rdata_i[23:16]}; 
                    3: mem_result <= {{24{rdata_i[31]}}, rdata_i[31:24]}; 
                    default: mem_result <= mem_result;
                endcase
            end else if (lsu_op == `LSU_OP_LBU) begin
                case ( byte_lane )
                    0: mem_result <= {24'h0, rdata_i[7 :0 ]};
                    1: mem_result <= {24'h0, rdata_i[15:8 ]}; 
                    2: mem_result <= {24'h0, rdata_i[23:16]}; 
                    3: mem_result <= {24'h0, rdata_i[31:24]}; 
                    default: mem_result <= mem_result;
                endcase
            end else if (lsu_op == `LSU_OP_LH) begin
                    case (byte_lane)
                    0: mem_result <= {{16{rdata_i[15]}}, rdata_i[15:0 ]}; 
                    2: mem_result <= {{16{rdata_i[31]}}, rdata_i[31:16]}; 
                    default: mem_result <= mem_result;
                endcase
            end else if (lsu_op == `LSU_OP_LHU) begin
                case (byte_lane)
                    0: mem_result <= {16'h0, rdata_i[15:0 ]}; 
                    2: mem_result <= {16'h0, rdata_i[31:16]}; 
                    default: mem_result <= mem_result;
                endcase
            end else if (lsu_op == `LSU_OP_LW) begin
                case (byte_lane)
                    0: mem_result <= rdata_i; 
                    default: mem_result <= mem_result;
                endcase
            end else begin
                mem_result <= mem_result;
            end
        end
    end

endmodule
