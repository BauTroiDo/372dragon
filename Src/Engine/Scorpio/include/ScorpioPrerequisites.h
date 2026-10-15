#ifndef __ScorpioPrerequisites_H__
#define __ScorpioPrerequisites_H__

#include <OgrePrerequisites.h>

//-----------------------------------------------------------------------
// Windows Settings
//-----------------------------------------------------------------------
//#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
//#   if OGRE_DYNAMIC_LINKAGE == 0
//#       pragma warn( "No dynamic linkage" )
#       define _ScorpioExport
//#   else
//#       ifdef PLUGIN_Scorpio_EXPORTS
//#           define _ScorpioExport __declspec(dllexport)
//#       else
//#           define _ScorpioExport __declspec(dllimport)
//#       endif
//#   endif
//#else
//#   define _ScorpioExport
//#endif

// CYS: export macros for the free functions declared in Scorpio.h (they used _OgreExport = dllimport outside
// OgreMain, so their definitions failed with C2491). Layout of the reference Plugin_Scorpio.dll (Bin and Bin64):
// StartScorpio/StopScorpio exported by decorated name (and aliased to dllStartPlugin/dllStopPlugin in the .def);
// createCollisionManager/destroyCollisionManager/convertEntityToHardwareSkinning exported by plain name through
// scripts/Plugin_Scorpio.def only, and imported by plain name by Render.dll.
#if defined(PLUGIN_Scorpio_EXPORTS)
#   define _ScorpioApi      __declspec(dllexport)
#   define _ScorpioDefApi
#else
#   define _ScorpioApi      __declspec(dllimport)
#   define _ScorpioDefApi   __declspec(dllimport)
#endif

namespace Ogre
{
    // Predeclare classes
    class Cloth;
    class Fabric;

    class UserCollideTester;
    class Collider;
    class StdCollider;
    class UserCollider;
    class ColliderSet;
    class CollisionManager;
}

#endif // __ScorpioPrerequisites_H__
