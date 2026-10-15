@echo off
rem Tests/scene: configure Build\cmake\scene-x64 with Tests\scene\scene_test.cmake injected, build CYSSceneTest,
rem run it (read-only; default data = Assets\CanonicalCY\Data, pass --data for another folder). Extra arguments go to
rem CYSSceneTest.exe. Keep this file ASCII only.
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
set "BLD=%ROOT%\Build\cmake\scene-x64"
if "%CMAKE_BUILD_PARALLEL_LEVEL%"=="" set CMAKE_BUILD_PARALLEL_LEVEL=5
"%CMAKE%" -S "%ROOT%\Src" -B "%BLD%" -G Ninja "-DCMAKE_MAKE_PROGRAM=%NINJA%" -DCMAKE_BUILD_TYPE=Release "-DCMAKE_PROJECT_CYSource_INCLUDE=%ROOTF%/Tests/scene/scene_test.cmake"
if errorlevel 1 exit /b 1
"%CMAKE%" --build "%BLD%" --target CYSSceneTest -- -k 0
if errorlevel 1 exit /b 1
"%BLD%\bin\CYSSceneTest.exe" %*
exit /b %ERRORLEVEL%
