`include "defines.v"

module arbiter (
  input                      clk,
  input                      rst,

  /* From WBU */
  input                      wbu_valid_i,

  /* From IDU */
  input                      idu_valid_i,
  input    [`INST_TYPE_BUS]  inst_type_i,

  /* AR: Address Read Channel */
  input    [`INST_ADDR_BUS]  ifu_araddr_i,
  input    [`INST_ADDR_BUS]  exu_araddr_i,
  output   [`INST_ADDR_BUS]  araddr_o,

  input                      ifu_arvalid_i,
  input                      exu_arvalid_i,
  output                     arvalid_o,

  input                      arready_i,
  output                     ifu_arready_o,
  output                     exu_arready_o,

  /* R: Data Read Channel */
  input    [`MEM_DATA_BUS]   rdata_i,
  output   [`MEM_DATA_BUS]   ifu_rdata_o,
  output   [`MEM_DATA_BUS]   exu_rdata_o,

  input    [`RRESP_DATA_BUS] rresp_i,
  output   [`RRESP_DATA_BUS] ifu_rresp_o,
  output   [`RRESP_DATA_BUS] exu_rresp_o,

  input                      rvalid_i,
  output                     ifu_rvalid_o,
  output                     exu_rvalid_o,

  input                      ifu_rready_i,
  input                      exu_rready_i,
  output                     rready_o,

  /* AW: Address Write Channel */
  /* verilator lint_off UNUSEDSIGNAL */
  input    [`INST_ADDR_BUS]  ifu_awaddr_i,
  input    [`INST_ADDR_BUS]  exu_awaddr_i,
  output   [`INST_ADDR_BUS]  awaddr_o,

  input                      ifu_awvalid_i,
  input                      exu_awvalid_i,
  output                     awvalid_o,

  input                      awready_i,
  output                     ifu_awready_o,
  output                     exu_awready_o,

  /*  W: Data Write Channel */
  input    [`MEM_DATA_BUS]   ifu_wdata_i,
  input    [`MEM_DATA_BUS]   exu_wdata_i,
  output   [`MEM_DATA_BUS]   wdata_o,

  input    [`WSTRB_DATA_BUS] ifu_wstrb_i,
  input    [`WSTRB_DATA_BUS] exu_wstrb_i,
  output   [`WSTRB_DATA_BUS] wstrb_o,

  input                      ifu_wvalid_i,
  input                      exu_wvalid_i,
  output                     wvalid_o,

  input                      wready_i,
  output                     ifu_wready_o,
  output                     exu_wready_o,

  /*  B: Response Write Channel */
  input    [`BRESP_DATA_BUS] bresp_i,
  output   [`BRESP_DATA_BUS] ifu_bresp_o,
  output   [`BRESP_DATA_BUS] exu_bresp_o,

  input                      bvalid_i,
  output                     ifu_bvalid_o,
  output                     exu_bvalid_o,

  input                      ifu_bready_i,
  input                      exu_bready_i,
  output                     bready_o
);

  parameter idle      = 3'b000;
  parameter ifu_read  = 3'b001;
  parameter exu_read  = 3'b010;
  parameter exu_write = 3'b011;

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  /* AR: Address Read Channel */
  assign araddr_o      = ( cur_state == ifu_read  ) ? ifu_araddr_i  :
                         ( cur_state == exu_read  ) ? exu_araddr_i  : 0;
  assign arvalid_o     = ( cur_state == ifu_read  ) ? ifu_arvalid_i : 
                         ( cur_state == exu_read  ) ? exu_arvalid_i : 0;
  assign ifu_arready_o = ( cur_state == ifu_read  ) ? arready_i     : 0;
  assign exu_arready_o = ( cur_state == exu_read  ) ? arready_i     : 0;

  /*  R: Data Read Channel */
  assign ifu_rdata_o   = ( cur_state == ifu_read  ) ? rdata_i       : 0;
  assign exu_rdata_o   = ( cur_state == exu_read  ) ? rdata_i       : 0;
  assign ifu_rresp_o   = ( cur_state == ifu_read  ) ? rresp_i       : 0;
  assign exu_rresp_o   = ( cur_state == exu_read  ) ? rresp_i       : 0;
  assign ifu_rvalid_o  = ( cur_state == ifu_read  ) ? rvalid_i      : 0;
  assign exu_rvalid_o  = ( cur_state == exu_read  ) ? rvalid_i      : 0;
  assign rready_o      = ( cur_state == ifu_read  ) ? ifu_rready_i  : 
                         ( cur_state == exu_read  ) ? exu_rready_i  : 0;

  /* AW: Address Write Channel */
  assign awaddr_o      = ( cur_state == exu_write ) ? exu_awaddr_i  : 0;
  assign awvalid_o     = ( cur_state == exu_write ) ? exu_awvalid_i : 0;
  assign ifu_awready_o = 0;
  assign exu_awready_o = ( cur_state == exu_write ) ? awready_i     : 0;

  /*  W: Data Write Channel */
  assign wdata_o       = ( cur_state == exu_write ) ? exu_wdata_i   : 0;
  assign wstrb_o       = ( cur_state == exu_write ) ? exu_wstrb_i   : 0;
  assign wvalid_o      = ( cur_state == exu_write ) ? exu_wvalid_i  : 0;
  assign ifu_wready_o  = 0;
  assign exu_wready_o  = ( cur_state == exu_write ) ? wready_i      : 0;

  /*  B: Response Write Channel */
  assign ifu_bresp_o   = 0;
  assign exu_bresp_o   = ( cur_state == exu_write ) ? bresp_i       : 0;
  assign ifu_bvalid_o  = 0;
  assign exu_bvalid_o  = ( cur_state == exu_write ) ? bvalid_i      : 0;
  assign bready_o      = ( cur_state == exu_write ) ? exu_bready_i  : 0;


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
        idle: if ( wbu_valid_i ) next_state = ifu_read;
              else if ( idu_valid_i && ( inst_type_i == `INST_LOAD  )) next_state = exu_read;
              else if ( idu_valid_i && ( inst_type_i == `INST_STORE )) next_state = exu_write;
        ifu_read:  if ( rready_o && rvalid_i ) next_state = idle;
        exu_read:  if ( rready_o && rvalid_i ) next_state = idle;
        exu_write: if ( bready_o && bvalid_i ) next_state = idle;
        default: next_state = cur_state;
      endcase
    end
  end

endmodule
