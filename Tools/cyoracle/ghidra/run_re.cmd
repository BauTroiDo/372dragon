@echo off
rem cy-oracle RE: CyOracleRE.java READ-ONLY (-readOnly -noanalysis) on the COPIED project Build\re\cy-oracle\projCG.
rem Heap capped at 3 GB. ASCII only. Usage: run_re.cmd JOBSFILE TAG
setlocal
set W=C:\TLBB\085\CY-Source\Build\re\cy-oracle
set L=C:\TLBB\085\CY-Source\Build\Logs\2026-09-15-cy-oracle\re
if not exist "%L%" mkdir "%L%"
set TEMP=%W%\tmp
set TMP=%W%\tmp
set MAXMEM=3G
set JAVA_TOOL_OPTIONS=-Duser.home=%W%\java-home -Dapplication.settingsdir=%W%\ghidra-settings -Dapplication.cachedir=%W%\ghidra-cache -Djava.io.tmpdir=%W%\tmp -Xmx3G
call C:\TLBB\085\tools\ghidra\ghidra_12.1.3_PUBLIC\support\analyzeHeadless.bat %W%\projCG cyg -process Game_C_9278c7f3.exe -noanalysis -readOnly -log "%L%\%2-app.log" -scriptlog "%L%\%2-script.log" -scriptPath "%W%\scripts" -postScript CyOracleRE.java %1 > "%L%\%2-run.log" 2>&1
set RC=%ERRORLEVEL%
echo EXIT %RC% >> "%L%\%2-run.log"
exit /b %RC%
