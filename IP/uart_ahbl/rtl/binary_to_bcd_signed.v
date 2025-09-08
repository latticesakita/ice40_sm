module binary_to_bcd_signed (
    input  wire        clk,
    input  wire        resetn,
    input  wire        stb_i,
    input  wire        sign_en,
    input  wire [31:0] din_i,
    output wire [39:0] bcd_o,
    output reg         done_o,
    output reg         sign_neg // 1なら負数
);

    reg [39:0] r_bcd;
    reg [28:0] r_din;
    reg [5:0]  r_cnt;
    reg        r_busy;

    integer i;

    assign bcd_o = r_bcd;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            r_bcd    <= 40'd0;
            r_din    <= 29'd0;
            r_cnt    <= 6'd0;
            r_busy   <= 1'b0;
            done_o   <= 1'b0;
            sign_neg <= 1'b0;
        end else if (stb_i && !r_busy) begin
            r_busy   <= 1'b1;
            done_o   <= 1'b0;
            r_cnt    <= 6'd3;

            if (sign_en && din_i[31] == 1'b1) begin
                // 負数の場合：絶対値に変換
                sign_neg <= 1'b1;
                r_din    <= -din_i[28:0]; // 下位29bitの絶対値
                r_bcd    <= {37'd0, (-din_i[31:29])}; // 上位3bitの絶対値
            end else begin
                sign_neg <= 1'b0;
                r_din    <= din_i[28:0];
                r_bcd    <= {37'd0, din_i[31:29]};
            end
        end else if (r_busy) begin
            // Add-3 step for each BCD digit
            for (i = 0; i < 10; i = i + 1) begin
                if (r_bcd[i*4 +: 4] >= 5)
                    r_bcd[i*4 +: 4] <= r_bcd[i*4 +: 4] + 4'd3;
            end

            // Shift left and insert next binary bit
            r_bcd <= {r_bcd[38:0], r_din[28]};
            r_din <= {r_din[27:0], 1'b0};
            r_cnt <= r_cnt + 1;

            if (r_cnt == 6'd30) begin
                r_busy <= 1'b0;
                done_o <= 1'b1;
            end else begin
                done_o <= 1'b0;
            end
        end
    end
endmodule

