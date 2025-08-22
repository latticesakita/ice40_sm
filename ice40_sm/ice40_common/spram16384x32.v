// instatiate SP256K

module spram16384x32 (
	input clk_i,
	input [13:0] addr_i  ,
	input wr_en_i    ,
	input [3:0] mask_we,
	input [31:0] wr_data_i  ,
	output [31:0] rd_data_o  
);

wire [3:0] maskwe0;
wire [3:0] maskwe1;
assign maskwe0 = {mask_we[1],mask_we[1],mask_we[0],mask_we[0]};
assign maskwe1 = {mask_we[3],mask_we[3],mask_we[2],mask_we[2]};

SP256K u_spram16k_16_0 (
  .AD       (addr_i		),  // I
  .DI       (wr_data_i[15:0]	),  // I
  .MASKWE   (maskwe0		),  // I
  .WE       (wr_en_i		),  // I
  .CS       (1'b1		),  // I
  .CK       (clk_i		),  // I
  .STDBY    (1'b0		),  // I
  .SLEEP    (1'b0		),  // I
  .PWROFF_N (1'b1		),  // I
  .DO       (rd_data_o[15:0]	)   // O
);
SP256K u_spram16k_16_1 (
  .AD       (addr_i		),  // I
  .DI       (wr_data_i[31:16]	),  // I
  .MASKWE   (maskwe1		),  // I
  .WE       (wr_en_i		),  // I
  .CS       (1'b1		),  // I
  .CK       (clk_i		),  // I
  .STDBY    (1'b0		),  // I
  .SLEEP    (1'b0		),  // I
  .PWROFF_N (1'b1		),  // I
  .DO       (rd_data_o[31:16]	)   // O
);

endmodule
// vim:foldmethod=marker: 
