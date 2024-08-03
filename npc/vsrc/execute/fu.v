`include "defines.v"

module fu (
    input           clock,
    input           reset,

    input           valid_pre_i,
    input           lsu_ready_pre_o,
    output          fu_ready_pre_o,

    input           ready_post_i,
    output          fu_valid_post_o,

    input  [7:0]    inst_type_i,
    input  [7:0]    alu_op_i,
    input  [7:0]    csr_op_i,
    input  [31:0]   pc_i,
    input  [31:0]   imm_i,
    input  [31:0]   rdata1_i,
    input  [31:0]   rdata2_i,
    input  [31:0]   csr_rdata_i,

    output [31:0]   alu_result_o,
    output [31:0]   csr_wdata_o
);

    //-----------------------------------------------------------------
    // PIPELINE REG
    //-----------------------------------------------------------------
    reg [7:0]  inst_type;
    reg [7:0]  alu_op;
    reg [7:0]  csr_op;
    reg [31:0] pc;
    reg [31:0] imm;
    reg [31:0] rdata1;
    reg [31:0] rdata2;
    reg [31:0] csr_rdata;

    always @(posedge clock) begin
        if (reset) begin
            inst_type <= 0;
            alu_op    <= 0;
            csr_op    <= 0;
            pc        <= 0;
            imm       <= 0;
            rdata1    <= 0;
            rdata2    <= 0;
            csr_rdata <= 0;
        end else if (valid_pre_i && fu_ready_pre_o && lsu_ready_pre_o) begin
            if (inst_type_i != `INST_LOAD && inst_type_i != `INST_STORE) begin
                inst_type <= inst_type_i;
                alu_op    <= alu_op_i;
                csr_op    <= csr_op_i;
                pc        <= pc_i;
                imm       <= imm_i;
                rdata1    <= rdata1_i;
                rdata2    <= rdata2_i;
                csr_rdata <= csr_rdata_i;
            end else begin
                inst_type <= 0;
                alu_op    <= 0;
                csr_op    <= 0;
                pc        <= 0;
                imm       <= 0;
                rdata1    <= 0;
                rdata2    <= 0;
                csr_rdata <= 0;
            end
        end
    end

    //-----------------------------------------------------------------
    // FSM
    //-----------------------------------------------------------------
    parameter idle       = 2'b00;
    parameter wait_ready = 2'b01;

    reg [1:0] cur_state;
    reg [1:0] next_state;

    //-----------------------------------------------------------------
    // Outputs 
    //-----------------------------------------------------------------
    assign fu_ready_pre_o  = cur_state == idle;
    assign fu_valid_post_o = cur_state == wait_ready;


    //-----------------------------------------------------------------
    // Synchronous State - Transition always@ ( posedge Clock ) block
    //-----------------------------------------------------------------
    always @(posedge clock) begin
        if (reset) begin
            cur_state <= idle;
        end else begin
            cur_state <= next_state;
        end
    end


    //-----------------------------------------------------------------
    // Conditional State - Transition always@ ( * ) block
    //-----------------------------------------------------------------
    always @(*) begin
        next_state = cur_state;
        case (cur_state)
            idle: if (valid_pre_i)  begin
                if (inst_type_i != `INST_LOAD && inst_type_i != `INST_STORE)
                    next_state = wait_ready;
            end
            wait_ready: if (ready_post_i) next_state = idle;
            default:                      next_state = cur_state;
        endcase
    end

    //-----------------------------------------------------------------
    // ALU
    //-----------------------------------------------------------------
    wire [31:0] operand1;
    wire [31:0] operand2;

    assign operand1     = ( 
                            ( reset     == `RESET_ENABLE ) || 
                            ( inst_type == `INST_NOP     ) || 
                            ( alu_op    == `ALU_OP_NOP   )   
                            )                            ? 32'h0000_0000 :
                            ( inst_type == `INST_RR    ) ? rdata1      :
                            ( inst_type == `INST_RI    ) ? rdata1      :
                            ( inst_type == `INST_LUI   ) ? 32'h0000_0000 :
                            ( inst_type == `INST_AUIPC ) ? pc          : 
                            ( inst_type == `INST_JAL   ) ? pc          : 
                            ( inst_type == `INST_JALR  ) ? pc          : 
                            ( inst_type == `INST_CSRR  ) ? csr_rdata   : 32'h0000_0000;

    assign operand2     = ( 
                            ( reset     == `RESET_ENABLE ) || 
                            ( inst_type == `INST_NOP     ) || 
                            ( alu_op    == `ALU_OP_NOP   )   
                            )                            ? 32'h0000_0000 :
                            ( inst_type == `INST_RR    ) ? rdata2      :
                            ( inst_type == `INST_RI    ) ? imm         :
                            ( inst_type == `INST_LUI   ) ? imm         :
                            ( inst_type == `INST_AUIPC ) ? imm         : 32'h0000_0000;

    assign alu_result_o = ( 
                            ( reset     == `RESET_ENABLE ) || 
                            ( inst_type == `INST_NOP     ) || 
                            ( alu_op    == `ALU_OP_NOP   )   
                            )                              ?  32'h0000_0000         :
                            ( alu_op == `ALU_OP_ADD   )  ?  operand1  +  operand2 :
                            ( alu_op == `ALU_OP_SUB   )  ?  operand1  -  operand2 :
                            ( alu_op == `ALU_OP_XOR   )  ?  operand1  ^  operand2 :
                            ( alu_op == `ALU_OP_OR    )  ?  operand1  |  operand2 :
                            ( alu_op == `ALU_OP_AND   )  ?  operand1  &  operand2 :
                            ( alu_op == `ALU_OP_SLL   )  ?  operand1  << operand2[4:0] :
                            ( alu_op == `ALU_OP_SRL   )  ?  operand1  >> operand2[4:0] :
                            ( alu_op == `ALU_OP_SRA   )  ?  (({32{operand1[31]}} << (32'd32 - {28'b0, operand2[4:0]})) | (operand1 >> {28'b0, operand2[4:0]})) :
                            ( alu_op == `ALU_OP_SLT   )  ?  {{31{1'b0}},   $signed(operand1) <   $signed(operand2)} :
                            ( alu_op == `ALU_OP_SLTU  )  ?  {{31{1'b0}}, $unsigned(operand1) < $unsigned(operand2)} :
                            ( alu_op == `ALU_OP_LUI   )  ?  operand1  +  operand2 :
                            ( alu_op == `ALU_OP_AUIPC )  ?  operand1  +  operand2 :
                            ( alu_op == `ALU_OP_JUMP  )  ?  operand1  +  32'h4    : 
                            ( alu_op == `ALU_OP_CSRR  )  ?  operand1              : 0;


    //-----------------------------------------------------------------
    // CSR
    //-----------------------------------------------------------------
    assign csr_wdata_o  =   (csr_op == `CSR_OP_CSRRW) ? rdata1 :
                            (csr_op == `CSR_OP_CSRRS) ? rdata1 | csr_rdata :
                            (csr_op == `CSR_OP_ECALL) ? pc : 0;

    //-----------------------------------------------------------------
    // performance counter
    //-----------------------------------------------------------------
    export "DPI-C" function fu_cnt;
    function fu_cnt;
        output int _nr_compute_;
        _nr_compute_ = nr_compute;
    endfunction

    reg [31:0] nr_compute;
    
    always @(posedge clock) begin
        if (reset) begin
            nr_compute <= 0;
        end else if (fu_valid_post_o && ready_post_i) begin
            nr_compute <= nr_compute + 1;
        end
    end

endmodule
