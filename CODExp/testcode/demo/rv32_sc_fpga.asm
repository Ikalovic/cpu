# Test the RISC-V processor in simulation
# 验证：lui, addi, add, sub, xor, or, and, srl, sra, sll, sw, lw, beq, jal
# 本测试只验证单条指令的功能，不考察转发和冒险检测的功能，所以在相关指令之间添加了足够多的nop指令

#		Assembly	     		Description
main:	lui x5, 0x12345          #x5 <== 0x12345
		lui x6, 0xfffff          #x6 <== 0xfffff
		addi	x12, x0, 4       #x12 <== 0x00000004
		addi	x0, x0, 0        #nop
		addi	x0, x0, 0
        add	x7, x5, x6           #x7 <== 0x12344000
        sub	x8, x5, x6           #x8 <== 0x12346000

        xor	x9, x5, x6           #x9 <== 0xEDCBA000
        or	x10, x5, x6          #x10 <== 0xFFFFF000
        and	x11, x5, x6 	     #x11 <== 0x12345000

        srl	x13, x6, x12	     #x13 <== 0x0FFFFF00
        sra	x14, x6, x12	     #x14 <== 0xFFFFFF00
        sll	x15, x5, x12	     #x15 <== 0x23450000

        sw x10, 0(x12)           #mem[4] <== 0xFFFFF000
        sw x11, 4(x12)           #mem[8] <== 0x12345000
        lw x16, 0(x12)           #x16 <== 0xFFFFF000
        lw x17, 4(x12)           #x17 <== 0x12345000
        beq x11, x16, label1     #not taken
		addi	x0, x0, 0        #nop
		addi	x0, x0, 0        
		addi	x18, x0, 0x18    #x18 <== 0x00000018  
label1: beq x11, x17, label2     #taken
		addi	x0, x0, 0        #nop
		addi	x0, x0, 0        
		addi	x19, x0, 0x19    #x19 <== 0x00000000
label2: addi	x20, x0, 0x20    #x20 <== 0x00000020
        lui  x21, 0xffff0        #x21 <== 0xffff0000
		addi x22, x21, 0x0004    #x22 <== 0xffff0004
        addi x23, x21, 0x000C    #x22 <== 0xffff000C
display:lw   x21, 0x0(x22)       #x21 = status of SWs
        sw   x21, 0x0(x23)       #x21 to seg7
        jal  x0, display         #loop display