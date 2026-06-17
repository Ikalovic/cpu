module plcomp(clk, rstn);
    input clk;
    input rstn;

    wire [31:0] instr;
    wire [31:0] PC;
    wire        MemWrite;
    wire [31:0] dm_addr, dm_din, dm_dout;

    PipelineCPU U_PLCPU(
        .clk(clk),
        .reset(rstn),
        .inst_in(instr),
        .Data_in(dm_dout),
        .mem_w(MemWrite),
        .PC_out(PC),
        .Addr_out(dm_addr),
        .Data_out(dm_din),
        .reg_sel(5'd0),
        .reg_data()
    );

    dm U_DM(
        .clk(clk),
        .DMWr(MemWrite),
        .addr(dm_addr),
        .din(dm_din),
        .dout(dm_dout)
    );

    im U_imem(
        .addr(PC[31:2]),
        .dout(instr)
    );
endmodule
