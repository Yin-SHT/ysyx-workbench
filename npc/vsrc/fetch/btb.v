`include "defines.v"

module btb (
  input         clock,
  input         reset,

  input  [31:0] pc_i,          // assume pc_i is address of one branch instruction
  output        pvalid_o,      // predict valid bit indicates this pc extry exist or not
  output        ptaken_o,      // predict direction 
  output [31:0] ptarget_o,     // predict target

  input         flush_i,       // 0: predict success 1: predict failure
  input  [31:0] wpc_i,
  input         wtaken_i,      // true taken direction
  input  [31:0] wtarget_i      // true predict target
);

  reg       valid[63:0];
  reg[31:0] pc[63:0];
  reg[1:0]  cnt[63:0];        // 00 -> 01 -> 10 -> 11
  reg[31:0] target[63:0];

  wire[5:0] ridx = pc_i[5:0];   // read index
  wire[5:0] widx = wpc_i[5:0];  // write index

  //-----------------------------------------------------------------
  // Predict
  //-----------------------------------------------------------------
  assign pvalid_o  = valid[ridx];
  assign ptaken_o  = (pc[ridx] == pc_i) && (cnt[ridx] >= 2'b10);
  assign ptarget_o = target[ridx];

  //-----------------------------------------------------------------
  // Update
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if (!reset) begin
      if (flush_i) begin
        valid[widx] <= 1;
        pc[widx] <= wpc_i;
        if (!wtaken_i) begin                // 0: not taken
          if (cnt[widx] > 2'b00) begin
            cnt[widx] <= cnt[widx] - 1;
          end
        end else if (wtaken_i) begin        // 1: taken
          if (cnt[widx] < 2'b11) begin
            cnt[widx] <= cnt[widx] + 1;
          end
        end
        target[widx] <= wtarget_i;
      end 
    end
  end

endmodule
