`include "defines.v"

module execute_controller (
    input           clock,
    input           reset,

    input           valid_pre_i,
    output          ready_pre_o,

    output          valid_post_o,
    input           ready_post_i,

    input  [7:0]    inst_type_i,

    output          access_begin_o,
    input           access_done_i,

    output          we_o
);

    parameter idle         = 2'b00;  
    parameter wait_ready   = 2'b01;  
    parameter mem_access   = 2'b10;

    //-----------------------------------------------------------------
    // FSM
    //-----------------------------------------------------------------
    reg [1:0] cur_state;
    reg [1:0] next_state;

    //-----------------------------------------------------------------
    // Outputs 
    //-----------------------------------------------------------------
    assign we_o           = valid_pre_i && ready_pre_o;
    assign access_begin_o = cur_state == mem_access;
    assign ready_pre_o    = cur_state == idle;
    assign valid_post_o   = cur_state == wait_ready;

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
    always @(*) begin
        if (reset) begin
            next_state = idle;  
        end else begin
            next_state = cur_state;
            case (cur_state)
                idle: begin
                    if (valid_pre_i) begin
                        if (inst_type_i == `INST_LOAD || inst_type_i == `INST_STORE)
                            next_state = mem_access;
                        else 
                            next_state = wait_ready;
                    end
                end 
                wait_ready: if (ready_post_i)   next_state = idle;
                mem_access: if (access_done_i)  next_state = wait_ready;
                default:                        next_state = cur_state;
            endcase
        end
    end

endmodule 
