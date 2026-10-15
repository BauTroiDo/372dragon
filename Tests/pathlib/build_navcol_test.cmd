@echo off
rem CYS-NAV: build + run navcol_test (CY *.WCollision + navmesh walls) against PathLib.dll of ONE build tree.
rem Usage: build_navcol_test.cmd <BuildTree> <SceneFolder> <OutDir> [extra navmesh_test args]
rem   BuildTree = a configured CMake tree that built cys_pathlib (lib\PathLib.lib + bin\PathLib.dll),
rem   e.g. C:\TLBB\085\CY-Source\Build\wt-navmesh\Build\cmake\navmesh-x64  (never another agent's tree).
rem ASCII only.
setlocal
set "SELF=%~dp0"
set "BLD=%~1"
set "SCENES=%~2"
set "OUT=%~3"
if "%BLD%"=="" exit /b 2
if "%SCENES%"=="" exit /b 2
if "%OUT%"=="" set "OUT=%BLD%\test"
shift /1
shift /1
shift /1
set "EXTRA="
:collect
if "%~1"=="" goto run
set "EXTRA=%EXTRA% %~1"
shift /1
goto collect
:run
set "VS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "%VS%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
if errorlevel 1 exit /b 1
set "ROOT=%SELF%..\.."
if not exist "%OUT%" mkdir "%OUT%"
cl /nologo /EHsc /O2 /Zi /std:c++14 /utf-8 /Fe:"%OUT%\navcol_test.exe" /Fo:"%OUT%\\" /Fd:"%OUT%\\" ^
   /I"%ROOT%\Src\Engine\PathLib" /I"%ROOT%\Src\Client\WXClient\World" ^
   "%SELF%navcol_test.cpp" "%ROOT%\Src\Client\WXClient\World\CysNavMesh.cpp" "%ROOT%\Src\Client\WXClient\World\CysWCollision.cpp" ^
   /link /INCREMENTAL:NO "%BLD%\lib\PathLib.lib" >"%OUT%\build_navcol_test.log" 2>&1
type "%OUT%\build_navcol_test.log"
if errorlevel 1 exit /b 1
copy /y "%BLD%\bin\PathLib.dll" "%OUT%\PathLib.dll" >nul
"%OUT%\navcol_test.exe" "%SCENES%" --out "%OUT%" %EXTRA%
exit /b %ERRORLEVEL%
