@echo off
rem CYS-PERF: build fx-particles' CYSParticleBench (Tests\fx\particles) in a perf build tree. ASCII only.
rem Usage:
rem   build_particle_bench.cmd [main^|export]
rem     main (default): the main tree Src -> Build\cmake\perf-main-x64
rem     export        : Build\perf\src   -> Build\perf\src\Build\cmake\perf-x64
rem   The bench target is injected with CMAKE_PROJECT_CYSource_INCLUDE (Src\CMakeLists.txt is not touched);
rem   -DCYS_PARTICLES_UNIT=OFF builds the bench only. CMAKE_BUILD_PARALLEL_LEVEL is capped at 4.
rem   Run: <tree>\bin\CYSParticleBench.exe --label <name> --out <tsv> (see Tests\fx\particles\particle_bench.cpp).
setlocal
set "CMAKE_BUILD_PARALLEL_LEVEL=4"
set "HERE=%~dp0"
set "MODE=%~1"
if "%MODE%"=="" set "MODE=main"
set "COMPS=zlib;zziplib;freetype;devil;ogremain;ogre_d3d9;ogre_plugins;ogre_platform;ogre_smoke;opcode;tinyxml;expat;scorpio;particlefx2;wxengine;wxcore;wxrender;pathlib;cegui;falagardex;luaplus;uisystem;wxnetpackets;protocolgen;netcore;wxclient;viewer"
set "VS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
set "CMAKE=%VS%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
set "INJ=C:/TLBB/085/CY-Source/Tests/fx/particles/particles_test.cmake"
if /I "%MODE%"=="export" goto mode_export
set "ROOT=%HERE%..\.."
set "NAME=perf-main-x64"
goto have_mode
:mode_export
set "ROOT=%HERE%..\..\Build\perf\src"
set "NAME=perf-x64"
:have_mode
set "BLD=%ROOT%\Build\cmake\%NAME%"
if not exist "%BLD%\CMakeCache.txt" (
  echo no configured tree %BLD%: run build_perf.cmd %MODE% first
  exit /b 1
)
call "%VS%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
if errorlevel 1 exit /b 1
"%CMAKE%" -S "%ROOT%\Src" -B "%BLD%" "-DCMAKE_PROJECT_CYSource_INCLUDE=%INJ%" -DCYS_PARTICLES_UNIT=OFF "-DCYS_COMPONENTS=%COMPS%"
if errorlevel 1 exit /b 1
call "%ROOT%\Tools\build\build.cmd" x64 %NAME% Release "%COMPS%" CYSParticleBench
exit /b %ERRORLEVEL%
