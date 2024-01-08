`include "defines.v"

module clint (
  input                         clk,
  input                         rst,

  /* ARC: Address Read Channel */
  input   [`INST_ADDR_BUS]      araddr_i,

  input                         arvalid_i,
  output                        arready_o,

  /*  RC: Data Read Channel */
  output  reg [`INST_DATA_BUS]  rdata_o,
  output  reg [`RRESP_DATA_BUS] rresp_o,

  output                        rvalid_o,
  input                         rready_i,

  /* verilator lint_off UNUSEDSIGNAL */
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
  output  reg [`BRESP_DATA_BUS] bresp_o,

  output                        bvalid_o,
  input                         bready_i
);

  parameter idle             = 3'b000;
  parameter wait_low_rready  = 3'b001;
  parameter wait_high_rready = 3'b010;

  wire [31:0] off;

  reg [31:0] low_bytes;
  reg [31:0] high_bytes;

  reg [63:0] mtime;

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign off = ( araddr_i - `CLINT_ADDR_BEGIN ) / 4;

  /* ARC: Address Read Channel */
  assign arready_o = ( cur_state == idle );

  /*  RC: Data Read Channel */
  assign rdata_o  = ( cur_state == wait_low_rready  ) ? low_bytes  :
                    ( cur_state == wait_high_rready ) ? high_bytes : 0;
  assign rresp_o  = 0;
  assign rvalid_o = ( cur_state == wait_low_rready ) || ( cur_state == wait_high_rready );

  /* AWC: Address Write Channel */
  assign awready_o = 0;

  /*  WC: Data Write Channel */
  assign wready_o = 0;

  /*  BC: Response Write Channel */
  assign bresp_o = 0;
  assign bvalid_o = 0;

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
        idle:      if ( arvalid_i && ( off == 32'h0 )) next_state = wait_low_rready;
              else if ( arvalid_i && ( off == 32'h1 )) next_state = wait_high_rready;
        wait_low_rready:  if ( rready_i ) next_state = idle;
        wait_high_rready: if ( rready_i ) next_state = idle;
        default: next_state = cur_state;
      endcase
    end
  end

  //-----------------------------------------------------------------
  // MISCELlANEOUS
  //-----------------------------------------------------------------
  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      mtime <= 64'h0000_0000_0000_0000;
    end else begin
      mtime <= mtime + 1;
    end
  end

  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      low_bytes <= 32'h0000_0000;
      high_bytes <= 32'h0000_0000;
    end else begin
      low_bytes  <= low_bytes;
      high_bytes <= high_bytes;
      if ( arvalid_i && arready_o ) begin
        if ( off == 32'h0 ) begin
          low_bytes  <= mtime[31:0];
        end else if ( off == 32'h1 ) begin
          high_bytes <= mtime[63:32];
        end 
      end
    end
  end

endmodule
