module mc_nexys_a7_top(
    input        CLK100MHZ,
    input        BTNC,
    input [15:0] SW,
    output [15:0] LED,
    output       CA,
    output       CB,
    output       CC,
    output       CD,
    output       CE,
    output       CF,
    output       CG,
    output       DP,
    output [7:0] AN
    );

    reg [15:0] clkdiv = 16'b0;
    wire cpu_clk = clkdiv[14];
    wire reset = BTNC;

    wire [31:0] instr;
    wire [31:0] pc;
    wire        mem_w;
    wire [31:0] dm_addr;
    wire [31:0] dm_din;
    wire [31:0] dm_dout;
    wire [31:0] original_sid;
    wire [31:0] sorted_sid;
    wire [31:0] display_value = SW[0] ? sorted_sid : original_sid;
    wire [6:0] seg;

    always @(posedge CLK100MHZ) begin
        clkdiv <= clkdiv + 1'b1;
    end

    MCCPU U_CPU(
        .clk(cpu_clk),
        .reset(reset),
        .inst_in(instr),
        .Data_in(dm_dout),
        .mem_w(mem_w),
        .PC_out(pc),
        .Addr_out(dm_addr),
        .Data_out(dm_din),
        .reg_sel(5'd0),
        .reg_data()
    );

    board_dmem U_DM(
        .clk(cpu_clk),
        .DMWr(mem_w),
        .addr(dm_addr),
        .din(dm_din),
        .dout(dm_dout),
        .original_sid(original_sid),
        .sorted_sid(sorted_sid)
    );

    board_imem U_IM(
        .addr(pc[31:2]),
        .dout(instr)
    );

    hex8_7seg U_SEG(
        .clk(CLK100MHZ),
        .value(display_value),
        .an(AN),
        .seg(seg),
        .dp(DP)
    );

    assign {CG, CF, CE, CD, CC, CB, CA} = seg;
    assign LED = display_value[15:0];
endmodule
