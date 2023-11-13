`include "../defines.v"

module dsram (
  input                         clk,
  input                         rst,

  input   [`INST_TYPE_BUS]      inst_type_i,

  /* Address Read Channel */
  input   [`INST_ADDR_BUS]      araddr_i,

  input                         arvalid_i,
  output                        arready_o,

  /* Data Read Channel */
  output  reg [`INST_DATA_BUS]  rdata_o,
  output  reg [`INST_DATA_BUS]  rresp_o,

  input                         rready_i,
  output                        rvalid_o,

  /* Address Write Channel */
  input   [`MEM_ADDR_BUS]       awaddr_i,

  /* Data Write Channel */
  input   [`MEM_DATA_BUS]       wdata_i,
  input   [8 - 1 : 0]           wstrb_i
);

  import "DPI-C" function int paddr_read(input int raddr, output int rresp_o);
  import "DPI-C" function void paddr_write(input int waddr, input int wdata, input byte wmask);

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
      rdata_o <= 32'h0;
    end else begin
      if ( arvalid_i && arready_o ) begin
        rdata_o <= paddr_read( araddr_i, rresp_o );
      end else begin
        rdata_o <= rdata_o;
      end
    end
  end

  always @( * ) begin
    if ( rst == `RST_DISABLE && inst_type_i == `INST_STORE ) begin
      paddr_write(awaddr_i, wdata_i, wstrb_i);
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
      if ( arvalid_i && cur_state == read ) begin
        rc_cnt <= rc_cnt + 1;
      end else begin
        rc_cnt <= 4'b0;
      end
    end
  end

endmodule //isram 
