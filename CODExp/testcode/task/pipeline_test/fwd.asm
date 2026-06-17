#测试0：仅仅测试转发MEM-->EX, WB-->EX, WB-->MEM
main:	addi x5, x0, 1		#0x0: 00100293,  x5 = 1
	addi x6, x0, 2		#0x4: 00200313,  x6 = 2
	add  x7, x5, x6	#EX rs1 from WB, rs2 from MEM, x7 = 3, 0x8: 006283b3
	add  x8, x7, x6	#EX rs1 from MEM, rs2 from WB, x8 = 5, 0xc: 00638433
	sw  x8, 0(x0)		#MEM write data from WB's arith op, mem[0] = 5, 0x10: 00802023
	lw  x9, 0(x0)		#0x14: 00002483,  x9 = 5