@echo off
rem perf-cy: builds the present probe (d3d9.dll proxy) into OUTDIR. ASCII only.
rem Usage: build_probe.cmd OUTDIR
setlocal
set "OUT=%~1"
if "%OUT%"=="" exit /b 1
if not exist "%OUT%" mkdir "%OUT%"
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
cl /nologo /O2 /MT /W3 /EHsc /LD "%~dp0d3d9_probe.cpp" /Fo"%OUT%\\" /Fe"%OUT%\d3d9.dll" /link /DEF:"%~dp0d3d9_probe.def" user32.lib kernel32.lib
exit /b %ERRORLEVEL%
