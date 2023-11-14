`include "defines.v"

module isram (
  input                         clk,
  input                         rst,

  /* Address Read Channel */
  input   [`INST_ADDR_BUS]      araddr_i,

  input                         arvalid_i,
  output                        arready_o,

  /* Data Read Channel */
  output  reg [`INST_DATA_BUS]  rdata_o,
  output  reg [`INST_DATA_BUS]  rresp_o,

  input                         rready_i,
  output                        rvalid_o
);

  import "DPI-C" function int paddr_read(input int raddr, output int rresp_o);

  parameter idle        = 2'b00;
  parameter read        = 2'b01;
  parameter wait_rready = 2'b10;

  reg [3:0] rc_cnt;               // Data Read Channel
  reg [1:0] cur_state;
  reg [1:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign arready_o = ( cur_state == idle        );
  assign rvalid_o  = ( cur_state == wait_rready );

  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      rdata_o   <= 32'h0000_0000;
    end else begin
      rdata_o <= rdata_o;
      if ( arvalid_i && arready_o ) begin
        rdata_o <= paddr_read( araddr_i, rresp_o );
      end else begin
        rdata_o <= rdata_o;
      end
    end
  end


  //-----------------------------------------------------------------
  // Synchronous State - Transition always@ ( posedge Clock ) block
  //-----------------------------------------------------------------
  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      cur_state <= idle;
    end else begin
      cur_state <= next_state;
    end
  end


  //-----------------------------------------------------------------
  // Conditional State - Transition always@ ( * ) block
  //-----------------------------------------------------------------
  always @( * ) begin
    if ( rst == `RST_ENABLE ) begin
      next_state = idle;  
    end else begin
      next_state = cur_state;
      case ( cur_state )
        idle:        if ( arvalid_i )               next_state = read;
        read:        if ( rc_cnt >= `RC_THRESHOLD ) next_state = wait_rready;
        wait_rready: if ( rready_i )                next_state = idle;
        default: next_state = cur_state;
      endcase
    end
  end


  //-----------------------------------------------------------------
  // Miscellaneous
  //-----------------------------------------------------------------
  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      rc_cnt <= 4'h0;
    end else begin
      if ( cur_state == read ) begin
        rc_cnt <= rc_cnt + 1;
      end else begin
        rc_cnt <= 4'b0;
      end
    end
  end

endmodule //isram 
