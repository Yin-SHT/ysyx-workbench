`include "defines.v"

module xbar (
  input                     clk,
  input                     rst,

  /** CPU-end signals */
  /* AR: Address Read Channel */
  input [`MEM_ADDR_BUS]     cpu_araddr_i,
  input                     cpu_arvalid_i,
  output                    cpu_arready_o,

  /*  R: Data Read Channel */
  output [`MEM_DATA_BUS]    cpu_rdata_o,
  output [`RRESP_DATA_BUS]  cpu_rresp_o,
  output                    cpu_rvalid_o,
  input                     cpu_rready_i,

  /* AW: Address Write Channel */
  input [`MEM_ADDR_BUS]     cpu_awaddr_i,
  input                     cpu_awvalid_i,
  output                    cpu_awready_o,

  /*  W: Data Write Channel */
  input [`MEM_ADDR_BUS]     cpu_wdata_i,
  input [`WSTRB_DATA_BUS]   cpu_wstrb_i,
  input                     cpu_wvalid_i,
  output                    cpu_wready_o,

  /*  B: Response Write Channel */
  output [`RRESP_DATA_BUS]  cpu_bresp_o,
  output                    cpu_bvalid_o,
  input                     cpu_bready_i,

  /** PERI-end signals */
  /** SRAM */
  output [`MEM_ADDR_BUS]    sram_araddr_o,
  output                    sram_arvalid_o,
  input                     sram_arready_i,

  input [`MEM_DATA_BUS]     sram_rdata_i,
  input [`RRESP_DATA_BUS]   sram_rresp_i,
  input                     sram_rvalid_i,
  output                    sram_rready_o,

  output [`MEM_ADDR_BUS]    sram_awaddr_o,
  output                    sram_awvalid_o,
  input                     sram_awready_i,

  output [`MEM_ADDR_BUS]    sram_wdata_o,
  output [`WSTRB_DATA_BUS]  sram_wstrb_o,
  output                    sram_wvalid_o,
  input                     sram_wready_i,

  input [`BRESP_DATA_BUS]   sram_bresp_i,
  input                     sram_bvalid_i,
  output                    sram_bready_o,

  /** UART */
  output [`MEM_ADDR_BUS]    uart_araddr_o,
  output                    uart_arvalid_o,
  input                     uart_arready_i,

  input [`MEM_DATA_BUS]     uart_rdata_i,
  input [`RRESP_DATA_BUS]   uart_rresp_i,
  input                     uart_rvalid_i,
  output                    uart_rready_o,

  output [`MEM_ADDR_BUS]    uart_awaddr_o,
  output                    uart_awvalid_o,
  input                     uart_awready_i,

  output [`MEM_ADDR_BUS]    uart_wdata_o,
  output [`WSTRB_DATA_BUS]  uart_wstrb_o,
  output                    uart_wvalid_o,
  input                     uart_wready_i,

  input [`BRESP_DATA_BUS]   uart_bresp_i,
  input                     uart_bvalid_i,
  output                    uart_bready_o,

  /** CLINT */
  output [`MEM_ADDR_BUS]    clint_araddr_o,
  output                    clint_arvalid_o,
  input                     clint_arready_i,

  input [`MEM_DATA_BUS]     clint_rdata_i,
  input [`RRESP_DATA_BUS]   clint_rresp_i,
  input                     clint_rvalid_i,
  output                    clint_rready_o,

  output [`MEM_ADDR_BUS]    clint_awaddr_o,
  output                    clint_awvalid_o,
  input                     clint_awready_i,

  output [`MEM_ADDR_BUS]    clint_wdata_o,
  output [`WSTRB_DATA_BUS]  clint_wstrb_o,
  output                    clint_wvalid_o,
  input                     clint_wready_i,

  input [`BRESP_DATA_BUS]   clint_bresp_i,
  input                     clint_bvalid_i,
  output                    clint_bready_o
);

  parameter idle              = 4'b0000;
  parameter wait_sram_rvalid  = 4'b0001;
  parameter wait_sram_bvalid  = 4'b0010;
  parameter wait_uart_rvalid  = 4'b0011;
  parameter wait_uart_bvalid  = 4'b0100;
  parameter wait_clint_rvalid = 4'b0101;
  parameter wait_clint_bvalid = 4'b0110;

  reg [3:0] cur_state;
  reg [3:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  /* AR: Address Read Channel */
  assign sram_araddr_o   = ( cur_state == wait_sram_rvalid  ) ? cpu_araddr_i  : 0;
  assign uart_araddr_o   = ( cur_state == wait_uart_rvalid  ) ? cpu_araddr_i  : 0;
  assign clint_araddr_o  = ( cur_state == wait_clint_rvalid ) ? cpu_araddr_i  : 0;

  assign sram_arvalid_o  = ( cur_state == wait_sram_rvalid  ) ? cpu_arvalid_i : 0;
  assign uart_arvalid_o  = ( cur_state == wait_uart_rvalid  ) ? cpu_arvalid_i : 0;
  assign clint_arvalid_o = ( cur_state == wait_clint_rvalid ) ? cpu_arvalid_i : 0;

  assign cpu_arready_o   = ( cur_state == wait_sram_rvalid  ) ? sram_arready_i  : 
                           ( cur_state == wait_uart_rvalid  ) ? uart_arready_i  :
                           ( cur_state == wait_clint_rvalid ) ? clint_arready_i : 0;

  /*  R: Data Read Channel */
  assign cpu_rdata_o     = ( cur_state == wait_sram_rvalid  ) ? sram_rdata_i  :
                           ( cur_state == wait_uart_rvalid  ) ? uart_rdata_i  :
                           ( cur_state == wait_clint_rvalid ) ? clint_rdata_i : 0;

  assign cpu_rresp_o     = ( cur_state == wait_sram_rvalid  ) ? sram_rresp_i  :
                           ( cur_state == wait_uart_rvalid  ) ? uart_rresp_i  :
                           ( cur_state == wait_clint_rvalid ) ? clint_rresp_i : 0;

  assign cpu_rvalid_o    = ( cur_state == wait_sram_rvalid  ) ? sram_rvalid_i  :
                           ( cur_state == wait_uart_rvalid  ) ? uart_rvalid_i  :
                           ( cur_state == wait_clint_rvalid ) ? clint_rvalid_i : 0;

  assign sram_rready_o   = ( cur_state == wait_sram_rvalid  ) ? cpu_rready_i   : 0;
  assign uart_rready_o   = ( cur_state == wait_uart_rvalid  ) ? cpu_rready_i   : 0;
  assign clint_rready_o  = ( cur_state == wait_clint_rvalid ) ? cpu_rready_i   : 0;

  /* AW: Address Write Channel */
  assign sram_awaddr_o   = ( cur_state == wait_sram_bvalid  ) ? cpu_awaddr_i  : 0;
  assign uart_awaddr_o   = ( cur_state == wait_uart_bvalid  ) ? cpu_awaddr_i  : 0;
  assign clint_awaddr_o  = ( cur_state == wait_clint_bvalid ) ? cpu_awaddr_i  : 0;

  assign sram_awvalid_o  = ( cur_state == wait_sram_bvalid  ) ? cpu_awvalid_i : 0;
  assign uart_awvalid_o  = ( cur_state == wait_uart_bvalid  ) ? cpu_awvalid_i : 0;
  assign clint_awvalid_o = ( cur_state == wait_clint_bvalid ) ? cpu_awvalid_i : 0;

  assign cpu_awready_o   = ( cur_state == wait_sram_bvalid  ) ? sram_awready_i  : 
                           ( cur_state == wait_uart_bvalid  ) ? uart_awready_i  :
                           ( cur_state == wait_clint_bvalid ) ? clint_awready_i : 0;

  /*  W: Data Write Channel */
  assign sram_wdata_o    = ( cur_state == wait_sram_bvalid  ) ? cpu_wdata_i : 0;
  assign uart_wdata_o    = ( cur_state == wait_uart_bvalid  ) ? cpu_wdata_i : 0;
  assign clint_wdata_o   = ( cur_state == wait_clint_bvalid ) ? cpu_wdata_i : 0;

  assign sram_wstrb_o    = ( cur_state == wait_sram_bvalid  ) ? cpu_wstrb_i : 0;
  assign uart_wstrb_o    = ( cur_state == wait_uart_bvalid  ) ? cpu_wstrb_i : 0;
  assign clint_wstrb_o   = ( cur_state == wait_clint_bvalid ) ? cpu_wstrb_i : 0;

  assign sram_wvalid_o   = ( cur_state == wait_sram_bvalid  ) ? cpu_wvalid_i : 0;
  assign uart_wvalid_o   = ( cur_state == wait_uart_bvalid  ) ? cpu_wvalid_i : 0;
  assign clint_wvalid_o  = ( cur_state == wait_clint_bvalid ) ? cpu_wvalid_i : 0;

  assign cpu_wready_o    = ( cur_state == wait_sram_bvalid  ) ? sram_wready_i  : 
                           ( cur_state == wait_uart_bvalid  ) ? uart_wready_i  :
                           ( cur_state == wait_clint_bvalid ) ? clint_wready_i : 0;

  /*  B: Response Write Channel */
  assign cpu_bresp_o     = ( cur_state == wait_sram_bvalid  ) ? sram_bresp_i  :
                           ( cur_state == wait_uart_bvalid  ) ? uart_bresp_i  :
                           ( cur_state == wait_clint_bvalid ) ? clint_bresp_i : 0;

  assign cpu_bvalid_o    = ( cur_state == wait_sram_bvalid  ) ? sram_bvalid_i  :
                           ( cur_state == wait_uart_bvalid  ) ? uart_bvalid_i  :
                           ( cur_state == wait_clint_bvalid ) ? clint_bvalid_i : 0;

  assign sram_bready_o   = ( cur_state == wait_sram_bvalid  ) ? cpu_bready_i : 0;
  assign uart_bready_o   = ( cur_state == wait_uart_bvalid  ) ? cpu_bready_i : 0;
  assign clint_bready_o  = ( cur_state == wait_clint_bvalid ) ? cpu_bready_i : 0;

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
        idle:      if ( cpu_arvalid_i && ( cpu_araddr_i >= `SRAM_ADDR_BEGIN  ) && ( cpu_araddr_i < `SRAM_ADDR_END  ) ) next_state = wait_sram_rvalid;
              else if ( cpu_arvalid_i && ( cpu_araddr_i >= `UART_ADDR_BEGIN  ) && ( cpu_araddr_i < `UART_ADDR_END  ) ) next_state = wait_uart_rvalid;
              else if ( cpu_arvalid_i && ( cpu_araddr_i >= `CLINT_ADDR_BEGIN ) && ( cpu_araddr_i < `CLINT_ADDR_END ) ) next_state = wait_clint_rvalid; 
              else if ( cpu_awvalid_i && ( cpu_awaddr_i >= `SRAM_ADDR_BEGIN  ) && ( cpu_awaddr_i < `SRAM_ADDR_END  ) ) next_state = wait_sram_bvalid;                       
              else if ( cpu_awvalid_i && ( cpu_awaddr_i >= `UART_ADDR_BEGIN  ) && ( cpu_awaddr_i < `UART_ADDR_END  ) ) next_state = wait_uart_bvalid;
              else if ( cpu_awvalid_i && ( cpu_awaddr_i >= `CLINT_ADDR_BEGIN ) && ( cpu_awaddr_i < `CLINT_ADDR_END ) ) next_state = wait_clint_bvalid; 
        wait_sram_rvalid:  if ( cpu_rready_i && sram_rvalid_i  ) next_state = idle;
        wait_uart_rvalid:  if ( cpu_rready_i && uart_rvalid_i  ) next_state = idle;
        wait_clint_rvalid: if ( cpu_rready_i && clint_rvalid_i ) next_state = idle;
        wait_sram_bvalid:  if ( cpu_bready_i && sram_bvalid_i  ) next_state = idle;
        wait_uart_bvalid:  if ( cpu_bready_i && uart_bvalid_i  ) next_state = idle;
        wait_clint_bvalid: if ( cpu_bready_i && clint_bvalid_i ) next_state = idle;
        default: next_state = cur_state;
      endcase
    end
  end

endmodule
