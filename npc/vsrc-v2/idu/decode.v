`include "../defines.v"

module decode (
  input   rst,

  input   [`INST_ADDR_BUS]    pc_i,
  input   [`INST_DATA_BUS]    inst_i,

  output  [`INST_TYPE_BUS]    inst_type_o,
  output  [`ALU_OP_BUS]       alu_op_o,
  output  [`LSU_OP_BUS]       lsu_op_o,
  output  [`BPU_OP_BUS]       bpu_op_o,
  output                      wsel_o,
  output                      wena_o,
  output  [`REG_ADDR_BUS]     waddr_o,

  output  [`INST_ADDR_BUS]    pc_o,
  output  [`REG_DATA_BUS]     imm_o,

  output                      rena1_o,
  output                      rena2_o,
  output  [`REG_ADDR_BUS]     raddr1_o,
  output  [`REG_ADDR_BUS]     raddr2_o
);

  export "DPI-C" function inst_ebreak;
  function inst_ebreak;
      output int _ebreak;
      _ebreak = { {31{1'b0}}, ebreak };
  endfunction

  export "DPI-C" function inst_invalid;
  function inst_invalid;
      output int _unknown;
      _unknown = { {31{1'b0}}, unknown };
  endfunction

  
  wire [11 : 0]   funct12 =   inst_i[31 : 20];
  wire [ 6 : 0]   funct7  =   inst_i[31 : 25];
  wire [ 4 : 0]   rs2     =   inst_i[24 : 20];
  wire [ 4 : 0]   rs1     =   inst_i[19 : 15];
  wire [ 2 : 0]   funct3  =   inst_i[14 : 12];
  wire [ 4 : 0]   rd      =   inst_i[11 : 7 ];
  wire [ 6 : 0]   opcode  =   inst_i[6  : 0 ];


  wire [`REG_DATA_BUS] immI = {{21{inst_i[31]}}, inst_i[30:25], inst_i[24:21], inst_i[20]                         };
  wire [`REG_DATA_BUS] immS = {{21{inst_i[31]}}, inst_i[30:25], inst_i[11:8],  inst_i[7]                          };
  wire [`REG_DATA_BUS] immB = {{20{inst_i[31]}}, inst_i[7],     inst_i[30:25], inst_i[11:8],  1'b0                };
  wire [`REG_DATA_BUS] immU = {inst_i[31],       inst_i[30:20], inst_i[19:12], 12'b0                              };
  wire [`REG_DATA_BUS] immJ = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20],    inst_i[30:25], inst_i[24:21], 1'b0 };
  wire [`REG_DATA_BUS] immSHIFT = {27'b0, immI[4:0]};

  
  wire inst_add   = ( opcode == `OPCODE_ADD   ) & ( funct3 == `FUNCT3_ADD  ) & ( funct7 == `FUNCT7_ADD );
  wire inst_sub   = ( opcode == `OPCODE_SUB   ) & ( funct3 == `FUNCT3_SUB  ) & ( funct7 == `FUNCT7_SUB );
  wire inst_xor   = ( opcode == `OPCODE_XOR   ) & ( funct3 == `FUNCT3_XOR  ) & ( funct7 == `FUNCT7_XOR );
  wire inst_or    = ( opcode == `OPCODE_OR    ) & ( funct3 == `FUNCT3_OR   ) & ( funct7 == `FUNCT7_OR  );
  wire inst_and   = ( opcode == `OPCODE_AND   ) & ( funct3 == `FUNCT3_AND  ) & ( funct7 == `FUNCT7_AND );
  wire inst_sll   = ( opcode == `OPCODE_SLL   ) & ( funct3 == `FUNCT3_SLL  ) & ( funct7 == `FUNCT7_SLL );
  wire inst_srl   = ( opcode == `OPCODE_SRL   ) & ( funct3 == `FUNCT3_SRL  ) & ( funct7 == `FUNCT7_SRL );
  wire inst_sra   = ( opcode == `OPCODE_SRA   ) & ( funct3 == `FUNCT3_SRA  ) & ( funct7 == `FUNCT7_SRA );
  wire inst_slt   = ( opcode == `OPCODE_SLT   ) & ( funct3 == `FUNCT3_SLT  ) & ( funct7 == `FUNCT7_SLT );
  wire inst_sltu  = ( opcode == `OPCODE_SLTU  ) & ( funct3 == `FUNCT3_SLTU );
  
  wire inst_addi  = ( opcode == `OPCODE_ADDI  ) & ( funct3 == `FUNCT3_ADDI ); 
  wire inst_xori  = ( opcode == `OPCODE_XORI  ) & ( funct3 == `FUNCT3_XORI ); 
  wire inst_ori   = ( opcode == `OPCODE_ORI   ) & ( funct3 == `FUNCT3_ORI  ); 
  wire inst_andi  = ( opcode == `OPCODE_ANDI  ) & ( funct3 == `FUNCT3_ANDI );
  wire inst_slli  = ( opcode == `OPCODE_SLLI  ) & ( funct3 == `FUNCT3_SLLI ) & ( immI[11:5] == 7'h00 );
  wire inst_srli  = ( opcode == `OPCODE_SRLI  ) & ( funct3 == `FUNCT3_SRLI ) & ( immI[11:5] == 7'h00 );
  wire inst_srai  = ( opcode == `OPCODE_SRAI  ) & ( funct3 == `FUNCT3_SRAI ) & ( immI[11:5] == 7'h20 );
  wire inst_slti  = ( opcode == `OPCODE_SLTI  ) & ( funct3 == `FUNCT3_SLTI );
  wire inst_sltiu = ( opcode == `OPCODE_SLTIU ) & ( funct3 == `FUNCT3_SLTIU);
  
  wire inst_lb    = ( opcode == `OPCODE_LB    ) & ( funct3 == `FUNCT3_LB   );
  wire inst_lh    = ( opcode == `OPCODE_LH    ) & ( funct3 == `FUNCT3_LH   );
  wire inst_lw    = ( opcode == `OPCODE_LW    ) & ( funct3 == `FUNCT3_LW   );
  wire inst_lbu   = ( opcode == `OPCODE_LBU   ) & ( funct3 == `FUNCT3_LBU  );
  wire inst_lhu   = ( opcode == `OPCODE_LHU   ) & ( funct3 == `FUNCT3_LHU  );
  wire inst_sb    = ( opcode == `OPCODE_SB    ) & ( funct3 == `FUNCT3_SB   );
  wire inst_sh    = ( opcode == `OPCODE_SH    ) & ( funct3 == `FUNCT3_SH   );
  wire inst_sw    = ( opcode == `OPCODE_SW    ) & ( funct3 == `FUNCT3_SW   );

  wire inst_beq   = ( opcode == `OPCODE_BEQ   ) & ( funct3 == `FUNCT3_BEQ  );
  wire inst_bne   = ( opcode == `OPCODE_BNE   ) & ( funct3 == `FUNCT3_BNE  );
  wire inst_blt   = ( opcode == `OPCODE_BLT   ) & ( funct3 == `FUNCT3_BLT  );
  wire inst_bge   = ( opcode == `OPCODE_BGE   ) & ( funct3 == `FUNCT3_BGE  );
  wire inst_bltu  = ( opcode == `OPCODE_BLTU  ) & ( funct3 == `FUNCT3_BLTU );
  wire inst_bgeu  = ( opcode == `OPCODE_BGEU  ) & ( funct3 == `FUNCT3_BGEU );
  wire inst_jal   = ( opcode == `OPCODE_JAL   );
  wire inst_jalr  = ( opcode == `OPCODE_JALR  ) & ( funct3 == `FUNCT3_JALR );

  wire inst_lui   = ( opcode == `OPCODE_LUI   );
  wire inst_auipc = ( opcode == `OPCODE_AUIPC );

  wire ebreak     = ( opcode == `OPCODE_EBREAK) & ( funct3 == `FUNCT3_EBREAK ) & ( funct12 == `FUNCT12_EBREAK );
  wire ecall      = ( opcode == `OPCODE_ECALL ) & ( funct3 == `FUNCT3_ECALL  ) & ( funct12 == `FUNCT12_ECALL  );

  wire inst_csrrw = ( opcode == `OPCODE_CSRRW ) & ( funct3 == `FUNCT3_CSRRW );
  wire inst_csrrs = ( opcode == `OPCODE_CSRRS ) & ( funct3 == `FUNCT3_CSRRS );
  wire inst_mret  = ( opcode == `OPCODE_MRET  ) & ( funct3 == `FUNCT3_MRET  ) & ( funct12 == `FUNCT12_MRET   );

  wire inst_mul   = ( opcode == `OPCODE_MUL   ) & ( funct3 == `FUNCT3_MUL  ) & ( funct7 == `FUNCT7_MUL   );
  wire inst_mulh  = ( opcode == `OPCODE_MULH  ) & ( funct3 == `FUNCT3_MULH ) & ( funct7 == `FUNCT7_MULH  );
  wire inst_mulhu = ( opcode == `OPCODE_MULHU ) & ( funct3 == `FUNCT3_MULHU) & ( funct7 == `FUNCT7_MULHU );
  wire inst_div   = ( opcode == `OPCODE_DIV   ) & ( funct3 == `FUNCT3_DIV  ) & ( funct7 == `FUNCT7_DIV   );
  wire inst_divu  = ( opcode == `OPCODE_DIVU  ) & ( funct3 == `FUNCT3_DIVU ) & ( funct7 == `FUNCT7_DIVU  );
  wire inst_rem   = ( opcode == `OPCODE_REM   ) & ( funct3 == `FUNCT3_REM  ) & ( funct7 == `FUNCT7_REM   );
  wire inst_remu  = ( opcode == `OPCODE_REMU  ) & ( funct3 == `FUNCT3_REMU ) & ( funct7 == `FUNCT7_REMU  );

  // Check Unknown Instruction
  wire unknown    = !(
                      inst_add   | inst_sub   | inst_xor   | inst_or    | inst_and   | 
                      inst_sll   | inst_srl   | inst_sra   | inst_slt   | inst_sltu  |
                      inst_addi  |              inst_xori  | inst_ori   | inst_andi  |
                      inst_slli  | inst_srli  | inst_srai  | inst_slti  | inst_sltiu | 
                      inst_lb    | inst_lh    | inst_lw    | inst_lbu   | inst_lhu   | 
                      inst_sb    | inst_sh    | inst_sw    | 
                      inst_beq   | inst_bne   | inst_blt   | inst_bge   | inst_bltu  | inst_bgeu |
                      inst_jal   | inst_jalr  |
                      inst_lui   | inst_auipc |
                      ebreak     | ecall      | 
                      inst_csrrw | inst_csrrs | inst_mret  |
                      inst_mul   | inst_mulh  | inst_mulhu | inst_div   | inst_divu  | inst_rem  | inst_remu 
                     );

  
  wire [`REG_DATA_BUS] imm =  ( inst_addi  | inst_xori | inst_ori  | inst_andi  | inst_slti | inst_sltiu ) ? immI     :
                              ( inst_slli  | inst_srli | inst_srai                                       ) ? immSHIFT :
                              ( inst_lb    | inst_lh   | inst_lw   | inst_lbu   | inst_lhu               ) ? immI     : 
                              ( inst_sb    | inst_sh   | inst_sw                                         ) ? immS     : 
                              ( inst_beq   | inst_bne  | inst_blt  | inst_bge   | inst_bltu | inst_bgeu  ) ? immB     :
                              ( inst_jal                                                                 ) ? immJ     :
                              ( inst_jalr                                                                ) ? immI     : 
                              ( inst_lui   | inst_auipc                                                  ) ? immU     :
                              ( inst_csrrw | inst_csrrs                                                  ) ? immI     : 32'h0000_0000;

  
  assign  inst_type_o = ( rst    == `RST_ENABLE  ) ? `INST_NOP     :
                        ( opcode == 7'b011_0011  ) ? `INST_RR      :
                        ( opcode == 7'b001_0011  ) ? `INST_RI      :
                        ( opcode == 7'b000_0011  ) ? `INST_LOAD    :
                        ( opcode == 7'b010_0011  ) ? `INST_STORE   :
                        ( opcode == 7'b110_0011  ) ? `INST_BRANCH  :
                        ( opcode == 7'b110_1111  ) ? `INST_JAL     :
                        ( opcode == 7'b110_0111  ) ? `INST_JALR    :
                        ( opcode == 7'b011_0111  ) ? `INST_LUI     :
                        ( opcode == 7'b001_0111  ) ? `INST_AUIPC   :
                        ( opcode == 7'b111_0011  ) ? `INST_SYSTEM  : `INST_NOP;


  assign  alu_op_o    = ( rst == `RST_ENABLE     ) ? `ALU_OP_NOP   :
                        ( inst_add  | inst_addi  ) ? `ALU_OP_ADD   :
                        ( inst_sub               ) ? `ALU_OP_SUB   :
                        ( inst_xor  | inst_xori  ) ? `ALU_OP_XOR   :
                        ( inst_or   | inst_ori   ) ? `ALU_OP_OR    :
                        ( inst_and  | inst_andi  ) ? `ALU_OP_AND   :
                        ( inst_sll  | inst_slli  ) ? `ALU_OP_SLL   :
                        ( inst_srl  | inst_srli  ) ? `ALU_OP_SRL   :
                        ( inst_sra  | inst_srai  ) ? `ALU_OP_SRA   :
                        ( inst_slt  | inst_slti  ) ? `ALU_OP_SLT   :
                        ( inst_sltu | inst_sltiu ) ? `ALU_OP_SLTU  :
                        ( inst_jal  | inst_jalr  ) ? `ALU_OP_JUMP  : 
                        ( inst_lui               ) ? `ALU_OP_LUI   :
                        ( inst_auipc             ) ? `ALU_OP_AUIPC : `ALU_OP_NOP;

  assign  lsu_op_o    = ( rst == `RST_ENABLE     ) ? `LSU_OP_NOP   :
                        ( inst_lb                ) ? `LSU_OP_LB    :
                        ( inst_lh                ) ? `LSU_OP_LH    :
                        ( inst_lw                ) ? `LSU_OP_LW    :
                        ( inst_lbu               ) ? `LSU_OP_LBU   :
                        ( inst_lhu               ) ? `LSU_OP_LHU   :
                        ( inst_sb                ) ? `LSU_OP_SB    :
                        ( inst_sh                ) ? `LSU_OP_SH    :
                        ( inst_sw                ) ? `LSU_OP_SW    : `LSU_OP_NOP;

  assign  bpu_op_o    = ( rst == `RST_ENABLE     ) ? `BPU_OP_NOP   :
                        ( inst_beq               ) ? `BPU_OP_BEQ   :
                        ( inst_bne               ) ? `BPU_OP_BNE   :
                        ( inst_blt               ) ? `BPU_OP_BLT   :
                        ( inst_bge               ) ? `BPU_OP_BGE   :
                        ( inst_bltu              ) ? `BPU_OP_BLTU  :
                        ( inst_bgeu              ) ? `BPU_OP_BGEU  :
                        ( inst_jal               ) ? `BPU_OP_JAL   :
                        ( inst_jalr              ) ? `BPU_OP_JALR  : `BPU_OP_NOP;


  assign  wsel_o      = ( rst == `RST_ENABLE                                ) ? `SEL_ALU_DATA :
                        ( inst_lb | inst_lh | inst_lw | inst_lbu | inst_lhu ) ? `SEL_LSU_DATA : `SEL_ALU_DATA;

  assign  wena_o      = ( rst == `RST_DISABLE ) & 
                        ( 
                          inst_add  | inst_sub   | inst_xor   | inst_or    | inst_and   |
                          inst_sll  | inst_srl   | inst_sra   | inst_slt   | inst_sltu  | 
                          inst_addi |              inst_xori  | inst_ori   | inst_andi  |
                          inst_slli | inst_srli  | inst_srai  | inst_slti  | inst_sltiu |
                          inst_lb   | inst_lh    | inst_lw    | inst_lbu   | inst_lhu   |
                          inst_jal  | inst_jalr  |
                          inst_lui  | inst_auipc |
                          inst_csrrw| inst_csrrs |
                          inst_mul  | inst_mulh  | inst_mulhu | inst_div   | inst_divu | inst_rem  | inst_remu
                        );

  assign  waddr_o     = ( wena_o  == `WRITE_DISABLE ) ? `ZERO_REG :  rd;

  assign  pc_o        = pc_i;
  assign  imm_o       = imm;

  /* To Register File */
  assign  rena1_o     = ( rst == `RST_DISABLE ) & 
                        ( 
                          inst_add  | inst_sub  | inst_xor   | inst_or   | inst_and   |
                          inst_sll  | inst_srl  | inst_sra   | inst_slt  | inst_sltu  |
                          inst_addi |             inst_xori  | inst_ori  | inst_andi  | 
                          inst_slli | inst_srli | inst_srai  | inst_slti | inst_sltiu |
                          inst_lb   | inst_lh   | inst_lw    | inst_lbu  | inst_lhu   |
                          inst_sb   | inst_sh   | inst_sw    |
                          inst_beq  | inst_bne  | inst_blt   | inst_bge  | inst_bltu  | inst_bgeu |
                          inst_jalr |                
                          inst_csrrw| inst_csrrs|
                          inst_mul  | inst_mulh | inst_mulhu | inst_div  | inst_divu  | inst_rem  | inst_remu
                        );

  assign  rena2_o   = ( rst == `RST_DISABLE ) & 
                      ( 
                        inst_add  | inst_sub  | inst_xor   | inst_or   | inst_and   |
                        inst_sll  | inst_srl  | inst_sra   | inst_slt  | inst_sltu  |
                        inst_sb   | inst_sh   | inst_sw    | 
                        inst_beq  | inst_bne  | inst_blt   | inst_bge  | inst_bltu  | inst_bgeu |
                        inst_mul  | inst_mulh | inst_mulhu | inst_div  | inst_divu  | inst_rem  | inst_remu
                      );

  assign  raddr1_o  = ( rena1_o == `READ_DISABLE  ) ? `ZERO_REG : rs1; 
  assign  raddr2_o  = ( rena2_o == `READ_DISABLE  ) ? `ZERO_REG : rs2;

endmodule
