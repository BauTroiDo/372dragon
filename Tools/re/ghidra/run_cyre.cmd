@echo off
rem Usage: run_cyre.cmd <Program: Render.dll|Game.exe> <mode> <outName> [arg]   (lists: separate with + , cmd splits on commas)
rem Runs CyReDump.java read-only (-readOnly -noanalysis) against a COPY of the gfx Ghidra project.
rem GFXPROJ = directory holding gfx.gpr/gfx.rep (default: session copy of
rem           C:\TLBB\085\analysis\graphics-overhaul\ghidra\proj; never point two processes at one project).
setlocal
set G=C:\TLBB\085\tools\ghidra\ghidra_12.1.3_PUBLIC\support\analyzeHeadless.bat
if "%GFXPROJ%"=="" set GFXPROJ=C:\Users\PC-SAM~1\AppData\Local\Temp\claude\C--TLBB-085\7dee11c4-af32-4edd-9ec1-d23eb9125905\scratchpad\gfxcopy
set S=C:\TLBB\085\CY-Source\Tools\re\ghidra
set O=C:\TLBB\085\CY-Source\Tools\re\out\ghidra
if not exist "%O%" mkdir "%O%"
call "%G%" "%GFXPROJ%" gfx -process %1 -noanalysis -readOnly -scriptPath "%S%" -postScript CyReDump.java %2 "%O%\%3.txt" %4 > "%O%\%3.log" 2>&1
echo EXIT %ERRORLEVEL% >> "%O%\%3.log"
endlocal
