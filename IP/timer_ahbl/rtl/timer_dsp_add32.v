//32 bit ADDSUB: 32 bit input, 32 bit output ADDSUB
module timer_dsp_add32 (
	input	clk,
	input	resetn,
	input [31:0] A,
	input [31:0] B,
	output [31:0] O
);
MAC16 #(
.B_SIGNED			("0b0"),	// C24
.A_SIGNED			("0b0"),	// C23
.MODE_8x8			("0b1"),	// C22
.BOTADDSUB_CARRYSELECT		("0b00"),	// C20,C21
.BOTADDSUB_UPPERINPUT		("0b1"),	// C19
.BOTADDSUB_LOWERINPUT		("0b00"),	// C17,C18
.BOTOUTPUT_SELECT		("0b00"),	// C15,C16
.TOPADDSUB_CARRYSELECT		("0b10"),	// C13,C14
.TOPADDSUB_UPPERINPUT		("0b1"),	// C12
.TOPADDSUB_LOWERINPUT		("0b00"),	// C10,C11
.TOPOUTPUT_SELECT		("0b00"),	// C8,C9
.PIPELINE_16x16_MULT_REG2	("0b0"),	// C7
.PIPELINE_16x16_MULT_REG1	("0b0"),	// C6
.BOT_8x8_MULT_REG		("0b0"),	// C5
.TOP_8x8_MULT_REG		("0b0"),	// C4
.D_REG				("0b0"),	// C3
.B_REG				("0b0"),	// C2
.A_REG				("0b0"),	// C1
.C_REG				("0b0")	// C0
)
mac16_add_sub_32_bypassed_unsigned_reg_i (
.A0	(A[16]),
.A1	(A[17]),
.A2	(A[18]),
.A3	(A[19]),
.A4	(A[20]),
.A5	(A[21]),
.A6	(A[22]),
.A7	(A[23]),
.A8	(A[24]),
.A9	(A[25]),
.A10	(A[26]),
.A11	(A[27]),
.A12	(A[28]),
.A13	(A[29]),
.A14	(A[30]),
.A15	(A[31]),
.B0	(A[0]),
.B1	(A[1]),
.B2	(A[2]),
.B3	(A[3]),
.B4	(A[4]),
.B5	(A[5]),
.B6	(A[6]),
.B7	(A[7]),
.B8	(A[8]),
.B9	(A[9]),
.B10	(A[10]),
.B11	(A[11]),
.B12	(A[12]),
.B13	(A[13]),
.B14	(A[14]),
.B15	(A[15]),
.C0	(B[16]),
.C1	(B[17]),
.C2	(B[18]),
.C3	(B[19]),
.C4	(B[20]),
.C5	(B[21]),
.C6	(B[22]),
.C7	(B[23]),
.C8	(B[24]),
.C9	(B[25]),
.C10	(B[26]),
.C11	(B[27]),
.C12	(B[28]),
.C13	(B[29]),
.C14	(B[30]),
.C15	(B[31]),
.D0	(B[0]),
.D1	(B[1]),
.D2	(B[2]),
.D3	(B[3]),
.D4	(B[4]),
.D5	(B[5]),
.D6	(B[6]),
.D7	(B[7]),
.D8	(B[8]),
.D9	(B[9]),
.D10	(B[10]),
.D11	(B[11]),
.D12	(B[12]),
.D13	(B[13]),
.D14	(B[14]),
.D15	(B[15]),
.O0	(O[0]),
.O1	(O[1]),
.O2	(O[2]),
.O3	(O[3]),
.O4	(O[4]),
.O5	(O[5]),
.O6	(O[6]),
.O7	(O[7]),
.O8	(O[8]),
.O9	(O[9]),
.O10	(O[10]),
.O11	(O[11]),
.O12	(O[12]),
.O13	(O[13]),
.O14	(O[14]),
.O15	(O[15]),
.O16	(O[16]),
.O17	(O[17]),
.O18	(O[18]),
.O19	(O[19]),
.O20	(O[20]),
.O21	(O[21]),
.O22	(O[22]),
.O23	(O[23]),
.O24	(O[24]),
.O25	(O[25]),
.O26	(O[26]),
.O27	(O[27]),
.O28	(O[28]),
.O29	(O[29]),
.O30	(O[30]),
.O31	(O[31]),

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
.OLOADTOP(1'b0),
.OLOADBOT(1'b0),
.OHOLDTOP(1'b0),
.OHOLDBOT(1'b0),
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
