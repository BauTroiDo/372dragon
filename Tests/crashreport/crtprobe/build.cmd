@echo off
setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
cl /nologo /MD /O2 /W3 /D_CRT_SECURE_NO_WARNINGS /LD crtprobe_dll.c /Fe:crtprobe_dll.dll || exit /b 1
cl /nologo /MD /O2 /W3 /D_CRT_SECURE_NO_WARNINGS crtprobe.c /Fe:crtprobe.exe || exit /b 1
echo BUILD_OK
