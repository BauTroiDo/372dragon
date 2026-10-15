// CYS: clean-room shortcut setter; B RVA 0x26d540, see hotkeys_vi.md.
#include "CysHostHotKeys.h"
#include "LuaPlus.h"

#include <cmath>
#include <exception>
#include <limits>
#include <new>
#include <stdexcept>

namespace CysHostHotKeys
{
    namespace
    {
        const char* const servicesMetatable = "CysHostHotKeys.Services";

        std::int32_t ToInt32(double value)
        {
            const double truncated = std::trunc(value);
            const auto minimum = (std::numeric_limits<std::int32_t>::min)();
            const auto maximum = (std::numeric_limits<std::int32_t>::max)();
            if (!std::isfinite(value) || truncated < minimum || truncated > maximum)
                return minimum;
            return static_cast<std::int32_t>(truncated);
        }

        int SetCanUseHotKey(lua_State* state)
        {
            if (lua_type(state, 2) != LUA_TNUMBER)
                return 0; // B accepts NUMBER only; numeric strings and booleans are no-ops.

            const auto* services = static_cast<const Services*>(
                luaL_checkudata(state, lua_upvalueindex(1), servicesMetatable));
            if (!services || !services->setCanUseHotKey)
                return luaL_error(state, "DataPool:SetCanUseHotKey service is unavailable");

            const std::int32_t value = ToInt32(lua_tonumber(state, 2));
            const char* error = nullptr;
            try
            {
                services->setCanUseHotKey(services->context, value);
            }
            catch (const LuaPlus::LuaException&)
            {
                error = "DataPool:SetCanUseHotKey service Lua exception";
            }
            catch (const std::exception&)
            {
                error = "DataPool:SetCanUseHotKey service exception";
            }
            // Enter Lua's error path after the callback's C++ objects unwind.
            // Unknown/native faults propagate to the game's existing fatal path.
            if (error)
                return luaL_error(state, "%s", error);
            return 0;
        }
    }

    unsigned Register(LuaPlus::LuaObject& globals, const Services& services)
    {
        lua_State* state = globals.GetState()->GetCState();
        const int top = lua_gettop(state);
        try
        {
            globals.PushStack();
            lua_pushstring(state, "DataPool");
            lua_rawget(state, -2);
            if (lua_type(state, -1) != LUA_TUSERDATA || !lua_getmetatable(state, -1))
                throw std::runtime_error("CysHostHotKeys requires the DataPool receiver and metatable");

            // LuaPlus 5.0 always supplies a default metatable, even when the
            // receiver has never received its own game metatable.
            lua_getdefaultmetatable(state, LUA_TUSERDATA);
            const bool defaultMetatable = lua_rawequal(state, -1, -2) != 0;
            lua_pop(state, 1);
            if (defaultMetatable)
                throw std::runtime_error("CysHostHotKeys requires the DataPool receiver and metatable");

            lua_pushstring(state, "SetCanUseHotKey");
            lua_gettable(state, -2);
            const bool missing = lua_isnil(state, -1) != 0;
            lua_pop(state, 1);
            if (!missing)
            {
                lua_settop(state, top);
                return 0;
            }

            lua_pushstring(state, "SetCanUseHotKey");
            new (lua_newuserdata(state, sizeof(Services))) Services(services);
            if (luaL_newmetatable(state, servicesMetatable))
            {
                lua_pushstring(state, "__metatable");
                lua_pushstring(state, "CysHostHotKeys.Services");
                lua_rawset(state, -3);
            }
            lua_setmetatable(state, -2);
            lua_pushcclosure(state, SetCanUseHotKey, 1);
            lua_rawset(state, -3);
            lua_settop(state, top);
            return 1;
        }
        catch (...)
        {
            lua_settop(state, top);
            throw;
        }
    }
}
