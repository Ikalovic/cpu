// 指令存储器：仿真时由 testbench 使用 $readmemh 写入排序程序机器码。
module im(input  [31:2]  addr, output [31:0] dout);
  reg  [31:0] RAM[127:0];

  // 输入地址已经去掉低两位，因此这里按 32 位字寻址。
  assign dout = RAM[addr]; // word aligned
endmodule  
