@echo off
rem CYS-CRASHRPT 19/09/2026 - build the deliberate-crash harness for the engine crash reporter.
rem ASCII only (cmd.exe misparses UTF-8 comments).
rem
rem Usage: build_test.cmd [SRCDIR]
rem   SRCDIR = folder holding TDCrashReport.cpp / TDCrashReport.h / TDException.cpp to test.
rem            Default: Src\Engine\WXEngine\Exception (the working tree).
rem            Pass a scratch copy of the HEAD versions to build the "before" harness - that is
rem            how the A/B in Timeline\handoff\crash-report.md proves the test can fail.
rem
rem Output tree: CRASHRPT_TEST_OUT, default Build\cmake\crashrpt-x64\test.
rem Everything else (TDUtil.cpp, XZip.cpp, ...) comes from WXEngine.lib, built beforehand with
rem   Tools\build\build.cmd x64 crashrpt-x64 Release "wxengine" cys_wxengine
rem The two .obj we compile here define every symbol of their lib members, so the linker never
rem pulls those members: a mix-up would be a duplicate-symbol error, never a silent swap.
setlocal
set "VS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "%VS%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
if errorlevel 1 exit /b 1

set "ROOT=%~dp0..\.."
set "SRCDIR=%~1"
if "%SRCDIR%"=="" set "SRCDIR=%ROOT%\Src\Engine\WXEngine\Exception"

set "OUT=%CRASHRPT_TEST_OUT%"
if "%OUT%"=="" set "OUT=%ROOT%\Build\cmake\crashrpt-x64\test"
if not exist "%OUT%" mkdir "%OUT%"

rem CRASHRPT_TEST_LIB overrides which WXEngine.lib the harness links. Point it at the SAME tree the
rem shipped Game.exe was built from, so the harness exercises the exact library the client carries -
rem the two are not byte-identical (different trees embed different paths/flags).
set "LIB1=%CRASHRPT_TEST_LIB%"
if "%LIB1%"=="" set "LIB1=%ROOT%\Build\cmake\crashrpt-x64\lib\WXEngine.lib"
if not exist "%LIB1%" (
  echo [build_test.cmd] Missing %LIB1% - build cys_wxengine first.
  exit /b 2
)

rem Same defines and include order as Src\cmake\components\wxengine.cmake:
rem   PUBLIC  Src\Engine\Interface
rem   PRIVATE Src\Engine\WXEngine, Src\Client\WXClient  (last, so "..\WXClient\Global.h" resolves)
rem SRCDIR goes first so an alternative copy of TDCrashReport.h wins over the working tree's.
rem Defines/charset mirror Src\cmake\CYSCommon.cmake:27-37 (the sources are UTF-8, the engine
rem expects GBK bytes for the Chinese resource keys) plus wxengine.cmake's TENGDA_EXPORTS/_MBCS.
cl /nologo /EHsc /O2 /Zi /MD /source-charset:utf-8 /execution-charset:.936 ^
   /wd4828 /wd4819 /wd4996 /wd4251 /wd4275 /wd4244 /wd4267 /wd4018 /wd4305 /wd4800 /wd4995 ^
   /DWIN32 /D_WINDOWS /DNDEBUG /D_MBCS /DTENGDA_EXPORTS ^
   /D_CRT_SECURE_NO_WARNINGS /D_CRT_NONSTDC_NO_DEPRECATE /D_SCL_SECURE_NO_WARNINGS ^
   /D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS /D_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS ^
   /D_HAS_AUTO_PTR_ETC=1 /D_WINSOCK_DEPRECATED_NO_WARNINGS ^
   /I"%SRCDIR%" /I"%ROOT%\Src\Engine\Interface" /I"%ROOT%\Src\Engine\WXEngine" ^
   /I"%ROOT%\Src\Engine\WXEngine\Exception" /I"%ROOT%\Src\Client\WXClient" ^
   /Fe:"%OUT%\crashrpt_test.exe" /Fo:"%OUT%\\" /Fd:"%OUT%\crashrpt_test.pdb" ^
   "%~dp0crashrpt_test.cpp" "%SRCDIR%\TDCrashReport.cpp" "%SRCDIR%\TDException.cpp" ^
   /link /INCREMENTAL:NO /DEBUG "%LIB1%" dbghelp.lib shlwapi.lib user32.lib gdi32.lib shell32.lib advapi32.lib ole32.lib ^
   >"%OUT%\build.log" 2>&1
set "RC=%ERRORLEVEL%"
type "%OUT%\build.log"
exit /b %RC%
