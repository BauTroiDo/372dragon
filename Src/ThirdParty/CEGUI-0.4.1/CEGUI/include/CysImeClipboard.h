#pragma once
#include "CEGUIWindow.h"
#include "CEGUIPropertyHelper.h"
namespace CEGUI {
// Shared by the Win32 IME route and native tests; no widget DLL dependency.
inline bool cysAllowsClipboard(const Window* window)
{
    return window && (!window->isPropertyPresent("DisableCopyPaste") ||
        !PropertyHelper::stringToBool(window->getProperty("DisableCopyPaste")));
}
}
