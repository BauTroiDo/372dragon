// CYS: checked main-thread Lua evaluation for host timers; no UI or Win32 dependency.
#pragma once

#include <string>

namespace LuaPlus { class LuaState; }

namespace CysHostTimerLua
{
    enum class Phase
    {
        None, Unavailable, Preparation, SelectLoad, SelectCall,
        ExpressionLoad, ExpressionCall, RestoreLoad, RestoreCall
    };

    static const int CppException = -1;
    static const int MissingState = -2;

    struct Result
    {
        Phase phase = Phase::None;
        int status = 0;
        Phase restorePhase = Phase::None;
        int restoreStatus = 0;
        // False means a native exception crossed the Lua VM. Stop further dispatch;
        // catching it here does not prove that this legacy Lua state is recoverable.
        bool stateUsable = true;
        bool ok() const { return status == 0 && restoreStatus == 0 && stateUsable; }
    };

    const char* PhaseName(Phase phase) noexcept;

    // Caller owns state/activeEnv and invokes this only on their game thread.
    // Never returns Lua error text or expression contents in the result.
    Result Execute(LuaPlus::LuaState* state, std::string& activeEnv,
        const std::string& owner, const std::string& expression) noexcept;
}
