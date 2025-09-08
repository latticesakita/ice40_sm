
// address map
// 6'h00: RD_DATA_REG
// 6'h04: WR_DATA_REG
// 6'h08: SET_DATA_REG // upper 16bits for mask
// 6'h0c: CLEAR_DATA_REG // upper 16bits for mask
// 6'h10: DIRECTION_REG // upper 16bits for mask
// 6'h14: INT_TYPE_REG
// 6'h18: INT_METHOD_REG
// 6'h1c: INT_STATUS_REG
// 6'h20: INT_ENABLE_REG
// 6'h24: INT_SET_REG

// `define SPEED_OPTIMIZE
//`define REMOVE_TRI_STATE_BUFFER
`define AHBL_IF
`define DISABLE_INTERRUPT

`ifdef AHBL_IF
module gpio_ahbl #(
`else
module gpio_apb #(
`endif
	parameter BUS_WIDTH = 8,
	parameter DIRECTION = 'hFF, // 1 for output, 0 for input
	parameter INIT_OUTVAL = 'h00,
	parameter DEVICE = "CPNX" // ICE40UP or CPNX
) (
`ifdef REMOVE_TRI_STATE_BUFFER
	input	[BUS_WIDTH-1:0]	gpio_i,
	output	[BUS_WIDTH-1:0]	gpio_o,
	output	[BUS_WIDTH-1:0]	gpio_en_o,
`else
	inout	[BUS_WIDTH-1:0]	gpio_io,
	output	[BUS_WIDTH-1:0]	gpo_o, // debug purpose, IO output value
	output	[BUS_WIDTH-1:0]	gpi_o, // debug purpose, IO input value
`endif
`ifdef DISABLE_INTERRUPT
	output			int_o,
`else
	output	reg		int_o,
`endif

`ifdef AHBL_IF
	input [31:0]	ahbl_haddr_i,	// AHB address
	input [ 2:0]	ahbl_hburst_i,	// unused
	output [31:0]	ahbl_hrdata_o,	// AHB read data
	input [ 2:0]	ahbl_hsize_i,	// unused
	input [ 1:0]	ahbl_htrans_i,	// AHB transfer type
	input [31:0]	ahbl_hwdata_i,	// AHB write data
	input		ahbl_hready_i,	// unused
	output		ahbl_hreadyout_o,	// AHB ready signal
	output		ahbl_hresp_o, // Always 1 for this module
	input		ahbl_hsel_i,		// AHB select
	input		ahbl_hwrite_i,	// AHB write enable
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
	input		clk_i,
	input		resetn_i
);


reg [BUS_WIDTH-1:0] r_gpio_o;
reg [BUS_WIDTH-1:0] r_rval;
reg [BUS_WIDTH-1:0] r_dir;
wire [BUS_WIDTH-1:0] w_ioval;

// I/F independent signals
//reg [31:0]	r_rdata_o;
wire [31:0]     w_wdata_i;
wire [15:0]     w_wdata;
wire [15:0]     w_wdata_en;
wire [3:0] w_addr;
wire w_re;
wire w_we;
wire clk = clk_i;
wire resetn = resetn_i;

`ifdef AHBL_IF
// AHBL I/F {{{
// AHBL
reg r_we;
reg r_re;
reg [3:0] r_addr;
assign ahbl_hresp_o = 1'b0;
assign w_addr = r_addr;
assign w_re = r_re;
assign w_we = r_we;
assign ahbl_hreadyout_o = ~(r_we|r_re);
assign w_wdata_i     = ahbl_hwdata_i;
assign w_wdata = ahbl_hwdata_i[BUS_WIDTH-1:0];
assign w_wdata_en = ahbl_hwdata_i[BUS_WIDTH-1+16:16];

always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_we <= 0;
		r_re <= 0;
		r_addr <= 0;
	end
	else begin
		r_addr <= ahbl_haddr_i[5:2];
		r_we <= (ahbl_hsel_i && ahbl_htrans_i[1] &&   ahbl_hwrite_i);
		r_re <= (ahbl_hsel_i && ahbl_htrans_i[1] && (~ahbl_hwrite_i));
	end
end
//assign ahbl_hrdata_o = r_rdata_o;
assign	ahbl_hrdata_o[31         :BUS_WIDTH]  = 0;
assign	ahbl_hrdata_o[BUS_WIDTH-1:        0]  = r_rval;

`else
assign w_addr = apb_paddr_i[5:2]; // same as LMMI
assign w_wdata_i     = apb_pwdata_i;
assign w_wdata = apb_pwdata_i[BUS_WIDTH-1:0];
assign w_wdata_en = apb_pwdata_i[BUS_WIDTH-1+16:16];
assign w_re = (apb_psel_i && apb_penable_i && (!apb_pwrite_i));
assign w_we = (apb_psel_i && apb_penable_i && ( apb_pwrite_i));

assign	apb_pslverr_o = 1'b0;
assign  apb_pready_o  = 1'b1;
assign	apb_prdata_o[31         :BUS_WIDTH]  = 0;
assign	apb_prdata_o[BUS_WIDTH-1:        0]  = r_rval;

`endif
`ifdef REMOVE_TRI_STATE_BUFFER
	assign gpio_en_o = r_dir;
	assign gpio_o = r_gpio_o;
	assign w_ioval = gpio_i;
`else
	assign	gpo_o	= r_gpio_o;
	assign	gpi_o	= w_ioval;
`endif
`ifdef DISABLE_INTERRUPT
	assign int_o = 1'b0;
`else
	reg [BUS_WIDTH-1:0] r_int_type;
	reg [BUS_WIDTH-1:0] r_int_method;
	reg [BUS_WIDTH-1:0] r_int_status;
	reg [BUS_WIDTH-1:0] r_int_enable;
	reg [BUS_WIDTH-1:0] r_ioval_d;
	reg [BUS_WIDTH-1:0] r_ioval_dd;
	wire [BUS_WIDTH-1:0] w_pedge =   r_ioval_d  & (~r_ioval_dd);
	wire [BUS_WIDTH-1:0] w_nedge = (~r_ioval_d) &   r_ioval_dd ;
	wire [BUS_WIDTH-1:0] w_edge  =   r_ioval_d  ^   r_ioval_dd ;
	wire [BUS_WIDTH-1:0] w_pedge_int =   w_pedge & (~r_int_type) & r_int_method;
	wire [BUS_WIDTH-1:0] w_nedge_int =   w_nedge & (~r_int_type) & (~r_int_method);
	wire [BUS_WIDTH-1:0] w_level_int =   w_edge & r_int_type;
	`ifdef SPEED_OPTIMIZE
		reg [BUS_WIDTH-1:0] r_pedge_int;
		reg [BUS_WIDTH-1:0] r_nedge_int;
		reg [BUS_WIDTH-1:0] r_level_int;
	`endif
`endif

always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_rval <= INIT_OUTVAL;
	end
	else if (w_re) begin
		if(w_addr == 4'h00) begin
			r_rval <= w_ioval;
		end
		else if(w_addr == 4'h01) begin
			r_rval <= r_gpio_o;
		end
		else if(w_addr == 4'h04) begin
			r_rval <= r_dir;
		end
	end
end
// write
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_gpio_o <= INIT_OUTVAL;
	end
	else if(w_we) begin
		if(w_addr == 4'h01) begin
			r_gpio_o <= (r_gpio_o & (~w_wdata_en)) | (w_wdata & w_wdata_en);
		end
		else if(w_addr == 4'h02) begin
			r_gpio_o <= r_gpio_o | (w_wdata & w_wdata_en);
		end
		else if(w_addr == 4'h03) begin
			r_gpio_o <= r_gpio_o & (~(w_wdata & w_wdata_en));
		end
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_dir <= DIRECTION;
	end
	else if(w_we) begin
		if(w_addr == 4'h04) begin
			r_dir <= (r_dir & (~w_wdata_en)) | (w_wdata & w_wdata_en);
		end
	end
end


// ***** interrupt related logics *****
`ifndef DISABLE_INTERRUPT
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_int_type <= 0;
	end
	else if (w_we) begin
		if(w_addr == 4'h05) begin
			r_int_type <= w_wdata;
		end
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_int_method <= 0;
	end
	else if (w_we) begin
		if(w_addr == 4'h06) begin
			r_int_method <= w_wdata;
		end
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_int_status <= 0;
	end
	else if(w_we) begin
		if(w_addr == 4'h07) begin
			r_int_status <= r_int_status & (~w_wdata) & r_int_enable;
		end
		else if(w_addr == 4'h09) begin
			r_int_status <= r_int_status | (w_wdata & r_int_enable);
		end
	end
	else begin
`ifdef SPEED_OPTIMIZE
		r_int_status <= r_int_status | (r_int_enable & (r_pedge_int | r_nedge_int | r_level_int));
`else
		r_int_status <= r_int_status | (r_int_enable & (w_pedge_int | w_nedge_int | w_level_int));
`endif
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		int_o <= 0;
	end
	else begin
		int_o <= |r_int_status;
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_int_enable <= 0;
	end
	else if(w_we) begin
		if(w_addr == 4'h08) begin
			r_int_enable <= w_wdata;
		end
	end
end

always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_ioval_d  <= 0;
		r_ioval_dd <= 0;
	end
	else begin
		r_ioval_d  <= w_ioval;
		r_ioval_dd <= r_ioval_d;
	end
end
`ifdef SPEED_OPTIMIZE
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_pedge_int <= 0;
		r_nedge_int <= 0;
		r_level_int <= 0;
	end
	else begin
		r_pedge_int <= w_pedge_int;
		r_nedge_int <= w_nedge_int;
		r_level_int <= w_level_int;
	end
end
`endif
`endif

`ifndef REMOVE_TRI_STATE_BUFFER
genvar i;
for( i=0; i<BUS_WIDTH; i=i+1) begin
	if (DEVICE == "ICE40UP") begin
		BB_B  sb_io_i (
			.I	(r_gpio_o[i]),
			.O	(w_ioval[i]),
			.T_N	(r_dir[i]),
			.B	(gpio_io[i])
		);
	end
	else if(DEVICE == "CPNX") begin
		BB  io_i (
			.I	(r_gpio_o[i]),
			.O	(w_ioval[i]),
			.T	(~r_dir[i]),
			.B	(gpio_io[i])
		);
	end
	else begin
		assign w_ioval[i] = gpio_io[i];
		assign gpio_io[i] = ~r_dir[i] ? 1'bz : r_gpio_o[i];
	end
end
`endif
endmodule

