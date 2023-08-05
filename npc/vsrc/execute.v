`include "defines.v"

module execute (
  input rst,
  
  // Signal From Inst_Decode
  input                     rmem_ena_i,
  input                     wmem_ena_i,
  input [`ALU_OP_BUS]       alu_op_i,
  input [`REG_DATA_BUS]     operand1_i,
  input [`REG_DATA_BUS]     operand2_i,

  // Signal To Write_Back
  output [`REG_DATA_BUS]    alu_result_o,

  // Signal To Data-Mem
  output [`MEM_ADDR_BUS]    rmem_addr_o,
  output [`MEM_ADDR_BUS]    wmem_addr_o,
  output [`MEM_MASK_BUS]    wmem_mask_o,

  // Signal To Mem-Data-Expansion Unit
  output [`ALU_OP_BUS]      alu_op_o,
  output [`MEM_ADDR_BUS]    read_offset_o
);

  /* verilator lint_off UNUSEDSIGNAL */
  reg [`REG_DATA_BUS] alu_result;

  wire cout;
  wire [`REG_DATA_BUS] result;

  assign { cout, result } = {1'b0, operand1_i} + ({1'b0, ~operand2_i}) + 1;

  wire Cf = cout ^ 1'b1;

  wire unsigned_less_than = ( Cf == 1 );

  always @( * ) begin
    if ( rst == `RST_ENABLE ) begin
      alu_result = `ZERO_WORD;
    end else begin
      case ( alu_op_i )
        `ALU_OP_ADD   : alu_result = operand1_i   + operand2_i; 
        `ALU_OP_SUB   : alu_result = operand1_i   - operand2_i; 
        `ALU_OP_XOR   : alu_result = operand1_i   ^ operand2_i; 
        `ALU_OP_OR    : alu_result = operand1_i   | operand2_i; 
        `ALU_OP_SLTU  : alu_result = {{31{1'b0}}, unsigned_less_than}; 
        `ALU_OP_SLTIU : alu_result = {{31{1'b0}}, unsigned_less_than}; 
        `ALU_OP_JUMP  : alu_result = `INST_LENGTH + operand2_i;
        default       : alu_result =                `ZERO_WORD; 
      endcase
    end
  end

  // Compute Read Access Address
  reg [`MEM_ADDR_BUS] rmem_addr;
  always @( * ) begin
    if ( rst == `RST_ENABLE ) begin
      rmem_addr = `ZERO_ADDR;
    end else begin
      case ( alu_op_i )
        `ALU_OP_LB : rmem_addr = operand1_i + operand2_i; 
        `ALU_OP_LH : rmem_addr = operand1_i + operand2_i; 
        `ALU_OP_LW : rmem_addr = operand1_i + operand2_i; 
        `ALU_OP_LBU: rmem_addr = operand1_i + operand2_i; 
        `ALU_OP_LHU: rmem_addr = operand1_i + operand2_i; 
        default    : rmem_addr =              `ZERO_ADDR; 
      endcase
    end
  end

  reg [`MEM_ADDR_BUS] read_offset;
  always @( * ) begin
    if ( rst == `RST_ENABLE ) begin
      read_offset = `ZERO_ADDR;
    end if ( rmem_ena_i == `READ_ENABLE ) begin
      read_offset = ( rmem_addr - ( rmem_addr & 32'hFFFF_FFFC) );
    end else begin
      read_offset = `ZERO_ADDR;
    end
  end

  // Compute Write Access Address
  reg [`MEM_ADDR_BUS] wmem_addr;
  always @( * ) begin
    if ( rst == `RST_ENABLE ) begin
      wmem_addr = `ZERO_ADDR;
    end else begin
      case ( alu_op_i )
        `ALU_OP_SB: wmem_addr = operand1_i + operand2_i;
        `ALU_OP_SH: wmem_addr = operand1_i + operand2_i;
        `ALU_OP_SW: wmem_addr = operand1_i + operand2_i;
        default:    wmem_addr =              `ZERO_ADDR;
      endcase
    end
  end

  reg [`MEM_ADDR_BUS] write_offset;
  always @( * ) begin
    if ( rst == `RST_ENABLE ) begin
      write_offset = `ZERO_ADDR;
    end if ( wmem_ena_i == `WRITE_ENABLE ) begin
      write_offset = ( rmem_addr - ( rmem_addr & 32'h03) );
    end else begin
      write_offset = `ZERO_ADDR;
    end
  end

  assign alu_op_o       = alu_op_i;
  assign alu_result_o   = alu_result;
  assign rmem_addr_o    = rmem_addr;
  assign read_offset_o  = read_offset;
  assign wmem_addr_o    = wmem_addr;

  assign wmem_mask_o    = ( rst ==`RST_ENABLE      ) ? `ZERO_MASK : 
                          ( write_offset == 32'h00 ) ? ( ( alu_op_i == `ALU_OP_SB ) ? 8'b0000_0001 : 
                                                         ( alu_op_i == `ALU_OP_SH ) ? 8'b0000_0011 :
                                                         ( alu_op_i == `ALU_OP_SW ) ? 8'b0000_1111 : `ZERO_MASK ) :
                          ( write_offset == 32'h01 ) ? ( ( alu_op_i == `ALU_OP_SB ) ? 8'b0000_0010 : 
                                                         ( alu_op_i == `ALU_OP_SH ) ? 8'b0000_0110 : `ZERO_MASK ) :
                          ( write_offset == 32'h02 ) ? ( ( alu_op_i == `ALU_OP_SB ) ? 8'b0000_0100 : 
                                                         ( alu_op_i == `ALU_OP_SH ) ? 8'b0000_1100 : `ZERO_MASK ) :
                          ( write_offset == 32'h03 ) ? ( ( alu_op_i == `ALU_OP_SB ) ? 8'b0000_1000 : `ZERO_MASK ) : `ZERO_MASK;

endmodule
