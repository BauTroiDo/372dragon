@echo off
setlocal
rem Copy this launcher to a generated stage root containing Bin64.
rem Profile endpoints remain in Patch\CysServerProfile.txt; no password is stored here.
if not exist "%~dp0Bin64\Run-CY-Server.cmd" (
  echo Copy Play.cmd to the generated stage root before running it.
  pause
  exit /b 1
)
for /f "tokens=1 delims==" %%V in ('set CYS_ 2^>nul') do set "%%V="
call "%~dp0Bin64\Run-CY-Server.cmd"
endlocal
