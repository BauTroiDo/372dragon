@echo off
rem Tests/fx/particles: configure a build tree with Tests\fx\particles\particles_test.cmake injected, build
rem CYSParticleUnitTest (+ CYSParticleBench) and run the unit tests. Keep this file ASCII only.
rem Usage: run_particle_tests.cmd [tree name under Build\cmake, default fx-particles-x64] [extra unit test args]
rem The tree must already contain the components up to wxcore / particlefx2 (Tools\build\build.cmd).
setlocal
set "ROOT=%~dp0..\..\.."
pushd "%ROOT%" >nul
set "ROOT=%CD%"
popd >nul
set "ROOTF=%ROOT:\=/%"
set "TREE=%~1"
if "%TREE%"=="" set "TREE=fx-particles-x64"
set "VS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "%VS%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
if errorlevel 1 exit /b 1
set "CMAKE=%VS%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
set "BLD=%ROOT%\Build\cmake\%TREE%"
if "%CMAKE_BUILD_PARALLEL_LEVEL%"=="" set CMAKE_BUILD_PARALLEL_LEVEL=4
"%CMAKE%" -S "%ROOT%\Src" -B "%BLD%" "-DCMAKE_PROJECT_CYSource_INCLUDE=%ROOTF%/Tests/fx/particles/particles_test.cmake" -DCYS_PARTICLES_UNIT=ON
if errorlevel 1 exit /b 1
"%CMAKE%" --build "%BLD%" --target CYSParticleUnitTest CYSParticleBench -- -k 0
if errorlevel 1 exit /b 1
pushd "%BLD%\bin"
CYSParticleUnitTest.exe %2 %3 %4
set "RC=%ERRORLEVEL%"
popd
exit /b %RC%
