`include "ctrl_encode_def.v"
module EXT( 
    input	[11:0]			iimm, // I 型立即数字段 instr[31:20]
	input	[11:0]			simm, // S 型立即数字段 {instr[31:25], instr[11:7]}
	input	[11:0]			bimm, // B 型立即数字段，最低位 0 在本模块补齐
	input	[19:0]			uimm, // U 型立即数字段 instr[31:12]
	input	[19:0]			jimm, // J 型立即数字段，最低位 0 在本模块补齐
	input	[5:0]			EXTOp, // 控制器指定当前指令需要哪一种扩展方式

	output	reg [31:0] 	    immout
	);

always  @(*)
	 case (EXTOp)
		`EXT_CTRL_ITYPE:	immout <= {{20{iimm[11]}}, iimm[11:0]};       // I 型：12 位符号扩展
		`EXT_CTRL_STYPE:	immout <= {{20{simm[11]}}, simm[11:0]};       // S 型：12 位符号扩展
		`EXT_CTRL_BTYPE:    immout <= {{19{bimm[11]}}, bimm[11:0], 1'b0}; // B 型：符号扩展并左移 1 位
		`EXT_CTRL_UTYPE:	immout <= {uimm[19:0], 12'b0};                // U 型：高 20 位立即数，低 12 位补 0
		`EXT_CTRL_JTYPE:	immout <= {{21{jimm[19]}}, jimm[19:0], 1'b0}; // J 型：符号扩展并左移 1 位
		default:	        immout <= 32'b0;                              // 未使用立即数时输出 0
	 endcase
       
endmodule
