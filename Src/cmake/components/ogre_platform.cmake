# CYS component: OGRE Win32 platform manager.
#
# Finding: this Fairy OgreMain never loads OgrePlatform.dll. The DynLibManager load of
# OGRE_PLATFORM_LIB in OgrePlatformManager.cpp:53 is commented out and PlatformManager calls
# createPlatformConfigDialog(), createPlatformErrorDialog(), createPlatformInputReader(),
# createMyTimer(), MymessagePump() ... (PlatformManagers/Win32/include/OgreWin32PlatformDll.h)
# directly. The reference 0.85 OgreMain.dll (x86 and x64) imports DINPUT8.dll for the same reason.
#
# So the six Win32 platform sources and OgreWin32Resources.rc are compiled into OgreMain.dll by
# ogremain.cmake; there is no separate platform DLL and no target is defined here.
if(NOT TARGET OgreMain)
    message(WARNING "CYS: ogre_platform needs the ogremain component (the Win32 platform code is part of OgreMain.dll)")
endif()
