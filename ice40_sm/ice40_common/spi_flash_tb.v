// simulate dual mode

module spi_flash
(
	input clk,
	input cs,
	inout miso,
	inout mosi
);

localparam MEM0_NAME = "ice40_sm_Code.mem";
localparam MEM0_ADDR = 24'h03_0000;
localparam MEM1_NAME = "ice40_sm_Data.mem";
localparam MEM1_ADDR = 24'h05_0000;
localparam FLASH_SIZE = 8*1024*1024;

reg [7:0] opcode;
reg [23:0] addr;
reg [23:0] addrf;
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

reg [31:0] mem0 [0:FLASH_SIZE/4-1];
reg [31:0] mem1 [0:FLASH_SIZE/4-1];
integer size_fw;
integer i;
initial begin
	$readmemh(MEM0_NAME,mem0);
	size_fw = 0;

	for (i = 0; i < FLASH_SIZE-1; i = i + 1) begin
		mem[i] = 8'hFF;
	end
	for (i = 0; i < FLASH_SIZE/4-1; i = i + 1) begin
        	// Assuming unused entries are left as X
        	if (mem0[i] !== 32'bx) size_fw = size_fw + 1;
	end
	for (i = 0; i < size_fw; i = i + 1) begin
		mem[MEM0_ADDR +i*4  ] = mem0[i][31:24];
		mem[MEM0_ADDR +i*4+1] = mem0[i][23:16];
		mem[MEM0_ADDR +i*4+2] = mem0[i][15: 8];
		mem[MEM0_ADDR +i*4+3] = mem0[i][ 7: 0];
	end
	$readmemh(MEM1_NAME,mem1);
	size_fw = 0;

	for (i = 0; i < FLASH_SIZE/4-1; i = i + 1) begin
        	// Assuming unused entries are left as X
        	if (mem1[i] !== 32'bx) size_fw = size_fw + 1;
	end
	for (i = 0; i < size_fw; i = i + 1) begin
		mem[MEM1_ADDR +i*4  ] = mem1[i][31:24];
		mem[MEM1_ADDR +i*4+1] = mem1[i][23:16];
		mem[MEM1_ADDR +i*4+2] = mem1[i][15: 8];
		mem[MEM1_ADDR +i*4+3] = mem1[i][ 7: 0];
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
always @(negedge clk or posedge cs) begin
	if(cs) begin
		addrf <= 0;
	end
	else begin
		addrf <= #3000 addr;
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
assign r_dout = mem[addrf];


// falling edge data sent

always @(negedge clk or posedge cs) begin
	if(cs) begin
		rf_bcnt <= 0;
	end
	else if( rf_byte_cnt < 5) begin
		rf_bcnt <= #3000 rf_bcnt + 1;
	end
	else begin
		rf_bcnt[2:1] <= #3000 rf_bcnt[2:1] + 1;
		rf_bcnt[0]   <= #3000 1'b1;
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

