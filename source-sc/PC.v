module PC( clk, rst, NPC, PC );
  input              clk;   // CPU 时钟
  input              rst;   // 高电平复位
  input       [31:0] NPC;   // 下一条指令地址
  output reg  [31:0] PC;    // 当前指令地址
 
   always @(posedge clk, posedge rst) begin
     // 复位后从地址 0 开始取指；否则每个时钟装入 NPC 模块计算出的下一地址。
     if (rst) 
        PC <= 32'h0000_0000;
     else 
        PC <= NPC;
   end 
 endmodule
