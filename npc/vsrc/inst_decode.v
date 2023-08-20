`include "defines.v"

module inst_decode (
  input   rst,

  // Signal From inst_fetch
  input   [`INST_ADDR_BUS]    pc_i,

  // Signal From Mem   
  input   [`INST_DATA_BUS]    inst_i,

  /* verilator lint_off UNUSEDSIGNAL */
  // Signal From Regfile
  input   [`REG_DATA_BUS]     data1_i,
  input   [`REG_DATA_BUS]     data2_i,

  // Signal To Regfile
  output                      rena1_o,
  output                      rena2_o,
  output  [`REG_ADDR_BUS]     raddr1_o,
  output  [`REG_ADDR_BUS]     raddr2_o,
  output                      wena_o,
  output  [`REG_ADDR_BUS]     waddr_o,
    
  // Signal To Alu
  output  [`ALU_OP_BUS]       alu_op_o,
  output  [`REG_DATA_BUS]     operand1_o,
  output  [`REG_DATA_BUS]     operand2_o,

  // Signal To Control Transfer Unit
  output  [`TRAN_OP_BUS]      tran_op_o,
  output  [`INST_ADDR_BUS]    pc_o,
  output  [`REG_DATA_BUS]     imm_o,

  // Signel To Data-Mem/Alu
  output                      rmem_ena_o,
  output                      wmem_ena_o,
  
  // Signal To Data-Filter
  output [`MEM_DATA_BUS]      wmem_data_o,

  // Signal To Write-Back
  output                      wsel_o
);

  /*
   * This interface to communicate with C++ code
   */
  export "DPI-C" function inst_ebreak;
  function inst_ebreak;
      output int _ebreak;
      _ebreak = { {31{1'b0}}, ebreak };
  endfunction

  export "DPI-C" function inst_unknown;
  function inst_unknown;
      output int _unknown;
      _unknown = { {31{1'b0}}, unknown };
  endfunction

  // *** Parser instruction
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

  // Integer Compute Instruction
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

  wire ebreak     = ( opcode == `OPCODE_EBREAK ) & ( funct3 == `FUNCT3_EBREAK ) & ( funct12 == `FUNCT12_EBREAK );

  // Check Unknown Instruction
  wire unknown    = !(
                      inst_add  | inst_sub   | 
                      inst_xor  | inst_or    | inst_and  |
                      inst_sll  | inst_slt   | inst_srl  | inst_sra  | inst_sltu  |
                      inst_addi | inst_xori  | inst_ori  | inst_andi |
                      inst_slli | inst_srli  | inst_srai | inst_slti | inst_sltiu | 
                      inst_lb   | inst_lh    | inst_lw   | inst_lbu  | inst_lhu   | 
                      inst_sb   | inst_sh    | inst_sw   |
                      inst_beq  | inst_bne   | inst_blt  | inst_bge  | inst_bltu  | inst_bgeu |
                      inst_jal  | inst_jalr  |
                      inst_lui  | inst_auipc |
                      ebreak   
                     );
  // Parser Imm
  wire [`REG_DATA_BUS] imm =  ( inst_addi | inst_xori | inst_ori  | inst_andi  | 
                                inst_slli | inst_srli | inst_srai | inst_slti  | inst_sltiu             ) ? immI :
                              ( inst_lb   | inst_lh   | inst_lw   | inst_lbu   | inst_lhu               ) ? immI : 
                              ( inst_beq  | inst_bne  | inst_blt  | inst_bge   | inst_bltu | inst_bgeu  ) ? immB :
                              ( inst_jal                                                                ) ? immJ :
                              ( inst_jalr                                                               ) ? immI : 
                              ( inst_sb   | inst_sh  | inst_sw                                          ) ? immS : 
                              ( inst_lui  | inst_auipc                                                  ) ? immU : `ZERO_WORD;

  // *** Signal To Regfile
  assign rena1_o  = ( rst == `RST_DISABLE ) & 
                    ( 
                      inst_add  | inst_sub  |  
                      inst_xor  | inst_or   | inst_and  |
                      inst_sll  | inst_slt  | inst_srl  | inst_sra   | inst_sltu  |
                      inst_addi | inst_xori | inst_ori  | inst_andi  | 
                      inst_slli | inst_srli | inst_srai | inst_slti  | inst_sltiu |
                      inst_lb   | inst_lh   | inst_lw   | inst_lbu   | inst_lhu   |
                      inst_sb   | inst_sh   | inst_sw   |
                      inst_beq  | inst_bne  | inst_blt  | inst_bge   | inst_bltu  | inst_bgeu |
                      inst_jalr 
                    );

  assign rena2_o  = ( rst == `RST_DISABLE ) & 
                    ( 
                      inst_add  | inst_sub  | 
                      inst_xor  | inst_or   | inst_and  |
                      inst_sll  | inst_slt  | inst_srl  | inst_sra   | inst_sltu  |
                      inst_sb   | inst_sh   | inst_sw   |
                      inst_beq  | inst_bne  | inst_blt  | inst_bge   | inst_bltu  | inst_bgeu 
                    );

  assign wena_o   = ( rst == `RST_DISABLE ) & 
                    ( 
                      inst_add  | inst_sub  | 
                      inst_xor  | inst_or   | inst_and  |
                      inst_sll  | inst_slt  | inst_srl  | inst_sra   | inst_sltu  | 
                      inst_addi | inst_xori | inst_ori  | inst_andi  |
                      inst_slli | inst_srli | inst_srai | inst_slti  | inst_sltiu |
                      inst_lb   | inst_lh   | inst_lw   | inst_lbu   | inst_lhu   |
                      inst_jal  | inst_jalr |
                      inst_lui  | inst_auipc 
                    );

  assign raddr1_o = ( rena1_o == `READ_DISABLE  ) ? `ZERO_REG : rs1;
  assign raddr2_o = ( rena2_o == `READ_DISABLE  ) ? `ZERO_REG : rs2;
  assign waddr_o  = ( wena_o  == `WRITE_DISABLE ) ? `ZERO_REG :  rd;

  // *** Signal To Alu
  assign alu_op_o =   ( rst == `RST_ENABLE ) ? `ALU_OP_NOP :
                      ( inst_add           ) ? `ALU_OP_ADD :
                      ( inst_sub           ) ? `ALU_OP_SUB :
                      
                      ( inst_xor           ) ? `ALU_OP_XOR :
                      ( inst_or            ) ? `ALU_OP_OR  :
                      ( inst_and           ) ? `ALU_OP_AND  :

                      ( inst_sll           ) ? `ALU_OP_SLL  :
                      ( inst_srl           ) ? `ALU_OP_SRL  :
                      ( inst_sra           ) ? `ALU_OP_SRA  :
                      ( inst_slt           ) ? `ALU_OP_SLT  :
                      ( inst_sltu          ) ? `ALU_OP_SLTU:

                      ( inst_addi          ) ? `ALU_OP_ADD :
                      ( inst_xori          ) ? `ALU_OP_XOR :
                      ( inst_ori           ) ? `ALU_OP_OR  :
                      ( inst_andi          ) ? `ALU_OP_AND :

                      ( inst_slli          ) ? `ALU_OP_SLL :
                      ( inst_srli          ) ? `ALU_OP_SRL :
                      ( inst_srai          ) ? `ALU_OP_SRA :
                      ( inst_slti          ) ? `ALU_OP_SLTI :
                      ( inst_sltiu         ) ? `ALU_OP_SLTIU:
                      
                      ( inst_sb            ) ? `ALU_OP_SB  :
                      ( inst_sh            ) ? `ALU_OP_SH  :
                      ( inst_sw            ) ? `ALU_OP_SW  : 
                     
                      ( inst_lb            ) ? `ALU_OP_LB  :
                      ( inst_lh            ) ? `ALU_OP_LH  :
                      ( inst_lw            ) ? `ALU_OP_LW  :
                      ( inst_lbu           ) ? `ALU_OP_LBU :
                      ( inst_lhu           ) ? `ALU_OP_LHU :

                      ( inst_jal           ) ? `ALU_OP_JUMP:
                      ( inst_jalr          ) ? `ALU_OP_JUMP:

                      ( inst_lui           ) ? `ALU_OP_ADD :
                      ( inst_auipc         ) ? `ALU_OP_ADD : `ALU_OP_NOP;

  // *** operand* To Alu/Tran
  assign operand1_o = ( rst == `RST_ENABLE ) ? `ZERO_WORD  :
                      (
                        inst_add  | inst_sub  |  
                        inst_xor  | inst_or   | inst_and  |
                        inst_sll  | inst_slt  | inst_srl  | inst_sra   | inst_sltu  |
                        inst_addi | inst_xori | inst_ori  | inst_andi  | 
                        inst_slli | inst_srli | inst_srai | inst_slti  | inst_sltiu |
                        inst_lb   | inst_lh   | inst_lw   | inst_lbu   | inst_lhu   |
                        inst_sb   | inst_sh   | inst_sw   |
                        inst_beq  | inst_bne  | inst_blt  | inst_bge   | inst_bltu  | inst_bgeu |
                        inst_jalr 
                      )              ? data1_i :
                      ( inst_auipc ) ? pc_i    : `ZERO_WORD;
    
  assign operand2_o = ( rst == `RST_ENABLE ) ? `ZERO_WORD  :
                      (
                        inst_add  | inst_sub  |  
                        inst_xor  | inst_or   | inst_and  |
                        inst_sll  | inst_slt  | inst_srl  | inst_sra   | inst_sltu  |
                        inst_beq  | inst_bne  | inst_blt  | inst_bge   | inst_bltu  | inst_bgeu 
                      )              ? data2_i :
                      (
                        inst_addi | inst_xori | inst_ori  | inst_andi  | 
                        inst_slli | inst_srli | inst_srai | inst_slti  | inst_sltiu |
                        inst_lb   | inst_lh   | inst_lw   | inst_lbu   | inst_lhu   |
                        inst_sb   | inst_sh   | inst_sw   |
                        inst_lui  | inst_auipc
                      )                         ? imm     :
                      ( inst_jal  | inst_jalr ) ? pc_i    : `ZERO_WORD;

  // Signal To Tran
  assign tran_op_o  = ( rst == `RST_ENABLE ) ? `TRAN_OP_NOP  :
                      ( inst_beq           ) ? `TRAN_OP_BEQ  :
                      ( inst_bne           ) ? `TRAN_OP_BNE  :
                      ( inst_blt           ) ? `TRAN_OP_BLT  :
                      ( inst_bge           ) ? `TRAN_OP_BGE  :
                      ( inst_bltu          ) ? `TRAN_OP_BLTU :
                      ( inst_bgeu          ) ? `TRAN_OP_BGEU :
                      ( inst_jal           ) ? `TRAN_OP_JAL  :
                      ( inst_jalr          ) ? `TRAN_OP_JALR : `TRAN_OP_NOP;
 
  assign pc_o  = pc_i;               
  assign imm_o = imm ;

  // Signal To Data-Mem
  assign rmem_ena_o = ( rst == `RST_ENABLE                                ) ? `READ_DISABLE :
                      ( inst_lb | inst_lh | inst_lw | inst_lbu | inst_lhu ) ? `READ_ENABLE  : `READ_DISABLE;

  assign wmem_ena_o = ( rst == `RST_ENABLE          ) ? `WRITE_DISABLE :
                      ( inst_sb | inst_sh | inst_sw ) ? `WRITE_ENABLE  : `WRITE_DISABLE;

  assign wmem_data_o= ( rst == `RST_ENABLE          ) ? `ZERO_WORD     :
                      ( inst_sb | inst_sh | inst_sw ) ? data2_i        : `ZERO_WORD;

  // Signal To Write-Back
  assign wsel_o     = ( rst == `RST_ENABLE                                ) ? `ALU_DATA :
                      ( inst_lb | inst_lh | inst_lw | inst_lbu | inst_lhu ) ? `MEM_DATA : `ALU_DATA;

endmodule
