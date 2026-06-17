`include "ctrl_encode_def.v"
module SCCPU(
    input      clk,            // CPU 时钟
    input      reset,          // 高电平复位，复位后 PC 回到 0
    input [31:0]  inst_in,     // 当前 PC 从指令存储器取出的 32 位指令
    input [31:0]  Data_in,     // 数据存储器读出的数据，主要用于 lw 写回
   
    output    mem_w,          // 数据存储器写使能，sw 指令时有效
    output [31:0] PC_out,     // 当前指令地址，送给指令存储器
    output [31:0] Addr_out,   // ALU 计算结果；访存指令中作为数据存储器地址
    output [31:0] Data_out,   // 写入数据存储器的数据，来自 rs2

    input  [4:0] reg_sel,    // 调试端口：选择要观察的寄存器编号
    output [31:0] reg_data   // 调试端口：输出选中寄存器的值
    );

    wire        RegWrite;    // 寄存器堆写使能
    wire [5:0]  EXTOp;       // 立即数扩展类型控制信号
    wire [4:0]  ALUOp;       // ALU 运算类型控制信号
    wire [2:0]  NPCOp;       // 下一条 PC 的选择方式
    wire [1:0]  WDSel;       // 写回寄存器的数据来源选择
    wire        ALUSrc;      // ALU 第二操作数选择：0 选 RD2，1 选立即数
    wire        Zero;        // ALU 条件结果，供分支控制使用
    wire [31:0] NPC;         // 下一条 PC
    wire [4:0]  rs1;         // 源寄存器 1 编号
    wire [4:0]  rs2;         // 源寄存器 2 编号
    wire [4:0]  rd;          // 目的寄存器编号
    wire [6:0]  Op;          // opcode 字段
    wire [6:0]  Funct7;      // funct7 字段
    wire [2:0]  Funct3;      // funct3 字段
    wire [11:0] Imm12;       // 保留的 12 位立即数字段，便于调试观察
    wire [31:0] Imm32;       // 保留的 32 位立即数字段
    wire [19:0] IMM;         // 保留的 20 位立即数字段
    wire [4:0]  A3;          // 保留的写寄存器地址信号
    reg  [31:0] WD;          // 最终写回寄存器堆的数据
    wire [31:0] RD1,RD2;     // 寄存器堆两个读端口输出
    wire [31:0] B;           // ALU 的第二操作数
	
	wire [4:0]  iimm_shamt;
	wire [11:0] iimm,simm,bimm;
	wire [19:0] uimm,jimm;
	wire [31:0] immout;
    wire [31:0] aluout;
    
    // ALU 结果直接作为访存地址输出；对非访存指令也可用于调试观察执行结果。
    assign Addr_out=aluout;
	// I 型算术、lw、sw、jalr 等指令使用立即数作为 ALU 第二操作数。
	assign B = (ALUSrc) ? immout : RD2;
	// sw 写内存的数据固定来自 rs2。
	assign Data_out = RD2;
	
	// 从 32 位指令中拆出各类立即数字段。真正的符号扩展由 EXT 模块完成。
	assign iimm=inst_in[31:20];
	assign simm={inst_in[31:25],inst_in[11:7]};
	assign uimm=inst_in[31:12];
	assign bimm={inst_in[31],inst_in[7],inst_in[30:25],inst_in[11:8]};
	assign jimm={inst_in[31],inst_in[19:12],inst_in[20],inst_in[30:21]};

    // 指令译码字段，控制器和寄存器堆都依赖这些字段。
    assign Op = inst_in[6:0];
    assign Funct7 = inst_in[31:25];
    assign Funct3 = inst_in[14:12];
    assign rs1 = inst_in[19:15];
    assign rs2 = inst_in[24:20];
    assign rd = inst_in[11:7];
    assign Imm12 = inst_in[31:20];
    assign IMM = inst_in[31:12];
   
   // 控制器：根据 opcode/funct 字段和 ALU 条件结果生成数据通路控制信号。
	ctrl U_ctrl(
		.Op(Op), .Funct7(Funct7), .Funct3(Funct3), .Zero(Zero), 
		.RegWrite(RegWrite), .MemWrite(mem_w),
		.EXTOp(EXTOp), .ALUOp(ALUOp), .NPCOp(NPCOp), 
		.ALUSrc(ALUSrc), .WDSel(WDSel)
	);
    // PC 寄存器：在时钟上升沿装入 NPC。
	PC  U_PC(.clk(clk), .rst(reset), .NPC(NPC), .PC(PC_out) );
    // NPC 生成器：负责 PC+4、分支、jal、jalr 四类下一地址。
	NPC U_NPC(.PC(PC_out), .NPCOp(NPCOp), .IMM(immout), .RS1(RD1), .NPC(NPC));
    // 立即数扩展：把不同格式的立即数字段统一扩展为 32 位。
	EXT U_EXT(
		.iimm(iimm), .simm(simm), .bimm(bimm), .uimm(uimm), .jimm(jimm),
		.EXTOp(EXTOp), .immout(immout)
	);
    // 寄存器堆：两个组合读端口，一个时序写端口；x0 恒为 0。
	RF U_RF(
		.clk(clk), .rst(reset),
		.RFWr(RegWrite), 
		.A1(rs1), .A2(rs2), .A3(rd), 
		.WD(WD), 
		.RD1(RD1), .RD2(RD2),
		.reg_sel(reg_sel),
		.reg_data(reg_data)
	);
// ALU：执行算术、逻辑、移位、比较和分支条件计算。
	alu U_alu(.A(RD1), .B(B), .ALUOp(ALUOp), .C(aluout), .Zero(Zero));

// 写回多路选择器：
// 1. 普通算术逻辑指令写回 ALU 结果；
// 2. lw 写回数据存储器读出值；
// 3. jal/jalr 写回 PC+4 作为返回地址。
always @*
begin
	case(WDSel)
		`WDSel_FromALU: WD<=aluout;
		`WDSel_FromMEM: WD<=Data_in;
        `WDSel_FromPC:  WD<=PC_out+4;
        default: WD<=aluout;
	endcase
end

endmodule  
