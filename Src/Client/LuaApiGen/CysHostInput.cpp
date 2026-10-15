#include "CysHostInput.h"
#include "LuaPlus.h"
#include <exception>
#include <new>

namespace CysHostInput
{
    namespace
    {
        const Services& services(lua_State* state)
        { return *static_cast<const Services*>(lua_touserdata(state, lua_upvalueindex(1))); }

        int activeInput(lua_State* state)
        {
            const Services& api = services(state);
            if (!api.activeInputName) return luaL_error(state, "GetActiveInput service is unavailable");
            const char* name = api.activeInputName(api.context);
            lua_pushstring(state, name ? name : ""); // B returns an empty string for no input.
            return 1;
        }
        int capsLock(lua_State* state)
        {
            const Services& api = services(state);
            if (!api.capsLockStatus) return luaL_error(state, "GetCaplockStatus service is unavailable");
            lua_pushnumber(state, api.capsLockStatus(api.context) & 1);
            return 1;
        }
        int call(lua_State* state, int (*function)(lua_State*))
        {
            const char* error = nullptr;
            try { return function(state); }
            catch (const LuaPlus::LuaException&) { error = "input service Lua exception"; }
            catch (const std::exception&) { error = "input service exception"; }
            return luaL_error(state, "%s", error);
        }
        int luaActiveInput(lua_State* state) { return call(state, activeInput); }
        int luaCapsLock(lua_State* state) { return call(state, capsLock); }

        unsigned add(LuaPlus::LuaObject& globals, const char* name,
                     lua_CFunction function, const Services& api)
        {
            if (!globals.GetByName(name).IsNil()) return 0;
            lua_State* state = globals.GetState()->GetCState();
            globals.PushStack();
            lua_pushstring(state, name);
            new (lua_newuserdata(state, sizeof(Services))) Services(api);
            lua_pushcclosure(state, function, 1);
            lua_rawset(state, -3);
            lua_pop(state, 1);
            return 1;
        }
    }
    unsigned Register(LuaPlus::LuaObject& globals, const Services& api)
    {
        unsigned count = add(globals, "GetActiveInput", luaActiveInput, api);
        return count + add(globals, "GetCaplockStatus", luaCapsLock, api);
    }
}
