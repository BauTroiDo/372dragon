#pragma once

















#include "LuaPlus.h"

namespace CysHostHost2
{
    // Registers the host functions (forced); returns how many. Main thread only.
    int Register(LuaPlus::LuaState* state);
    // Same, resolving the Lua state from CScriptSystem (call site: CysModernGame after a session starts).
    void RegisterHost();
    // True when CYS_HOST2_OFF=1 (read once): nothing of this batch is registered.
    bool Disabled();

    // Game-layer answers, also used by the probe. nullptr / false = "B answers nothing".
    const char* ItemNameByIndex(int index);
    bool ToggleWuhunPage();

    // CYS_HOST2_LIVE=1 driver of the live GUI smoke (CysGlLoginSmoke case 52). Returns true when off or finished.
    bool Tick();
}
