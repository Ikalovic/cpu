module hex8_7seg(
    input        clk,
    input [31:0] value,
    output reg [7:0] an,
    output reg [6:0] seg,
    output       dp
    );

    reg [16:0] scan_cnt = 17'b0;
    wire [2:0] scan = scan_cnt[16:14];
    reg [3:0] hex;

    assign dp = 1'b1;

    always @(posedge clk) begin
        scan_cnt <= scan_cnt + 1'b1;
    end

    always @(*) begin
        an = 8'b1111_1111;
        an[scan] = 1'b0;

        case (scan)
        3'd0: hex = value[3:0];
        3'd1: hex = value[7:4];
        3'd2: hex = value[11:8];
        3'd3: hex = value[15:12];
        3'd4: hex = value[19:16];
        3'd5: hex = value[23:20];
        3'd6: hex = value[27:24];
        3'd7: hex = value[31:28];
        default: hex = 4'h0;
        endcase

        case (hex)
        4'h0: seg = 7'b1000000;
        4'h1: seg = 7'b1111001;
        4'h2: seg = 7'b0100100;
        4'h3: seg = 7'b0110000;
        4'h4: seg = 7'b0011001;
        4'h5: seg = 7'b0010010;
        4'h6: seg = 7'b0000010;
        4'h7: seg = 7'b1111000;
        4'h8: seg = 7'b0000000;
        4'h9: seg = 7'b0010000;
        4'ha: seg = 7'b0001000;
        4'hb: seg = 7'b0000011;
        4'hc: seg = 7'b1000110;
        4'hd: seg = 7'b0100001;
        4'he: seg = 7'b0000110;
        4'hf: seg = 7'b0001110;
        default: seg = 7'b1111111;
        endcase
    end
endmodule
