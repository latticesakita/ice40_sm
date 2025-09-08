
// 8'b0000_0000: inta       :Alarm all (readonly)
// 8'b0000_0100: clocks     : Clocks if CLOCKS_EN is set
// 8'b0000_1000: ticks      : Ticks
// 8'b0000_1100: prescale   : Prescale
// 8'b0001_0000: int0       :Alarm0 / interrupts
// 8'b0001_0100: int1       :Alarm1 / interrupts
// 8'b0001_1000: int2       :Alarm2 / interrupts
// 8'b0001_1100: int3       :Alarm3 / interrupts
// 8'b0010_0000: repeat0_en : Alarm0 repeat enable
// 8'b0010_0100: repeat1_en : Alarm1 repeat enable
// 8'b0010_1000: repeat2_en : Alarm2 repeat enable
// 8'b0010_1100: repeat3_en : Alarm3 repeat enable
// 8'b0011_0000: set0       :Alarm0 set & enable
// 8'b0011_0100: set1       :Alarm1 set & enable
// 8'b0011_1000: set2       :Alarm2 set & enable
// 8'b0011_1100: set3       :Alarm3 set & enable
// 8'b0100_0000: end0       :Alarm0 end time
// 8'b0100_0100: end1       :Alarm1 end time
// 8'b0100_1000: end2       :Alarm2 end time
// 8'b0100_1100: end3       :Alarm3 end time
// 8'b0101_0000: en0        :Alarm0 enable/disable
// 8'b0101_0100: en1        :Alarm1 enable/disable
// 8'b0101_1000: en2        :Alarm2 enable/disable
// 8'b0101_1100: en3        :Alarm3 enable/disable
// 8'b0110_0000: int0_en    :Alarm0 interrupt enable/disable
// 8'b0110_0100: int1_en    :Alarm1 interrupt enable/disable
// 8'b0110_1000: int2_en    :Alarm2 interrupt enable/disable
// 8'b0110_1100: int3_en    :Alarm3 interrupt enable/disable

`define AHBL_IF
//`define CLOCKS_EN
`define PRESCALE_8BITS

module timer_ahbl
#(
	parameter PRESCALE = 24-1,
	parameter USE_DSP  = 1
)
(
	output		int_o,
`ifdef AHBL_IF
        input	[31:0]	ahbl_haddr_i, 
	input	[2:0]	ahbl_hburst_i,
        output	[31:0]	ahbl_hrdata_o, 
	input   [2:0]	ahbl_hsize_i,
        input	[1:0]	ahbl_htrans_i, 
        input	[31:0]	ahbl_hwdata_i, 
	input		ahbl_hready_i,
        output		ahbl_hreadyout_o,
        output		ahbl_hresp_o, 
        input		ahbl_hsel_i, 
        input		ahbl_hwrite_i, 
`else
        input		apb_penable_i, 
        input		apb_psel_i, 
        input		apb_pwrite_i, 
        input	[31:0]	apb_paddr_i, 
        input	[31:0]	apb_pwdata_i, 
        output	[31:0]	apb_prdata_o, 
        output		apb_pslverr_o, 
        output		apb_pready_o,
`endif
	output  [31:0]  systime_o,
	input		clk_i,
	input		resetn_i
);
localparam NUM_OF_TIMERS = 2;


// I/F independent signals
reg [31:0]	r_rdata_o;
wire [31:0]     w_wdata_i;
wire [31:0] w_addr;
wire w_re;
wire w_we;
wire access_en;
wire clk;
wire resetn;
assign clk = clk_i;
assign resetn = resetn_i;

`ifdef AHBL_IF
// AHBL I/F {{{
// AHBL
reg r_we;
reg r_re;
reg [7:0] r_addr;
assign ahbl_hresp_o = 1'b0;
assign w_addr = {24'b0, r_addr}; // ahbl_haddr_i;
assign access_en = ahbl_hsel_i && ahbl_htrans_i[1];
assign w_re = (ahbl_hsel_i && ahbl_htrans_i[1] && (!ahbl_hwrite_i));
assign w_we = r_we;
assign ahbl_hreadyout_o = ~(r_we|r_re);
assign ahbl_hrdata_o = r_rdata_o;
assign w_wdata_i     = ahbl_hwdata_i;

always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_we <= 0;
		r_re <= 0;
		r_addr <= 0;
	end
	else begin
		r_we <= (ahbl_hsel_i && ahbl_htrans_i[1] &&   ahbl_hwrite_i);
		r_re <= (ahbl_hsel_i && ahbl_htrans_i[1] && (~ahbl_hwrite_i));
		r_addr <= ahbl_haddr_i[7:0];
	end
end

// AHBL I/F }}}
`else
// APB I/F {{{
assign w_addr = apb_paddr_i;
assign access_en = apb_psel_i && apb_penable_i;
assign w_re = (apb_psel_i && apb_penable_i && (!apb_pwrite_i));
assign w_we = (apb_psel_i && apb_penable_i && ( apb_pwrite_i));
assign apb_pready_o = 1'b1;
assign apb_prdata_o = r_rdata_o;
assign w_wdata_i = apb_pwdata_i;
// APB I/F }}}
`endif


reg [2:0] r_rst = 3'b000;
reg [1:0]	r_alarm_enable;
reg [1:0]	r_alarm_repeat;
reg [1:0]	r_alarm_int;
reg [1:0]	r_alarm_int_en;
//reg [31:0]	r_alarm0_set;
reg [31:0]	r_alarm0_end;
reg [31:0]	r_alarm1_set;
reg [31:0]	r_alarm1_end;
wire w_enable;
`ifdef CLOCKS_EN
wire [31:0] w_clocks; // clock from power up
`endif
wire [31:0] w_ticks; // ticks at every PRESCALE, if clock is 24MHz and PRESCALE=24000-1, this will be milli sec.
wire [31:0] w_alarm_end;
wire [31:0] w_alarm_set;
`ifdef PRESCALE_8BITS
reg [7:0] r_prescale;
wire [7:0] w_tick_cnt;
`else
reg [31:0] r_prescale;
wire [31:0] w_tick_cnt;
`endif
wire w_tick_reload;
wire  w_alarm0_fire;
wire  w_alarm1_fire;
assign w_tick_reload = (w_tick_cnt == r_prescale) ? 1'b1 : 1'b0;
assign int_o = |(r_alarm_int & r_alarm_int_en);
assign systime_o = w_ticks;

assign w_alarm0_fire = (w_ticks == r_alarm0_end) ;
assign w_alarm1_fire = (w_ticks == r_alarm1_end) ;


assign w_enable = r_rst[2];
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_rst <= 0;
	end
	else begin
		r_rst <= {r_rst[1:0], 1'b1};
	end
end

reg [31:0] r_alarm_set;
reg [3:0] r_alarm_end_valid;
// reg [3:0] r_alarm_end_valid_m;
// always @(posedge clk or negedge resetn) begin
// 	if(!resetn) begin
// 		r_alarm_end_valid <= 0;
// 	end
// 	else begin
// 		r_alarm_end_valid <= r_alarm_end_valid_m;
// 	end
// end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_alarm_set <= 32'b1;
		r_alarm_end_valid <= 4'b0;
	end
	//else if(w_alarm0_fire && r_alarm_repeat[0]) begin
	//	r_alarm_set       <= r_alarm0_set;
	//	r_alarm_end_valid <= 4'b0001;
	//end
	else if(w_alarm1_fire && r_alarm_repeat[1]) begin
		r_alarm_set       <= r_alarm1_set;
		r_alarm_end_valid <= 4'b0010;
	end
	else if(w_we && (w_addr[7:4]==4'b0011)) begin
		r_alarm_set       <= w_wdata_i;
		r_alarm_end_valid[0] <= (w_addr[3:2] == 2'b00);
		r_alarm_end_valid[1] <= (w_addr[3:2] == 2'b01);
	end
	else if(w_we && (w_addr[7:4]==4'b0101)) begin
		r_alarm_set       <= w_wdata_i;
		r_alarm_end_valid[0] <= (w_addr[3:2] == 2'b00);
		r_alarm_end_valid[1] <= (w_addr[3:2] == 2'b01);
	end
	else begin
		r_alarm_end_valid <= 4'b0;
	end
end

assign w_alarm_set = r_alarm_set;
//assign w_alarm_set = 
//	(w_alarm1_fire && r_alarm_repeat[1]) ? r_alarm1_set :
//	(w_we && (w_addr[7:4]==4'b0011))     ? w_wdata_i :
//	(w_we && (w_addr[7:4]==4'b0101))     ? w_wdata_i : 32'd1;


generate if (USE_DSP == 1) begin
`ifdef CLOCKS_EN
	timer_dsp_acc32 clocks_i (
		.clk(clk), .resetn(resetn), .enable(w_enable), .load(~w_enable), .load_val(32'd0), .d(32'd1), .acc(w_clocks) );
`endif

`ifdef PRESCALE_8BITS
	reg [7:0] r_tick_cnt;
	assign w_tick_cnt = r_tick_cnt;
	always @(posedge clk or negedge resetn) begin
		if(!resetn) begin
			r_tick_cnt <= 0;
		end
		else if(w_tick_reload) begin
			r_tick_cnt <= 0;
		end
		else begin
			r_tick_cnt <= r_tick_cnt + 1;
		end
	end
`else
	timer_dsp_acc32 ticks_cnt_i (
		.clk(clk), .resetn(resetn), .enable(w_enable), .load(w_tick_reload), .load_val(32'd0), .d(32'd1), .acc(w_tick_cnt) );
`endif
	timer_dsp_acc32 ticks_i (
		.clk(clk), .resetn(resetn), .enable(w_tick_reload), .load(~w_enable), .load_val(32'd0), .d(32'd1), .acc(w_ticks) );
	timer_dsp_add32 alarm_end_i (
		.clk(clk), .resetn(resetn), .A(w_ticks), .B(w_alarm_set), .O(w_alarm_end) );
end
else
begin
	reg [31:0] r_ticks;

`ifdef PRESCALE_8BITS
	reg [7:0] r_tick_cnt;
`else
	reg [31:0] r_tick_cnt;
`endif
	assign w_ticks  = r_ticks;
	assign w_tick_cnt = r_tick_cnt;
`ifdef CLOCKS_EN
	reg [31:0] r_clks;
	assign w_clocks = r_clks;
	always @(posedge clk or negedge resetn) begin
		if(!resetn) begin
			r_clks <= 0;
		end
		else begin
			r_clks <= r_clks + 1;
		end
	end
`endif
	always @(posedge clk or negedge resetn) begin
		if(!resetn) begin
			r_tick_cnt <= 0;
		end
		else if(w_tick_reload) begin
			r_tick_cnt <= 0;
		end
		else begin
			r_tick_cnt <= r_tick_cnt + 1;
		end
	end
	always @(posedge clk or negedge resetn) begin
		if(!resetn) begin
			r_ticks <= 0;
		end
		else if(w_tick_reload) begin
			r_ticks <= r_ticks + 1;
		end
	end
	assign w_alarm_end = w_ticks + w_alarm_set;
end
endgenerate


// TIMER
// **** READ ACCESS ****
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_rdata_o <= 32'h00;
	end
	else if(w_re) begin
		case(w_addr[7:2])
		6'b0000_00: r_rdata_o <= {24'b0,r_alarm_int};
`ifdef CLOCKS_EN
		6'b0000_01: r_rdata_o <= w_clocks  ;
`endif
		6'b0000_10: r_rdata_o <= w_ticks   ;
`ifdef PRESCALE_8BITS
		6'b0000_11: r_rdata_o <= {24'b0,r_prescale};
`else
		6'b0000_11: r_rdata_o <= r_prescale;
`endif
		6'b0001_00: r_rdata_o <= {31'b0,r_alarm_int[0]};
		6'b0001_01: r_rdata_o <= {31'b0,r_alarm_int[1]};
		6'b0010_00: r_rdata_o <= {31'b0,r_alarm_repeat[0]};
		6'b0010_01: r_rdata_o <= {31'b0,r_alarm_repeat[1]};
		//6'b0011_00: r_rdata_o <= r_alarm0_set;
		6'b0011_01: r_rdata_o <= r_alarm1_set;
		6'b0100_00: r_rdata_o <= r_alarm0_end;
		6'b0100_01: r_rdata_o <= r_alarm1_end;
		6'b0101_00: r_rdata_o <= {31'b0,r_alarm_enable[0]};
		6'b0101_01: r_rdata_o <= {31'b0,r_alarm_enable[1]};
		6'b0110_00: r_rdata_o <= {31'b0,r_alarm_int_en[0]};
		6'b0110_01: r_rdata_o <= {31'b0,r_alarm_int_en[1]};
		default: r_rdata_o <= 0;
		endcase
	end
end

always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_alarm_int_en[0] <= 0;
	end
	else if(w_we && (w_addr[7:2] == 6'b0110_00)) begin
		r_alarm_int_en[0] <= w_wdata_i[0];
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_alarm_int_en[1] <= 0;
	end
	else if(w_we && (w_addr[7:2] == 6'b0110_01)) begin
		r_alarm_int_en[1] <= w_wdata_i[0];
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_alarm_int[0] <= 0;
	end
	else if(access_en && (w_addr[7:2] == 6'b0001_00)) begin
		r_alarm_int[0] <= 0;
	end
	else if(w_alarm0_fire) begin
		r_alarm_int[0] <=  r_alarm_enable[0] | r_alarm_int[0];
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_alarm_int[1] <= 0;
	end
	else if(access_en && (w_addr[7:2] == 6'b0001_01)) begin
		r_alarm_int[1] <= 0;
	end
	else if(w_alarm1_fire) begin
		r_alarm_int[1] <= r_alarm_enable[1] | r_alarm_int[1];
	end
end


`ifdef PRESCALE_8BITS
	always @(posedge clk or negedge resetn) begin
		if(!resetn) begin
			r_prescale <= PRESCALE;
		end
		else if(w_we ) begin
			if(w_addr[7:2] == 6'b0000_11) begin
				r_prescale <= w_wdata_i[7:0];
			end
		end
	end
`else
	always @(posedge clk or negedge resetn) begin
		if(!resetn) begin
			r_prescale <= PRESCALE;
		end
		else if(w_we ) begin
			if(w_addr[7:2] == 6'b0000_11) begin
				r_prescale <= w_wdata_i;
			end
		end
	end
`endif

always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_alarm_enable[0] <= 0;
		r_alarm_repeat[0] <= 0;
	end
	else if(w_alarm0_fire) begin
			r_alarm_enable[0] <= r_alarm_repeat[0];
	end
	else if(w_we) begin
		if(w_addr[7:2] == 6'b0011_00) begin
			r_alarm_enable[0] <= 1'b1;
		end
		else if(w_addr[7:2] == 6'b0101_00) begin
			r_alarm_enable[0] <= w_wdata_i[0];
		end
		else if(w_addr[7:2] == 6'b0010_00) begin
			r_alarm_repeat[0] <= w_wdata_i[0];
		end
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_alarm_enable[1] <= 0;
		r_alarm_repeat[1] <= 0;
	end
	else if(w_alarm1_fire) begin
			r_alarm_enable[1] <= r_alarm_repeat[1];
	end
	else if(w_we) begin
		if(w_addr[7:2] == 6'b0011_01) begin
			r_alarm_enable[1] <= 1'b1;
		end
		else if(w_addr[7:2] == 6'b0101_01) begin
			r_alarm_enable[1] <= w_wdata_i[0];
		end
		else if(w_addr[7:2] == 6'b0010_01) begin
			r_alarm_repeat[1] <= w_wdata_i[0];
		end
	end
end
//always @(posedge clk or negedge resetn) begin
//	if(!resetn) begin
//		r_alarm0_set <= 0;
//	end
//	else if(w_we) begin
//		if(w_addr[7:2] == 6'b0011_00) begin
//			r_alarm0_set <= w_wdata_i;
//		end
//	end
//end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_alarm1_set <= 0;
	end
	else if(w_we) begin
		if(w_addr[7:2] == 6'b0011_01) begin
			r_alarm1_set <= w_wdata_i;
		end
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_alarm0_end <= 0;
	end
	else if(r_alarm_end_valid[0]) begin
		r_alarm0_end <= w_alarm_end;
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_alarm1_end <= 0;
	end
	else if(r_alarm_end_valid[1]) begin
		r_alarm1_end <= w_alarm_end;
	end
end
endmodule

// vim:foldmethod=marker:
//
