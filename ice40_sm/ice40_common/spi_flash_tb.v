// simulate dual mode

module spi_flash
(
	input clk,
	input cs,
	inout miso,
	inout mosi
);

localparam FW_ADDR = 24'h03_0000;
localparam FLASH_SIZE = 8*1024*1024;

reg [7:0] opcode;
reg [23:0] addr;
reg [2:0] r_bcnt;
reg [3:0] r_byte_cnt;
reg [7:0] mem [0:FLASH_SIZE-1];
wire [7:0] r_dout;
// falling edge data
reg [2:0] rf_bcnt;
reg [3:0] rf_byte_cnt;
wire       rf_mosi;
wire       rf_miso;

assign miso = (rf_byte_cnt < 5) ? 1'bz : rf_miso;
assign mosi = (rf_byte_cnt < 5) ? 1'bz : rf_mosi ;
assign {rf_miso,rf_mosi} = 
		(rf_bcnt[2:1] == 2'b00) ? r_dout[7:6] :
		(rf_bcnt[2:1] == 2'b01) ? r_dout[5:4] :
		(rf_bcnt[2:1] == 2'b10) ? r_dout[3:2] :
				 r_dout[1:0] ;

reg [31:0] mem_fw [0:FLASH_SIZE/4-1];
integer size_fw;
integer i;
initial begin
	$readmemh("ice40_nano_Code.mem",mem_fw);
	size_fw = 0;

	for (i = 0; i < FLASH_SIZE-1; i = i + 1) begin
		mem[i] = 8'hFF;
	end
	for (i = 0; i < FLASH_SIZE/4-1; i = i + 1) begin
        	// Assuming unused entries are left as X
        	if (mem_fw[i] !== 32'bx) size_fw = size_fw + 1;
	end
	for (i = 0; i < size_fw; i = i + 1) begin
		mem[FW_ADDR +i*4  ] = mem_fw[i][31:24];
		mem[FW_ADDR +i*4+1] = mem_fw[i][23:16];
		mem[FW_ADDR +i*4+2] = mem_fw[i][15: 8];
		mem[FW_ADDR +i*4+3] = mem_fw[i][ 7: 0];
	end
end

// rising edge capture
always @(posedge clk or posedge cs) begin
	if(cs) begin
		r_bcnt <= 0;
	end
	else if( r_byte_cnt < 5) begin
		r_bcnt <= r_bcnt + 1;
	end
	else begin
		r_bcnt[2:1] <= r_bcnt[2:1] + 1;
		r_bcnt[0]   <= 1'b1;
	end
end
always @(posedge clk or posedge cs) begin
	if(cs) begin
		r_byte_cnt <= 0;
	end
	else if(&r_byte_cnt) begin
		r_byte_cnt <= r_byte_cnt;
	end
	else if(&r_bcnt) begin
		r_byte_cnt <= r_byte_cnt + 1;
	end
end
always @(posedge clk or posedge cs) begin
	if(cs) begin
		opcode <= 0;
	end
	else if(r_byte_cnt==0) begin
		opcode <= {opcode[6:0],mosi};
	end
end
always @(posedge clk or posedge cs) begin
	if(cs) begin
		addr <= 0;
	end
	else if(r_byte_cnt==1) begin
		addr[23:16] <= {addr[22:16],mosi};
	end
	else if(r_byte_cnt==2) begin
		addr[15:8] <= {addr[14:8],mosi};
	end
	else if(r_byte_cnt==3) begin
		addr[7:0] <= {addr[6:0],mosi};
	end
	else if((r_byte_cnt>=5)&&(&r_bcnt)) begin
		addr <= addr + 1;
	end
end

// always @(posedge clk or posedge cs) begin
// 	if(cs) begin
// 		r_dout <= 0;
// 	end
// 	else if(&r_bcnt) begin
// 		r_dout <= mem[addr];
// 	end
// end
assign r_dout = mem[addr];


// falling edge data sent

always @(negedge clk or posedge cs) begin
	if(cs) begin
		rf_bcnt <= 0;
	end
	else if( rf_byte_cnt < 5) begin
		rf_bcnt <= rf_bcnt + 1;
	end
	else begin
		rf_bcnt[2:1] <= rf_bcnt[2:1] + 1;
		rf_bcnt[0]   <= 1'b1;
	end
end
always @(negedge clk or posedge cs) begin
	if(cs) begin
		rf_byte_cnt <= 0;
	end
	else if(&rf_byte_cnt) begin
		rf_byte_cnt <= rf_byte_cnt;
	end
	else if(&rf_bcnt) begin
		rf_byte_cnt <= rf_byte_cnt + 1;
	end
end

endmodule

