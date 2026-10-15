@echo off
rem Build + run the navmesh (click-to-move) offline test against PathLib.dll of ONE build tree.
rem Usage: build_navmesh_test.cmd <BuildTree> <SceneFolder> <OutDir> [extra navmesh_test args]
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
cl /nologo /EHsc /O2 /Zi /std:c++14 /utf-8 /Fe:"%OUT%\navmesh_test.exe" /Fo:"%OUT%\\" /Fd:"%OUT%\\" ^
   /I"%ROOT%\Src\Engine\PathLib" /I"%ROOT%\Src\Client\WXClient\World" ^
   "%SELF%navmesh_test.cpp" "%ROOT%\Src\Client\WXClient\World\CysNavMesh.cpp" ^
   /link /INCREMENTAL:NO "%BLD%\lib\PathLib.lib" >"%OUT%\build_navmesh_test.log" 2>&1
type "%OUT%\build_navmesh_test.log"
if errorlevel 1 exit /b 1
copy /y "%BLD%\bin\PathLib.dll" "%OUT%\PathLib.dll" >nul
"%OUT%\navmesh_test.exe" "%SCENES%" --out "%OUT%" %EXTRA%
exit /b %ERRORLEVEL%
