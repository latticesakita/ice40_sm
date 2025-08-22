module i2c_slave_tb (
  input wire scl,
  inout wire sda,
  input clk
);

  parameter SLAVE_ADDR = 7'h36;
  reg [7:0] memory [0:65535];
  reg [15:0] offset = 0;
  reg [3:0] bit_cnt = 0;
  reg [7:0] shift_reg = 0;
  reg sda_out = 0;
  reg [2:0] state = 0;

  assign sda = sda_out ? 1'b0 : 1'bz;

  localparam IDLE       = 3'd0;
  localparam ADDR       = 3'd1;
  localparam OFFSET_H   = 3'd2;
  localparam OFFSET_L   = 3'd3;
  localparam WRITE_DATA = 3'd4;
  localparam READ_DATA  = 3'd5;

reg r_sda_d = 0;
reg r_scl_d = 0;
reg r_stop = 0;
always @(posedge clk) begin
	r_sda_d <= sda;
	r_scl_d <= scl;
	r_stop <= ((~r_scl_d & scl)||(state == IDLE)) ? 0 : ((~r_sda_d & sda) & scl) | r_stop;
end

	


  always @(negedge scl) begin
    if(r_stop) begin
        bit_cnt <= 0;
        shift_reg <= 0;
        sda_out <= 0;
        state <= ADDR;
    end
    else
    case (state)
      IDLE: begin
        bit_cnt <= 0;
        shift_reg <= 0;
        sda_out <= 0;
        state <= ADDR;
      end

      ADDR: begin
	if (bit_cnt < 7) begin
        	shift_reg <= {shift_reg[6:0], sda};
        	bit_cnt <= bit_cnt + 1;
	end
        else if (bit_cnt == 7) begin
        	shift_reg <= {shift_reg[6:0], sda};
        	bit_cnt <= bit_cnt + 1;
          	if (shift_reg[6:0] == SLAVE_ADDR) begin
          		sda_out <= 1; // ACK
          	end else begin
          		sda_out <= 0; // NACK
          	end
	end
	else if(bit_cnt == 8) begin
		state <= (sda_out == 0) ? IDLE : (shift_reg[0]) ? READ_DATA : OFFSET_H;
		if( shift_reg[0] ) begin
			shift_reg <= memory[offset]; // get ready for read or destroy when write
			sda_out   <= memory[offset][7];
			bit_cnt <= 1;
		end
		else begin
			bit_cnt <= 0;
			sda_out <= 0;
		end
        end
      end

      OFFSET_H: begin
	if (bit_cnt < 7) begin
        	shift_reg <= {shift_reg[6:0], sda};
        	bit_cnt <= bit_cnt + 1;
	end
        else if (bit_cnt == 7) begin
        	shift_reg <= {shift_reg[6:0], sda};
        	bit_cnt <= bit_cnt + 1;
		sda_out <= 1; // ACK
        end
	else if(bit_cnt == 8) begin
		offset[15:8] <= shift_reg;
		state <= OFFSET_L;
		sda_out <= 0;
		bit_cnt <= 0;
	end
      end
      OFFSET_L: begin
	if (bit_cnt < 7) begin
        	shift_reg <= {shift_reg[6:0], sda};
        	bit_cnt <= bit_cnt + 1;
	end
        else if (bit_cnt == 7) begin
        	shift_reg <= {shift_reg[6:0], sda};
        	bit_cnt <= bit_cnt + 1;
		sda_out <= 1; // ACK
        end
	else if(bit_cnt == 8) begin
		offset[7:0] <= shift_reg;
		state <= WRITE_DATA;
		sda_out <= 0;
		bit_cnt <= 0;
	end
      end

      WRITE_DATA: begin
	if (bit_cnt < 7) begin
        	shift_reg <= {shift_reg[6:0], sda};
        	bit_cnt <= bit_cnt + 1;
	end
        else if (bit_cnt == 7) begin
        	shift_reg <= {shift_reg[6:0], sda};
        	bit_cnt <= bit_cnt + 1;
		sda_out <= 1; // ACK
        end
	else if(bit_cnt == 8) begin
		memory[offset] <= shift_reg;
		offset <= offset + 1;
		state <= WRITE_DATA;
		sda_out <= 0;
		bit_cnt <= 0;
	end
      end

      READ_DATA: begin
	if (bit_cnt < 7) begin
        	sda_out <= shift_reg[7 - bit_cnt];
        	bit_cnt <= bit_cnt + 1;
	end
        else if (bit_cnt == 7) begin
		sda_out <= 0; // NACK
		state <= IDLE;
		offset <= offset + 1;
        end
	else if(bit_cnt == 8) begin
		shift_reg <= memory[offset]; // get ready for read or destroy when write
		sda_out   <= memory[offset][7];
		bit_cnt <= 1;
	end
      end
    endcase
  end

endmodule

