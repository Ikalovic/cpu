`include "ctrl_encode_def.v"
// 数据存储器：128 个 32 位字，供 lw/sw 访问。
module dm(clk, DMWr, addr, din, dout);
   input          clk;
   input          DMWr;
   input  [31:0]  addr;
   input  [31:0]  din;
   output reg [31:0]  dout;
   
   reg [31:0] dmem[127:0];
   
   // 写操作在时钟上升沿发生，符合同步 RAM 的常见写入模型。
   always @(posedge clk)
      if (DMWr) begin
         // addr[8:2] 表示按字寻址；例如 0x180 对应下标 96。
         dmem[addr[8:2]] <= din;
      end
   
     // 读操作为组合读，lw 指令可在同一周期得到 dout。
     always @(*) begin
         dout <= dmem[addr[8:2]];
     end
     
endmodule    
