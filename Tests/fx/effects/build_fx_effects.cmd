@echo off
rem Tests/fx/effects: build the private fx-effects-x64 tree (RelWithDebInfo) used by the effects agent.
rem Usage: build_fx_effects.cmd LOGNAME [TARGET]
rem   LOGNAME log name -> Build\Logs\2026-09-13-fx-effects\<LOGNAME>.log
rem   TARGET  optional CMake target (omitted = whole tree)
rem Keeps CMAKE_BUILD_PARALLEL_LEVEL at 4. Keep this file ASCII only.
setlocal
set "ROOT=%~dp0..\..\.."
pushd "%ROOT%" >nul
set "ROOT=%CD%"
popd >nul
set "LOGDIR=%ROOT%\Build\Logs\2026-09-13-fx-effects"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set "LOGN=%~1"
if "%LOGN%"=="" set "LOGN=build"
set CMAKE_BUILD_PARALLEL_LEVEL=4
set "COMPS=zlib;zziplib;freetype;devil;ogremain;ogre_d3d9;ogre_plugins;ogre_platform;opcode;tinyxml;expat;scorpio;particlefx2;wxengine;wxcore;wxrender;viewer"
echo START %DATE% %TIME% > "%LOGDIR%\%LOGN%.log"
if "%~2"=="" (
  call "%ROOT%\Tools\build\build.cmd" x64 fx-effects-x64 RelWithDebInfo "%COMPS%" >> "%LOGDIR%\%LOGN%.log" 2>&1
) else (
  call "%ROOT%\Tools\build\build.cmd" x64 fx-effects-x64 RelWithDebInfo "%COMPS%" %2 >> "%LOGDIR%\%LOGN%.log" 2>&1
)
set RC=%ERRORLEVEL%
echo END %DATE% %TIME% EXIT %RC% >> "%LOGDIR%\%LOGN%.log"
endlocal & exit /b %RC%
