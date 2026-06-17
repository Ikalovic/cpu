# 计算机设计实验 Lab 6 最终交付

本仓库仅保留最终 CPU 实现代码和实验报告材料。

## 目录结构

```text
source-sc/           单周期 RISC-V CPU 最终代码与仿真入口
source-mc/           多周期 RISC-V CPU 最终代码与仿真入口
source-pipeline/     五级流水线 RISC-V CPU 最终代码与仿真入口
nexys-a7/            Nexys A7 开发板封装、显示模块与约束文件
交付的实验报告/       实验报告 PDF、LaTeX 源文件、图片素材和 Overleaf 包
```

## 实验报告

最终 PDF 位于：

```text
交付的实验报告/实验报告.pdf
```

Overleaf 可上传压缩包位于：

```text
交付的实验报告/实验报告-Overleaf.zip
```

LaTeX 主文件位于：

```text
交付的实验报告/report/main.tex
```

## 仿真运行

单周期 CPU：

```bash
cd source-sc
make run
```

多周期 CPU：

```bash
cd source-mc
make run
```

流水线 CPU：

```bash
cd source-pipeline
make run
```

报告中使用的测试截图、代码截图和开发板照片已随报告源文件一并提交。
