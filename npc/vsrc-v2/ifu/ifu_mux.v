`include "defines.v"

module ifu_mux (
  input                   reset,

  // f: bpu 
  input                   branch_en_i, 
  input  [`NPC_ADDR_BUS]  dnpc_i,

  // f: ifu_reg 
  input  [`NPC_ADDR_BUS]  snpc_i,

  // t: ifu_reg
  output [`NPC_ADDR_BUS]  next_pc_o
);

  assign next_pc_o = ( reset       == `RESET_ENABLE  ) ? `RESET_VECTOR :
                     ( branch_en_i == `BRANCH_ENABLE ) ? dnpc_i        :  // dynamic next pc
                                                         snpc_i        ;  // static next pc

endmodule
