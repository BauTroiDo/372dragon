@echo off
rem Import B OgreMain.dll (read-only source) into a NEW scratch Ghidra project, auto-analyse, then decompile
rem auto-constant related functions by name.  Usage: run_ogre_import.cmd <projectDir>
setlocal
set G=C:\TLBB\085\tools\ghidra\ghidra_12.1.3_PUBLIC\support\analyzeHeadless.bat
set PR=%1
if "%PR%"=="" set PR=C:\Users\PC-SAM~1\AppData\Local\Temp\claude\C--TLBB-085\7dee11c4-af32-4edd-9ec1-d23eb9125905\scratchpad\ogreproj
set S=C:\TLBB\085\CY-Source\Tools\re\ghidra
set O=C:\TLBB\085\CY-Source\Tools\re\out\ghidra
if not exist "%PR%" mkdir "%PR%"
if not exist "%O%" mkdir "%O%"
call "%G%" "%PR%" ogreB -import "C:\TLBB\085\client_GL\Bin64\OgreMain.dll" -scriptPath "%S%" -postScript CyReByName.java byname "%O%\ogre_autoparams.txt" _updateAutoParams+AutoParamDataSource:: > "%O%\ogre_import.log" 2>&1
echo EXIT %ERRORLEVEL% >> "%O%\ogre_import.log"
endlocal
