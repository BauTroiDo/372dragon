#include "ai/AIScript.h"
#include "sol.hpp"
extern "C"
{
    int luaopen_laiscript(lua_State *L)
	{
		sol::state_view state_view(L);
        auto laiscript = state_view.create_table();
        laiscript.new_usertype<AIScript>(
		    "AIScript", "new",sol::initializers([](AIScript &uninitialized_memory)
							  { return new (&uninitialized_memory) AIScript(); }),
            "ParseScript", &AIScript::ParseScript,
            "ProcessScript", &AIScript::ProcessScript
        );

        return laiscript.push();
    }
}