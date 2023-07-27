`include "defines.v"

module top (
    input   clk,
    input   rst,

    input   [ `INST_WIDTH - 1      : 0 ]  inst_i,
    output  [ `INST_ADDR_WIDTH - 1 : 0 ]  pc
);
    wire [ `INST_ADDR_WIDTH - 1 : 0 ]    pc_pc_id  ;
    wire [ `INST_ADDR_WIDTH - 1 : 0 ]    pc_id_exe ;
    wire [ `INST_ADDR_WIDTH - 1 : 0 ]    pc_exe_wb ;
    wire [ `INST_ADDR_WIDTH - 1 : 0 ]    pc_wb_pc  ;
    wire [ `INST_WIDTH - 1 : 0 ]         inst      ;
    wire [ `REG_WIDTH - 1 : 0 ]          rf_data1  ;
    wire [ `REG_WIDTH - 1 : 0 ]          rf_data2  ;
    wire [ `REG_ADDR_WIDTH - 1 : 0 ]     raddr1    ;
    wire [ `REG_ADDR_WIDTH - 1 : 0 ]     raddr2    ;
    wire                                 rena1     ;
    wire                                 rena2     ;
    wire [ `ALU_OP_WIDTH - 1 : 0 ]       alu_op    ;
    wire [ `REG_WIDTH - 1 : 0 ]          operand1  ;
    wire [ `REG_WIDTH - 1 : 0 ]          operand2  ;
    wire [ `REG_ADDR_WIDTH - 1 : 0 ]     waddr_id_exe     ;
    wire [ `ALU_OP_WIDTH - 1 : 0 ]       alu_op    ;
    wire [ `REG_WIDTH - 1 : 0 ]          operand1  ;
    wire [ `REG_WIDTH - 1 : 0 ]          operand2  ;
    wire [ `REG_ADDR_WIDTH - 1 : 0 ]     waddr_exe_wb     ;
    wire                                 wena_id_exe      ;

    wire [ `REG_WIDTH - 1 : 0 ]          result    ;
    wire [ `REG_ADDR_WIDTH - 1 : 0 ]     waddr_wb_rf     ;
    wire                                 wena_exe_wb      ;
    wire [ `REG_WIDTH      - 1 : 0 ]     result    ;
    wire                                 wena_wb_rf      ;

    wire [ `REG_WIDTH      - 1 : 0 ]     wdata     ;

    assign pc = pc_pc_id;
    assign inst = inst_i;

    pc u_pc (
    	.clk     (      clk      ),
        .rst     (      rst      ),
        .pc_next (      pc_wb_pc ),
        .pc      (      pc_pc_id )
    );

    inst_decode u_inst_decode(
    	.rst        (   rst         ),       
        
        .pc_i       (   pc_pc_id    ),
        .pc_o       (   pc_id_exe   ),

        .inst_i     (   inst        ),
        .rf_data1_i (   rf_data1    ),
        .rf_data2_i (   rf_data2    ),
        .raddr1_o   (   raddr1      ),
        .raddr2_o   (   raddr2      ),
        .rena1_o    (   rena1       ),
        .rena2_o    (   rena2       ),
        .alu_op_o   (   alu_op      ),
        .operand1_o (   operand1    ),
        .operand2_o (   operand2    ),
        .waddr_o    (   waddr_id_exe       ),
        .wena_o     (   wena_id_exe        )
    );
       
    regfile u_regfile(
    	.clk        (   clk         ),
        .rst        (   rst         ),

        .rf_data1_o (   rf_data1    ),
        .rf_data2_o (   rf_data2    ),
        .wdata_i    (   wdata       ),
        .waddr_i    (   waddr_wb_rf       ),
        .wena_i     (   wena_wb_rf        ),
        .raddr1_i   (   raddr1      ),
        .rena1_i    (   rena1       ),
        .raddr2_i   (   raddr2      ),
        .rena2_i    (   rena2       )
    );
    
    execute u_execute(
    	.rst        (   rst          ),

        .pc_i       (   pc_id_exe    ),
        .pc_o       (   pc_exe_wb    ),

        .alu_op_i   (   alu_op       ),
        .operand1_i (   operand1     ),
        .operand2_i (   operand2     ),
        .waddr_i    (   waddr_id_exe        ),
        .wena_i     (   wena_id_exe         ),
        .result_o   (   result       ),
        .waddr_o    (   waddr_exe_wb        ),
        .wena_o     (   wena_exe_wb         )
    );
    
    write_back u_write_back(
    	.rst      (     rst         ),

        .pc_i     (     pc_exe_wb   ),
        .pc_o     (     pc_wb_pc    ),

        .result_i (     result      ),
        .waddr_i  (     waddr_exe_wb       ),
        .wena_i   (     wena_exe_wb        ),
        .wdata_o  (     wdata       ),
        .waddr_o  (     waddr_wb_rf       ),
        .wena_o   (     wena_wb_rf        )
    );

endmodule
