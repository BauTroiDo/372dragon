#pragma once
#include "CEGUIWindow.h"
#include "LuaPlus.h"

namespace CysFlashBinding
{
    inline int flashMe(lua_State* state, CEGUI::Window& window)
    {
        // B UI_CEGUI+0x15270: actual number, truncate to int, enable only 1.
        // The interval also handles nonfinite/out-of-range input without a cast.
        if (lua_type(state, 2) != LUA_TNUMBER) return 0;
        const double value = lua_tonumber(state, 2);
        window.setProperty("Flash", value >= 1.0 && value < 2.0 ? "1" : "0");
        return 0;
    }
}
