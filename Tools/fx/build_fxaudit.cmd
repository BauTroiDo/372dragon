@echo off
rem fx-audit: build TlbbViewer (OgreMain + D3D9 + WXCore + Plugin_ParticleFX2) in its own tree.
rem Usage: build_fxaudit.cmd [TARGET]   (no target = all configured components)
rem Output: C:\TLBB\085\CY-Source\Build\cmake\fxaudit-x64\bin
rem Keep this file ASCII only.
setlocal
set CMAKE_BUILD_PARALLEL_LEVEL=4
call C:\TLBB\085\CY-Source\Tools\build\build.cmd x64 fxaudit-x64 RelWithDebInfo "zlib;zziplib;freetype;devil;ogremain;ogre_d3d9;ogre_plugins;ogre_platform;opcode;tinyxml;expat;scorpio;particlefx2;wxengine;wxcore;viewer" %1
exit /b %ERRORLEVEL%
