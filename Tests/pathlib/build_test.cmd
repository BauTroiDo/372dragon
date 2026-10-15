@echo off
rem Build the PathLib test harness with the MSVC 2022 x64 toolchain.
setlocal
set "VS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "%VS%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
if errorlevel 1 exit /b 1
rem CYS: PATHLIB_TEST_OUT overrides the output tree (each agent builds in its own tree; Timeline trap 15).
set "OUT=%PATHLIB_TEST_OUT%"
if "%OUT%"=="" set "OUT=%~dp0..\..\Build\cmake\pathlib-x64\test"
if not exist "%OUT%" mkdir "%OUT%"
cl /nologo /EHa /O2 /Zi /std:c++14 /Fe:"%OUT%\pathlib_test.exe" /Fo:"%OUT%\\" /Fd:"%OUT%\\" ^
   "%~dp0pathlib_test.cpp" /link /INCREMENTAL:NO >"%OUT%\build.log" 2>&1
type "%OUT%\build.log"
exit /b %ERRORLEVEL%
