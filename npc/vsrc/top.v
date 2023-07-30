`include "defines.v"

module top (
    input   clk,
    input   rst,

    input   [`INST_DATA_BUS]  inst_i,
    output  [`INST_ADDR_BUS]  pc
);

    // *** Wire to connect if and id
    wire [`INST_ADDR_BUS]   dnpc_wb_if;  
    wire [`INST_ADDR_BUS]   pc_if_id;  

    // *** Wire to connect regfile and id
    wire [`REG_DATA_BUS]    data1_rf_id;
    wire [`REG_DATA_BUS]    data2_rf_id;

    // *** Wire to connect id and regfile
    wire [`REG_ADDR_BUS]    raddr1_id_rf;
    wire [`REG_ADDR_BUS]    raddr2_id_rf;
    wire                    rena1_id_rf;
    wire                    rena2_id_rf;

    // *** Wire to connect id and exe
    wire [`INST_ADDR_BUS]   snpc_id_exe;
    wire [`ALU_OP_BUS]      alu_op_id_exe;
    wire [`REG_DATA_BUS]    operand1_id_exe;
    wire [`REG_DATA_BUS]    operand2_id_exe;
    wire                    wena_id_exe;
    wire [`REG_ADDR_BUS]    waddr_id_exe;
    wire [`REG_DATA_BUS]    jump_target_id_exe;

    // *** Wire to connect wb and regfile
    wire [`REG_DATA_BUS]    wdata_wb_rf;
    wire                    wena_wb_rf;
    wire [`REG_ADDR_BUS]    waddr_wb_rf;

    // *** Wire to connect exe and wb
    wire [`INST_ADDR_BUS]   dnpc_exe_wb;
    wire [`REG_DATA_BUS]    result_exe_wb;
    wire                    wena_exe_wb;
    wire [`REG_ADDR_BUS]    waddr_exe_wb;   

    assign pc = pc_if_id;

    inst_fetch u_inst_fetch (
        .clk        ( clk           ),
        .rst        ( rst           ),
        .next_pc    ( dnpc_wb_if    ),
        .pc         ( pc_if_id      )
    );

    inst_decode u_inst_decode (
        .rst            ( rst                   ),
        .pc_i           ( pc_if_id              ),
        .inst_i         ( inst_i                ),
        .data1_i        ( data1_rf_id           ),
        .data2_i        ( data2_rf_id           ),
        .raddr1_o       ( raddr1_id_rf          ),
        .raddr2_o       ( raddr2_id_rf          ),
        .rena1_o        ( rena1_id_rf           ),
        .rena2_o        ( rena2_id_rf           ),
        .snpc_o         ( snpc_id_exe           ),
        .alu_op_o       ( alu_op_id_exe         ),
        .operand1_o     ( operand1_id_exe       ),
        .operand2_o     ( operand2_id_exe       ),
        .wena_o         ( wena_id_exe           ),
        .waddr_o        ( waddr_id_exe          ),
        .jump_target_o  ( jump_target_id_exe    )
    );

    regfile u_regfile (
        .clk        ( clk               ),
        .rst        ( rst               ),
        .wdata_i    ( wdata_wb_rf       ),
        .wena_i     ( wena_wb_rf        ),
        .waddr_i    ( waddr_wb_rf       ),
        .raddr1_i   ( raddr1_id_rf      ),
        .rena1_i    ( rena1_id_rf       ),
        .raddr2_i   ( raddr2_id_rf      ),
        .rena2_i    ( rena2_id_rf       ),
        .data1_o    ( data1_rf_id       ),
        .data2_o    ( data2_rf_id       )
    );

    execute u_execute (
        .rst        ( rst                ),
        .snpc_i     ( snpc_id_exe        ),
        .alu_op_i   ( alu_op_id_exe      ),
        .operand1_i ( operand1_id_exe    ),
        .operand2_i ( operand2_id_exe    ),
        .wena_i     ( wena_id_exe        ),
        .waddr_i    ( waddr_id_exe       ),
        .j_target_i ( jump_target_id_exe ),
        .result_o   ( result_exe_wb      ),
        .wena_o     ( wena_exe_wb        ),
        .waddr_o    ( waddr_exe_wb       ),
        .dnpc_o     ( dnpc_exe_wb        )
    );

    write_back u_write_back (
        .rst        ( rst               ),
        .dnpc_i     ( dnpc_exe_wb       ),
        .dnpc_o     ( dnpc_wb_if        ),
        .result_i   ( result_exe_wb     ),
        .wena_i     ( wena_exe_wb       ),
        .waddr_i    ( waddr_exe_wb      ),
        .wdata_o    ( wdata_wb_rf       ),
        .wena_o     ( wena_wb_rf        ),
        .waddr_o    ( waddr_wb_rf       )    
    );

endmodule
