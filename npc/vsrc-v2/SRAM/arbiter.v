`include "defines.v"

module arbiter (
  input                      clk,
  input                      rst,

  /* AR: Address Read Channel */
  input    [`INST_ADDR_BUS]  ifu_araddr_i,
  input    [`INST_ADDR_BUS]  exu_araddr_i,
  output   [`INST_ADDR_BUS]  sram_araddr_o,

  input                      ifu_arvalid_i,
  input                      exu_arvalid_i,
  output                     sram_arvalid_o,

  input                      sram_arready_i,
  output                     ifu_arready_o,
  output                     exu_arready_o,

  /* R: Data Read Channel */
  input    [`MEM_DATA_BUS]   sram_rdata_i,
  output   [`MEM_DATA_BUS]   ifu_rdata_o,
  output   [`MEM_DATA_BUS]   exu_rdata_o,

  input    [`MEM_DATA_BUS]   sram_rresp_i,
  output   [`MEM_DATA_BUS]   ifu_rresp_o,
  output   [`MEM_DATA_BUS]   exu_rresp_o,

  input                      sram_rvalid_i,
  output                     ifu_rvalid_o,
  output                     exu_rvalid_o,

  input                      ifu_rready_i,
  input                      exu_rready_i,
  output                     sram_rready_o,

  /* AW: Address Write Channel */
  input    [`INST_ADDR_BUS]  ifu_awaddr_i,
  input    [`INST_ADDR_BUS]  exu_awaddr_i,
  output   [`INST_ADDR_BUS]  sram_awaddr_o,

  input                      ifu_awvalid_i,
  input                      exu_awvalid_i,
  output                     sram_awvalid_o,

  input                      sram_awready_i,
  output                     ifu_awready_o,
  output                     exu_awready_o,

  /*  W: Data Write Channel */
  input    [`MEM_DATA_BUS]   ifu_wdata_i,
  input    [`MEM_DATA_BUS]   exu_wdata_i,
  output   [`MEM_DATA_BUS]   sram_wdata_o,

  input    [7:0]             ifu_wstrb_i,
  input    [7:0]             exu_wstrb_i,
  output   [7:0]             sram_wstrb_o,

  input                      ifu_wvalid_i,
  input                      exu_wvalid_i,
  output                     sram_wvalid_o,

  input                      sram_wready_i,
  output                     ifu_wready_o,
  output                     exu_wready_o,

  /*  B: Response Write Channel */
  input    [`INST_DATA_BUS]  sram_bresp_i,
  output   [`INST_DATA_BUS]  ifu_bresp_o,
  output   [`INST_DATA_BUS]  exu_bresp_o,

  input                      sram_bvalid_i,
  output                     ifu_bvalid_o,
  output                     exu_bvalid_o,

  input                      ifu_bready_i,
  input                      exu_bready_i,
  output                     sram_bready_o
);

  parameter idle      = 3'b000;
  parameter ifu_read  = 3'b001;
  parameter ifu_write = 3'b010;
  parameter exu_read  = 3'b011;
  parameter exu_write = 3'b100;
  parameter post      = 3'b101;

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  /* AR: Address Read Channel */
  assign sram_araddr_o    =   (( cur_state == ifu_read  ) || ( cur_state == post )) ? ifu_araddr_i   : 
                              (( cur_state == exu_read  ) || ( cur_state == post )) ? exu_araddr_i   : 32'h0000_0000;
  assign sram_arvalid_o   =   (( cur_state == ifu_read  ) || ( cur_state == post )) ? ifu_arvalid_i  : 
                              (( cur_state == exu_read  ) || ( cur_state == post )) ? exu_arvalid_i  : 1'b0;
  assign ifu_arready_o    =   (( cur_state == ifu_read  ) || ( cur_state == post )) ? sram_arready_i : 1'b0;
  assign exu_arready_o    =   (( cur_state == exu_read  ) || ( cur_state == post )) ? sram_arready_i : 1'b0;

  /*  R: Data Read Channel */
  assign ifu_rdata_o      =   (( cur_state == ifu_read  ) || ( cur_state == post )) ? sram_rdata_i   : 32'h0000_0000;
  assign exu_rdata_o      =   (( cur_state == exu_read  ) || ( cur_state == post )) ? sram_rdata_i   : 32'h0000_0000;
  assign ifu_rresp_o      =   (( cur_state == ifu_read  ) || ( cur_state == post )) ? sram_rresp_i   : 32'h0000_0000;
  assign exu_rresp_o      =   (( cur_state == exu_read  ) || ( cur_state == post )) ? sram_rresp_i   : 32'h0000_0000;
  assign ifu_rvalid_o     =   (( cur_state == ifu_read  ) || ( cur_state == post )) ? sram_rvalid_i  : 1'b0;
  assign exu_rvalid_o     =   (( cur_state == exu_read  ) || ( cur_state == post )) ? sram_rvalid_i  : 1'b0;
  assign sram_rready_o    =   (( cur_state == ifu_read  ) || ( cur_state == post )) ? ifu_rready_i   : 
                              (( cur_state == exu_read  ) || ( cur_state == post )) ? exu_rready_i   : 1'b0;

  /* AW: Address Write Channel */
  assign sram_awaddr_o    =   (( cur_state == ifu_write ) || ( cur_state == post )) ? ifu_awaddr_i   :
                              (( cur_state == exu_write ) || ( cur_state == post )) ? exu_awaddr_i   : 32'h0000_0000;
  assign sram_awvalid_o   =   (( cur_state == ifu_write ) || ( cur_state == post )) ? ifu_awvalid_i  :
                              (( cur_state == exu_write ) || ( cur_state == post )) ? exu_awvalid_i  : 1'b0;
  assign ifu_awready_o    =   (( cur_state == ifu_write ) || ( cur_state == post )) ? sram_awready_i : 1'b0;
  assign exu_awready_o    =   (( cur_state == exu_write ) || ( cur_state == post )) ? sram_awready_i : 1'b0;

  /*  W: Data Write Channel */
  assign sram_wdata_o     =   (( cur_state == ifu_write ) || ( cur_state == post ))  ? ifu_wdata_i   : 
                              (( cur_state == exu_write ) || ( cur_state == post ))  ? exu_wdata_i   : 32'h0000_0000;
  assign sram_wstrb_o     =   (( cur_state == ifu_write ) || ( cur_state == post ))  ? ifu_wstrb_i   :
                              (( cur_state == exu_write ) || ( cur_state == post ))  ? exu_wstrb_i   : 8'b0000_0000;
  assign sram_wvalid_o    =   (( cur_state == ifu_write ) || ( cur_state == post ))  ? ifu_wvalid_i  :
                              (( cur_state == exu_write ) || ( cur_state == post ))  ? exu_wvalid_i  : 1'b0;
  assign ifu_wready_o     =   (( cur_state == ifu_write ) || ( cur_state == post ))  ? sram_wready_i : 1'b0;
  assign exu_wready_o     =   (( cur_state == exu_write ) || ( cur_state == post ))  ? sram_wready_i : 1'b0;

  /*  B: Response Write Channel */
  assign ifu_bresp_o      =   (( cur_state == ifu_write ) || ( cur_state == post )) ? sram_bresp_i   : 32'h0000_0000;
  assign exu_bresp_o      =   (( cur_state == exu_write ) || ( cur_state == post )) ? sram_bresp_i   : 32'h0000_0000;
  assign ifu_bvalid_o     =   (( cur_state == ifu_write ) || ( cur_state == post )) ? sram_bvalid_i  : 1'b0;
  assign exu_bvalid_o     =   (( cur_state == exu_write ) || ( cur_state == post )) ? sram_bvalid_i  : 1'b0;
  assign sram_bready_o    =   (( cur_state == ifu_write ) || ( cur_state == post )) ? ifu_bready_i   : 
                              (( cur_state == exu_write ) || ( cur_state == post )) ? exu_bready_i   : 1'b0;


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
          if      ( ifu_arvalid_i ) next_state = ifu_read; 
          else if ( exu_arvalid_i ) next_state = exu_read;
          else if ( exu_awvalid_i ) next_state = exu_write;
        end
        ifu_read:  if ( sram_rvalid_i && ifu_rready_i ) next_state = post;
        exu_read:  if ( sram_rvalid_i && exu_rready_i ) next_state = post;
        exu_write: if ( sram_bvalid_i && exu_bready_i ) next_state = post;
        post:                                           next_state = idle;
        default: next_state = cur_state;
      endcase
    end
  end

endmodule
