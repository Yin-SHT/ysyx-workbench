`include "defines.v"

module pmem (
    input           clock,
    input           reset,

    output          awready_o,
    input           awvalid_i,
    input [31:0]    awaddr_i,
    input [3:0]     awid_i,
    input [7:0]     awlen_i,
    input [2:0]     awsize_i,
    input [1:0]     awburst_i,

    output          wready_o,
    input           wvalid_i,
    input [31:0]    wdata_i,
    input [3:0]     wstrb_i,
    input           wlast_i,

    input           bready_i,
    output          bvalid_o,
    output [1:0]    bresp_o,
    output [3:0]    bid_o,

    output          arready_o,
    input           arvalid_i,
    input  [31:0]   araddr_i,
    input  [3:0]    arid_i,
    input  [7:0]    arlen_i,
    input  [2:0]    arsize_i,
    input  [1:0]    arburst_i,

    input           rready_i,
    output          rvalid_o,
    output [1:0]    rresp_o,
    output [31:0]   rdata_o,
    output          rlast_o,
    output [3:0]    rid_o
);
  
    import "DPI-C" function void axi4_read(input int araddr, output int rdata, input int arsize);
    import "DPI-C" function void axi4_write(input int awaddr, input int wdata, input int awsize, input int wstrb);

    parameter idle         = 3'b000;  

    parameter wait_read    = 3'b010;
    parameter wait_rready  = 3'b011;  

    parameter wait_write   = 3'b100;
    parameter wait_bready  = 3'b101;
    
    reg [2:0]  cur_state;
    reg [2:0]  next_state;

    reg [31:0] araddr;
    reg [7:0]  arlen;
    reg [2:0]  arsize;
    reg [31:0] rdata;

    reg [31:0] awaddr;
    reg [2:0]  awsize;
    reg [31:0] wdata;
    reg [3:0]  wstrb;

    //-----------------------------------------------------------------
    // Outputs 
    //-----------------------------------------------------------------
    assign awready_o = cur_state == idle;

    assign wready_o  = cur_state == idle;

    assign bvalid_o  = cur_state == wait_bready;
    assign bresp_o   = 0;
    assign bid_o     = 0;

    assign arready_o = cur_state == idle;

    assign rvalid_o  = cur_state == wait_rready;
    assign rresp_o   = 0;
    assign rdata_o   = cur_state == wait_rready ? rdata      : 0;
    assign rlast_o   = cur_state == wait_rready ? arlen == 0 : 0;
    assign rid_o     = 0;
    
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
                    if (arvalid_i) begin
                        next_state = wait_read;
                    end if (awvalid_i) begin
                        next_state = wait_write;
                    end
                end      
                wait_read:   next_state = wait_rready;
                wait_write:  next_state = wait_bready;
                wait_rready: if (rready_i && arlen != 0) next_state = wait_read;
                             else if (rready_i && arlen == 0) next_state = idle;
                wait_bready: if (bready_i) next_state = idle;
                default: next_state = cur_state;
            endcase
        end
    end

    //-----------------------------------------------------------------
    // Miscellaneous
    //-----------------------------------------------------------------
    always @(posedge clock) begin
        if (reset) begin
            awaddr <= 0;
            awsize <= 0;
            wdata  <= 0;
            wstrb  <= 0;
        end else if (cur_state == idle && awvalid_i && wvalid_i) begin
            awaddr <= awaddr_i;
            awsize <= awsize_i;
            wdata  <= wdata_i;
            wstrb  <= wstrb_i;
        end 
    end

    always @(posedge clock) begin
        if (reset) begin
            araddr <= 0;
            arlen  <= 0;
            arsize <= 0;
        end else if (cur_state == idle && arvalid_i) begin
            araddr <= araddr_i;
            arlen  <= arlen_i;
            arsize <= arsize_i;
        end else if (cur_state == wait_rready && rready_i) begin
            if (arlen > 0) 
                arlen <= arlen - 1; 
        end else if (cur_state == wait_read) begin
            araddr <= araddr + 4;
        end
    end

    always @(posedge clock) begin
        if (cur_state == wait_read) begin
            axi4_read(araddr, rdata, {29'h0, arsize});
        end else if (cur_state == wait_write) begin
            axi4_write(awaddr, wdata, {29'h0, awsize}, {28'h0, wstrb});
        end
    end

endmodule
