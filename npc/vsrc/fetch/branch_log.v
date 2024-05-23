`include "defines.v"

module branch_log (
  input [31:0]  pc_i, 
  input [31:0]  inst_i, 

	output        fetch_rena1_o,
	output [4:0]  fetch_raddr1_o,
	input  [31:0] fetch_rdata1_i,

	output        fetch_rena2_o,
	output [4:0]  fetch_raddr2_o,
	input  [31:0] fetch_rdata2_i,

  output        is_branch_o,
  output        taken_o,
  output [31:0] dnpc_o
);

  //-----------------------------------------------------------------
  // Pre-Decode
  //-----------------------------------------------------------------
  wire [ 4:0] rs2     = inst_i[24:20];
  wire [ 4:0] rs1     = inst_i[19:15];
  wire [ 2:0] funct3  = inst_i[14:12];
  wire [ 6:0] opcode  = inst_i[6 :0 ];

  wire [`REG_DATA_BUS] immI = {{21{inst_i[31]}}, inst_i[30:25], inst_i[24:21], inst_i[20]                         };
  wire [`REG_DATA_BUS] immB = {{20{inst_i[31]}}, inst_i[7],     inst_i[30:25], inst_i[11:8],  1'b0                };
  wire [`REG_DATA_BUS] immJ = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20],    inst_i[30:25], inst_i[24:21], 1'b0 };

  wire inst_beq  = (opcode == `OPCODE_BEQ ) & (funct3 == `FUNCT3_BEQ );
  wire inst_bne  = (opcode == `OPCODE_BNE ) & (funct3 == `FUNCT3_BNE );
  wire inst_blt  = (opcode == `OPCODE_BLT ) & (funct3 == `FUNCT3_BLT );
  wire inst_bge  = (opcode == `OPCODE_BGE ) & (funct3 == `FUNCT3_BGE );
  wire inst_bltu = (opcode == `OPCODE_BLTU) & (funct3 == `FUNCT3_BLTU);
  wire inst_bgeu = (opcode == `OPCODE_BGEU) & (funct3 == `FUNCT3_BGEU);
  wire inst_jal  = (opcode == `OPCODE_JAL );
  wire inst_jalr = (opcode == `OPCODE_JALR) & (funct3 == `FUNCT3_JALR);

  wire[31:0]  imm = (inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu) ? immB :
                    (inst_jal                                                         ) ? immJ :
                    (inst_jalr                                                        ) ? immI : 0;

  wire[`BPU_OP_BUS] bpu_op =  inst_beq  ? `BPU_OP_BEQ   :
                              inst_bne  ? `BPU_OP_BNE   :
                              inst_blt  ? `BPU_OP_BLT   :
                              inst_bge  ? `BPU_OP_BGE   :
                              inst_bltu ? `BPU_OP_BLTU  :
                              inst_bgeu ? `BPU_OP_BGEU  :
                              inst_jal  ? `BPU_OP_JAL   :
                              inst_jalr ? `BPU_OP_JALR  : `BPU_OP_NOP;

  wire equal, signed_less_than, unsigned_less_than;

  subtract u_substract(
    .rdata1_i             (fetch_rdata1_i),
    .rdata2_i             (fetch_rdata2_i),
    .equal_o              (equal),
    .signed_less_than_o   (signed_less_than),
    .unsigned_less_than_o (unsigned_less_than)
  );

  //-----------------------------------------------------------------
  // Compute
  //-----------------------------------------------------------------
  assign fetch_rena1_o  = inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu | inst_jalr;
  assign fetch_rena2_o  = inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu;
  assign fetch_raddr1_o = rs1; 
  assign fetch_raddr2_o = rs2;

  assign  is_branch_o = inst_beq  | 
                        inst_bne  | 
                        inst_blt  | 
                        inst_bge  | 
                        inst_bltu | 
                        inst_bgeu | 
                        inst_jal  | 
                        inst_jalr;

  assign  taken_o = ((bpu_op == `BPU_OP_BEQ)  && equal)               ||
                    ((bpu_op == `BPU_OP_BNE)  && !equal)              ||
                    ((bpu_op == `BPU_OP_BLT)  && signed_less_than)    ||
                    ((bpu_op == `BPU_OP_BGE)  && !signed_less_than)   ||
                    ((bpu_op == `BPU_OP_BLTU) && unsigned_less_than)  ||
                    ((bpu_op == `BPU_OP_BGEU) && !unsigned_less_than) ||
                    ((bpu_op == `BPU_OP_JAL))                         ||
                    ((bpu_op == `BPU_OP_JALR));

  assign  dnpc_o  = (taken_o && (bpu_op == `BPU_OP_BEQ))  ? pc_i + imm :  
                    (taken_o && (bpu_op == `BPU_OP_BNE))  ? pc_i + imm :  
                    (taken_o && (bpu_op == `BPU_OP_BLT))  ? pc_i + imm :  
                    (taken_o && (bpu_op == `BPU_OP_BGE))  ? pc_i + imm :  
                    (taken_o && (bpu_op == `BPU_OP_BLTU)) ? pc_i + imm :  
                    (taken_o && (bpu_op == `BPU_OP_BGEU)) ? pc_i + imm :  
                    (taken_o && (bpu_op == `BPU_OP_JAL))  ? pc_i + imm :
                    (taken_o && (bpu_op == `BPU_OP_JALR)) ? fetch_rdata1_i + imm : 0;   // need some modification  !!!!!!!!!

endmodule

module subtract (
  input [`REG_DATA_BUS]     rdata1_i,
  input [`REG_DATA_BUS]     rdata2_i,

  output equal_o,
  output signed_less_than_o, 
  output unsigned_less_than_o
);

  wire cout;
  wire [`REG_DATA_BUS] result;
  wire Of, Cf, Sf, Zf; 

  assign { cout, result } = { 1'b0, rdata1_i } + ({ 1'b0, ~rdata2_i }) + 1;
  assign Of = ((  rdata1_i[31] ) & ( !rdata2_i[31] ) & ( !result[31] )) | 
              (( !rdata1_i[31] ) & (  rdata2_i[31] ) & (  result[31] ));
  assign Cf = cout ^ 1'b1;
  assign Sf = result[31];
  assign Zf =  ~(| result);

  assign equal_o              = Zf;
  assign signed_less_than_o   = Sf ^ Of;
  assign unsigned_less_than_o = Cf;
    
endmodule
