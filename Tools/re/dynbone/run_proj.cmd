@echo off
rem dynbone RE (read-only): run a script against one of the COPIED projects under Build\re\dynbone.
rem Usage: run_proj.cmd <gfxproj|ogreproj|cproj> <projectName: gfx|ogreB|cren> <program> <script.java> <mode> <outName> [arg]
setlocal
set GHIDRA_HEADLESS_MAXMEM=3G
set G=C:\TLBB\085\tools\ghidra\ghidra_12.1.3_PUBLIC\support\analyzeHeadless.bat
set R=C:\TLBB\085\CY-Source\Build\re\dynbone
set S=C:\TLBB\085\CY-Source\Tools\re\ghidra;%R%\scripts
set O=%R%\out
if not exist "%O%" mkdir "%O%"
call "%G%" "%R%\%1" %2 -process %3 -noanalysis -readOnly -scriptPath "%S%" -postScript %4 %5 "%O%\%6.txt" %7 > "%O%\%6.log" 2>&1
echo EXIT %ERRORLEVEL% >> "%O%\%6.log"
endlocal
