`include "../defines.v"

module pc_mux (
  input rst,

  input                   be, 
  input [`INST_ADDR_BUS]  pc_i,
  input [`INST_ADDR_BUS]  dnpc_i,

  output [`INST_ADDR_BUS]  next_pc
);


  assign next_pc = ( rst == `RST_ENABLE    )  ?  32'h8000_0000 :
                   ( be  == `BRANCH_ENABLE )  ?  dnpc_i        : 
                                                 pc_i + 4      ;

endmodule
