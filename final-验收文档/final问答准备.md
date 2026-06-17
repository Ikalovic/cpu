# Final 问答准备

本文件根据 `../final/UESTIONS.md` 和本工程新增代码整理，面向现场提问。

## 一、单周期 CPU

### 1. `add x3, x1, x2` 如何执行？

`add` 是 R 型指令。CPU 从指令中取出 `rs1=x1`、`rs2=x2`、`rd=x3`。寄存器堆读出 `x1` 和 `x2` 后，ALU 执行加法，结果通过写回通路写入 `x3`。控制信号中 `RegWrite=1`，`ALUSrc=0`，`WDSel=ALU`，`MemWrite=0`，下一条 PC 为 `PC+4`。

### 2. `slt` 和 `sltu` 的区别是什么？

`slt` 使用有符号比较，判断 `$signed(A) < $signed(B)`。`sltu` 使用无符号比较，判断 `$unsigned(A) < $unsigned(B)`。两者都把比较结果写回目的寄存器，成立写 `1`，不成立写 `0`。

### 3. I 型逻辑立即数如何实现？

`andi`、`ori`、`xori` 都是 I 型指令。CPU 读出 `rs1`，将 12 位立即数符号扩展为 32 位，ALU 分别执行按位与、按位或、按位异或，结果写回 `rd`。

### 4. 移位指令为什么只用低 5 位？

RV32I 的寄存器宽度为 32 位，合法移位范围是 0 到 31，因此移位量只需要 5 位。`slli`、`srli`、`srai` 在 ALU 中使用 `B[4:0]` 作为移位量。

### 5. `jalr` 为什么要清零最低位？

RISC-V 规定 `jalr` 的目标地址为：

```text
(rs1 + imm) & 0xfffffffe
```

最低位清零可以保证跳转目标按规范对齐，同时允许最低位作为辅助信息位。函数返回常用 `jalr x0, x1, 0`，因为 `x1` 保存了之前 `jal` 写入的返回地址。

## 二、多周期 CPU

### 1. 多周期 CPU 和单周期 CPU 的区别是什么？

单周期 CPU 一条指令在一个时钟周期内完成所有阶段。多周期 CPU 将一条指令拆成 `FETCH`、`DECODE`、`EXEC`、`MEM`、`WB` 等状态，每个时钟周期只做其中一部分工作。

### 2. 多周期 CPU 为什么不需要流水线冒险处理？

多周期 CPU 同一时间只处理一条指令。下一条指令要等当前指令完成后才开始取指，因此不存在多条指令重叠执行，也不会出现流水线中的数据冒险、结构冒险或控制冒险。

### 3. `ir`、`mdr`、`aluout_reg` 的作用是什么？

`ir` 保存当前指令，保证多周期执行时后续状态仍能使用同一条指令。`mdr` 保存数据存储器读出的值，供写回阶段使用。`aluout_reg` 保存 ALU 结果或 `jal/jalr` 返回地址，供后续阶段写回或访存使用。

## 三、流水线 CPU

### 1. 五级流水线每一级做什么？

五级流水线包括：

```text
IF  ：取指
ID  ：译码和读寄存器
EX  ：ALU 运算、地址计算、分支判断
MEM ：访问数据存储器
WB  ：写回寄存器
```

阶段之间通过 `IF/ID`、`ID/EX`、`EX/MEM`、`MEM/WB` 流水线寄存器传递指令、数据和控制信号。

### 2. 流水线 CPU 和多周期 CPU 最大区别是什么？

多周期 CPU 是一条指令分多拍执行，同一时刻 CPU 中只有一条有效指令。流水线 CPU 是多条指令重叠执行，同一时刻可以有不同指令分别处在 IF、ID、EX、MEM、WB 阶段。

### 3. 为什么流水线 CPU 需要冒险处理？

因为多条指令重叠执行，后一条指令可能在前一条指令写回之前就读取相关寄存器，形成数据冒险。分支或跳转指令改变 PC 时，顺序路径上的指令可能已经被取入流水线，形成控制冒险。硬件资源同时被多个阶段使用时，还可能出现结构冒险。

### 4. `hazard_unit.v` 做什么？

`hazard_unit.v` 负责三类控制：

```text
forwarding：从 EX/MEM 或 MEM/WB 转发数据到 EX 阶段。
stall：检测 load-use 冒险，暂停 PC 和 IF/ID。
flush：branch、jal、jalr 改变 PC 时清除错误路径指令。
```

### 5. 流水线 CPU 为什么拆成多个模块？

当前流水线 CPU 的模块职责如下：

```text
PipelineCPU.v 负责顶层连接、PC 更新和四组流水线寄存器推进。
pipe_decode.v 负责 opcode/funct3/funct7 译码并生成控制信号。
pipe_alu.v 负责 EX 阶段算术、逻辑、比较和移位。
pipe_branch.v 负责分支条件、jal/jalr 目标地址和 PC+4。
hazard_unit.v 负责 forwarding、stall 和 flush。
```

这样结构与单周期 CPU 中的 `ctrl.v`、`alu.v`、`NPC.v` 类似，验收时可以按模块分别解释。

### 6. 什么是 load-use 冒险？

典型例子：

```asm
lw  x1, 0(x2)
add x3, x1, x4
```

`lw` 读出的数据要到 MEM 阶段结束才有效，但下一条 `add` 在紧接着的 EX 阶段就需要 `x1`。这时单纯 forwarding 来不及，需要暂停一拍并向流水线插入 bubble。

### 7. `forward_a` 和 `forward_b` 如何选择？

`forward_a` 和 `forward_b` 控制 ALU 两个输入端的数据来源：

```text
00：使用 ID/EX 中保存的寄存器读数
10：从 EX/MEM 阶段转发 ALU 结果
01：从 MEM/WB 阶段转发写回数据
```

这样连续相关指令不必等待写回阶段完成。

### 8. 分支和跳转如何处理？

本工程流水线在 EX 阶段确定 `branch/jal/jalr` 是否改变 PC。如果改变 PC，则更新 PC 为跳转目标，并对已经取入的错误路径指令执行 flush，使其变成无效指令。

### 8. `jal` 和 `jalr` 的写回值是什么？

`jal` 和 `jalr` 都把当前指令的下一条地址 `PC+4` 写回 `rd`，作为返回地址。`jal` 的目标地址是 `PC + J 型立即数`，`jalr` 的目标地址是 `(rs1 + I 型立即数) & 0xfffffffe`。

## 四、最终测试相关问题

### 1. 为什么新增 `plcomp.v`？

`../final/verilog-tests/tb/pl_final_tb.v` 默认实例化 `plcomp`，并通过 `dut.U_PLCPU.U_RF.rf[i]` 读取寄存器。本工程原流水线顶层是 `pipecomp`，CPU 实例名是 `U_PIPECPU`。为了不改老师给的 testbench，新增 `plcomp.v` 作为兼容封装，并在内部把 `PipelineCPU` 命名为 `U_PLCPU`。

### 2. 为什么 final 测试要拆成很多 `.dat`？

拆成多个小测试点可以定位具体错误。例如 `sc_compare_slt.dat` 只测 `slt`，`sc_shift_immediate.dat` 只测移位立即数，`pl_jalr.dat` 重点测跳转返回和流水线冲刷。这样比只用一个大程序更容易评分和排错。

### 3. 如果寄存器全是 0 怎么排查？

优先检查 `$readmemh` 是否成功加载 `.dat`。本工程路径包含中文，过长的绝对路径可能超过 testbench 中 `imem_file` 寄存器宽度，导致路径被截断。建议使用相对路径，例如：

```text
+IMEM=../../final/verilog-tests/tests/sc/sc_compare_slt.dat
```
