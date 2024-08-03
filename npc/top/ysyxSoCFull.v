module ysyxSoCFull (
    input clock, 
    input reset
);

    reg         awready;
    reg         awvalid;
    reg [31:0]  awaddr;
    reg [3:0]   awid;
    reg [7:0]   awlen;
    reg [2:0]   awsize;
    reg [1:0]   awburst;

    reg         wready;
    reg         wvalid;
    reg [31:0]  wdata;
    reg [3:0]   wstrb;
    reg         wlast;

    reg         bready;
    reg         bvalid;
    reg  [1:0]  bresp;
    reg  [3:0]  bid;

    reg         arready;
    reg         arvalid;
    reg  [31:0] araddr;
    reg  [3:0]  arid;
    reg  [7:0]  arlen;
    reg  [2:0]  arsize;
    reg  [1:0]  arburst;

    reg         rready;
    reg         rvalid;
    reg  [1:0]  rresp;
    reg  [31:0] rdata;
    reg         rlast;
    reg  [3:0]  rid;

    cpu cpu0(
      .clock                      (clock),                               
      .reset                      (reset),                                
      .io_interrupt               (0),

      .io_master_awready          (awready),                                                      
      .io_master_awvalid          (awvalid),                                            
      .io_master_awaddr           (awaddr ),                                          
      .io_master_awid             (awid   ),                                        
      .io_master_awlen            (awlen  ),                                          
      .io_master_awsize           (awsize ),                                          
      .io_master_awburst          (awburst),                                            
                                  
      .io_master_wready           (wready ),                                          
      .io_master_wvalid           (wvalid ),                                          
      .io_master_wdata            (wdata  ),                                          
      .io_master_wstrb            (wstrb  ),                                          
      .io_master_wlast            (wlast  ),                                          
                                  
      .io_master_bready           (bready ),                                          
      .io_master_bvalid           (bvalid ),                                          
      .io_master_bresp            (bresp  ),                                          
      .io_master_bid              (bid    ),                                        
                                  
      .io_master_arready          (arready),                                            
      .io_master_arvalid          (arvalid),                                            
      .io_master_araddr           (araddr ),                                            
      .io_master_arid             (arid   ),                                        
      .io_master_arlen            (arlen  ),                                          
      .io_master_arsize           (arsize ),                                          
      .io_master_arburst          (arburst),                                            
                                  
      .io_master_rready           (rready ),                                          
      .io_master_rvalid           (rvalid ),                                          
      .io_master_rresp            (rresp  ),                                          
      .io_master_rdata            (rdata  ),                                          
      .io_master_rlast            (rlast  ),                                          
      .io_master_rid              (rid    ),

      .io_slave_awready           (/* unused */),                                                      
      .io_slave_awvalid           (0),                                                
      .io_slave_awaddr            (0),                                                
      .io_slave_awid              (0),                                              
      .io_slave_awlen             (0),                                              
      .io_slave_awsize            (0),                                                
      .io_slave_awburst           (0),                                                

      .io_slave_wready            (/* unused */),                                                
      .io_slave_wvalid            (0),                                                
      .io_slave_wdata             (0),                                              
      .io_slave_wstrb             (0),                                              
      .io_slave_wlast             (0),                                              

      .io_slave_bready            (0),
      .io_slave_bvalid            (/* unused */),                                                
      .io_slave_bresp             (/* unused */),                                              
      .io_slave_bid               (/* unused */),                                            

      .io_slave_arready           (/* unused */),                                                
      .io_slave_arvalid           (0),                                                
      .io_slave_araddr            (0),                                                
      .io_slave_arid              (0),                                              
      .io_slave_arlen             (0),                                              
      .io_slave_arsize            (0),                                                
      .io_slave_arburst           (0),                                                

      .io_slave_rready            (0),                                                
      .io_slave_rvalid            (/* unused */),                                                
      .io_slave_rresp             (/* unused */),                                              
      .io_slave_rdata             (/* unused */),                                              
      .io_slave_rlast             (/* unused */),                                              
      .io_slave_rid               (/* unused */)                                  
    );

    pmem pmem0 (
      .clock         (clock),
      .reset         (reset),

      .awready_o     (awready),
      .awvalid_i     (awvalid),
      .awaddr_i      (awaddr ),
      .awid_i        (awid   ),
      .awlen_i       (awlen  ),
      .awsize_i      (awsize ),
      .awburst_i     (awburst),
                    
      .wready_o      (wready ),
      .wvalid_i      (wvalid ),
      .wdata_i       (wdata  ),
      .wstrb_i       (wstrb  ),
      .wlast_i       (wlast  ),
                    
      .bready_i      (bready ),
      .bvalid_o      (bvalid ),
      .bresp_o       (bresp  ),
      .bid_o         (bid    ),
                    
      .arready_o     (arready),
      .arvalid_i     (arvalid),
      .araddr_i      (araddr ),
      .arid_i        (arid   ),
      .arlen_i       (arlen  ),
      .arsize_i      (arsize ),
      .arburst_i     (arburst),
                    
      .rready_i      (rready ),
      .rvalid_o      (rvalid ),
      .rresp_o       (rresp  ),
      .rdata_o       (rdata  ),
      .rlast_o       (rlast  ),
      .rid_o         (rid    )
    );

endmodule
