// CYS: clean-room timer environment bridge; see Docs/specs/lua/timers_vi.md.
#include "CysHostTimerLua.h"
#include "LuaPlus.h"

namespace CysHostTimerLua
{
    namespace
    {
        struct StackGuard
        {
            LuaPlus::LuaState* state;
            int top;
            bool& usable;
            StackGuard(LuaPlus::LuaState* lua, bool& stateUsable)
                : state(lua), top(lua->GetTop()), usable(stateUsable) {}
            ~StackGuard()
            {
                // A native C++ exception can bypass the VM's setjmp cleanup. In that
                // case even stack/environment recovery must not re-enter this state.
                if (usable) state->SetTop(top);
            }
        };

        struct Failure
        {
            Phase phase;
            int status;
            bool usable;
            Failure(Phase where = Phase::None, int code = 0, bool stateUsable = true)
                : phase(where), status(code), usable(stateUsable) {}
        };

        Failure RunChunk(LuaPlus::LuaState* state, const std::string& text,
            const char* name, Phase loadPhase, Phase callPhase) noexcept
        {
            Phase phase = loadPhase;
            try
            {
                int status = state->LoadBuffer(text.data(), text.size(), name);
                if (status != 0) return Failure(phase, status);
                phase = callPhase;
                status = state->PCall(0, 0, 0);
                return status == 0 ? Failure() : Failure(phase, status);
            }
            catch (...)
            {
                return Failure(phase, CppException, false);
            }
        }
    }

    const char* PhaseName(Phase phase) noexcept
    {
        switch (phase)
        {
        case Phase::None: return "none";
        case Phase::Unavailable: return "unavailable";
        case Phase::Preparation: return "preparation";
        case Phase::SelectLoad: return "select-load";
        case Phase::SelectCall: return "select-call";
        case Phase::ExpressionLoad: return "expression-load";
        case Phase::ExpressionCall: return "expression-call";
        case Phase::RestoreLoad: return "restore-load";
        case Phase::RestoreCall: return "restore-call";
        }
        return "unknown";
    }

    Result Execute(LuaPlus::LuaState* state, std::string& activeEnv,
        const std::string& owner, const std::string& expression) noexcept
    {
        Result result;
        if (!state)
        {
            result.phase = Phase::Unavailable;
            result.status = MissingState;
            result.stateUsable = false;
            return result;
        }
        StackGuard stack(state, result.stateUsable);
        try
        {
            const std::string oldName = activeEnv;
            std::string selectedName = owner + "_Env";
            std::string restoredName = oldName;
            // Allocate every command/name before changing the Lua environment. Keep
            // B's name-expression semantics, but avoid its fixed MAX_PATH buffer.
            const std::string selectCommand = "setmetatable(_G, {__index = " + selectedName + "});";
            const std::string restoreCommand = "setmetatable(_G, {__index = " + oldName + "});";

            Failure failure = RunChunk(state, selectCommand, "=CysTimer.select",
                Phase::SelectLoad, Phase::SelectCall);
            result.phase = failure.phase;
            result.status = failure.status;
            result.stateUsable = failure.usable;
            if (!result.stateUsable) return result;
            if (result.status == 0)
            {
                activeEnv.swap(selectedName);
                failure = RunChunk(state, expression, "=CysTimer.expression",
                    Phase::ExpressionLoad, Phase::ExpressionCall);
                result.phase = failure.phase;
                result.status = failure.status;
                result.stateUsable = failure.usable;
                if (!result.stateUsable) return result;
            }

            // B restores a previous name only when nonempty and different. CY also
            // attempts restoration after a failed select, whose Lua code may already
            // have changed the metatable before the active name was committed.
            const bool selectFailed = result.status != 0 &&
                (result.phase == Phase::SelectLoad || result.phase == Phase::SelectCall);
            if (!oldName.empty() && (oldName != activeEnv || selectFailed))
            {
                failure = RunChunk(state, restoreCommand, "=CysTimer.restore",
                    Phase::RestoreLoad, Phase::RestoreCall);
                result.restorePhase = failure.phase;
                result.restoreStatus = failure.status;
                result.stateUsable = failure.usable;
                if (failure.status == 0) activeEnv.swap(restoredName);
            }
        }
        catch (...)
        {
            // Preparatory C++ allocation failure happened outside the protected VM.
            result.phase = Phase::Preparation;
            result.status = CppException;
        }
        return result;
    }
}
