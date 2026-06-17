# 实验报告交付说明

报告入口文件：

```text
交付的实验报告/report/main.tex
```

已安装 `xelatex`，并已在本地使用 XeLaTeX 编译通过。生成的 PDF 位于：

```text
交付的实验报告/实验报告.pdf
```

如需在 Overleaf 修改，把 `实验报告-Overleaf.zip` 上传到 Overleaf 后，主文件选择 `main.tex`，编译器选择 XeLaTeX。

正式提交前需要替换报告中的占位内容：

```text
1. 首页的单位、姓名、学号。
2. GitHub 链接。
3. 测试1：单周期 CPU 30 条指令测试截图。
4. 测试2：流水线 CPU 30 条指令测试截图。
5. 测试3：单周期 CPU 学号排序截图。
6. 测试4：流水线 CPU 学号排序截图。
7. 测试5：开发板运行照片或视频截图。
8. diff 网页顶部统计截图。
```

已写入报告的本地验证结果：

```text
python3 final-验收文档/run_final_tests.py
Summary: 16/16 passed

source-sc make run
[PASS] lab-6 sid sorting simulation passed.

source-mc make run
[PASS] lab-6 multi-cycle sid sorting simulation passed.

source-pipeline make run
[PASS] lab-6 pipeline sid sorting simulation passed.
```

本地 LaTeX 编译命令：

```text
cd 交付的实验报告/report
xelatex -interaction=nonstopmode main.tex
xelatex -interaction=nonstopmode main.tex
```
