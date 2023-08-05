`include "defines.v"

module top (
  input clk,
  input rst
);

  wire [`INST_ADDR_BUS] dnpc__addr_transfer;
  wire [`INST_ADDR_BUS] pc__inst_fetch;

  inst_fetch u_inst_fetch (
    .rst ( rst ),
    .clk ( clk ),

    .next_pc ( dnpc__addr_transfer ),
    .pc( pc__inst_fetch )
  );

  wire [`INST_DATA_BUS] inst__inst_mem;
  
  inst_mem u_inst_mem(
    .rst ( rst ),
    
    .pc_i ( pc__inst_fetch ),
    .inst_o ( inst__inst_mem )
  );

  wire [`REG_DATA_BUS] data1__regfile;
  wire [`REG_DATA_BUS] data2__regfile;
  wire                 wsel__inst_deocde;
  wire [`MEM_DATA_BUS] wmem_data__inst_decode;
  wire                 rmem_ena__inst_decode;
  wire                 wmem_ena__inst_decode;
  wire [`ALU_OP_BUS]   alu_op__inst_decode;
  wire [`REG_DATA_BUS] operand1__inst_decode;
  wire [`REG_DATA_BUS] operand2__inst_decode;
  wire [`TRAN_OP_BUS]  tran_op__inst_decode;
  wire [`INST_ADDR_BUS] pc_inst__decode;
  wire [`REG_DATA_BUS] imm__inst_decode;
  wire [`REG_ADDR_BUS] waddr__inst_decode;
  wire [`REG_ADDR_BUS] raddr1__inst_decode;
  wire [`REG_ADDR_BUS] raddr2__inst_decode;
  wire                 wena__inst_decode;
  wire                 rena1__inst_decode;
  wire                 rena2__inst_decode;

  inst_decode u_inst_decode (
    .rst ( rst ),

    .pc_i ( pc__inst_fetch ),
    .inst_i ( inst__inst_mem ),
    .data1_i ( data1__regfile ),
    .data2_i ( data2__regfile ),

    .wsel_o ( wsel__inst_deocde ),

    .wmem_data_o ( wmem_data__inst_decode ),
    
    .rmem_ena_o ( rmem_ena__inst_decode ),
    .wmem_ena_o ( wmem_ena__inst_decode ),
    
    .alu_op_o ( alu_op__inst_decode ),
    .operand1_o ( operand1__inst_decode ),
    .operand2_o ( operand2__inst_decode ),
    
    .tran_op_o ( tran_op__inst_decode ),
    .pc_o ( pc_inst__decode ), 
    .imm_o ( imm__inst_decode ),
    
    .waddr_o ( waddr__inst_decode ),
    .raddr1_o ( raddr1__inst_decode ),
    .raddr2_o ( raddr2__inst_decode ),
    .wena_o ( wena__inst_decode ),
    .rena1_o ( rena1__inst_decode ),
    .rena2_o ( rena2__inst_decode )
  );

  wire [`MEM_DATA_BUS] wmem_data__data_filter;

  data_filter u_data_filter (
    .rst ( rst ),

    .wmem_data_i ( wmem_data__inst_decode ),
    .alu_op_i ( alu_op__inst_decode ),
    .wmem_data_o ( wmem_data__data_filter )
  ); 

  wire [`MEM_ADDR_BUS] rmem_addr__alu;
  wire [`MEM_ADDR_BUS] wmem_addr__alu;
  wire [`MEM_MASK_BUS] wmem_mask__alu;
  wire [`ALU_OP_BUS]   alu_op__alu;
  wire [`MEM_ADDR_BUS] read_offset__alu;
  wire [`REG_DATA_BUS] alu_result__alu;

  execute u_execute (
    .rst ( rst ),

    .rmem_ena_i ( rmem_ena__inst_decode ),
    .wmem_ena_i ( wmem_ena__inst_decode ),
    .alu_op_i ( alu_op__inst_decode ),
    .operand1_i ( operand1__inst_decode ),
    .operand2_i ( operand2__inst_decode ),

    .rmem_addr_o ( rmem_addr__alu ),
    .wmem_addr_o ( wmem_addr__alu ),
    .wmem_mask_o ( wmem_mask__alu ),
    .alu_op_o ( alu_op__alu ),
    .read_offset_o ( read_offset__alu ),
    .alu_result_o ( alu_result__alu )
  );

  addr_transfer u_addr_transfer (
    .rst ( rst ),

    .operand1_i ( operand1__inst_decode ),
    .operand2_i ( operand2__inst_decode ),
    .tran_op_i ( tran_op__inst_decode ),
    .pc_i ( pc_inst__decode ),
    .imm_i ( imm__inst_decode ),
    .dnpc_o ( dnpc__addr_transfer )
  ); 

  wire [`MEM_DATA_BUS] rmem_data__data_mem;

  data_mem u_data_mem (
    .rst ( rst ),
    .clk ( clk ),

    .wmem_data_i ( wmem_data__data_filter ),
    .rmem_ena_i ( rmem_ena__inst_decode ),
    .wmem_ena_i ( wmem_ena__inst_decode ),
    .rmem_addr_i ( rmem_addr__alu ),
    .wmem_addr_i ( wmem_addr__alu ),
    .wmem_mask_i ( wmem_mask__alu ),
    .rmem_data_o ( rmem_data__data_mem )
  );

  wire [`MEM_DATA_BUS] mem_data__data_expansion;

  data_expan u_data_expan (
    .rst ( rst ),

    .rmem_data_i ( rmem_data__data_mem ),
    .alu_op_i ( alu_op__alu ),
    .read_offset_i ( read_offset__alu ),
    .mem_data_o ( mem_data__data_expansion )
  );

  wire [`REG_DATA_BUS] wdata__write_back;

  write_back u_write_back (
    .rst ( rst ),

    .wsel_i ( wsel__inst_deocde ),
    .mem_data_i ( mem_data__data_expansion ),
    .alu_result_i ( alu_result__alu ),
    .wdata_o ( wdata__write_back )
  );

  regfile u_regfile (
    .rst ( rst ),
    .clk ( clk ),
    .rena1_i ( rena1__inst_decode ),
    .rena2_i ( rena2__inst_decode ),
    .raddr1_i ( raddr1__inst_decode ),
    .raddr2_i ( raddr2__inst_decode ),
    .wena_i ( wena__inst_decode ),
    .waddr_i ( waddr__inst_decode ),
    .wdata_i ( wdata__write_back ),
    .data1_o ( data1__regfile ),
    .data2_o ( data2__regfile )
  );

endmodule
