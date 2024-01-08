`include "defines.v"

module uart (
  input                         clk,
  input                         rst,

  /* verilator lint_off UNUSEDSIGNAL */
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
  parameter print        = 3'b001;
  parameter wait_awvalid = 3'b010;
  parameter wait_wvalid  = 3'b011;
  parameter wait_bready  = 3'b100;

  wire we;

  reg [`MEM_DATA_BUS] uart_reg;

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  /* Write enable */
  assign we = wvalid_i && wready_o;

  /* ARC: Address Read Channel */
  assign arready_o = 0;

  /*  RC: Data Read Channel */
  assign rdata_o = 0;
  assign rresp_o = 0;
  assign rvalid_o = 0;

  /* AWC: Address Write Channel */
  assign awready_o = ( cur_state == idle ) || ( cur_state == wait_awvalid );

  /*  WC: Data Write Channel */
  assign wready_o  = ( cur_state == idle ) || ( cur_state == wait_wvalid  );

  /*  BC: Response Write Channel */
  assign bresp_o = 0;
  assign bvalid_o = ( cur_state == wait_bready );


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
        idle:      if (  awvalid_i  &&  wvalid_i  ) next_state = print;
              else if ( !awvalid_i  &&  wvalid_i  ) next_state = wait_awvalid;
              else if (  awvalid_i  && !wvalid_i  ) next_state = wait_wvalid;
        wait_awvalid: if ( awvalid_i ) next_state = print;
        wait_wvalid:  if ( wvalid_i  ) next_state = print;
        print: next_state = wait_bready;
        wait_bready: if ( bready_i ) next_state = idle;
        default: next_state = cur_state;
      endcase
    end
  end

  //-----------------------------------------------------------------
  // MISCELlANEOUS
  //-----------------------------------------------------------------
  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_ENABLE ) begin
      uart_reg  <= 32'h0000_0000;
    end else if ( we ) begin
      uart_reg <= wdata_i;
    end
  end

  always @( posedge clk or negedge rst ) begin
    if ( rst == `RST_DISABLE ) begin
      if ( cur_state == print ) begin
        $display("%c", uart_reg[7:0]);
      end
    end
  end

endmodule
