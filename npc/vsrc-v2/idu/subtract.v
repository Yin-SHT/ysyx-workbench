`include "defines.v"

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
    
endmodule // subtract 


