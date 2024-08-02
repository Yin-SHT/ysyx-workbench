`include "defines.v"

module fetch_controller (
    input           reset,
    input           clock,

    input           valid_pre_i,
    output          ready_pre_o,

    output          valid_post_o,
    input           ready_post_i,

    input           branch_en_i,
    input  [31:0]   dnpc_i,

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

    //-----------------------------------------------------------------
    // PC
    //-----------------------------------------------------------------
    reg [31:0] pc;
    reg [31:0] inst;
    
    assign pc_o   = pc;
    assign inst_o = inst;

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

    always @(posedge clock) begin
        if (reset) begin
            inst <= 0;
        end else if (rvalid_i && rready_o) begin
            inst <= rdata_i;
        end 
    end

    //-----------------------------------------------------------------
    // FSM
    //-----------------------------------------------------------------
    parameter init         = 3'b000; 
    parameter idle         = 3'b001; 
    parameter wait_ready   = 3'b010; 

    parameter wait_arready = 3'b011; 
    parameter wait_rvalid  = 3'b100; 

    reg [2:0] cur_state;
    reg [2:0] next_state;

    //-----------------------------------------------------------------
    // Outputs 
    //-----------------------------------------------------------------
    assign ready_pre_o  = cur_state == idle;
    assign valid_post_o = cur_state == wait_ready;

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

    assign arvalid_o = cur_state == wait_arready;    
    assign araddr_o  = cur_state == wait_arready ? pc_o   : 0;                                  
    assign arid_o    = cur_state == wait_arready ? 0      : 0;                                
    assign arlen_o   = cur_state == wait_arready ? 0      : 0;                                 
    assign arsize_o  = cur_state == wait_arready ? 3'b010 : 0;                                  
    assign arburst_o = cur_state == wait_arready ? 2'b01  : 0;                                   

    assign rready_o  = cur_state == wait_rvalid;    

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
                init:         if (firing)       next_state = wait_arready;
                idle:         if (valid_pre_i)  next_state = wait_arready;
                wait_arready: if (arready_i)    next_state = wait_rvalid;  
                wait_rvalid:  if (rvalid_i)     next_state = wait_ready; 
                wait_ready:   if (ready_post_i) next_state = idle;
            default:                            next_state = cur_state;
            endcase
        end
    end

    //-----------------------------------------------------------------
    // Error detection
    //-----------------------------------------------------------------
    always @(posedge clock) begin
        if (!reset) begin
            if (rvalid_i && rresp_i != 2'b00) begin
                $fatal("read failed in fetch\n");
            end
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
        output int _nr_fetch_;
        complete = {31'h0, pre_handshake};
        _nr_fetch_ = nr_fetch;
    endfunction

    reg pre_handshake;
    reg cur_handshake;
    reg [31:0] nr_fetch;
 
    always @(posedge clock) begin
        if (reset) begin
            pre_handshake <= 0;
            cur_handshake <= 0;
        end else begin
            pre_handshake <= cur_handshake;
            cur_handshake <= valid_pre_i && ready_pre_o;
        end
    end

    always @(posedge clock) begin
        if (reset) begin
            nr_fetch <= 0;
        end else if (rvalid_i && rready_o) begin
            nr_fetch <= nr_fetch + 1;
        end
    end

endmodule 
