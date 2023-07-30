`include "defines.v"

module inst_decode (
    input   rst,

    // Signal From inst_fetch
    input   [`INST_ADDR_BUS]    pc_i,

    // Signal From Mem   
    input   [`INST_DATA_BUS]    inst_i,

    // Signal From Regfile
    input   [`REG_DATA_BUS]     data1_i,
    input   [`REG_DATA_BUS]     data2_i,

    // Signal To Regfile
    output  [`REG_ADDR_BUS]     raddr1_o,
    output  [`REG_ADDR_BUS]     raddr2_o,
    output                      rena1_o,
    output                      rena2_o,
    
    // Signal To Alu
    output  [`INST_ADDR_BUS]    snpc_o,
    output  [`ALU_OP_BUS]       alu_op_o,
    output  [`REG_DATA_BUS]     operand1_o,
    output  [`REG_DATA_BUS]     operand2_o,
    output                      wena_o,
    output  [`REG_ADDR_BUS]     waddr_o,

    output  [`REG_DATA_BUS]     jump_target_o
);
    /*
     * This interface to communicate with C++ code
     */
    export "DPI-C" function program_done;
    function program_done;
        output int done;
        done = { {31{1'b0}}, inst_ebreak };
    endfunction

    /* verilator lint_off UNUSEDSIGNAL */

    //  *** 0. Parser instruction
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

    // *** 1. Get Insts Type 
    
    // >> ADD MORE INSTRUCTIONS
    // *** I Type
    wire inst_addi   = ( opcode == `OPCODE_ADDI   ) & ( funct3 == `FUNCT3_ADDI   );
    wire inst_jalr   = ( opcode == `OPCODE_JALR   ) & ( funct3 == `FUNCT3_JALR   );
    
    // *** U Type
    wire inst_aupic  = ( opcode == `OPCODE_AUIPC );
    wire inst_lui    = ( opcode == `OPCODE_LUI   );

    // *** J Type
    wire inst_jal    = ( opcode == `OPCODE_JAL   );

    // *** S Type
    wire inst_sw     = ( opcode == `OPCODE_SW    ) & ( funct3 == `FUNCT3_SW      );

    // *** System instructions
    wire inst_ebreak = ( opcode == `OPCODE_EBREAK ) & ( funct3 == `FUNCT3_EBREAK ) & ( funct12 == `FUNCT12_EBREAK );

    // *** 2. Get Imm

    // >> Confirm Imm
    wire imm_req = ( inst_addi ) | ( inst_aupic ) | ( inst_lui ) | ( inst_sw );
    wire [`REG_DATA_BUS] imm =  ( ( inst_addi  ) | ( inst_jalr ) ) ? immI : 
                                ( ( inst_aupic ) | ( inst_lui  ) ) ? immU :
                                ( ( inst_jal   ) )                 ? immJ : 
                                ( ( inst_sw    ) )                 ? immS : `ZERO_WORD;

    // *** 3. Generate signal
    assign  snpc_o = pc_i + 4;

    // >> Confirm src1, src2
    assign  rena1_o     =   ( rst == 1'b0 ) & ( ( inst_addi   ) | ( inst_jalr ) ) ;
    assign  raddr1_o    =   rena1_o    ?    rs1    :    `ZERO_REG;

    assign  rena2_o     =   1'b0;
    assign  raddr2_o    =   rena2_o    ?    rs2    :    `ZERO_REG;

    // >> Confirm alu_op_xxx
    assign  alu_op_o    =   ( ( rst == 1'b1 ) )   ?    `ALU_OP_NOP    : 
                            ( ( inst_addi ) | ( inst_aupic ) | ( inst_lui ) )    ?    `ALU_OP_ADD    :    
                            ( ( inst_jal  ) )                                    ?    `ALU_OP_JAL    :
                            ( ( inst_jalr ) )                                    ?    `ALU_OP_JALR   :  `ALU_OP_NOP; 

    // >> Confirm operand1, operand2
    assign  operand1_o  =   ( rena1_o      )    ?    data1_i    :
                            ( inst_aupic   )    ?    pc_i       :    `ZERO_WORD;

    assign  operand2_o  =   ( rena2_o      )    ?    data2_i    :   
                            ( imm_req      )    ?    imm        :    
                            ( inst_jal     )    ?    pc_i + 4   :    
                            ( inst_jalr    )    ?    pc_i + 4   :    `ZERO_WORD;

    // >> Confirm wena, waddr
    assign  wena_o      =   ( inst_addi ) | ( inst_aupic ) | ( inst_lui ) | ( inst_jal ) | ( inst_jalr );
    assign  waddr_o     =   ( wena_o    )   ?   rd  :   `ZERO_REG;

    // *** 3. Process Jump Instructions
    assign  jump_target_o   =   ( rst == 1'b1  )    ?   `ZERO_WORD      :   
                                ( inst_jal     )    ?   pc_i    + imm   :   
                                ( inst_jalr    )    ?   data1_i + imm   :   `ZERO_WORD;

endmodule
