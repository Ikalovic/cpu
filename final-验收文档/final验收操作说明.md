# Final 验收操作说明

## 一、最终验收材料来源

本次 final 验收材料位于：

```text
../final
```

关键文件：

```text
../final/EADME.md
../final/UESTIONS.md
../final/verilog-tests/README.md
../final/verilog-tests/tb/sc_final_tb.v
../final/verilog-tests/tb/pl_final_tb.v
../final/verilog-tests/tests/expected_results.json
../final/verilog-tests/tests/sc/*.dat
../final/verilog-tests/tests/pl/*.dat
```

`EADME.md` 中要求最终验收覆盖单周期 CPU 和流水线 CPU 的扩展指令。`verilog-tests` 目录提供按点测试模板和测试数据，`expected_results.json` 给出每个测试点的期望寄存器值。

## 二、最终要求覆盖的指令

单周期 CPU 需要覆盖：

```text
slt, sltu,
andi, ori, xori,
srli, srai, slli,
slti, sltiu,
bne, bge, bgeu, blt, bltu,
jalr
```

流水线 CPU 需要覆盖：

```text
slt, sltu,
andi, ori, xori,
srli, srai, slli,
slti, sltiu,
beq, bne, bge, bgeu, blt, bltu,
jal, jalr
```

其中 `sltui` 按 RISC-V 标准应理解为 `sltiu`。

## 三、单周期 CPU final 测试

进入单周期目录：

```bash
cd source-sc
```

编译 final 单周期 testbench：

```bash
iverilog -I . -s sc_final_tb -o sc_final.out alu.v ctrl.v dm.v EXT.v im.v NPC.v PC.v sccomp.v SCCPU.v RF.v ../../final/verilog-tests/tb/sc_final_tb.v
```

运行单个测试点：

```bash
vvp sc_final.out +IMEM=../../final/verilog-tests/tests/sc/sc_compare_slt.dat +CYCLES=80
```

输出会打印寄存器快照：

```text
[REG] x10=00000001
[REG] x11=00000000
```

这些结果与 `../final/verilog-tests/tests/expected_results.json` 比对。

## 四、流水线 CPU final 测试

进入流水线目录：

```bash
cd source-pipeline
```

编译 final 流水线 testbench：

```bash
iverilog -I . -s pl_final_tb -o pl_final.out PipelineCPU.v pipe_decode.v pipe_alu.v pipe_branch.v hazard_unit.v dm.v im.v plcomp.v RF.v ../../final/verilog-tests/tb/pl_final_tb.v
```

运行单个测试点：

```bash
vvp pl_final.out +IMEM=../../final/verilog-tests/tests/pl/pl_compare_slt.dat +CYCLES=160
```

注意：`pl_final_tb.v` 默认实例化：

```verilog
plcomp dut(.clk(clk), .rstn(rstn));
```

并读取：

```verilog
dut.U_PLCPU.U_RF.rf[i]
```

因此本工程新增 `source-pipeline/plcomp.v` 作为兼容封装，在内部实例化：

```verilog
PipelineCPU U_PLCPU(...)
```

流水线 CPU 已按模块拆分：

```text
PipelineCPU.v   顶层，负责 PC、流水线寄存器和模块连接
pipe_decode.v   ID 阶段译码和控制信号生成
pipe_alu.v      EX 阶段 ALU 运算
pipe_branch.v   EX 阶段分支、jal、jalr 目标地址和 PC+4 结果
hazard_unit.v   forwarding、load-use stall、flush
```

## 五、一键运行全部 final 测试

在 `lab-6` 根目录执行：

```bash
python3 final-验收文档/run_final_tests.py
```

脚本会执行：

```text
7 个单周期测试
9 个流水线测试
```

并自动比对 `expected_results.json`。

预期结果：

```text
[PASS] sc/sc_compare_slt.dat
[PASS] sc/sc_compare_sltu.dat
[PASS] sc/sc_logic_immediate.dat
[PASS] sc/sc_shift_immediate.dat
[PASS] sc/sc_set_less_immediate.dat
[PASS] sc/sc_branches.dat
[PASS] sc/sc_jalr.dat
[PASS] pl/pl_compare_slt.dat
[PASS] pl/pl_compare_sltu.dat
[PASS] pl/pl_logic_immediate.dat
[PASS] pl/pl_shift_immediate.dat
[PASS] pl/pl_set_less_immediate.dat
[PASS] pl/pl_branches.dat
[PASS] pl/pl_beq.dat
[PASS] pl/pl_jal.dat
[PASS] pl/pl_jalr.dat
Summary: 16/16 passed
```

## 六、现场验收建议顺序

建议按下面顺序操作：

1. 展示 `../final/EADME.md` 中的最终指令范围。
2. 展示 `source-sc`、`source-pipeline` 两个 CPU 工程。
3. 编译并运行单周期 final testbench。
4. 编译并运行流水线 final testbench。
5. 运行 `python3 final-验收文档/run_final_tests.py` 展示 16/16 通过。
6. 展示 `source-pipeline/PipelineCPU.v` 的流水线寄存器和顶层连接。
7. 展示 `pipe_decode.v`、`pipe_alu.v`、`pipe_branch.v` 的模块职责。
8. 展示 `source-pipeline/hazard_unit.v` 的 forwarding、stall、flush。
9. 回答 `final问答准备.md` 中的核心问题。

## 七、注意事项

不要使用过长的绝对路径作为 `+IMEM=` 参数。`sc_final_tb.v` 和 `pl_final_tb.v` 中保存路径的寄存器宽度为 1024 bit，路径过长或包含中文路径时可能被截断，导致 `$readmemh` 没有正确加载程序。建议使用相对路径，例如：

```bash
+IMEM=../../final/verilog-tests/tests/sc/sc_compare_slt.dat
```

如果寄存器输出全部为 0，优先检查 `.dat` 文件是否真正加载成功。
