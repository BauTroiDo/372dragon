@echo off
rem CY-Source perf builds (keep this file ASCII only).
rem Usage:
rem   build_perf.cmd [export^|main] [target]
rem     export (default): Build\perf\src (pristine HEAD export + CYS-PERF changes)
rem                       -> Build\perf\src\Build\cmake\perf-x64
rem     main            : the main tree Src -> Build\cmake\perf-main-x64 (integration check)
rem   CMAKE_BUILD_PARALLEL_LEVEL is capped at 4 (shared machine).
rem   cg.dll is read from a private copy in Build\perf\cg (never from client_GL at build time).
setlocal
set "CMAKE_BUILD_PARALLEL_LEVEL=4"
set "HERE=%~dp0"
set "MODE=%~1"
if "%MODE%"=="" set "MODE=export"
set "TARGET=%~2"
set "COMPS=zlib;zziplib;freetype;devil;ogremain;ogre_d3d9;ogre_plugins;ogre_platform;ogre_smoke;opcode;tinyxml;expat;scorpio;particlefx2;wxengine;wxcore;wxrender;pathlib;cegui;falagardex;luaplus;uisystem;wxnetpackets;protocolgen;netcore;wxclient;viewer"
set "VS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
set "CMAKE=%VS%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
set "NINJA=%VS%\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
set "CGDLL=%HERE%..\..\Build\perf\cg\cg.dll"
if /I "%MODE%"=="main" goto mode_main
set "ROOT=%HERE%..\..\Build\perf\src"
set "NAME=perf-x64"
goto have_mode
:mode_main
set "ROOT=%HERE%..\.."
set "NAME=perf-main-x64"
:have_mode
set "BLD=%ROOT%\Build\cmake\%NAME%"
if exist "%BLD%\CMakeCache.txt" goto do_build
call "%VS%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
if errorlevel 1 exit /b 1
"%CMAKE%" -S "%ROOT%\Src" -B "%BLD%" -G Ninja "-DCMAKE_MAKE_PROGRAM=%NINJA%" -DCMAKE_BUILD_TYPE=Release "-DCYS_COMPONENTS=%COMPS%" "-DCYS_CG_DLL=%CGDLL%"
if errorlevel 1 exit /b 1
:do_build
call "%ROOT%\Tools\build\build.cmd" x64 %NAME% Release "%COMPS%" %TARGET%
exit /b %ERRORLEVEL%
