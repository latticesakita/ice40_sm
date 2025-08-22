// instatiate SP256K

module spram32768x32 (
	input clk_i,
	input [14:0] addr_i  ,
	input wr_en_i    ,
	input [3:0] mask_we,
	input [31:0] wr_data_i  ,
	output [31:0] rd_data_o  
);

reg r_addr14 = 0;
wire       we0;
wire       we1;
wire [3:0] maskwe0;
wire [3:0] maskwe1;
wire [31:0] rd_data_o0;
wire [31:0] rd_data_o1;
assign maskwe0 = {mask_we[1],mask_we[1],mask_we[0],mask_we[0]};
assign maskwe1 = {mask_we[3],mask_we[3],mask_we[2],mask_we[2]};
assign we0 = wr_en_i & (~addr_i[14]);
assign we1 = wr_en_i & ( addr_i[14]);
assign rd_data_o = (r_addr14 == 0) ? rd_data_o0 : rd_data_o1;

always @(posedge clk_i) begin
	r_addr14 <= addr_i[14];
end


SP256K u_spram16k_16_0 (
  .AD       (addr_i		),  // I
  .DI       (wr_data_i[15:0]	),  // I
  .MASKWE   (maskwe0		),  // I
  .WE       (we0		),  // I
  .CS       (1'b1		),  // I
  .CK       (clk_i		),  // I
  .STDBY    (1'b0		),  // I
  .SLEEP    (1'b0		),  // I
  .PWROFF_N (1'b1		),  // I
  .DO       (rd_data_o0[15:0]	)   // O
);
SP256K u_spram16k_16_1 (
  .AD       (addr_i		),  // I
  .DI       (wr_data_i[31:16]	),  // I
  .MASKWE   (maskwe1		),  // I
  .WE       (we0		),  // I
  .CS       (1'b1		),  // I
  .CK       (clk_i		),  // I
  .STDBY    (1'b0		),  // I
  .SLEEP    (1'b0		),  // I
  .PWROFF_N (1'b1		),  // I
  .DO       (rd_data_o0[31:16]	)   // O
);
SP256K u_spram16k_16_2 (
  .AD       (addr_i		),  // I
  .DI       (wr_data_i[15:0]	),  // I
  .MASKWE   (maskwe0		),  // I
  .WE       (we1		),  // I
  .CS       (1'b1		),  // I
  .CK       (clk_i		),  // I
  .STDBY    (1'b0		),  // I
  .SLEEP    (1'b0		),  // I
  .PWROFF_N (1'b1		),  // I
  .DO       (rd_data_o1[15:0]	)   // O
);
SP256K u_spram16k_16_3 (
  .AD       (addr_i		),  // I
  .DI       (wr_data_i[31:16]	),  // I
  .MASKWE   (maskwe1		),  // I
  .WE       (we1		),  // I
  .CS       (1'b1		),  // I
  .CK       (clk_i		),  // I
  .STDBY    (1'b0		),  // I
  .SLEEP    (1'b0		),  // I
  .PWROFF_N (1'b1		),  // I
  .DO       (rd_data_o1[31:16]	)   // O
);

endmodule
// vim:foldmethod=marker: 
