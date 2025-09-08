//32 bit ACCUMULATOR: 32 bit input, 32 bit output Accumulator
module timer_dsp_acc32 (
	input	clk,
	input	resetn,
	input	enable,
	input	load,
	input [31:0] load_val,
	input [31:0] d,
	output [31:0] acc
);

MAC16 #(
.B_SIGNED			("0b0"),	// C24
.A_SIGNED			("0b0"),	// C23
.MODE_8x8			("0b1"),	// C22
.BOTADDSUB_CARRYSELECT		("0b00"),	// C20,C21
.BOTADDSUB_UPPERINPUT		("0b0"),	// C19
.BOTADDSUB_LOWERINPUT		("0b00"),	// C17,C18
.BOTOUTPUT_SELECT		("0b01"),	// C15,C16
.TOPADDSUB_CARRYSELECT		("0b10"),	// C13,C14
.TOPADDSUB_UPPERINPUT		("0b0"),	// C12
.TOPADDSUB_LOWERINPUT		("0b00"),	// C10,C11
.TOPOUTPUT_SELECT		("0b01"),	// C8,C9
.PIPELINE_16x16_MULT_REG2	("0b0"),	// C7
.PIPELINE_16x16_MULT_REG1	("0b0"),	// C6
.BOT_8x8_MULT_REG		("0b0"),	// C5
.TOP_8x8_MULT_REG		("0b0"),	// C4
.D_REG				("0b0"),	// C3
.B_REG				("0b0"),	// C2
.A_REG				("0b0"),	// C1
.C_REG				("0b0")	// C0
)
mac16_acc_32_bypassed_unsigned_i (
.A0	(d[16]),
.A1	(d[17]),
.A2	(d[18]),
.A3	(d[19]),
.A4	(d[20]),
.A5	(d[21]),
.A6	(d[22]),
.A7	(d[23]),
.A8	(d[24]),
.A9	(d[25]),
.A10	(d[26]),
.A11	(d[27]),
.A12	(d[28]),
.A13	(d[29]),
.A14	(d[30]),
.A15	(d[31]),
.B0	(d[0]),
.B1	(d[1]),
.B2	(d[2]),
.B3	(d[3]),
.B4	(d[4]),
.B5	(d[5]),
.B6	(d[6]),
.B7	(d[7]),
.B8	(d[8]),
.B9	(d[9]),
.B10	(d[10]),
.B11	(d[11]),
.B12	(d[12]),
.B13	(d[13]),
.B14	(d[14]),
.B15	(d[15]),
.C0	(load_val[16]),
.C1	(load_val[17]),
.C2	(load_val[18]),
.C3	(load_val[19]),
.C4	(load_val[20]),
.C5	(load_val[21]),
.C6	(load_val[22]),
.C7	(load_val[23]),
.C8	(load_val[24]),
.C9	(load_val[25]),
.C10	(load_val[26]),
.C11	(load_val[27]),
.C12	(load_val[28]),
.C13	(load_val[29]),
.C14	(load_val[30]),
.C15	(load_val[31]),
.D0	(load_val[0]),
.D1	(load_val[1]),
.D2	(load_val[2]),
.D3	(load_val[3]),
.D4	(load_val[4]),
.D5	(load_val[5]),
.D6	(load_val[6]),
.D7	(load_val[7]),
.D8	(load_val[8]),
.D9	(load_val[9]),
.D10	(load_val[10]),
.D11	(load_val[11]),
.D12	(load_val[12]),
.D13	(load_val[13]),
.D14	(load_val[14]),
.D15	(load_val[15]),
.O0	(acc[0]),
.O1	(acc[1]),
.O2	(acc[2]),
.O3	(acc[3]),
.O4	(acc[4]),
.O5	(acc[5]),
.O6	(acc[6]),
.O7	(acc[7]),
.O8	(acc[8]),
.O9	(acc[9]),
.O10	(acc[10]),
.O11	(acc[11]),
.O12	(acc[12]),
.O13	(acc[13]),
.O14	(acc[14]),
.O15	(acc[15]),
.O16	(acc[16]),
.O17	(acc[17]),
.O18	(acc[18]),
.O19	(acc[19]),
.O20	(acc[20]),
.O21	(acc[21]),
.O22	(acc[22]),
.O23	(acc[23]),
.O24	(acc[24]),
.O25	(acc[25]),
.O26	(acc[26]),
.O27	(acc[27]),
.O28	(acc[28]),
.O29	(acc[29]),
.O30	(acc[30]),
.O31	(acc[31]),

.CLK	(clk),
.CE	(resetn),
.IRSTTOP(~resetn),
.IRSTBOT(~resetn),
.ORSTTOP(~resetn),
.ORSTBOT(~resetn),
.AHOLD	(1'b0),
.BHOLD	(1'b0),
.CHOLD	(1'b0),
.DHOLD	(1'b0),
.OLOADTOP(load),
.OLOADBOT(load),
.OHOLDTOP(~enable),
.OHOLDBOT(~enable),
.ADDSUBTOP(1'b0),
.ADDSUBBOT(1'b0),
.CO(),
.CI(1'b0),
//MAC cascading ports.
.ACCUMCI(1'b0),
.ACCUMCO(),
.SIGNEXTIN(1'b0),
.SIGNEXTOUT()
);

endmodule
// vim:foldmethod=marker:
//
