# 测试1：
# 待验证：有条件与无条件分支指令后误读的指令是否能够正确清空，没有delay slot
# 不考虑分支指令与前面指令之间的数据依赖，所以添加了必要的nop指令

main:	addi x5, x0, 1          #x5 = 1, 00100293
		addi x6, x0, 1          #x6 = 1, 00100313
		addi x7, x0, 0		    #x7 = 0, 00000393
		addi x8, x0, 0          #x8 = 0, 00000413
		addi x0, x0, 0          #00000013
		addi x0, x0, 0          #00000013
		beq  x5, x6, br1        #00628863  
#跳转，EX级计算地址，分支决策，MEM级调入目标指令，需清除2条指令
		addi x8, x8, 1			#should flush--ID_EX, 00140413 
		addi x9, x9, 1          #should flush--IF_ID, 00148493
		jal  x0, end            #0140006F
br1:	addi x7, x7, 1			#x7 = 1, 00138393
		jal  x0, end            #00C0006F 
#跳转，EX级计算地址，MEM级调入目标指令，需清除2条指令
		addi x8, x8, 1			#should flush, 00140413
		addi x9, x9, 1          #should flush, 00148493
end:	addi x7, x7, 1          #x7 = 2, x8 = 0, x9 = 0, 00138393

