`include "defines.v"

module inst_decode (
    input   rst,

    input   [ `INST_ADDR_WIDTH - 1 : 0 ]    pc_i,
    output  [ `INST_ADDR_WIDTH - 1 : 0 ]    pc_o,

    // Mem   
    input   [ `INST_WIDTH - 1 : 0 ]         inst_i,

    // RF
    input   [ `REG_WIDTH - 1 : 0 ]          rf_data1_i,
    input   [ `REG_WIDTH - 1 : 0 ]          rf_data2_i,

    // RF
    output  [ `REG_ADDR_WIDTH - 1 : 0 ]     raddr1_o,
    output  [ `REG_ADDR_WIDTH - 1 : 0 ]     raddr2_o,
    output                                  rena1_o,
    output                                  rena2_o,
    
    // ALU
    output  [ `ALU_OP_WIDTH - 1 : 0 ]       alu_op_o,
    output  [ `REG_WIDTH - 1 : 0 ]          operand1_o,
    output  [ `REG_WIDTH - 1 : 0 ]          operand2_o,
    output  [ `REG_ADDR_WIDTH - 1 : 0 ]     waddr_o,
    output                                  wena_o
);
    export "DPI-C" function program_done;
    // Communicate with c++
    function program_done;
        output int done;
        done = { {31{ 1'b0 }}, inst_ebreak };
    endfunction

    assign pc_o = pc_i;

    /*
     * * Parser insts
     */
    /* verilator lint_off UNUSEDSIGNAL */

    // For system instruction
    wire [ 11 : 0 ]  funct12 =   inst_i[ 31 : 20 ];

    wire [ 6 : 0 ]   funct7  =   inst_i[ 31 : 25 ];
    wire [ 4 : 0 ]   rs2     =   inst_i[ 24 : 20 ];
    wire [ 4 : 0 ]   rs1     =   inst_i[ 19 : 15 ];
    wire [ 2 : 0 ]   funct3  =   inst_i[ 14 : 12 ];
    wire [ 4 : 0 ]   rd      =   inst_i[ 11 : 7  ];
    wire [ 6 : 0 ]   opcode  =   inst_i[ 6  : 0  ];

    wire [ `IMM_WIDTH - 1 : 0 ] immI = { {21{inst_i[31]}}, inst_i[30:25], inst_i[24:21], inst_i[20]                       };
    wire [ `IMM_WIDTH - 1 : 0 ] immS = { {21{inst_i[31]}}, inst_i[30:25], inst_i[11:8],  inst_i[7]                        };
    wire [ `IMM_WIDTH - 1 : 0 ] immB = { {20{inst_i[31]}}, inst_i[7],     inst_i[30:25], inst_i[11:8],  1'b0              };
    wire [ `IMM_WIDTH - 1 : 0 ] immU = { inst_i[31],       inst_i[30:20], inst_i[19:12], 12'b0                          };
    wire [ `IMM_WIDTH - 1 : 0 ] immJ = { {12{inst_i[31]}}, inst_i[19:12], inst_i[20],    inst_i[30:25], inst_i[24:21], 1'b0 };

    // Insts
    // TODO: more insts
    

    // I Type
    wire inst_addi   = ( opcode == `OPCODE_ADDI   ) & ( funct3 == `FUNCT3_ADDI   );
    wire inst_ebreak = ( opcode == `OPCODE_EBREAK ) & ( funct3 == `FUNCT3_EBREAK ) & ( funct12 == `FUNCT12_EBREAK );

    wire imm_require = ( inst_addi );
    wire [ `IMM_WIDTH - 1 : 0 ] imm = ( inst_addi ) ? immI  :
                                                    `ZERO_WORD;

    /*
     * * Generate signal
     */
                                            
    assign  rena1_o  =   ( rst == 1'b0 ) & ( 
                        ( inst_addi   ) 
                        );
    assign  raddr1_o   =   rena1_o  ?   rs1 :   `REG_ADDR_WIDTH'b0;

    assign  rena2_o  =   1'b0;
    assign  raddr2_o   =   rena2_o  ?   rs2 :   `REG_ADDR_WIDTH'b0;

    assign  alu_op_o =  ( rst == 1'b1 )  ?  `ALU_OP_NOP     :
                        ( inst_addi   )  ?  `ALU_OP_ADD    :
                                            `ALU_OP_NOP     ; 

    assign  operand1_o = ( rena1_o      )    ?   rf_data1_i  :   `ZERO_WORD;
    assign  operand2_o = ( imm_require )    ?   imm         :   
                         ( rena2_o      )    ?   rf_data2_i  :   `ZERO_WORD;

    assign  wena_o   = ( inst_addi );
    assign  waddr_o  = ( wena_o    )   ?   rd  :   `REG_ADDR_WIDTH'b0;


endmodule






















