module board_imem(
    input  [31:2]  addr,
    output [31:0]  dout
    );

    reg [31:0] RAM[127:0];

    initial begin
        $readmemh("rv32_sid_sort_sim.dat", RAM, 0, 54);
    end

    assign dout = RAM[addr];
endmodule

module board_dmem(
    input         clk,
    input         DMWr,
    input  [31:0] addr,
    input  [31:0] din,
    output reg [31:0] dout,
    output [31:0] original_sid,
    output [31:0] sorted_sid
    );

    reg [31:0] dmem[127:0];
    integer i;

    initial begin
        for (i = 0; i < 128; i = i + 1)
            dmem[i] = 32'h0000_0000;
    end

    always @(posedge clk) begin
        if (DMWr)
            dmem[addr[8:2]] <= din;
    end

    always @(*) begin
        dout = dmem[addr[8:2]];
    end

    assign original_sid = dmem[96];
    assign sorted_sid   = dmem[97];
endmodule
