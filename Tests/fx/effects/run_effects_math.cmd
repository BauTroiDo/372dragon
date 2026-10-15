@echo off
rem Tests/fx/effects: compile and run the standalone effect-maths unit test (no engine link). ASCII only.
setlocal
set "VS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "%VS%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
if errorlevel 1 exit /b 1
set "OUT=%~dp0..\..\..\Build\Logs\2026-09-13-fx-effects"
if not exist "%OUT%" mkdir "%OUT%"
cl /nologo /EHsc /W3 /Fe:"%OUT%\effects_math_test.exe" /Fo:"%OUT%\effects_math_test.obj" "%~dp0effects_math_test.cpp" >"%OUT%\effects_math_build.log" 2>&1
if errorlevel 1 (
  echo BUILD FAILED - see %OUT%\effects_math_build.log
  exit /b 1
)
"%OUT%\effects_math_test.exe"
exit /b %ERRORLEVEL%
