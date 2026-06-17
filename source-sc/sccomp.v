`include "ctrl_encode_def.v"
module sccomp(clk, rstn, reg_sel, reg_data);
   input          clk, rstn;       // CPU 时钟和复位
   input [4:0]    reg_sel;         // 调试选择：查看指定寄存器
   output [31:0]  reg_data;        // 调试输出：指定寄存器的值
   
   wire [31:0]    instr;
   wire [31:0]    PC;
   wire           MemWrite;
   wire [31:0]    dm_addr, dm_din, dm_dout;
   
   wire reset;
   assign reset = rstn;
   
   // 单周期 CPU：一拍内完成取指、译码、执行、访存和写回。
   SCCPU U_SCCPU(
         .clk(clk),
         .reset(reset),
         .inst_in(instr),             // 从指令存储器送入 CPU 的当前指令
         .Data_in(dm_dout),           // 数据存储器读出的数据，供 lw 写回
         .mem_w(MemWrite),            // sw 时拉高的数据存储器写使能
         .PC_out(PC),                 // 当前 PC，送给指令存储器
         .Addr_out(dm_addr),          // ALU 输出，作为数据存储器地址
         .Data_out(dm_din),           // sw 写入数据存储器的数据
         .reg_sel(reg_sel),
         .reg_data(reg_data)
         );
   
   // 数据存储器：连接 lw/sw 的地址、写数据、读数据和写使能。
   dm    U_DM(
         .clk(clk),
         .DMWr(MemWrite),
         .addr(dm_addr),
         .din(dm_din),
         .dout(dm_dout)
         );
         
  // 指令存储器按字寻址，因此使用 PC[31:2] 去掉低两位字节偏移。
   im    U_imem ( 
         .addr(PC[31:2]),
         .dout(instr)
         );
  
endmodule




















