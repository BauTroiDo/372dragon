@echo off
rem Usage: run_luaapi.cmd <proj: game|cegui> <Program: Game.exe|UI_CEGUI.dll|CEGUIBase.dll> <Script.java> <logName> [script args...]
rem Runs a Ghidra post-script READ-ONLY (-readOnly -noanalysis) against the COPY of the
rem analyzed projects in CY-Source\Build\re\luaapi (never the originals in analysis\ghidra).
rem Heap capped at 3G (shared machine). One Ghidra process at a time.
setlocal
set G=C:\TLBB\085\tools\ghidra\ghidra_12.1.3_PUBLIC\support\analyzeHeadless.bat
set GHIDRA_HEADLESS_MAXMEM=3G
set B=C:\TLBB\085\CY-Source\Build\re\luaapi
set S=C:\TLBB\085\CY-Source\Tools\re\luaapi;C:\TLBB\085\CY-Source\Tools\re\ghidra
set L=C:\TLBB\085\CY-Source\Build\Logs\2026-09-12-luaapi
if not exist "%L%" mkdir "%L%"
if /I "%1"=="game" (set PD=%B%\game-exe-proj& set PN=game_exe)
if /I "%1"=="cegui" (set PD=%B%\cegui-proj& set PN=cegui)
set PROG=%2
set SCR=%3
set LOGN=%4
shift
shift
shift
shift
set ARGS=
:collect
if "%~1"=="" goto run
set ARGS=%ARGS% %1
shift
goto collect
:run
call "%G%" "%PD%" %PN% -process %PROG% -noanalysis -readOnly -scriptPath "%S%" -postScript %SCR% %ARGS% > "%L%\%LOGN%.log" 2>&1
echo EXIT %ERRORLEVEL% >> "%L%\%LOGN%.log"
endlocal
