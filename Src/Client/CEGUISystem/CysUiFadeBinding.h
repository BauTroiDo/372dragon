#pragma once
#include "CEGUIWindow.h"
#include "LuaPlus.h"

namespace CysUiFadeBinding
{
    inline int startFade(lua_State* state, CEGUI::Window& window)
    {
        // B accepts actual Lua numbers only, including its first argument.
        if (lua_type(state, 2) != LUA_TNUMBER || lua_type(state, 3) != LUA_TNUMBER ||
            lua_type(state, 4) != LUA_TNUMBER) return 0;
        window.startFade(static_cast<float>(lua_tonumber(state, 2)),
            static_cast<float>(lua_tonumber(state, 3)), static_cast<float>(lua_tonumber(state, 4)));
        return 0;
    }
}
