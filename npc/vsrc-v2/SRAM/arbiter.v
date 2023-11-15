`include "../defines.v"

module arbiter (
  input                      clk,
  input                      rst,

  input    [`INST_ADDR_BUS]  ifu_araddr_i,
  input    [`INST_ADDR_BUS]  exu_araddr_i,
  output   [`INST_ADDR_BUS]  sram_araddr_o,

  input                      ifu_arvalid_i,
  input                      exu_arvalid_i,
  output                     sram_arvalid_o,

  input                      sram_arready_i,
  output                     ifu_arready_o,
  output                     exu_arready_o,

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

  input    [`INST_ADDR_BUS]  ifu_awaddr_i,
  input    [`INST_ADDR_BUS]  exu_awaddr_i,
  output   [`INST_ADDR_BUS]  sram_awaddr_o,

  input                      ifu_awvalid_i,
  input                      exu_awvalid_i,
  output                     sram_awvalid_o,

  input                      sram_awready_i,
  output                     ifu_awready_o,
  output                     exu_awready_o,

  input    [`MEM_DATA_BUS]   ifu_wdata_i,
  input    [`MEM_DATA_BUS]   exu_wdata_i,
  output   [`MEM_DATA_BUS]   sram_wdata_o,

  input                      ifu_wvalid_i,
  input                      exu_wvalid_i,
  output                     sram_wvalid_o,

  input                      sram_wready_i,
  output                     ifu_wready_o,
  output                     exu_wready_o,

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

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign sram_araddr_o =
  assign sram_arvalid_o =
  assign ifu_arready_o =
  assign exu_arready_o =
  assign ifu_rdata_o =
  assign exu_rdata_o =
  assign ifu_rresp_o =
  assign exu_rresp_o =
  assign ifu_rvalid_o =
  assign exu_rvalid_o =
  assign sram_rready_o =
  assign sram_awaddr_o =
  assign sram_awvalid_o =
  assign ifu_awready_o =
  assign exu_awready_o =
  assign sram_wdata_o =
  assign sram_wvalid_o =
  assign ifu_wready_o =
  assign exu_wready_o =
  assign ifu_bresp_o =
  assign exu_bresp_o =
  assign ifu_bvalid_o =
  assign exu_bvalid_o =
  assign sram_bready_o =


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

endmodule
