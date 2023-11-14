`include "defines.v"

module pc_mux (
  input                    rst,

  input                    branch_en_i, 
  input  [`INST_ADDR_BUS]  araddr_i,
  input  [`INST_ADDR_BUS]  dnpc_i,

  output [`INST_ADDR_BUS]  next_pc_o
);

  assign next_pc_o  = ( rst          == `RST_ENABLE    )  ?  `RST_PC       :
                      ( branch_en_i  == `BRANCH_ENABLE )  ?   dnpc_i       :     // dynamic next pc
                                                              araddr_i + 4 ;     // static  next pc

endmodule
