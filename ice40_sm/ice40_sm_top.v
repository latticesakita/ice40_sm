

module ice40_sm_top (
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

localparam MINIMUM_SPI_LOAD_SIZE = 4096/4;
localparam STATE_LOAD_SYSTEM0 = 0;
localparam STATE_LOAD_WAIT = 1;
localparam STATE_LOAD_SYSTEM1 = 14;
localparam STATE_LOAD_DONE = 15;

reg [7:0] r_rst_cnt = 0;
wire oclk; // 24MHz
wire clk_soc;
wire clk_spi;
wire clk2x_spi;
wire resetn;
wire resetn_soc;

//assign clk_soc = clk_i; // oclk;
assign clk_spi = clk_soc;
assign clk2x_spi = oclk;
assign resetn = r_rst_cnt[7];

// system0
reg 		r_fill;
reg [3:0]	load_state;
wire 		load_done;
wire [23:0]     flash_addr;
reg [13:0]	r_spi_sram_addr;
wire 		spi_sram_we;
wire [31:0]	spi_sram_din;
wire [13:0]	soc_sram_addr;
wire [31:0]	soc_sram_din;
wire [31:0]	soc_sram_dout;
wire		soc_sram_we;
wire [3:0]	soc_sram_maskwe;
wire		soc_sram_re;
reg 		soc_sram_write_done;
reg		soc_sram_read_valid;
wire [13:0]	sram_addr;
wire [31:0]	sram_din;
wire [31:0]	sram_dout;
wire		sram_we;
wire [3:0]	sram_maskwe;

// system1
wire 		spi_dram_we;
wire [31:0]	spi_dram_din;
wire [13:0]	soc_dram_addr;
wire [31:0]	soc_dram_din;
wire [31:0]	soc_dram_dout;
wire		soc_dram_we;
wire [3:0]	soc_dram_maskwe;
wire		soc_dram_re;
reg 		soc_dram_write_done;
reg		soc_dram_read_valid;
wire [13:0]	dram_addr;
wire [31:0]	dram_din;
wire [31:0]	dram_dout;
wire		dram_we;
wire [3:0]	dram_maskwe;

// hard IP I/F
wire		ip_done;
wire [7:0]	ip_addr;
wire [7:0]	ip_wdata;
wire [7:0]	ip_rdata;
wire		ip_we;
wire		ip_stb;
wire [1:0]	ip_int;
wire		ip_ack;



assign sram_addr     = (load_state==STATE_LOAD_SYSTEM0) ? r_spi_sram_addr : soc_sram_addr[13:0]  ;
assign sram_din      = (load_state==STATE_LOAD_SYSTEM0) ? spi_sram_din    : soc_sram_din;
assign sram_we       = (load_state==STATE_LOAD_SYSTEM0) ? spi_sram_we     : soc_sram_we;
assign sram_maskwe   = (load_state==STATE_LOAD_SYSTEM0) ? 4'b1111         : soc_sram_maskwe;
assign soc_sram_dout = sram_dout;
//assign soc_sram_write_done = soc_sram_we;

assign dram_addr     = (load_state==STATE_LOAD_SYSTEM1) ? r_spi_sram_addr : soc_dram_addr[13:0]  ;
assign dram_din      = (load_state==STATE_LOAD_SYSTEM1) ? spi_sram_din    : soc_dram_din;
assign dram_we       = (load_state==STATE_LOAD_SYSTEM1) ? spi_sram_we     : soc_dram_we;
assign dram_maskwe   = (load_state==STATE_LOAD_SYSTEM1) ? 4'b1111         : soc_dram_maskwe  ;
assign soc_dram_dout = dram_dout;
//assign soc_dram_write_done = soc_dram_we;


assign load_done  = (load_state == STATE_LOAD_DONE) & ip_done;
assign flash_addr = (load_state == STATE_LOAD_SYSTEM0) ? 24'h030000 : 24'h050000;
assign resetn_soc = load_done;

genclk genclk_i (
	.oclk	(oclk),
	.clk12	(clk_soc)
);


always @(posedge oclk) begin
	if(!resetn) begin
		r_rst_cnt <= r_rst_cnt + 1;
	end
end


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
	.sram_read_valid(soc_sram_read_valid),
	.dram_addr	(soc_dram_addr),
	.dram_din 	(soc_dram_din ),
	.dram_dout	(soc_dram_dout),
	.dram_re  	(soc_dram_re  ),
	.dram_we  	(soc_dram_we  ),
	.dram_maskwe	(soc_dram_maskwe),
	.dram_write_done(soc_dram_write_done),
	.dram_read_valid(soc_dram_read_valid)
	);


spram16384x32 system0 (
	.clk_i		(clk_soc),
	.addr_i		(sram_addr[13:0]),
	.wr_data_i	(sram_din ),
	.rd_data_o	(sram_dout),
	.mask_we	(sram_maskwe),
	.wr_en_i	(sram_we)
);
spram16384x32 system1 (
	.clk_i		(clk_soc),
	.addr_i		(dram_addr[13:0]),
	.wr_data_i	(dram_din ),
	.rd_data_o	(dram_dout),
	.mask_we	(dram_maskwe),
	.wr_en_i	(dram_we)
);
always @(posedge clk_soc or negedge resetn) begin
	if(!resetn) begin
		soc_sram_read_valid <= 1'b0;
		soc_dram_read_valid <= 1'b0;
		soc_sram_write_done <= 1'b0;
		soc_dram_write_done <= 1'b0;
	end
	else begin
		soc_sram_read_valid <= soc_sram_re;
		soc_dram_read_valid <= soc_dram_re;
		soc_sram_write_done <= soc_sram_we;
		soc_dram_write_done <= soc_dram_we;
	end
end

hard_ip hard_ip_i (
	.ipload_i	(resetn),
	.rst_i		(resetn),
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

wire spi_fifo_rstn;
assign spi_fifo_rstn = (load_state==STATE_LOAD_WAIT) ? 1'b0 : resetn;

spi_fifo spi_fifo_i (
	.clk2x	(clk2x_spi), //48MHz was failed on board test, use 24MHz
	.clk	(clk_spi) ,
	
	.i_flash_addr	(flash_addr),
	
	.i_fill	(r_fill),
	.o_fifo_empty	(),
	.o_spram_en	(spi_sram_we),
	.o_spram_dout	(spi_sram_din),
	
	
	.SPI_CSS     (spi_cs), //
	.SPI_CLK     (spi_clk), // 
	.SPI_MISO    (spi_miso), // 
	.SPI_MOSI    (spi_mosi), // 
	
	//.resetn      (resetn)
	.resetn      (spi_fifo_rstn)
);

always @(posedge clk_spi or negedge resetn) begin
	if(!resetn) begin
		load_state <= STATE_LOAD_SYSTEM0;
	end
	else if(load_state==STATE_LOAD_DONE) begin
	end
	else if(load_state==STATE_LOAD_SYSTEM0) begin
		if(spi_sram_we&&(spi_sram_din == 32'hFFFF_FFFF)) begin
			load_state <= (r_spi_sram_addr < MINIMUM_SPI_LOAD_SIZE) ? STATE_LOAD_SYSTEM0 : STATE_LOAD_WAIT;
		end
	end
	else if(load_state==STATE_LOAD_SYSTEM1) begin
		//TODO: it won't work if data are initialized as FFFF_FFFF or -1 in software side
		if(spi_sram_we&&(spi_sram_din == 32'hFFFF_FFFF)) begin
			load_state <= (r_spi_sram_addr < MINIMUM_SPI_LOAD_SIZE) ? STATE_LOAD_SYSTEM1 : STATE_LOAD_DONE;
		end
	end
	else begin
		load_state <= load_state + 1;
	end
end
always @(posedge clk_spi or negedge resetn) begin
	if(!resetn) begin
		r_fill <= 0;
	end
	else if(load_state == STATE_LOAD_SYSTEM0) begin
		r_fill <= 1;
	end
	else if(load_state == STATE_LOAD_SYSTEM1) begin
		r_fill <= 1;
	end
	else begin
		r_fill <= 0;
	end
end
always @(posedge clk_soc or negedge resetn) begin
	if(!resetn) begin
		r_spi_sram_addr <= 0;
	end
	else if((load_state==STATE_LOAD_SYSTEM0)||(load_state==STATE_LOAD_SYSTEM1)) begin
		if(spi_sram_we) begin
			r_spi_sram_addr <= r_spi_sram_addr + 1;
		end
	end
	else begin
		r_spi_sram_addr <= 0;
	end
end
endmodule
