@echo off
setlocal

rem Lab-6 multi-cycle CPU sid sorting simulation script for Windows.
rem Usage: build.bat [build|run|wave|clean]

cd /d "%~dp0"

set "OSS_CAD_ROOT=D:\oss-cad-suite\oss-cad-suite"
if exist "%OSS_CAD_ROOT%\bin\iverilog.exe" (
    set "PATH=%OSS_CAD_ROOT%\bin;%OSS_CAD_ROOT%\lib;%PATH%"
)

set "TOP=mccomp_tb"
set "OUT=mccpu_sim.out"
set "VCD=mccpu_sid_sort.vcd"
set "ACTION=%~1"

if "%ACTION%"=="" set "ACTION=run"

if /I "%ACTION%"=="clean" goto clean
if /I "%ACTION%"=="build" goto check_tools
if /I "%ACTION%"=="run" goto check_tools
if /I "%ACTION%"=="wave" goto check_tools

echo [ERROR] Unknown action: %ACTION%
echo Usage: build.bat [build^|run^|wave^|clean]
exit /b 1

:check_tools
where iverilog >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Cannot find iverilog. Please install OSS CAD Suite or add Icarus Verilog to PATH.
    exit /b 1
)

where vvp >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Cannot find vvp. Please install OSS CAD Suite or add Icarus Verilog to PATH.
    exit /b 1
)

where gtkwave >nul 2>nul
if errorlevel 1 (
    echo [WARN] Cannot find gtkwave. Simulation can still run, but waveform opening is unavailable.
    set "HAS_GTKWAVE=0"
) else (
    set "HAS_GTKWAVE=1"
)

goto build

:build
echo [INFO] Building %OUT% ...
iverilog -I . -s %TOP% -o %OUT% ^
    MCCPU.v ^
    dm.v ^
    im.v ^
    mccomp.v ^
    mccomp_tb.v ^
    RF.v

if errorlevel 1 (
    echo [ERROR] Build failed.
    exit /b 1
)

if /I "%ACTION%"=="build" (
    echo [OK] Build finished: %OUT%
    exit /b 0
)

goto run

:run
echo [INFO] Running simulation ...
vvp %OUT%
if errorlevel 1 (
    echo [ERROR] Simulation failed.
    exit /b 1
)

if exist "%VCD%" (
    echo [OK] Waveform generated: %VCD%
) else (
    echo [WARN] Simulation finished, but %VCD% was not found.
)

if /I "%ACTION%"=="wave" goto wave

echo [OK] Done.
exit /b 0

:wave
if not exist "%VCD%" (
    echo [ERROR] Cannot find %VCD%. Please run build.bat run first.
    exit /b 1
)

if "%HAS_GTKWAVE%"=="1" (
    echo [INFO] Opening GTKWave ...
    start "" gtkwave "%VCD%"
    echo [OK] Done.
    exit /b 0
)

echo [ERROR] Cannot open GTKWave because gtkwave was not found in PATH.
exit /b 1

:clean
if exist "%OUT%" del /f /q "%OUT%"
if exist "%VCD%" del /f /q "%VCD%"
if exist "*.log" del /f /q "*.log"
echo [OK] Clean finished.
exit /b 0
