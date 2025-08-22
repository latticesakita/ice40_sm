

module hard_ip #(
	//parameter CLK_DIVIDER	= "60", // 24MHz / 400kHz
	parameter I2C1_EN = 1,
	parameter I2C2_EN = 1,
	parameter SPI1_EN = 0,
	parameter SPI2_EN = 0
)
(
	input		rst_i		,
	input [7:0]	sb_adr_i	,
	input		sb_clk_i	,
	input [7:0]	sb_dat_i	,
	input 		sb_stb_i	,
	input		sb_wr_i		,
	inout		i2c1_scl_io	,
	inout		i2c1_sda_io	,
	inout		i2c2_scl_io	,
	inout		i2c2_sda_io	,
	input		ipload_i	,
	output [1:0]	i2c_pirq_o	,
	output [1:0]	i2c_pwkup_o	,
	output		sb_ack_o	,
	output		ipdone_o	,
	output [7:0]	sb_dat_o	
);

wire       i2c1_ack_o;
wire       i2c2_ack_o;
wire [7:0] i2c1_dat_o;
wire [7:0] i2c2_dat_o;

assign ipdone_o = 1'b1;
assign sb_ack_o = i2c1_ack_o | i2c2_ack_o;
assign sb_dat_o = (sb_adr_i[7:4]==4'b0001) ? i2c1_dat_o : i2c2_dat_o;

generate if( I2C1_EN == 1 ) begin
wire i2c1_scl_i;
wire i2c1_sda_i;
wire i2c1_scl_o;
wire i2c1_sda_o;
wire i2c1_scl_oe;
wire i2c1_sda_oe;
I2C_B #(
	.BUS_ADDR74		("0b0001"),
	.SDA_INPUT_DELAYED	("1")
) i2c_upper_left (
	.SBCLKI		(sb_clk_i),
	.SBRWI		(sb_wr_i),
	.SBSTBI		(sb_stb_i),
	.SBADRI7	(sb_adr_i[7]),
	.SBADRI6	(sb_adr_i[6]),
	.SBADRI5	(sb_adr_i[5]),
	.SBADRI4	(sb_adr_i[4]),
	.SBADRI3	(sb_adr_i[3]),
	.SBADRI2	(sb_adr_i[2]),
	.SBADRI1	(sb_adr_i[1]),
	.SBADRI0	(sb_adr_i[0]),
	.SBDATI7	(sb_dat_i[7]),
	.SBDATI6	(sb_dat_i[6]),
	.SBDATI5	(sb_dat_i[5]),
	.SBDATI4	(sb_dat_i[4]),
	.SBDATI3	(sb_dat_i[3]),
	.SBDATI2	(sb_dat_i[2]),
	.SBDATI1	(sb_dat_i[1]),
	.SBDATI0	(sb_dat_i[0]),
	.SCLI		(i2c1_scl_i),
	.SDAI		(i2c1_sda_i),
	.SBDATO7	(i2c1_dat_o[7]),
	.SBDATO6	(i2c1_dat_o[6]),
	.SBDATO5	(i2c1_dat_o[5]),
	.SBDATO4	(i2c1_dat_o[4]),
	.SBDATO3	(i2c1_dat_o[3]),
	.SBDATO2	(i2c1_dat_o[2]),
	.SBDATO1	(i2c1_dat_o[1]),
	.SBDATO0	(i2c1_dat_o[0]),
	.SBACKO		(i2c1_ack_o),
	.I2CIRQ		(i2c_pirq_o[0]),
	.I2CWKUP	(i2c_pwkup_o[0]),
	.SCLO		(i2c1_scl_o),
	.SCLOE		(i2c1_scl_oe),
	.SDAO		(i2c1_sda_o),
	.SDAOE		(i2c1_sda_oe)
);
BB_B i2c1_scl (
.T_N(i2c1_scl_oe),
.I  (i2c1_scl_o),
.O  (i2c1_scl_i),
.B  (i2c1_scl_io)
);
BB_B i2c1_sda (
.T_N(i2c1_sda_oe),
.I  (i2c1_sda_o),
.O  (i2c1_sda_i),
.B  (i2c1_sda_io)
);
end
else begin
assign i2c1_dat_o = 8'h00;
assign i2c1_ack_o = 1'b0;
assign i2c_pirq_o[0] = 1'b0;
assign i2c_pwkup_o[0] = 1'b0;
end
if( I2C2_EN == 1 ) begin
wire i2c2_scl_i;
wire i2c2_sda_i;
wire i2c2_scl_o;
wire i2c2_sda_o;
wire i2c2_scl_oe;
wire i2c2_sda_oe;
I2C_B #(
	.BUS_ADDR74		("0b0011"),
	.SDA_INPUT_DELAYED	("1")
) i2c_upper_right (
	.SBCLKI		(sb_clk_i),
	.SBRWI		(sb_wr_i),
	.SBSTBI		(sb_stb_i),
	.SBADRI7	(sb_adr_i[7]),
	.SBADRI6	(sb_adr_i[6]),
	.SBADRI5	(sb_adr_i[5]),
	.SBADRI4	(sb_adr_i[4]),
	.SBADRI3	(sb_adr_i[3]),
	.SBADRI2	(sb_adr_i[2]),
	.SBADRI1	(sb_adr_i[1]),
	.SBADRI0	(sb_adr_i[0]),
	.SBDATI7	(sb_dat_i[7]),
	.SBDATI6	(sb_dat_i[6]),
	.SBDATI5	(sb_dat_i[5]),
	.SBDATI4	(sb_dat_i[4]),
	.SBDATI3	(sb_dat_i[3]),
	.SBDATI2	(sb_dat_i[2]),
	.SBDATI1	(sb_dat_i[1]),
	.SBDATI0	(sb_dat_i[0]),
	.SCLI		(i2c2_scl_i),
	.SDAI		(i2c2_sda_i),
	.SBDATO7	(i2c2_dat_o[7]),
	.SBDATO6	(i2c2_dat_o[6]),
	.SBDATO5	(i2c2_dat_o[5]),
	.SBDATO4	(i2c2_dat_o[4]),
	.SBDATO3	(i2c2_dat_o[3]),
	.SBDATO2	(i2c2_dat_o[2]),
	.SBDATO1	(i2c2_dat_o[1]),
	.SBDATO0	(i2c2_dat_o[0]),
	.SBACKO		(i2c2_ack_o),
	.I2CIRQ		(i2c_pirq_o[1]),
	.I2CWKUP	(i2c_pwkup_o[1]),
	.SCLO		(i2c2_scl_o),
	.SCLOE		(i2c2_scl_oe),
	.SDAO		(i2c2_sda_o),
	.SDAOE		(i2c2_sda_oe)
);
BB_B i2c2_scl (
.T_N(i2c2_scl_oe),
.I  (i2c2_scl_o),
.O  (i2c2_scl_i),
.B  (i2c2_scl_io)
);
BB_B i2c2_sda (
.T_N(i2c2_sda_oe),
.I  (i2c2_sda_o),
.O  (i2c2_sda_i),
.B  (i2c2_sda_io)
);
end
else begin
assign i2c2_dat_o = 8'h00;
assign i2c2_ack_o = 1'b0;
assign i2c_pirq_o[1] = 1'b0;
assign i2c_pwkup_o[1] = 1'b0;
end
endgenerate

endmodule

