`include "ctrl_encode_def.v"

module NPC( PC, NPCOp, IMM, RS1, NPC );  // 下一条 PC 生成模块
   input  [31:0] PC;        // 当前指令地址
   input  [2:0]  NPCOp;     // 下一条 PC 的选择方式
   input  [31:0] IMM;       // 已经扩展好的分支/跳转立即数
   input  [31:0] RS1;       // jalr 使用的基址寄存器值
   output reg [31:0] NPC;   // 下一条指令地址
   
   wire [31:0] PCPLUS4;
   assign PCPLUS4 = PC + 4; // 默认顺序执行地址
   
   always @(*) begin
      case (NPCOp)
          `NPC_PLUS4:  NPC = PCPLUS4;                  // 普通指令：PC 顺序加 4
          `NPC_BRANCH: NPC = PC+IMM;                   // B 型分支：当前 PC 加分支偏移
          `NPC_JUMP:   NPC = PC+IMM;                   // jal：当前 PC 加 J 型偏移
          `NPC_JALR:   NPC = (RS1 + IMM) & 32'hffff_fffe; // jalr：目标地址最低位清 0
          default:     NPC = PCPLUS4;
      endcase
   end 
   
endmodule
