// CYS: checked UI script execution; fixed metadata only, no expression/error text.
#pragma once
#include "LuaPlus.h"
#include <cstdio>
#include <cstring>
#include <string>

namespace CysCheckedScriptLua
{
    // Deliberately not std::exception: generic host-service translation must not
    // turn an unusable VM into lua_error and re-enter it during native unwind.
    struct StateUnavailable
    {
        static const char* Message() noexcept { return "CYS Lua state unavailable after native failure"; }
    };
    enum class Phase { None, Unavailable, Preparation, SelectLoad, SelectCall, ExpressionLoad, ExpressionCall };
    enum { CppException = -1, MissingState = -2, InvalidInput = -3, StackCapacity = -4 };
    struct Result
    {
        Phase phase = Phase::None;
        int status = 0;
        bool stateUsable = true;
        bool restored = false;
        int stackTop = -1;      // CYS-CYGUI: lua_gettop when the chunk started (fixed metadata, no script text)
        // CYS-CYGUI2: the Lua error object of a failed chunk, printable ASCII only (other bytes -> '?'), truncated.
        // Needed to fix the CY scripts by group; never re-enters the VM (lua_tostring on the object left by pcall).
        char error[200] = {};
        bool ok() const { return status == 0 && stateUsable; }
    };
    inline void ThrowIfUnusable(const Result& result)
    { if (!result.stateUsable) throw StateUnavailable(); }
    inline const char* PhaseName(Phase value) noexcept
    {
        switch (value)
        {
        case Phase::None: return "none";
        case Phase::Unavailable: return "unavailable";
        case Phase::Preparation: return "preparation";
        case Phase::SelectLoad: return "select-load";
        case Phase::SelectCall: return "select-call";
        case Phase::ExpressionLoad: return "expression-load";
        case Phase::ExpressionCall: return "expression-call";
        }
        return "unknown";
    }
    inline bool Identifier(const std::string& name) noexcept
    {
        if (name.empty() || name.size() > 96) return false;
        for (std::size_t i = 0; i != name.size(); ++i)
        {
            const unsigned char c = static_cast<unsigned char>(name[i]);
            if (!(c == '_' || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
                  (i != 0 && c >= '0' && c <= '9'))) return false;
        }
        return true;
    }
    namespace Detail
    {
        // CYS-CYGUI2: copy the error object pcall/load left on top of the stack into result.error (sanitized).
        inline void CaptureError(lua_State* raw, Result& result) noexcept
        {
            if (!raw || lua_gettop(raw) < 1 || !lua_isstring(raw, -1)) return;
            const char* text = lua_tostring(raw, -1);
            if (!text) return;
            std::size_t n = 0;
            for (; text[n] && n + 1 < sizeof(result.error); ++n)
            {
                const unsigned char c = static_cast<unsigned char>(text[n]);
                result.error[n] = (c >= 0x20 && c < 0x7f) ? static_cast<char>(c) : '?';
            }
            result.error[n] = 0;
        }
        inline void Chunk(LuaPlus::LuaState* state, const char* text, std::size_t length,
            const char* name, Phase load, Phase call, Result& result) noexcept
        {
            result.phase = load;
            try
            {
                result.status = state->LoadBuffer(text, length, name);
                if (result.status != 0) { CaptureError(state->GetCState(), result); return; }
                result.phase = call;
                result.status = state->PCall(0, 0, 0);
                if (result.status == 0) result.phase = Phase::None;
                else CaptureError(state->GetCState(), result);
            }
            catch (...)
            {
                // Native unwind can bypass the VM's setjmp cleanup. Never re-enter it.
                result.status = CppException;
                result.stateUsable = false;
            }
        }
    }
    // The caller owns the Lua state and active name on the GUI thread. Restore the
    // actual previous metatable, including nil, without executing a Lua restore string.
    inline Result Execute(LuaPlus::LuaState* state, std::string& activeEnv,
        const std::string& selectedEnv, const char* expression) noexcept
    {
        Result result;
        if (!state)
        { result.phase = Phase::Unavailable; result.status = MissingState; result.stateUsable = false; return result; }
        if (!expression || !Identifier(selectedEnv))
        { result.phase = Phase::Preparation; result.status = InvalidInput; return result; }
        bool enteredVm = false;
        try
        {
            // Finish C++ allocations before changing either environment.
            std::string previousName = activeEnv;
            std::string nextName = selectedEnv;
            const std::string select = "setmetatable(_G, {__index = " + selectedEnv + "});";
            const std::size_t length = std::strlen(expression);
            enteredVm = true;
            lua_State* raw = state->GetCState();
            const int top = lua_gettop(raw);
            result.stackTop = top;
            if (!lua_checkstack(raw, 4))
            { result.phase = Phase::Preparation; result.status = StackCapacity; return result; }
            // Keep the old metatable rooted below both protected chunks, also across
            // nested C++ -> Lua -> C++ calls and collection performed by the script.
            if (!lua_getmetatable(raw, LUA_GLOBALSINDEX)) lua_pushnil(raw);
            Detail::Chunk(state, select.data(), select.size(), "=CysScript.select",
                Phase::SelectLoad, Phase::SelectCall, result);
            if (result.stateUsable && result.status == 0)
            {
                activeEnv.swap(nextName);
                Detail::Chunk(state, expression, length, "=CysScript.expression",
                    Phase::ExpressionLoad, Phase::ExpressionCall, result);
            }
            if (result.stateUsable)
            {
                lua_pushvalue(raw, top + 1);
                lua_setmetatable(raw, LUA_GLOBALSINDEX);
                lua_settop(raw, top);
                activeEnv.swap(previousName);
                result.restored = true;
            }
        }
        catch (...)
        {
            // Preparatory allocation failure is recoverable. A native exception in
            // a raw VM operation is not: conservatively prohibit subsequent VM use.
            result.phase = Phase::Preparation;
            result.status = CppException;
            result.stateUsable = !enteredVm;
        }
        return result;
    }
    struct Census
    {
        unsigned long long calls = 0, failures = 0, unusable = 0;
        // Fixed-length, filtered owner metadata. No Lua error object is inspected.
        bool Record(const Result& result, const std::string& owner, char* out, std::size_t capacity) noexcept
        {
            ++calls;
            if (out && capacity) out[0] = 0;
            if (result.ok())
            {
                // CYS-CYGUI: stack-depth sample every 250 calls (fixed metadata) to locate a Lua stack leak.
                if (out && capacity && calls % 250 == 0)
                {
                    std::snprintf(out, capacity, "CYS Lua sample env=%s top=%d calls=%llu failures=%llu",
                        Identifier(owner) ? owner.c_str() : "invalid", result.stackTop, calls, failures);
                    out[capacity - 1] = 0;
                    return true;
                }
                return false;
            }
            ++failures;
            if (!result.stateUsable) ++unusable;
            if (out && capacity)
            {
                std::snprintf(out, capacity,
                    "CYS Lua failure env=%s phase=%s code=%d usable=%d restored=%d top=%d calls=%llu failures=%llu unusable=%llu err=%s",
                    Identifier(owner) ? owner.c_str() : "invalid", PhaseName(result.phase), result.status,
                    result.stateUsable ? 1 : 0, result.restored ? 1 : 0, result.stackTop, calls, failures, unusable,
                    result.error);
                out[capacity - 1] = 0;
            }
            return true;
        }
    };
}
