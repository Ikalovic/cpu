# Lab 6 Final 验收文档包

本目录用于集中存放最终验收相关说明。材料来源包括当前 `lab-6` 工程和 `../final` 目录下的最终测试模板。

## 文件说明

```text
README.md              本目录说明
final验收操作说明.md   按最终验收流程整理的操作步骤
final测试记录.md       已完成测试、命令和结果记录
final问答准备.md       根据 ../final/UESTIONS.md 和新增代码整理的答辩提纲
run_final_tests.py     一键复跑 final 16 个按点测试并比对 expected_results.json
```

## 当前完成状态

当前工程已完成：

```text
单周期 CPU final 指令测试：7/7 通过
流水线 CPU final 指令测试：9/9 通过
总计：16/16 通过
```

已新增兼容 final 流水线 testbench 的文件：

```text
source-pipeline/plcomp.v
```

原因是 `../final/verilog-tests/tb/pl_final_tb.v` 默认实例化 `plcomp`，并访问 `dut.U_PLCPU.U_RF.rf[i]`。当前流水线工程原本使用 `pipecomp` 和 `U_PIPECPU`，因此新增 `plcomp.v` 作为兼容封装，不改变已有流水线 CPU 实现。

流水线 CPU 已整理为多模块结构：

```text
source-pipeline/PipelineCPU.v   顶层、PC 和四组流水线寄存器
source-pipeline/pipe_decode.v   ID 阶段译码和控制信号生成
source-pipeline/pipe_alu.v      EX 阶段 ALU 运算
source-pipeline/pipe_branch.v   EX 阶段分支、jal、jalr 目标地址和 PC+4
source-pipeline/hazard_unit.v   forwarding、load-use stall、flush
```

## 快速复跑

在 `lab-6` 根目录执行：

```bash
python3 final-验收文档/run_final_tests.py
```

预期输出末尾：

```text
Summary: 16/16 passed
```
