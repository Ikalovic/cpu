# Final 测试记录

## 一、测试环境

```text
工程目录：lab-6
仿真工具：iverilog + vvp
测试来源：../final/verilog-tests
```

## 二、编译命令

单周期 CPU：

```bash
cd source-sc
iverilog -I . -s sc_final_tb -o sc_final.out alu.v ctrl.v dm.v EXT.v im.v NPC.v PC.v sccomp.v SCCPU.v RF.v ../../final/verilog-tests/tb/sc_final_tb.v
```

流水线 CPU：

```bash
cd source-pipeline
iverilog -I . -s pl_final_tb -o pl_final.out PipelineCPU.v pipe_decode.v pipe_alu.v pipe_branch.v hazard_unit.v dm.v im.v plcomp.v RF.v ../../final/verilog-tests/tb/pl_final_tb.v
```

## 三、单周期测试结果

| 测试文件 | 覆盖指令 | 结果 |
|---|---|---|
| `sc/sc_compare_slt.dat` | `slt` | PASS |
| `sc/sc_compare_sltu.dat` | `sltu` | PASS |
| `sc/sc_logic_immediate.dat` | `andi, ori, xori` | PASS |
| `sc/sc_shift_immediate.dat` | `slli, srli, srai` | PASS |
| `sc/sc_set_less_immediate.dat` | `slti, sltiu` | PASS |
| `sc/sc_branches.dat` | `bne, bge, bgeu, blt, bltu` | PASS |
| `sc/sc_jalr.dat` | `jalr` | PASS |

单周期测试结论：

```text
7/7 passed
```

## 四、流水线测试结果

| 测试文件 | 覆盖指令或行为 | 结果 |
|---|---|---|
| `pl/pl_compare_slt.dat` | `slt` | PASS |
| `pl/pl_compare_sltu.dat` | `sltu` | PASS |
| `pl/pl_logic_immediate.dat` | `andi, ori, xori` | PASS |
| `pl/pl_shift_immediate.dat` | `slli, srli, srai` | PASS |
| `pl/pl_set_less_immediate.dat` | `slti, sltiu` | PASS |
| `pl/pl_branches.dat` | `bne, bge, bgeu, blt, bltu` | PASS |
| `pl/pl_beq.dat` | `beq` | PASS |
| `pl/pl_jal.dat` | `jal` | PASS |
| `pl/pl_jalr.dat` | `jalr` | PASS |

流水线测试结论：

```text
9/9 passed
```

## 五、总结果

```text
Summary: 16/16 passed
```

## 六、已做的适配

为了适配 `../final/verilog-tests/tb/pl_final_tb.v`，新增了：

```text
source-pipeline/plcomp.v
```

该文件只做接口兼容，不改变流水线 CPU 主体。它将现有 `PipelineCPU` 实例化为：

```verilog
PipelineCPU U_PLCPU(...)
```

这样 final testbench 可以通过：

```verilog
dut.U_PLCPU.U_RF.rf[i]
```

读取流水线 CPU 的寄存器堆。

流水线 CPU 已整理为多模块结构：

```text
PipelineCPU.v   顶层和流水线寄存器
pipe_decode.v   译码和控制信号生成
pipe_alu.v      ALU 运算
pipe_branch.v   分支、jal、jalr 的目标地址与控制判断
hazard_unit.v   冒险处理
```
