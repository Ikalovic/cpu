# Test the RISC-V processor in simulation
# 待验证：lui, addi, add，sub，xor, or, and, srl, sra, sll, sw, lw
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
		addi	x0, x0, 0        #nop
		addi	x0, x0, 0        
		addi	x0, x0, 0
        add     x18, x16, x17    #x18 <== 0x12344000

