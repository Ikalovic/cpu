module dm(clk, DMWr, addr, din, dout);
    input          clk;
    input          DMWr;
    input  [31:0] addr;
    input  [31:0] din;
    output reg [31:0] dout;

    reg [31:0] dmem[127:0];

    always @(posedge clk) begin
        if (DMWr)
            dmem[addr[8:2]] <= din;
    end

    always @(*) begin
        dout = dmem[addr[8:2]];
    end
endmodule
