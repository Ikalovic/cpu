`include "ctrl_encode_def.v"

module ctrl(Op, Funct7, Funct3, Zero,
            RegWrite, MemWrite,
            EXTOp, ALUOp, NPCOp,
            ALUSrc, WDSel
            );

   input  [6:0] Op;
   input  [6:0] Funct7;
   input  [2:0] Funct3;
   input        Zero;

   output reg       RegWrite;
   output reg       MemWrite;
   output reg [5:0] EXTOp;
   output reg [4:0] ALUOp;
   output reg [2:0] NPCOp;
   output reg       ALUSrc;
   output reg [1:0] WDSel;

   always @(*) begin
      // 先给所有控制信号默认值，避免组合逻辑产生锁存器。
      // 默认行为是不写寄存器、不写内存、PC 顺序加 4、ALU 不执行特殊操作。
      RegWrite = 1'b0;
      MemWrite = 1'b0;
      EXTOp    = 6'b0;
      ALUOp    = `ALUOp_nop;
      NPCOp    = `NPC_PLUS4;
      ALUSrc   = 1'b0;
      WDSel    = `WDSel_FromALU;

      case (Op)
      7'b0110111: begin // lui
         // lui：把 U 型立即数放到高 20 位，低 12 位补 0 后写入 rd。
         RegWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_UTYPE;
         ALUOp    = `ALUOp_lui;
      end

      7'b0110011: begin // R-type
         // R 型指令：两个源操作数都来自寄存器堆，结果写回 rd。
         // final 测试中的 slt/sltu 在这里译码：
         // slt 使用 funct3=010、有符号比较；sltu 使用 funct3=011、无符号比较。
         RegWrite = 1'b1;
         case ({Funct7, Funct3})
         {7'b0000000, 3'b000}: ALUOp = `ALUOp_add;
         {7'b0100000, 3'b000}: ALUOp = `ALUOp_sub;
         {7'b0000000, 3'b010}: ALUOp = `ALUOp_slt;
         {7'b0000000, 3'b011}: ALUOp = `ALUOp_sltu;
         {7'b0000000, 3'b100}: ALUOp = `ALUOp_xor;
         {7'b0000000, 3'b110}: ALUOp = `ALUOp_or;
         {7'b0000000, 3'b111}: ALUOp = `ALUOp_and;
         {7'b0000000, 3'b001}: ALUOp = `ALUOp_sll;
         {7'b0000000, 3'b101}: ALUOp = `ALUOp_srl;
         {7'b0100000, 3'b101}: ALUOp = `ALUOp_sra;
         default: begin
            RegWrite = 1'b0;
            ALUOp = `ALUOp_nop;
         end
         endcase
      end

      7'b0010011: begin // I-type arithmetic
         // I 型算术逻辑指令：rs1 与符号扩展后的立即数进入 ALU。
         // final 测试中的 andi/ori/xori/slti/sltiu/slli/srli/srai 均属于本类。
         // slli/srli/srai 的立即数字段低 5 位作为 shamt，funct7 区分逻辑右移和算术右移。
         RegWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_ITYPE;
         case (Funct3)
         3'b000: ALUOp = `ALUOp_add;  // addi
         3'b010: ALUOp = `ALUOp_slt;  // slti
         3'b011: ALUOp = `ALUOp_sltu; // sltiu
         3'b100: ALUOp = `ALUOp_xor;  // xori
         3'b110: ALUOp = `ALUOp_or;   // ori
         3'b111: ALUOp = `ALUOp_and;  // andi
         3'b001: ALUOp = (Funct7 == 7'b0000000) ? `ALUOp_sll : `ALUOp_nop;
         3'b101: ALUOp = (Funct7 == 7'b0100000) ? `ALUOp_sra : `ALUOp_srl;
         default: begin
            RegWrite = 1'b0;
            ALUOp = `ALUOp_nop;
         end
         endcase
      end

      7'b0000011: begin // lw
         // lw：地址 = rs1 + imm，读出的内存数据写回 rd。
         RegWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_ITYPE;
         ALUOp    = `ALUOp_add;
         WDSel    = `WDSel_FromMEM;
      end

      7'b0100011: begin // sw
         // sw：地址 = rs1 + imm，写入内存的数据来自 rs2，不写寄存器。
         MemWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_STYPE;
         ALUOp    = `ALUOp_add;
      end

      7'b1100011: begin // branches
         // B 型分支：EXT 产生带符号偏移，ALU 判断条件是否成立。
         // Zero 在这里表示“是否跳转”，成立时 NPC 选择 PC + imm。
         // final 测试覆盖 beq/bne/blt/bge/bltu/bgeu；这些指令都不写寄存器。
         EXTOp = `EXT_CTRL_BTYPE;
         case (Funct3)
         3'b000: begin ALUOp = `ALUOp_sub;  NPCOp = Zero ? `NPC_BRANCH : `NPC_PLUS4; end // beq
         3'b001: begin ALUOp = `ALUOp_bne;  NPCOp = Zero ? `NPC_BRANCH : `NPC_PLUS4; end // bne
         3'b100: begin ALUOp = `ALUOp_blt;  NPCOp = Zero ? `NPC_BRANCH : `NPC_PLUS4; end // blt
         3'b101: begin ALUOp = `ALUOp_bge;  NPCOp = Zero ? `NPC_BRANCH : `NPC_PLUS4; end // bge
         3'b110: begin ALUOp = `ALUOp_bltu; NPCOp = Zero ? `NPC_BRANCH : `NPC_PLUS4; end // bltu
         3'b111: begin ALUOp = `ALUOp_bgeu; NPCOp = Zero ? `NPC_BRANCH : `NPC_PLUS4; end // bgeu
         default: begin ALUOp = `ALUOp_nop; NPCOp = `NPC_PLUS4; end
         endcase
      end

      7'b1101111: begin // jal
         // jal：无条件跳转到 PC + J 型立即数，同时把 PC+4 写入 rd。
         RegWrite = 1'b1;
         EXTOp    = `EXT_CTRL_JTYPE;
         NPCOp    = `NPC_JUMP;
         WDSel    = `WDSel_FromPC;
      end

      7'b1100111: begin // jalr
         // jalr：跳转目标为 rs1 + I 型立即数，返回地址 PC+4 写入 rd。
         // 当 rd=x0 时，RF 会忽略写 x0，所以 jalr x0,x1,0 可作为函数返回。
         RegWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_ITYPE;
         ALUOp    = `ALUOp_add;
         NPCOp    = `NPC_JALR;
         WDSel    = `WDSel_FromPC;
      end

      default: begin
         RegWrite = 1'b0;
         MemWrite = 1'b0;
      end
      endcase
   end
endmodule
