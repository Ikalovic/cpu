  module RF(   input         clk,
               input         rst,        // 高电平复位
               input         RFWr,       // 寄存器写使能
               input  [4:0]  A1, A2, A3, // A1/A2 为读地址，A3 为写地址
               input  [31:0] WD,         // 写回数据
               output [31:0] RD1, RD2,   // 两个组合读端口
               input  [4:0]  reg_sel,    // 调试选择信号
               output [31:0] reg_data    // 调试输出
           );

    reg [31:0] rf[31:0];
    integer i;

    always @(posedge clk, posedge rst) begin
      if (rst) begin    // 复位时清零 x1-x31，x0 始终保持为 0
        for (i=1; i<32; i=i+1)
            rf[i] <= 0; 
      end
      
      else 
        if (RFWr) begin
          // RISC-V 规定 x0 恒为 0，因此目的寄存器为 x0 时忽略写入。
          if(A3 != 5'b0) begin
              rf[A3] <= WD;
          end
        end
      end

    // 组合读端口；读 x0 时直接返回 0，避免 x0 被数组状态影响。
    assign RD1 = (A1 != 0) ? rf[A1] : 0;
    assign RD2 = (A2 != 0) ? rf[A2] : 0;
    assign reg_data = (reg_sel != 0) ? rf[reg_sel] : 0; 

  endmodule 
