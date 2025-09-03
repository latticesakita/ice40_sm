module genclk (
	output clk24,
	output clk12
);

reg [1:0] r_div = 0;
assign clk12 = r_div[0];

// DIV:00 = 48MHz, DIV:01=24MHz, DIV:10=12MHz, DIV:11=6MHz
HSOSC #(.CLKHF_DIV ("0b01")) osc0(.CLKHFEN (1'b1), .CLKHFPU(1'b1), .CLKHF(clk24));

always @(posedge clk24) r_div <= r_div + 1;

endmodule

