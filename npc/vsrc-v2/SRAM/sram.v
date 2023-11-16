`include "defines.v"

module sram (
  input                         clk,
  input                         rst,

  /* ARC: Address Read Channel */
  input   [`INST_ADDR_BUS]      araddr_i,

  input                         arvalid_i,
  output                        arready_o,

  /*  RC: Data Read Channel */
  output  reg [`INST_DATA_BUS]  rdata_o,
  output  reg [`INST_DATA_BUS]  rresp_o,

  output                        rvalid_o,
  input                         rready_i,

  /* AWC: Address Write Channel */
  input   [`MEM_ADDR_BUS]       awaddr_i,

  input                         awvalid_i,
  output                        awready_o,

  /*  WC: Data Write Channel */
  input   [`MEM_DATA_BUS]       wdata_i,
  input   [7:0]                 wstrb_i,

  input                         wvalid_i,
  output                        wready_o,

  /*  BC: Response Write Channel */
  output  reg [`INST_DATA_BUS]  bresp_o,

  output                        bvalid_o,
  input                         bready_i
);

  import "DPI-C" function int paddr_read(input int raddr, output int rresp_o);
  import "DPI-C" function int paddr_write(input int waddr, input int wdata, input byte wmask);

  parameter idle        = 3'b000;

  /* States with read operation */
  parameter read        = 3'b001;
  parameter wait_rready = 3'b010;

  /* States with write operation */
  parameter wait_wvalid = 3'b011;
  parameter write       = 3'b100;
  parameter wait_bready = 3'b101;

  reg [3:0] rc_cnt;               // RC: Data Read Channel
  reg [3:0] wc_cnt;               // WC: Data Write Channel
  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign arready_o = ( cur_state == idle        );
  assign rvalid_o  = ( cur_state == wait_rready );
  
  assign awready_o = ( cur_state == idle        );
  assign wready_o  = ( cur_state == wait_wvalid );
  assign bvalid_o  = ( cur_state == wait_bready );

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

  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      bresp_o <= 32'h0;
    end else begin
      if (( cur_state == wait_wvalid ) && wvalid_i ) begin
        bresp_o <= paddr_write( awaddr_i, wdata_i, wstrb_i );
      end else begin
        bresp_o = bresp_o;
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
        idle: begin
          if ( arvalid_i ) begin
            next_state = read;
          end else if ( awvalid_i ) begin
            next_state = wait_wvalid;
          end 
        end
        read:        if ( rc_cnt >= `RC_THRESHOLD ) next_state = wait_rready;
        wait_rready: if ( rready_i                ) next_state = idle;
        wait_wvalid: if ( wvalid_i                ) next_state = write;
        write:       if ( wc_cnt >= `WC_THRESHOLD ) next_state = wait_bready;
        wait_bready: if ( bready_i                ) next_state = idle;
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

  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      wc_cnt <= 4'h0;
    end else begin
      if ( cur_state == write ) begin
        wc_cnt <= wc_cnt + 1;
      end else begin
        wc_cnt <= 4'b0;
      end
    end
  end

endmodule // dsram 
