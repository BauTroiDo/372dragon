/*
CYS: see WXFxParamHelpers.h
*/
#include "WXFxParamHelpers.h"

#include <OgreLogManager.h>

#include <set>

namespace WX {
namespace Fx {

    void logOnce(const String& key, const String& message)
    {
        static std::set<String> reported;
        if (!reported.insert(key).second)
            return;
        if (Ogre::LogManager::getSingletonPtr())
            Ogre::LogManager::getSingleton().logMessage("CYS FX: " + message + " (reported once)");
    }

} // namespace Fx
} // namespace WX
