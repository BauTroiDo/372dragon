@echo off
rem Syntax/semantic compile check (no objects) of the generated stubs in Src\Client\LuaApiGen
rem against the 0.85 LuaPlus headers, x64 MSVC (VS 2022 Build Tools). Log: Build\Logs\2026-09-12-luaapi\stub_compile.log
setlocal
set L=C:\TLBB\085\CY-Source\Build\Logs\2026-09-12-luaapi
set S=C:\TLBB\085\CY-Source\Src
if not exist "%L%" mkdir "%L%"
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul
cl /nologo /Zs /EHsc /std:c++17 /W3 /source-charset:utf-8 /execution-charset:.936 /D_CRT_SECURE_NO_WARNINGS /DWIN32 /D_WINDOWS /I "%S%\ThirdParty\LuaPlus\Src\LuaPlus" /I "%S%\ThirdParty\LuaPlus\Src\LuaPlus\include" /I "%S%\ThirdParty\LuaPlus\Src" "%S%\Client\LuaApiGen\*.cpp" > "%L%\stub_compile.log" 2>&1
echo EXIT %ERRORLEVEL% >> "%L%\stub_compile.log"
endlocal
