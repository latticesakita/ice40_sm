
`timescale 1ns/10ps

module spi_fifo (
input           clk2x       , // SPI I/O clock
input           clk         , // FIFO interface clock

input [23:0]	i_flash_addr,

// FIFO interface
input           i_fill      ,
output          o_fifo_empty,
output		o_spram_en,
output [31:0]   o_spram_dout ,

output          SPI_CSS     , //
output          SPI_CLK     , // 
inout           SPI_MISO    , // 
inout           SPI_MOSI    , // 

input		resetn      
);

// state machine
parameter [3:0] 
	S_IDLE  = 4'b0000, // 0
	S_CMD   = 4'b0001, // 1
	S_ADDR0 = 4'b0010, // 2
	S_ADDR1 = 4'b0011, // 3
	S_ADDR2 = 4'b0111, // 7
	S_DUMMY = 4'b0110, // 6
	S_WRTD0 = 4'b0100, // 4
	S_WRTD1 = 4'b1100, // C
	S_FILL  = 4'b1110, // E
	S_WAIT  = 4'b1010, // A
	S_LAST  = 4'b1111; // F

reg     [3:0]   state;
reg     [3:0]   nstate;

reg	[2:0]	bit_cnt;

reg	[7:0]	byte_out;

reg	[1:0]	fill_d;
reg		st_fill_d;
reg		init_req;
reg		enable;
wire		byte_tick;


wire            fifo_full;

wire		w_csb;
wire	[1:0]	w_clk;
reg		r_do_o;
wire		w_do_z;
wire		w_di_o;
wire		w_di_z;

wire	[1:0]	w_do_i;
wire	[1:0]	w_di_i;

always @(posedge clk2x or negedge resetn)
begin
    if(resetn == 1'b0) 
	fill_d <= 2'b0;
    else 
	fill_d <= {fill_d[0], i_fill};
end

always @(posedge clk2x or negedge resetn)
begin
    if(resetn == 1'b0) 
	init_req <= 1'b0;
    else if(fill_d == 2'b10)
	init_req <= 1'b1;
    else if(state == S_LAST)
	init_req <= 1'b0;
end

always @(posedge clk2x or negedge resetn)
begin
    if(resetn == 1'b0) 
	enable <= 1'b0;
    else
	enable <= i_fill;
end

always @(posedge clk2x or negedge resetn)
begin
    if(resetn == 1'b0) 
	state <= S_IDLE;
    else
	state <= nstate;
end

always @(*)
begin
    case(state)
	S_IDLE :
	    nstate <= enable ? S_CMD : S_IDLE;
	S_CMD:
	    nstate <= byte_tick ? S_ADDR0 : S_CMD;
	S_ADDR0:
	    nstate <= byte_tick ? S_ADDR1 : S_ADDR0;
	S_ADDR1:
	    nstate <= byte_tick ? S_ADDR2 : S_ADDR1;
	S_ADDR2:
	    nstate <= byte_tick ? S_DUMMY : S_ADDR2;
	S_DUMMY:
	    nstate <= byte_tick ? S_FILL : S_DUMMY; 
	S_WRTD0:
	    nstate <= S_WRTD1;
	S_WRTD1:
	    nstate <= S_FILL;
	S_FILL:
	    nstate <= byte_tick ? (init_req ? S_LAST : (fifo_full ? S_WAIT : S_FILL)) : S_FILL;
	S_WAIT:
	    nstate <= fifo_full ? S_WAIT : S_FILL;
	S_LAST:
	    nstate <= S_IDLE;
	default:
	    nstate <= S_IDLE ;
    endcase
end

always @(posedge clk2x or negedge resetn)
begin
    if(resetn == 1'b0) 
	byte_out <= 8'b0;
    else if(state == S_IDLE)
	byte_out <= 8'h3B; // fast read, dual output
    else if(byte_tick)
	case(state)
	    S_CMD  : byte_out <= i_flash_addr[23:16];
	    S_ADDR0: byte_out <= i_flash_addr[15: 8];
	    S_ADDR1: byte_out <= i_flash_addr[7 : 0];
	    default: byte_out <= 8'b0;
	endcase
end

assign w_csb  = (state == S_IDLE);
assign w_clk  = ((state == S_IDLE) || (state == S_LAST) || (state == S_WAIT)) ? 2'b00 : 2'b01;
assign w_do_z = (state == S_DUMMY) || (state == S_FILL) || (state == S_WAIT);
assign w_di_z = 1'b1;
assign w_di_o = 1'b0;

always @(*)
begin
    case(bit_cnt)
	3'd0   : r_do_o = byte_out[7];
	3'd1   : r_do_o = byte_out[6];
	3'd2   : r_do_o = byte_out[5];
	3'd3   : r_do_o = byte_out[4];
	3'd4   : r_do_o = byte_out[3];
	3'd5   : r_do_o = byte_out[2];
	3'd6   : r_do_o = byte_out[1];
	default: r_do_o = byte_out[0];
    endcase
end

always @(posedge clk2x or negedge resetn)
begin
    if(resetn == 1'b0) 
	bit_cnt <= 3'b0;
    else if((state == S_IDLE) || (state == S_WRTD0) || (state == S_WRTD1))
	bit_cnt <= 3'b0;
    else if(state != S_WAIT)
	bit_cnt <= (bit_cnt + 3'd1) | {(state == S_FILL), 2'b00}; // Use Dual Output mode for fill
end

assign byte_tick = (bit_cnt == 3'd7);


always @(posedge clk2x or negedge resetn)
begin
    if(resetn == 1'b0) 
	st_fill_d <= 1'b0;
    else 
	st_fill_d <= (state == S_FILL) || (state ==S_WRTD0) || (state ==S_WRTD1);
end



reg [10:0] r_waddr_clkw;
reg [ 8:0] r_waddr_clkr_m;
reg [ 8:0] r_waddr_clkr;
reg [ 8:0] r_raddr_clkr;
reg        r_ren;
reg [1:0]  r_ren_d;
reg        r_spram_en;
reg [31:0] r_spram_out;
reg        r_wen;
reg [1:0]  r_wdata;
wire [1:0] w_wdata;
wire [7:0] w_rdata;
assign w_wdata = r_wdata; // {w_di_i[0], w_do_i[0]};
assign fifo_full = ((r_waddr_clkr+8) == r_raddr_clkr);
assign o_fifo_empty = (r_waddr_clkr == r_raddr_clkr);
assign o_spram_dout  = r_spram_out;
assign o_spram_en    = r_spram_en;

always @(posedge clk2x or negedge resetn) begin
	if(!resetn) begin
		r_wdata <= 0;
		r_wen   <= 0;
	end
	else begin
		//r_wdata <= {w_di_i[0], w_do_i[0]}; // capture in rising edge
		r_wdata <= {w_di_i[1], w_do_i[1]}; // capture in falling edge in case clk2out delay in SPI flash is long.
		r_wen   <= st_fill_d;
	end
end
always @(posedge clk2x or negedge resetn) begin
	if(!resetn) begin
		r_waddr_clkw <= 0;
	end
	else if(r_wen) begin
		r_waddr_clkw <= r_waddr_clkw + 1;
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_waddr_clkr_m <= 0;
		r_waddr_clkr <= 0;
	end
	else begin
		r_waddr_clkr_m <= r_waddr_clkw[10:2];
		r_waddr_clkr   <= r_waddr_clkr_m;
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_raddr_clkr <= 0;
	end
	else if(r_ren) begin
		r_raddr_clkr <= r_raddr_clkr + 1;
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_ren <= 0;
	end
	else if(r_ren) begin
		r_ren <= 0;
	end
	else begin
		r_ren <= (r_waddr_clkr!=r_raddr_clkr) ? 1'b1 : 1'b0;
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_ren_d <= 0;
	end
	else begin
		r_ren_d <= {r_ren_d[0],r_ren};
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_spram_out <= 0;
	end
	else if(r_ren_d[0]) begin
		r_spram_out <= {r_spram_out[23:0],w_rdata[1:0],w_rdata[3:2],w_rdata[5:4],w_rdata[7:6]};
		//r_spram_out <= {w_rdata[1:0],w_rdata[3:2],w_rdata[5:4],w_rdata[7:6],r_spram_out[31:8]};
	end
end
always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		r_spram_en <= 0;
	end
	else if(!r_ren_d[1]) begin
		r_spram_en <= 0;
	end
	else begin
		r_spram_en <= r_raddr_clkr[1:0] == 2'b00;
	end
end
dpram2048x2_512x8 dpram2_8_i (
	.wr_clk_i   (clk2x           ),
	.rd_clk_i   (clk             ),
	.wr_clk_en_i(1'b1            ),
	.rd_en_i    (r_ren         ),
	.rd_clk_en_i(1'b1            ),
	.wr_en_i    (r_wen         ),
	.wr_data_i  (w_wdata  ),
	.wr_addr_i  (r_waddr_clkw ),
	.rd_addr_i  (r_raddr_clkr ),
	.rd_data_o  (w_rdata     )
);


// IO {{{

IOL_B #( .LATCHIN ("NONE_DDR"), .DDROUT  ("YES")) u_io_clk (
    .PADDI  (        ),  // I
    .DO1    (w_clk[1]),  // I
    .DO0    (w_clk[0]),  // I
    .CE     (1'b1    ),  // I
    .IOLTO  (1'b0    ),  // I
    .HOLD   (1'b0    ),  // I
    .INCLK  (clk2x   ),  // I
    .OUTCLK (clk2x   ),  // I
    .PADDO  (SPI_CLK ),  // O
    .PADDT  (        ),  // O
    .DI1    (        ),  // O
    .DI0    (        )   // O
);

IOL_B #(.LATCHIN ("NONE_DDR"), .DDROUT  ("YES")) u_io_csb (
    .PADDI  (        ),  // I
    .DO1    (w_csb   ),  // I
    .DO0    (w_csb   ),  // I
    .CE     (1'b1    ),  // I
    .IOLTO  (1'b0    ),  // I
    .HOLD   (1'b0    ),  // I
    .INCLK  (clk2x   ),  // I
    .OUTCLK (clk2x   ),  // I
    .PADDO  (SPI_CSS ),  // O
    .PADDT  (        ),  // O
    .DI1    (        ),  // O
    .DI0    (        )   // O
);

wire	     	do_t;
wire	     	do_i;
wire	     	do_o;

BB_B u_BB_do (
    .T_N(do_t    ), 
    .I  (do_o    ), 
    .O  (do_i    ), 
    .B  (SPI_MOSI)
); 

IOL_B #( .LATCHIN ("LATCH_REG"), .DDROUT  ("YES")) u_io_mosi (
    .PADDI  (do_i     ),  // I
    .DO1    (r_do_o   ),  // I
    .DO0    (r_do_o   ),  // I
    .CE     (1'b1     ),  // I
    .IOLTO  (!w_do_z  ),  // I
    .HOLD   (1'b0     ),  // I
    .INCLK  (clk2x    ),  // I
    .OUTCLK (clk2x    ),  // I
    .PADDO  (do_o     ),  // O
    .PADDT  (do_t     ),  // O
    .DI1    (w_do_i[1]),  // O
    .DI0    (w_do_i[0])   // O
);

wire	     	di_t;
wire	     	di_i;
wire	     	di_o;

BB_B u_BB_di (
    .T_N(di_t    ), 
    .I  (di_o    ), 
    .O  (di_i    ), 
    .B  (SPI_MISO)
); 

IOL_B #( .LATCHIN ("LATCH_REG"), .DDROUT  ("YES")) u_io_miso (
    .PADDI  (di_i     ),  // I
    .DO1    (w_di_o   ),  // I
    .DO0    (w_di_o   ),  // I
    .CE     (1'b1     ),  // I
    .IOLTO  (!w_di_z  ),  // I
    .HOLD   (1'b0     ),  // I
    .INCLK  (clk2x    ),  // I
    .OUTCLK (clk2x    ),  // I
    .PADDO  (di_o     ),  // O
    .PADDT  (di_t     ),  // O
    .DI1    (w_di_i[1]),  // O
    .DI0    (w_di_i[0])   // O
);

// IO }}}

endmodule

// vim:foldmethod=marker: 
