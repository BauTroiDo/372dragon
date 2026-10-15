@echo off
rem Tests/fx: configure Build\cmake\wxfx-x64 with Tests\fx\fx_test.cmake injected, build CYSFxParseTest, run it
rem (read-only on client_GL). Extra arguments go to CYSFxParseTest.exe. Keep this file ASCII only.
setlocal
set "ROOT=%~dp0..\.."
pushd "%ROOT%" >nul
set "ROOT=%CD%"
popd >nul
set "ROOTF=%ROOT:\=/%"
set "VS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "%VS%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
if errorlevel 1 exit /b 1
set "CMAKE=%VS%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
set "NINJA=%VS%\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
set "BLD=%ROOT%\Build\cmake\wxfx-x64"
if "%CMAKE_BUILD_PARALLEL_LEVEL%"=="" set CMAKE_BUILD_PARALLEL_LEVEL=5
"%CMAKE%" -S "%ROOT%\Src" -B "%BLD%" -G Ninja "-DCMAKE_MAKE_PROGRAM=%NINJA%" -DCMAKE_BUILD_TYPE=Release -DCYS_COMPONENTS="opcode;tinyxml;expat;scorpio;particlefx2;wxengine;wxcore;wxrender" "-DCMAKE_PROJECT_CYSource_INCLUDE=%ROOTF%/Tests/fx/fx_test.cmake"
if errorlevel 1 exit /b 1
"%CMAKE%" --build "%BLD%" --target CYSFxParseTest -- -k 0
if errorlevel 1 exit /b 1
"%BLD%\bin\CYSFxParseTest.exe" %*
exit /b %ERRORLEVEL%
