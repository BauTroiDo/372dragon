// CYS: clean-room read-only queries; B evidence is recorded in the Lua spec.
#include "CysHostQueries.h"
#include "LuaPlus.h"

#include <cmath>
#include <exception>
#include <limits>
#include <new>
#include <stdexcept>
#include <string>

namespace CysHostQueries
{
    namespace
    {
        const char* const servicesMetatable = "CysHostQueries.Services";

        std::int32_t ToInt32(double value)
        {
            const double truncated = std::trunc(value);
            const auto minimum = (std::numeric_limits<std::int32_t>::min)();
            const auto maximum = (std::numeric_limits<std::int32_t>::max)();
            if (!std::isfinite(value) || truncated < minimum || truncated > maximum)
                return minimum;
            return static_cast<std::int32_t>(truncated);
        }

        int GetItemTableIndex(lua_State* state)
        {
            if (lua_type(state, 2) != LUA_TNUMBER)
                return luaL_error(state, "PlayerPackage:GetItemTableIndex requires a numeric index");

            const auto* services = static_cast<const Services*>(
                luaL_checkudata(state, lua_upvalueindex(1), servicesMetatable));
            if (!services || !services->bagItemTableIndex)
                return luaL_error(state, "PlayerPackage:GetItemTableIndex service is unavailable");

            const std::int32_t index = ToInt32(lua_tonumber(state, 2));
            std::int32_t result = -1;
            const char* error = nullptr;
            try
            {
                result = services->bagItemTableIndex(services->context, index);
            }
            catch (const LuaPlus::LuaException&)
            {
                error = "PlayerPackage:GetItemTableIndex service Lua exception";
            }
            catch (const std::exception&)
            {
                error = "PlayerPackage:GetItemTableIndex service exception";
            }
            // Enter Lua's error path after the callback's C++ objects unwind.
            // Unknown/native faults propagate to the game's existing fatal path.
            if (error)
                return luaL_error(state, "%s", error);
            lua_pushnumber(state, static_cast<double>(result));
            return 1;
        }
        int GetServerAreaDis(lua_State* state)
        {
            if (lua_type(state, 2) != LUA_TNUMBER)
                return luaL_error(state, "GameProduceLogin:GetServerAreaDis requires a numeric index");
            const auto* services = static_cast<const Services*>(
                luaL_checkudata(state, lua_upvalueindex(1), servicesMetatable));
            if (!services || !services->areaDescription)
                return luaL_error(state, "GameProduceLogin:GetServerAreaDis service is unavailable");
            const char* result = nullptr;
            const char* error = nullptr;
            try { result = services->areaDescription(services->context, ToInt32(lua_tonumber(state, 2))); }
            catch (const LuaPlus::LuaException&) { error = "GameProduceLogin:GetServerAreaDis service Lua exception"; }
            catch (const std::exception&) { error = "GameProduceLogin:GetServerAreaDis service exception"; }
            if (error) return luaL_error(state, "%s", error);
            if (!result) return luaL_error(state, "GameProduceLogin:GetServerAreaDis service returned null");
            lua_pushstring(state, result);
            return 1;
        }

        int LoginNumeric(lua_State* state, bool page)
        {
            if (lua_type(state, 2) != LUA_TNUMBER)
                return luaL_error(state, "GameProduceLogin catalog requires a numeric index");
            const auto* services = static_cast<const Services*>(
                luaL_checkudata(state, lua_upvalueindex(1), servicesMetatable));
            if (!services || (page ? !services->setCurrentServerPage : !services->areaRecommendLevel))
                return luaL_error(state, "GameProduceLogin catalog service is unavailable");
            int result = 0;
            const char* error = nullptr;
            try {
                const auto index = ToInt32(lua_tonumber(state, 2));
                if (page) services->setCurrentServerPage(services->context, index);
                else result = services->areaRecommendLevel(services->context, index);
            }
            catch (const LuaPlus::LuaException&) { error = "GameProduceLogin catalog service Lua exception"; }
            catch (const std::exception&) { error = "GameProduceLogin catalog service exception"; }
            if (error) return luaL_error(state, "%s", error);
            if (page) return 0;
            lua_pushnumber(state, result);
            return 1;
        }
        int GetServerAreaRecommendLevel(lua_State* state) { return LoginNumeric(state, false); }
        int SetCurrentServerPage(lua_State* state) { return LoginNumeric(state, true); }

        int SetLoginServerKeyword(lua_State* state)
        {
            if (!lua_isstring(state, 2))
                return luaL_error(state, "GameProduceLogin:SetLoginServerKeyword requires text");
            const auto* services = static_cast<const Services*>(
                luaL_checkudata(state, lua_upvalueindex(1), servicesMetatable));
            if (!services || !services->setLoginServerKeyword)
                return luaL_error(state, "GameProduceLogin:SetLoginServerKeyword service is unavailable");
            int result = 0;
            const char* error = nullptr;
            try { result = services->setLoginServerKeyword(services->context, std::string(lua_tostring(state, 2))); }
            catch (const LuaPlus::LuaException&) { error = "GameProduceLogin search service Lua exception"; }
            catch (const std::exception&) { error = "GameProduceLogin search service exception"; }
            if (error) return luaL_error(state, "%s", error);
            lua_pushnumber(state, result);
            return 1;
        }

        void PushServer(lua_State* state, const LoginServerInfo& info, bool search)
        {
            lua_pushstring(state, info.name.c_str());
            lua_pushnumber(state, info.status);
            lua_pushnumber(state, info.recommendLevel);
            lua_pushnumber(state, info.isNew ? 1 : 0);
            if (!search) { lua_pushnumber(state, info.provider); return; }
            lua_pushnumber(state, info.rowOrdinal);
            lua_pushnumber(state, info.areaIndex);
            lua_pushnumber(state, info.serverId);
            lua_pushnumber(state, info.serverIndex);
        }

        int GetKeywordLoginServerInfo(lua_State* state)
        {
            if (lua_type(state, 2) != LUA_TNUMBER)
                return luaL_error(state, "GameProduceLogin:GetKeywordLoginServerInfo requires a numeric index");
            const auto* services = static_cast<const Services*>(
                luaL_checkudata(state, lua_upvalueindex(1), servicesMetatable));
            if (!services || !services->keywordLoginServerInfo)
                return luaL_error(state, "GameProduceLogin:GetKeywordLoginServerInfo service is unavailable");
            const char* error = nullptr;
            {
                LoginServerInfo result;
                try {
                    if (!services->keywordLoginServerInfo(services->context, ToInt32(lua_tonumber(state, 2)), result))
                        result = LoginServerInfo{};
                }
                catch (const LuaPlus::LuaException&) { error = "GameProduceLogin search service Lua exception"; }
                catch (const std::exception&) { error = "GameProduceLogin search service exception"; }
                if (!error) PushServer(state, result, true);
            }
            if (error) return luaL_error(state, "%s", error);
            return 8;
        }

        // This build implements local desktop account login, without either SDK.
        int IsYunGameMobileClient(lua_State* state) { lua_pushboolean(state, 0); return 1; }
        int IsWeGameClient(lua_State* state) { lua_pushnumber(state, 0); return 1; }
    }

    static unsigned RegisterMethod(LuaPlus::LuaObject& globals, const Services& services,
                                   const char* receiver, const char* method, lua_CFunction function)
    {
        lua_State* state = globals.GetState()->GetCState();
        const int top = lua_gettop(state);
        try
        {
            globals.PushStack();
            lua_pushstring(state, receiver);
            lua_rawget(state, -2);
            if (lua_type(state, -1) != LUA_TUSERDATA || !lua_getmetatable(state, -1))
                throw std::runtime_error(std::string("CysHostQueries requires the ") + receiver + " receiver and metatable");

            // LuaPlus 5.0 always supplies a default metatable, even when the
            // receiver has never received its own game metatable.
            lua_getdefaultmetatable(state, LUA_TUSERDATA);
            const bool defaultMetatable = lua_rawequal(state, -1, -2) != 0;
            lua_pop(state, 1);
            if (defaultMetatable)
                throw std::runtime_error(std::string("CysHostQueries requires the ") + receiver + " receiver and metatable");

            lua_pushstring(state, method);
            lua_gettable(state, -2);
            const bool missing = lua_isnil(state, -1) != 0;
            lua_pop(state, 1);
            if (!missing)
            {
                lua_settop(state, top);
                return 0;
            }

            lua_pushstring(state, method);
            new (lua_newuserdata(state, sizeof(Services))) Services(services);
            if (luaL_newmetatable(state, servicesMetatable))
            {
                lua_pushstring(state, "__metatable");
                lua_pushstring(state, "CysHostQueries.Services");
                lua_rawset(state, -3);
            }
            lua_setmetatable(state, -2);
            lua_pushcclosure(state, function, 1);
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
    unsigned Register(LuaPlus::LuaObject& globals, const Services& services)
    { return RegisterMethod(globals, services, "PlayerPackage", "GetItemTableIndex", GetItemTableIndex); }

    unsigned RegisterLogin(LuaPlus::LuaObject& globals, const Services& services)
    { return RegisterMethod(globals, services, "GameProduceLogin", "GetServerAreaDis", GetServerAreaDis); }

    unsigned RegisterGlLogin(LuaPlus::LuaObject& globals, const Services& services)
    {
        unsigned count = 0;
        count += RegisterMethod(globals, services, "GameProduceLogin", "GetServerAreaRecommendLevel", GetServerAreaRecommendLevel);
        count += RegisterMethod(globals, services, "GameProduceLogin", "SetCurrentServerPage", SetCurrentServerPage);
        count += RegisterMethod(globals, services, "GameProduceLogin", "SetLoginServerKeyword", SetLoginServerKeyword);
        count += RegisterMethod(globals, services, "GameProduceLogin", "GetKeywordLoginServerInfo", GetKeywordLoginServerInfo);
        count += RegisterMethod(globals, services, "GameProduceLogin", "IsYunGameMobileClient", IsYunGameMobileClient);
        count += RegisterMethod(globals, services, "GameProduceLogin", "IsWeGameClient", IsWeGameClient);
        return count;
    }

    int PushLoginServerInfo(LuaPlus::LuaState* state, const LoginServerInfo* info)
    {
        PushServer(state->GetCState(), info ? *info : LoginServerInfo{}, false);
        // CYS-CYGUI2: CY 3.71 SelectServer.lua reads 8 values (name, status, level, isNew, provider, prizeLevel,
        // version, wushentan; SelectServer_Data_GetServerInfo) and compares wushentan with 0 (replay-6: nil).
        // The private server has no prize/version/Wushentan data: 0.
        lua_State* raw = state->GetCState();
        lua_pushnumber(raw, 0);
        lua_pushnumber(raw, 0);
        lua_pushnumber(raw, 0);
        return 8;
    }

    int CheckAccount(LuaPlus::LuaState* owner, const AccountServices& services)
    {
        lua_State* state = owner->GetCState();
        if (!services.acceptingInput || !services.submit)
            return luaL_error(state, "GameProduceLogin:CheckAccount service is unavailable");
        const char* error = nullptr;
        bool accepting = false;
        try { accepting = services.acceptingInput(services.context); }
        catch (const LuaPlus::LuaException&) { error = "GameProduceLogin:CheckAccount state service exception"; }
        catch (const std::exception&) { error = "GameProduceLogin:CheckAccount state service exception"; }
        if (error) return luaL_error(state, "%s", error);
        if (!accepting) return 0; // B checks account-input state before arguments.
        // CYS-CY 14/09 (cs2-world): three call forms reach this host. 0.85: CheckAccount(account, password) - two
        // STRING arguments (legacy). client_GL: CheckAccount(suffix). CY 3.71 LogOn.lua LogOn_CheckAccount:
        // CheckAccount(strTail, bMiBao, bUseHardwareMiBao, strHardwarePWD, 1) - the suffix plus numbers/flags. The
        // old test "3+ arguments and #3 not nil" took the CY form for legacy: lua_isstring accepts the number bMiBao,
        // so "@changyou.com" became the account and "0" the password (gui-live-3: account '' after the suffix was
        // dropped; the profile filter refused it before any socket). Legacy now means exactly two string arguments.
        const bool legacy = lua_gettop(state) == 3 && lua_type(state, 2) == LUA_TSTRING && lua_type(state, 3) == LUA_TSTRING;
        if (!lua_isstring(state, 2) || (legacy && !lua_isstring(state, 3)))
            return luaL_error(state, "GameProduceLogin:CheckAccount requires a suffix or account and password");
        if (!legacy && !services.copyEditText)
            return luaL_error(state, "GameProduceLogin:CheckAccount editbox service is unavailable");
        {
            struct Input
            {
                char account[1024] = {}, password[1024] = {};
                std::string user, secret;
                ~Input()
                {
                    volatile char* p = password;
                    for (unsigned i = 0; i < sizeof(password); ++i) p[i] = 0;
                    if (!secret.empty()) {
                        p = &secret[0];
                        for (std::size_t i = 0; i < secret.size(); ++i) p[i] = 0;
                    }
                }
            } input;
            try
            {
                if (legacy)
                {
                    input.user = lua_tostring(state, 2);
                    input.secret = lua_tostring(state, 3);
                }
                else
                {
                    const int userSize = services.copyEditText(services.context, "LogOn_ID", input.account, sizeof(input.account));
                    const int secretSize = services.copyEditText(services.context, "LogOn_PassWord", input.password, sizeof(input.password));
                    if (userSize < 0 || secretSize < 0 || userSize >= sizeof(input.account) || secretSize >= sizeof(input.password) ||
                        input.account[userSize] != 0 || input.password[secretSize] != 0)
                        error = "GameProduceLogin:CheckAccount cannot read account editboxes";
                    else
                    {
                        input.user.assign(input.account, userSize);
                        input.user += lua_tostring(state, 2);
                        input.secret.assign(input.password, secretSize);
                    }
                }
                if (!error) services.submit(services.context, input.user, input.secret);
            }
            catch (const LuaPlus::LuaException&) { error = "GameProduceLogin:CheckAccount input service Lua exception"; }
            catch (const std::exception&) { error = "GameProduceLogin:CheckAccount input service exception"; }
        }
        if (error) return luaL_error(state, "%s", error);
        return 0;
    }

}
