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

  parameter idle         = 3'b000;

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  /* Write enable */

  /* ARC: Address Read Channel */

  /*  RC: Data Read Channel */

  /* AWC: Address Write Channel */

  /*  WC: Data Write Channel */

  /*  BC: Response Write Channel */

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
        default: next_state = cur_state;
      endcase
    end
  end

  //-----------------------------------------------------------------
  // MISCELlANEOUS
  //-----------------------------------------------------------------

endmodule
