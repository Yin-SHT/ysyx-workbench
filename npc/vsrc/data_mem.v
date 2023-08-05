`include "defines.v"

module data_mem (
  input                   rst,
  input                   clk,

  // Signal From Inst_Decode 
  input                   rmem_ena_i,
  input                   wmem_ena_i,
  
  // Signal From Data_Filter 
  input  [`MEM_DATA_BUS]  wmem_data_i,

  // Signal From Execute
  input  [`MEM_ADDR_BUS]  rmem_addr_i,
  input  [`MEM_ADDR_BUS]  wmem_addr_i,
  input  [`MEM_MASK_BUS]  wmem_mask_i,

  // Signal To Mem_Data_Expansion 
  output [`MEM_DATA_BUS]  rmem_data_o
);

  import "DPI-C" function int data_npc_pmem_read( input int raddr );
  import "DPI-C" function void npc_pmem_write( input int waddr, input int wdata, input byte wmask );

  reg [`MEM_DATA_BUS] rmem_data; 

  always @( * ) begin
    if ( rst == `RST_ENABLE ) begin
      rmem_data = `ZERO_WORD;
    end if ( rmem_ena_i == `READ_ENABLE ) begin
      rmem_data = data_npc_pmem_read( rmem_addr_i );
    end else begin
      rmem_data = `ZERO_WORD;
    end
  end

  always @( posedge clk ) begin
    if ( rst == `RST_DISABLE ) begin
      if ( wmem_ena_i == `WRITE_ENABLE ) begin
        npc_pmem_write( wmem_addr_i, wmem_data_i, wmem_mask_i );
      end
    end
  end

  assign rmem_data_o = rmem_data;

endmodule
