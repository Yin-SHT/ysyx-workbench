`include "defines.v"

module fetch_controller (
    input           reset,
    input           clock,

    input           valid_pre_i,
    output          ready_pre_o,

    output          valid_post_o,
    input           ready_post_i,

    output          request_valid_o,
    input           request_ready_i,

    output          response_ready_o,
    input           response_valid_i,

    input           branch_en_i,
    input  [31:0]   dnpc_i,

    output [31:0]   pc_o
);

    //-----------------------------------------------------------------
    // PC
    //-----------------------------------------------------------------
    reg [31:0] pc;
    
    assign pc_o   = pc;

    always @(posedge clock) begin
        if (reset) begin
            pc <= 0;
        end else if (firing) begin
            pc <= `RESET_VECTOR;
        end else if (valid_pre_i && ready_pre_o) begin
            if (branch_en_i) begin
                pc <= dnpc_i;
            end else begin
                pc <= pc + 4;
            end
        end 
    end

    //-----------------------------------------------------------------
    // FSM
    //-----------------------------------------------------------------
    parameter init         = 3'b000; 
    parameter idle         = 3'b001; 
    parameter wait_iready  = 3'b010; 
    parameter wait_ivalid  = 3'b011; 
    parameter wait_ready   = 3'b100;

    reg [2:0] cur_state;
    reg [2:0] next_state;

    //-----------------------------------------------------------------
    // Outputs 
    //-----------------------------------------------------------------
    assign ready_pre_o      = cur_state == idle;
    assign valid_post_o     = cur_state == wait_ready;

    assign request_valid_o  = cur_state == wait_iready;
    assign response_ready_o = cur_state == wait_ivalid;

    //-----------------------------------------------------------------
    // Synchronous State - Transition always@ ( posedge Clock ) block
    //-----------------------------------------------------------------
    always @(posedge clock) begin
        if (reset) begin
            cur_state <= init;
        end else begin
            cur_state <= next_state;
        end
    end

    //-----------------------------------------------------------------
    // Conditional State - Transition always@ ( * ) block
    //-----------------------------------------------------------------
    always @( * ) begin
        if (reset) begin
            next_state = init;  
        end else begin
            next_state = cur_state;
            case (cur_state)
                init:        if (firing)           next_state = wait_iready;
                idle:        if (valid_pre_i)      next_state = wait_iready;
                wait_iready: if (request_ready_i)  next_state = wait_ivalid;  
                wait_ivalid: if (response_valid_i) next_state = wait_ready; 
                wait_ready:  if (ready_post_i)     next_state = idle;
            default:                               next_state = cur_state;
            endcase
        end
    end

    //-----------------------------------------------------------------
    // Miscellaneous
    //-----------------------------------------------------------------
    reg [127:0] tick;
    wire firing = tick == 1;

    always @(posedge clock) begin
        if (reset) begin
            tick <= 0;
        end else begin
            tick <= tick + 1;
        end
    end

    //-----------------------------------------------------------------
    // performance counter
    //-----------------------------------------------------------------
    export "DPI-C" function fetch_cnt;
    function fetch_cnt;
        output int complete;
        complete = {31'h0, pre_handshake};
    endfunction

    reg pre_handshake;
    reg cur_handshake;
 
    always @(posedge clock) begin
        if (reset) begin
            pre_handshake <= 0;
            cur_handshake <= 0;
        end else begin
            pre_handshake <= cur_handshake;
            cur_handshake <= valid_pre_i && ready_pre_o;
        end
    end

endmodule 
