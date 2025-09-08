module binary_to_bcd_optimized (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [31:0] binary_in,
    output reg [39:0] bcd_out,
    output reg done
);

    reg [39:0] r_bcd;
    reg [28:0] binary;
    reg [4:0] i;
    reg processing;

    integer j;
    reg [3:0] digit;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_bcd <= 0;
            binary <= 0;
            i <= 0;
            done <= 0;
            processing <= 0;
            bcd_out <= 0;
        end else if (start && !processing) begin
            // 最初の3bitをBCDに挿入し、残り29bitを処理対象に
            r_bcd <= {binary_in[28:0], 8'b0, binary_in[31:29]};
            binary <= binary_in[28:0];
            i <= 0;
            done <= 0;
            processing <= 1;
        end else if (processing) begin
            if (i < 29) begin
                // Add-3 step for each BCD digit
                for (j = 0; j < 10; j = j + 1) begin
                    digit = r_bcd[39 - j*4 -: 4];
                    if (digit >= 5)
                        r_bcd[39 - j*4 -: 4] <= digit + 4'd3;
                end

                // Shift left and insert next binary bit
                r_bcd <= {r_bcd[38:0], binary[28]};
                binary <= binary << 1;
                i <= i + 1;
            end else begin
                bcd_out <= r_bcd;
                done <= 1;
                processing <= 0;
            end
        end
    end
endmodule

