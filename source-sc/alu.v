`include "ctrl_encode_def.v"

module alu(A, B, ALUOp, C, Zero);
   input  signed [31:0] A, B;
   input         [4:0]  ALUOp;
   output signed [31:0] C;
   output Zero;  // 分支条件标志：对 B 型指令表示条件是否成立
   
   reg [31:0] C;
   integer    i;
       
   always @(*) begin
      // ALU 是纯组合逻辑，根据控制器给出的 ALUOp 选择运算。
      // 普通算术/逻辑指令直接输出运算结果；分支类 ALUOp 输出条件真假。
      case (ALUOp)
      `ALUOp_lui:  C = B;                                   // lui 的立即数已在 EXT 中左移 12 位
      `ALUOp_add:  C = A + B;                               // add/addi，也用于 lw/sw 地址计算
      `ALUOp_sub:  C = A - B;                               // sub，也用于 beq 判断是否相等
      `ALUOp_bne:  C = (A != B);                            // bne 条件
      `ALUOp_blt:  C = (A < B);                             // 有符号小于
      `ALUOp_bge:  C = (A >= B);                            // 有符号大于等于
      `ALUOp_bltu: C = ($unsigned(A) < $unsigned(B));        // 无符号小于
      `ALUOp_bgeu: C = ($unsigned(A) >= $unsigned(B));       // 无符号大于等于
      `ALUOp_slt:  C = (A < B) ? 32'd1 : 32'd0;             // slt/slti：有符号比较，成立写 1
      `ALUOp_sltu: C = ($unsigned(A) < $unsigned(B)) ? 32'd1 : 32'd0; // sltu/sltiu：无符号比较
      `ALUOp_xor:  C = A ^ B;
      `ALUOp_or:   C = A | B;
      `ALUOp_and:  C = A & B;
      `ALUOp_sll:  C = A << B[4:0];                         // RISC-V 移位量只取低 5 位
      `ALUOp_srl:  C = $unsigned(A) >> B[4:0];              // 逻辑右移，高位补 0
      `ALUOp_sra:  C = A >>> B[4:0];                        // srai/sra：算术右移，保持符号位
      default:     C = A;                                   // 未识别操作保持 A，便于仿真观察
      endcase
   end

   // 对 beq/sub 这类操作，C==0 表示条件成立；
   // 对 bne/blt/bge/bltu/bgeu，C 本身就是 0/1 条件结果，因此用 C!=0。
   assign Zero = (ALUOp == `ALUOp_bne ||
                  ALUOp == `ALUOp_blt ||
                  ALUOp == `ALUOp_bge ||
                  ALUOp == `ALUOp_bltu ||
                  ALUOp == `ALUOp_bgeu) ? (C != 32'b0) : (C == 32'b0);

endmodule
    
