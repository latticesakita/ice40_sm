
//`define DEBUG_STARTUP

module ice40_sm_top (
`ifdef DEBUG_STARTUP
	input  reset_riscv,
	output reset_riscv_o,
	input  reset_spi,
`endif
	input clk_i, // 12MHz
	input rxd_i,
	output txd_o,
	inout [7:0] led_o,
	inout [1:0] scl_io,
	inout [1:0] sda_io,
	output spi_cs ,
	output spi_clk, 
	inout  spi_miso,
	inout  spi_mosi
);

reg [7:0] r_rst_cnt = 0;
wire oclk; // 24MHz
wire clk_soc;
wire clk_spi;
wire clk2x_spi;
wire resetn;
wire resetn_soc;

assign clk_soc = clk_i; // oclk;
assign clk_spi = clk_soc;
assign clk2x_spi = oclk;
assign resetn = r_rst_cnt[7];

reg [13:0]	r_spi_sram_addr;
wire 		spi_sram_we;
wire [31:0]	spi_sram_din;
reg		r_fill;
wire		load_done;
wire [31:0]	soc_sram_addr;
wire [31:0]	soc_sram_din;
wire [31:0]	soc_sram_dout;
wire		soc_sram_we;
wire [3:0]	soc_sram_maskwe;
wire		soc_sram_re;
wire		soc_sram_write_done;
reg		soc_sram_read_valid;
wire [13:0]	sram_addr;
wire [31:0]	sram_din;
wire [31:0]	sram_dout;
wire		sram_we;
wire [3:0]	sram_maskwe;
// hard IP I/F
wire		ip_done;
wire [7:0]	ip_addr;
wire [7:0]	ip_wdata;
wire [7:0]	ip_rdata;
wire		ip_we;
wire		ip_stb;
wire [1:0]	ip_int;
wire		ip_ack;



assign sram_addr = load_done ? soc_sram_addr[13:0] : r_spi_sram_addr ;
assign sram_din  = load_done ? soc_sram_din  : spi_sram_din    ;
assign sram_we   = load_done ? soc_sram_we   : spi_sram_we     ;
assign sram_maskwe = load_done ? soc_sram_maskwe : 4'b1111;
assign soc_sram_dout = sram_dout;
assign load_done = (~r_fill) & ip_done;
assign soc_sram_write_done = 1'b1;
`ifdef DEBUG_STARTUP
	reg [1:0] rstn_soc;
	assign reset_riscv_o = resetn_soc;
	assign resetn_soc = rstn_soc[1];
	always @(posedge clk_soc or negedge resetn) begin
		if(!resetn) begin
			rstn_soc <= 0;
		end
		else begin
			rstn_soc <= {rstn_soc[0],load_done & reset_riscv};
		end
	end
`else
	assign resetn_soc = load_done;
`endif

always @(posedge oclk) begin
	if(!resetn) begin
		r_rst_cnt <= r_rst_cnt + 1;
	end
end

// DIV:00 = 48MHz, DIV:01=24MHz, DIV:10=12MHz, DIV:11=6MHz
HSOSC #(.CLKHF_DIV ("0b01")) osc0(.CLKHFEN (1'b1), .CLKHFPU(1'b1), .CLKHF(oclk));

ice40_sm ice40_sm_inst (
	.clk_i		(clk_soc), 
	.rstn_i		(resetn_soc), 
	.rxd		(rxd_i),
	.txd		(txd_o),
	.gpio_io	(led_o),

	.ip_addr_o	(ip_addr),
	.ip_wdata_o	(ip_wdata),
	.ip_rdata_i	(ip_rdata),
	.ip_int_i	(ip_int),
	.ip_stb_o	(ip_stb),
	.ip_we_o	(ip_we),
	.ip_ack_i	(ip_ack),

	.sram_addr	(soc_sram_addr),
	.sram_din 	(soc_sram_din ),
	.sram_dout	(soc_sram_dout),
	.sram_re  	(soc_sram_re  ),
	.sram_we  	(soc_sram_we  ),
	.sram_maskwe	(soc_sram_maskwe),
	.sram_write_done(soc_sram_write_done),
	.sram_read_valid(soc_sram_read_valid)
	);


spram16384x32 system0 (
	.clk_i		(clk_soc),
	.addr_i		(sram_addr[13:0]),
	.wr_data_i	(sram_din ),
	.rd_data_o	(sram_dout),
	.mask_we	(sram_maskwe),
	.wr_en_i	(sram_we)
);
always @(posedge clk_soc or negedge resetn) begin
	if(!resetn) begin
		soc_sram_read_valid <= 1'b0;
	end
	else begin
		soc_sram_read_valid <= soc_sram_re;
	end
end
always @(posedge clk_soc or negedge resetn) begin
	if(!resetn) begin
		r_spi_sram_addr <= 0;
	end
	else if(spi_sram_we) begin
		r_spi_sram_addr <= r_spi_sram_addr + 1;
	end
end
always @(posedge clk_soc or negedge resetn) begin
	if(!resetn) begin
		r_fill <= 1'b1;
	end
	// else if(r_spi_sram_addr ==0 ) begin
	// 	r_fill <= 1'b1;
	// end
	else if(spi_sram_we && r_fill) begin
		r_fill <= (spi_sram_din == 32'hFFFF_FFFF) ? 1'b0: 1'b1;
	end
end

`ifdef DEBUG_STARTUP
reg [7:0] rst_spi;
always @(posedge clk_soc or negedge resetn) begin
	if(!resetn) begin
		rst_spi <= 0;
	end
	else if(reset_spi && (rst_spi[7] == 0)) begin
		rst_spi <= rst_spi + 1;
	end
end
`endif

hard_ip hard_ip_i (
	.ipload_i	(resetn),
	.rst_i		(~resetn),
	.sb_adr_i	(ip_addr[7:0]),	// 8bits
	.sb_clk_i	(clk_soc),
	.sb_dat_i	(ip_wdata[7:0]),	// 8bits
	.sb_stb_i	(ip_stb),
	.sb_wr_i	(ip_we),
	.i2c1_scl_io	(scl_io[0]),
	.i2c1_sda_io	(sda_io[0]),
	.i2c2_scl_io	(scl_io[1]),
	.i2c2_sda_io	(sda_io[1]),
	.i2c_pirq_o	(ip_int),	// 2 bits
	.i2c_pwkup_o	(),	// 2 bits
	.ipdone_o	(ip_done),
	.sb_ack_o	(ip_ack),
	.sb_dat_o	(ip_rdata[7:0])	// 8bits
);



spi_fifo spi_fifo_i (
	.clk2x	(clk2x_spi), //48MHz was failed on board test, use 24MHz
	.clk	(clk_spi) ,
	
	.i_flash_addr	(24'h030000),
	
`ifdef DEBUG_STARTUP
	.i_fill	(r_fill & rst_spi[7]),
`else
	.i_fill	(r_fill),
`endif
	.o_fifo_empty	(),
	.o_spram_en	(spi_sram_we),
	.o_spram_dout	(spi_sram_din),
	
	
	.SPI_CSS     (spi_cs), //
	.SPI_CLK     (spi_clk), // 
	.SPI_MISO    (spi_miso), // 
	.SPI_MOSI    (spi_mosi), // 
	
	.resetn      (resetn)
);

endmodule
