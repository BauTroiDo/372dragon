// CYS: clean-room adapters from the host-API contract, not generated stubs.
#include "CysHostGlobals.h"
#include "../WXClient/Script/CysCheckedScriptLua.h"
#include "LuaPlus.h"

#include <cstring>
#include <exception>
#include <new>
#include <stdexcept>

namespace CysHostGlobals
{
    namespace
    {
        const Services& GetServices(lua_State* state)
        {
            return *static_cast<const Services*>(lua_touserdata(state, lua_upvalueindex(1)));
        }

        std::string ReadString(lua_State* state, int index)
        {
            const char* value = lua_tostring(state, index);
            // B passes these values through GetString/C-string service parameters.
            return std::string(value);
        }

        int PackFormat(lua_State* state, int argumentCount)
        {
            const std::size_t capacity = 1024;
            const char* pattern = lua_tostring(state, 1);
            const std::size_t patternLength = std::strlen(pattern);
            if (patternLength == 0)
                return luaL_error(state, "ScriptGlobal_Format: empty template cannot be packed");
            if (patternLength >= capacity)
                return luaL_error(state, "ScriptGlobal_Format: packed output exceeds 1024-byte capacity");

            const char* arguments[15];
            std::size_t lengths[15];
            std::size_t payloadLength = 0;
            for (int i = 0; i < argumentCount; ++i)
            {
                arguments[i] = lua_tostring(state, i + 2);
                lengths[i] = std::strlen(arguments[i]);
                if (lengths[i] >= capacity || payloadLength + lengths[i] + 2 >= capacity)
                    return luaL_error(state, "ScriptGlobal_Format: packed output exceeds 1024-byte capacity");
                payloadLength += lengths[i] + 2;
            }

            const bool padded = payloadLength == 56;
            const std::size_t encodedLength = patternLength + 3 + payloadLength + (padded ? 1 : 0);
            if (encodedLength >= capacity)
                return luaL_error(state, "ScriptGlobal_Format: packed output exceeds 1024-byte capacity");

            // CYS: the host returns a packed dictionary expression, not rendered text.
            // Build the representation from its byte contract; UI resolves it later.
            std::string result;
            result.reserve(encodedLength);
            result.append(pattern, patternLength - 1);
            result += '*';
            result += static_cast<char>(argumentCount);
            result += static_cast<char>((payloadLength + 3 + (padded ? 1 : 0)) & 0xff);
            for (int i = 0; i < argumentCount; ++i)
            {
                result += '*';
                result += static_cast<char>(lengths[i] & 0xff);
                result.append(arguments[i], lengths[i]);
            }
            if (padded)
                result += ' ';
            result += '}';

            // Match B's C-string boundary, including truncation at a zero length byte.
            lua_pushstring(state, result.c_str());
            return 1;
        }

        int Format(lua_State* state)
        {
            const int count = lua_gettop(state);
            if (!lua_isstring(state, 1))
                return luaL_error(state, "ScriptGlobal_Format: expected a string template");
            if (count > 16)
                return luaL_error(state, "ScriptGlobal_Format: at most 15 arguments are supported");
            for (int i = 2; i <= count; ++i)
            {
                // CYS-CYGUI2: CY scripts pass nil slots (g_ServerInfo.strServerName[i] before the list arrives,
                // GameProduceLogin:GetSelectLoginServer() stub): format them as " " instead of failing the chunk.
                // Not "": a zero length byte truncates the packed expression at the C-string boundary (B contract),
                // and the login screen then showed the raw "WQWL_201130_03**" (smoke-login-4).
                if (lua_isnil(state, i))
                {
                    lua_pushstring(state, " ");
                    lua_replace(state, i);
                    continue;
                }
                if (!lua_isstring(state, i))
                    return luaL_error(state, "ScriptGlobal_Format: argument %d must be a string or number", i - 1);
            }

            const Services& services = GetServices(state);
            if (count == 1)
            {
                if (!services.pushEvent)
                    return luaL_error(state, "ScriptGlobal_Format: event service is unavailable");
                services.pushEvent(services.context, "NEW_DEBUGMESSAGE", {std::string(lua_tostring(state, 1))});
                return 0;
            }
            return PackFormat(state, count - 1);
        }

        int PushEvent(lua_State* state)
        {
            if (!lua_isstring(state, 1))
                return luaL_error(state, "PushEvent: expected an event name");
            const Services& services = GetServices(state);
            if (!services.pushEvent)
                return luaL_error(state, "PushEvent: event service is unavailable");

            std::vector<std::string> arguments;
            for (int i = 2; i <= lua_gettop(state); ++i)
            {
                // B stops at the first nil or value not convertible by lua_tostring.
                if (!lua_isstring(state, i))
                    break;
                arguments.push_back(ReadString(state, i));
            }
            services.pushEvent(services.context, ReadString(state, 1), arguments);
            return 0;
        }

        int CloseWindow(lua_State* state)
        {
            if (!lua_isstring(state, 1))
                return luaL_error(state, "CloseWindow: expected a window name");
            const Services& services = GetServices(state);
            if (!services.closeWindow)
                return luaL_error(state, "CloseWindow: window service is unavailable");
            const bool immediate = lua_type(state, 2) == LUA_TBOOLEAN && lua_toboolean(state, 2) != 0;
            services.closeWindow(services.context, ReadString(state, 1), immediate);
            return 0;
        }

        // CYS: B 0x229810 sends event 0x1ba, named SET_SOFTKEY_AIM.
        // Resolve by name: CY event IDs deliberately retain their legacy values.
        int SetSoftKeyAim(lua_State* state)
        {
            if (!lua_isstring(state, 1))
                return luaL_error(state, "SetSoftKeyAim: expected an editbox name");
            const Services& services = GetServices(state);
            if (!services.pushEvent)
                return luaL_error(state, "SetSoftKeyAim: event service is unavailable");
            services.pushEvent(services.context, "SET_SOFTKEY_AIM", {ReadString(state, 1)});
            return 0;
        }

        int OpenWindow(lua_State* state)
        {
            const Services& services = GetServices(state);
            if (!services.openWindowBlocked)
                return luaL_error(state, "OpenWindow: scene service is unavailable");
            // B checks the scene before examining the Lua arguments.
            if (services.openWindowBlocked(services.context)) return 0;
            if (!lua_isstring(state, 1))
                return luaL_error(state, "OpenWindow: expected a window name");
            if (!services.pushEvent)
                return luaL_error(state, "OpenWindow: event service is unavailable");
            services.pushEvent(services.context, "OPEN_WINDOW", {ReadString(state, 1)});
            return 0;
        }

        // CYS: GL ToggleWindow uses the same scene gate as OpenWindow and
        // dispatches the named event; each layout owns its visibility transition.
        int ToggleWindow(lua_State* state)
        {
            const Services& services = GetServices(state);
            if (!services.openWindowBlocked)
                return luaL_error(state, "ToggleWindow: scene service is unavailable");
            if (services.openWindowBlocked(services.context)) return 0;
            if (!lua_isstring(state, 1))
                return luaL_error(state, "ToggleWindow: expected a window name");
            if (!services.pushEvent)
                return luaL_error(state, "ToggleWindow: event service is unavailable");
            services.pushEvent(services.context, "TOGGLE_WINDOW", {ReadString(state, 1)});
            return 0;
        }

        std::string FormatDictionaryLiteral(const std::string& pattern)
        {
            // B formats into 2048 bytes, but the Lua wrapper supplies no varargs.
            // Reject consuming/invalid conversions rather than reading absent data.
            std::string result;
            for (std::size_t i = 0; i < pattern.size() && pattern[i] != '\0'; ++i)
            {
                char value = pattern[i];
                if (value == '%')
                {
                    if (i + 1 >= pattern.size() || pattern[i + 1] != '%')
                        throw std::runtime_error("GetDictionaryString: template requires unsupported format arguments");
                    ++i;
                }
                if (result.size() < 2048) result += value;
            }
            return result;
        }

        int GetDictionaryString(lua_State* state)
        {
            // B returns no values for non-string-convertible keys; extras are ignored.
            if (!lua_isstring(state, 1)) return 0;
            const Services& services = GetServices(state);
            if (!services.dictionaryText || !services.stripTextColour)
                return luaL_error(state, "GetDictionaryString: dictionary service is unavailable");
            const std::string pattern = services.dictionaryText(services.context, ReadString(state, 1));
            const std::string formatted = FormatDictionaryLiteral(pattern);
            const std::string result = services.stripTextColour(services.context, formatted);
            lua_pushstring(state, result.c_str());
            return 1;
        }

        int HideContexMenu4Speaker(lua_State* state)
        {
            const Services& services = GetServices(state);
            if (!services.pushEvent)
                return luaL_error(state, "Talk:HideContexMenu4Speaker: event service is unavailable");
            services.pushEvent(services.context, "HIDE_CONTEXMENU_SPEAKER", {});
            return 0;
        }

        int CallService(lua_State* state, lua_CFunction function)
        {
            try
            {
                return function(state);
            }
            catch (const CysCheckedScriptLua::StateUnavailable&)
            {
                // A nested native failure invalidated the VM; no Lua API is safe here.
                throw;
            }
            catch (const std::exception& error)
            {
                lua_pushfstring(state, "host service failed: %s", error.what());
            }
            catch (const LuaPlus::LuaException& error)
            {
                lua_pushfstring(state, "host service failed: %s", error.GetMessage());
            }
            // Enter Lua's error path after C++ temporaries and the exception unwind.
            return lua_error(state);
        }

        int LuaFormat(lua_State* state) { return CallService(state, Format); }
        int LuaPushEvent(lua_State* state) { return CallService(state, PushEvent); }
        int LuaCloseWindow(lua_State* state) { return CallService(state, CloseWindow); }
        int LuaSetSoftKeyAim(lua_State* state) { return CallService(state, SetSoftKeyAim); }
        int LuaOpenWindow(lua_State* state) { return CallService(state, OpenWindow); }
        int LuaToggleWindow(lua_State* state) { return CallService(state, ToggleWindow); }
        int LuaGetDictionaryString(lua_State* state) { return CallService(state, GetDictionaryString); }
        int LuaHideContexMenu4Speaker(lua_State* state) { return CallService(state, HideContexMenu4Speaker); }

        unsigned RegisterOne(LuaPlus::LuaObject& globals, const char* name,
                             lua_CFunction function, const Services& services)
        {
            if (!globals.GetByName(name).IsNil())
                return 0;
            lua_State* state = globals.GetState()->GetCState();
            globals.PushStack();
            lua_pushstring(state, name);
            new (lua_newuserdata(state, sizeof(Services))) Services(services);
            lua_pushcclosure(state, function, 1);
            lua_rawset(state, -3);
            lua_pop(state, 1);
            return 1;
        }
    }

    unsigned Register(LuaPlus::LuaObject& globals, const Services& services)
    {
        unsigned added = RegisterOne(globals, "ScriptGlobal_Format", LuaFormat, services);
        added += RegisterOne(globals, "PushEvent", LuaPushEvent, services);
        added += RegisterOne(globals, "CloseWindow", LuaCloseWindow, services);
        added += RegisterOne(globals, "SetSoftKeyAim", LuaSetSoftKeyAim, services);
        added += RegisterOne(globals, "OpenWindow", LuaOpenWindow, services);
        added += RegisterOne(globals, "ToggleWindow", LuaToggleWindow, services);
        added += RegisterOne(globals, "GetDictionaryString", LuaGetDictionaryString, services);
        return added;
    }

    unsigned RegisterTalk(LuaPlus::LuaObject& globals, const Services& services)
    {
        lua_State* state = globals.GetState()->GetCState();
        const int top = lua_gettop(state);
        try
        {
            globals.PushStack();
            lua_pushstring(state, "Talk");
            lua_rawget(state, -2);
            if (lua_type(state, -1) != LUA_TUSERDATA || !lua_getmetatable(state, -1))
                throw std::runtime_error("CysHostGlobals requires the Talk receiver and metatable");
            lua_getdefaultmetatable(state, LUA_TUSERDATA);
            const bool defaultMetatable = lua_rawequal(state, -1, -2) != 0;
            lua_pop(state, 1);
            if (defaultMetatable)
                throw std::runtime_error("CysHostGlobals requires the Talk receiver and metatable");
            lua_pushstring(state, "HideContexMenu4Speaker");
            lua_gettable(state, -2);
            const bool missing = lua_isnil(state, -1) != 0;
            lua_pop(state, 1);
            if (missing)
            {
                lua_pushstring(state, "HideContexMenu4Speaker");
                new (lua_newuserdata(state, sizeof(Services))) Services(services);
                lua_pushcclosure(state, LuaHideContexMenu4Speaker, 1);
                lua_rawset(state, -3);
            }
            lua_settop(state, top);
            return missing ? 1 : 0;
        }
        catch (...)
        {
            lua_settop(state, top);
            throw;
        }
    }
}
