
`timescale 1 ns / 100 ps

module tb;

// GSR GSR_INST (.GSR_N(1'b1));
// PUR PUR_INST (.PUR(1'b1));

parameter FREQ = 12.0;
parameter PERIOD = 1000.0 / FREQ;

reg rstn;
reg clk;

initial begin
	rstn <= 0;
	#100 rstn <= 1;
end
initial begin
	clk = 1'b0;
	forever #(PERIOD/2) clk = ~clk;
end

wire uart_rx;
wire uart_tx;
wire [15:0] led;
wire scl1_io;
wire sda1_io;
wire scl2_io;
wire sda2_io;
wire spi_cs  ;
wire spi_clk ;
wire spi_mosi;
wire spi_miso;

pullup(uart_rx);
pullup(scl1_io);
pullup(sda1_io);
pullup(scl2_io);
pullup(sda2_io);
pullup(led[0]);
pullup(led[1]);
pullup(led[2]);
pullup(led[3]);
pullup(led[4]);
pullup(led[5]);
pullup(led[6]);
pullup(led[7]);
pullup(led[8]);
pullup(led[9]);
pullup(led[10]);
pullup(led[11]);
pullup(led[12]);
pullup(led[13]);
pullup(led[14]);
pullup(led[15]);
pullup(spi_miso);
pullup(spi_mosi);

ice40_sm_top dut (
	//.rstn_i	(rstn),
	.clk_i	(clk),
	.rxd_i	(uart_rx),
	.txd_o	(uart_tx),
	.led_o	(led[7:0]),
	.scl_io	({scl2_io,scl1_io}),
	.sda_io	({sda2_io,sda1_io}),
	.spi_cs  	(spi_cs  ),
	.spi_clk 	(spi_clk ), 
	.spi_miso	(spi_miso),
	.spi_mosi	(spi_mosi) 
);
// SPI Flash 
spi_flash spi_flash_i (
	.clk		(spi_clk),
	.cs		(spi_cs),
	.miso		(spi_miso),
	.mosi		(spi_mosi)
);
// I2C slave
i2c_slave_tb ov08x (
	.scl(scl1_io),
	.sda(sda1_io),
	.clk(clk)
);



integer code_log;
integer data_log;

initial begin
	code_log = $fopen("code.log", "w");
	data_log = $fopen("data.log", "w");
end
reg r_htransm0_d = 0;
reg r_htransm1_d = 0;
reg [31:0] r_haddr0;
reg [31:0] r_haddr1;
always @(posedge dut.clk_soc) begin
	r_htransm0_d    <= dut.ice40_sm_inst.cpu_inst_AHBL_M0_INSTR_interconnect_HTRANS[1];
	r_htransm1_d    <= dut.ice40_sm_inst.cpu_inst_AHBL_M1_DATA_interconnect_HTRANS[1];
	r_haddr0 <= dut.ice40_sm_inst.cpu_inst_AHBL_M0_INSTR_interconnect_HADDR;
	r_haddr1 <= dut.ice40_sm_inst.cpu_inst_AHBL_M1_DATA_interconnect_HADDR;
end
always @(posedge dut.clk_soc) begin
	if( dut.ice40_sm_inst.cpu_inst_AHBL_M0_INSTR_interconnect_HTRANS[1]
		&& dut.ice40_sm_inst.cpu_inst_AHBL_M0_INSTR_interconnect_HWRITE) begin
			$display(code_log, "%0t: %08x, %08x", $time, 
				dut.ice40_sm_inst.cpu_inst_AHBL_M0_INSTR_interconnect_HADDR,
				dut.ice40_sm_inst.cpu_inst_AHBL_M0_INSTR_interconnect_HWDATA);
			$fwrite(code_log, "%0t: %08x, %08x, write\n", $time, 
				dut.ice40_sm_inst.cpu_inst_AHBL_M0_INSTR_interconnect_HADDR,
				dut.ice40_sm_inst.cpu_inst_AHBL_M0_INSTR_interconnect_HWDATA);
	end
	else if(r_htransm0_d 
		&& dut.ice40_sm_inst.cpu_inst_AHBL_M0_INSTR_interconnect_HREADYOUT
		&& ~dut.ice40_sm_inst.cpu_inst_AHBL_M0_INSTR_interconnect_HWRITE) begin
			$display(code_log, "%0t: %08x, %08x", $time, 
				r_haddr0,
				dut.ice40_sm_inst.cpu_inst_AHBL_M0_INSTR_interconnect_HRDATA);
			$fwrite(code_log, "%0t: %08x, %08x\n", $time, 
				r_haddr0,
				dut.ice40_sm_inst.cpu_inst_AHBL_M0_INSTR_interconnect_HRDATA);
	end
end
always @(posedge dut.clk_soc) begin
	if( dut.ice40_sm_inst.cpu_inst_AHBL_M1_DATA_interconnect_HTRANS[1]
		&& dut.ice40_sm_inst.cpu_inst_AHBL_M1_DATA_interconnect_HWRITE) begin
			$display(data_log, "%0t: %08x, %08x write", $time, 
				dut.ice40_sm_inst.cpu_inst_AHBL_M1_DATA_interconnect_HADDR,
				dut.ice40_sm_inst.cpu_inst_AHBL_M1_DATA_interconnect_HWDATA);
			$fwrite(data_log, "%0t: %08x, %08x, write\n", $time, 
				dut.ice40_sm_inst.cpu_inst_AHBL_M1_DATA_interconnect_HADDR,
				dut.ice40_sm_inst.cpu_inst_AHBL_M1_DATA_interconnect_HWDATA);
	end
	else if(r_htransm0_d 
		&& dut.ice40_sm_inst.cpu_inst_AHBL_M1_DATA_interconnect_HREADYOUT
		&& ~dut.ice40_sm_inst.cpu_inst_AHBL_M1_DATA_interconnect_HWRITE) begin
			$display(data_log, "%0t: %08x, %08x read", $time, 
				r_haddr0,
				dut.ice40_sm_inst.cpu_inst_AHBL_M1_DATA_interconnect_HRDATA);
			$fwrite(data_log, "%0t: %08x, %08x read\n", $time, 
				r_haddr0,
				dut.ice40_sm_inst.cpu_inst_AHBL_M1_DATA_interconnect_HRDATA);
	end
end

endmodule
