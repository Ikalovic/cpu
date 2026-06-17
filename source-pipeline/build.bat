@echo off
setlocal

set OUT=pipe_cpu_sim.out
set SRC=PipelineCPU.v pipe_decode.v pipe_alu.v pipe_branch.v hazard_unit.v dm.v im.v pipecomp.v pipecomp_tb.v RF.v

if "%1"=="clean" goto clean
if "%1"=="build" goto build
if "%1"=="run" goto run
if "%1"=="wave" goto wave
goto run

:build
iverilog -I . -s pipecomp_tb -o %OUT% %SRC%
goto end

:run
call :build
if errorlevel 1 goto end
vvp %OUT%
goto end

:wave
call :run
if exist pipe_cpu_sid_sort.vcd gtkwave pipe_cpu_sid_sort.vcd
goto end

:clean
if exist %OUT% del %OUT%
if exist pipe_cpu_sid_sort.vcd del pipe_cpu_sid_sort.vcd
goto end

:end
endlocal
