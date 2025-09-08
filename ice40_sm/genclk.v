module genclk (
	output oclk,
	output clk12
);

reg [1:0] r_div = 0;
assign clk12 = r_div[1];

// DIV:00 = 48MHz, DIV:01=24MHz, DIV:10=12MHz, DIV:11=6MHz
HSOSC #(.CLKHF_DIV ("0b00")) osc0(.CLKHFEN (1'b1), .CLKHFPU(1'b1), .CLKHF(oclk));

always @(posedge oclk) r_div <= r_div + 1;

endmodule

