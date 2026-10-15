@echo off
rem CYS-CRTGUARD 20/09/2026 - build the format-specifier counter self-test.
rem ASCII only (cmd.exe misparses UTF-8 comments).
rem
rem It compiles the SHIPPED source file (Src\Engine\WXEngine\Exception\CysCrtGuard.cpp), not a
rem copy, so the test measures the code the client actually carries. It needs no WXEngine.lib:
rem crtguard_fmt_test.cpp stubs TDU_Log and the three crash-report writers.
rem
rem Usage: build_crtguard_test.cmd [SRCDIR]
rem   SRCDIR = folder holding CysCrtGuard.cpp. Default: Src\Engine\WXEngine\Exception.
rem            Pass a scratch copy of an older version to build a "before" harness.
rem Output tree: CRTGUARD_TEST_OUT, default Build\cmake\crtguard-test.
setlocal
set "VS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "%VS%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
if errorlevel 1 exit /b 1

set "ROOT=%~dp0..\.."
set "SRCDIR=%~1"
if "%SRCDIR%"=="" set "SRCDIR=%ROOT%\Src\Engine\WXEngine\Exception"

set "OUT=%CRTGUARD_TEST_OUT%"
if "%OUT%"=="" set "OUT=%ROOT%\Build\cmake\crtguard-test"
if not exist "%OUT%" mkdir "%OUT%"

rem Same defines / include order as Src\cmake\components\wxengine.cmake + CYSCommon.cmake.
cl /nologo /EHsc /O2 /Zi /MD /source-charset:utf-8 /execution-charset:.936 ^
   /wd4828 /wd4819 /wd4996 /wd4251 /wd4275 /wd4244 /wd4267 /wd4018 /wd4305 /wd4800 /wd4995 ^
   /DWIN32 /D_WINDOWS /DNDEBUG /D_MBCS /DTENGDA_EXPORTS ^
   /D_CRT_SECURE_NO_WARNINGS /D_CRT_NONSTDC_NO_DEPRECATE /D_SCL_SECURE_NO_WARNINGS ^
   /D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS /D_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS ^
   /D_HAS_AUTO_PTR_ETC=1 /D_WINSOCK_DEPRECATED_NO_WARNINGS ^
   /I"%SRCDIR%" /I"%ROOT%\Src\Engine\Interface" /I"%ROOT%\Src\Engine\WXEngine" ^
   /Fe:"%OUT%\crtguard_fmt_test.exe" /Fo:"%OUT%\\" /Fd:"%OUT%\crtguard_fmt_test.pdb" ^
   "%~dp0crtguard_fmt_test.cpp" "%SRCDIR%\CysCrtGuard.cpp" ^
   /link /INCREMENTAL:NO /DEBUG shlwapi.lib winmm.lib user32.lib advapi32.lib ^
   >"%OUT%\build.log" 2>&1
set "RC=%ERRORLEVEL%"
type "%OUT%\build.log"
if not "%RC%"=="0" exit /b %RC%
"%OUT%\crtguard_fmt_test.exe"
exit /b %ERRORLEVEL%
