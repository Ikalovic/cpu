# 测试3：J和B指令都是在EX级进行条件判断和目标地址计算，不提前分支。
# Test the RISC-V processor in simulation
# 已经能正确执行：addi, lw, sw, beq，jal, jalr
# 待验证：能否正确处理需要停顿的数据依赖: load-use, arith-beq//NO, load-beq, arith-jal//no, load-jalr，//load-jal也是同样需要阻塞1周期

main:	addi x5, x0, 5     #x5 = 5
		sw	 x5, 0(x0)		#mem[0] = 5
		lw	 x6, 0(x0)    #x6 = 5
		addi x7, x6, 2		#load-use data hazard, stall 1 cycle, x7 = 7
		addi x8, x0, 7      #x8 = 7
		beq x7, x8, br1 	#jump, arith-beq data hazard , forward M -EX
		addi x10, x0, 10	#should flush , x10=0
br1ret:  lw   x7, 0(x0)		#should flush,  x7 = 5
		beq  x5, x7, br2 	#jump , lw-beq data hazard, stall 1 cycle,and forward WB -EX
		addi x10, x0, 10	#should flush, x10=0
br2ret:  jal  x0, end      #should flush, no stall

br1:	    addi x11, x0, 0x1c  # br1ret, x11=0x1c
        jalr x0, x11, 0      #no stall, forward M -EX

br2:	    addi x12, x0, 40   #x12=40
        sw   x12, 8(x0)  #forward WB -M 
        lw   x13, 8(x0)   #x13=40
        jalr  x0, x13, 0	#jalr x0, br2ret //stall 1 cycle,and forward WB -EX

end:	    addi x9, x5, 0x100  #x9=0x105