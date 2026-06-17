module mccomp(clk, rstn, reg_sel, reg_data);
   input          clk, rstn;      // CPU 时钟和复位
   input  [4:0]   reg_sel;        // 调试选择：查看指定寄存器
   output [31:0]  reg_data;       // 调试输出：指定寄存器的值

   wire [31:0] instr;
   wire [31:0] PC;
   wire        MemWrite;
   wire [31:0] dm_addr, dm_din, dm_dout;

   // 多周期 CPU 顶层：输出 PC 取指，输出访存地址/数据控制数据存储器。
   MCCPU U_MCCPU(
      .clk(clk),
      .reset(rstn),
      .inst_in(instr),
      .Data_in(dm_dout),
      .mem_w(MemWrite),
      .PC_out(PC),
      .Addr_out(dm_addr),
      .Data_out(dm_din),
      .reg_sel(reg_sel),
      .reg_data(reg_data)
   );

   // 数据存储器：连接 lw/sw 的地址、写数据、读数据和写使能。
   dm U_DM(
      .clk(clk),
      .DMWr(MemWrite),
      .addr(dm_addr),
      .din(dm_din),
      .dout(dm_dout)
   );

   // 指令存储器按字寻址，因此使用 PC[31:2] 去掉低两位字节偏移。
   im U_imem(
      .addr(PC[31:2]),
      .dout(instr)
   );
endmodule
