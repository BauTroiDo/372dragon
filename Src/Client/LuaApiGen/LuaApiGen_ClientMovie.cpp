




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_ClientMovie_HasMovie(LuaPlus::LuaState* state) { return Stub(state, "ClientMovie", "HasMovie", "b"); }

        int LAG_ClientMovie_IsPlaying(LuaPlus::LuaState* state) { return Stub(state, "ClientMovie", "IsPlaying", "b"); }

        int LAG_ClientMovie_Pause(LuaPlus::LuaState* state) { return Stub(state, "ClientMovie", "Pause", "b"); }


        int LAG_ClientMovie_Play(LuaPlus::LuaState* state) { return Stub(state, "ClientMovie", "Play", "b"); }

        int LAG_ClientMovie_Stop(LuaPlus::LuaState* state) { return Stub(state, "ClientMovie", "Stop", "b"); }

        int LAG_ClientMovie_TestPlay(LuaPlus::LuaState* state) { return Stub(state, "ClientMovie", "TestPlay", ""); }
    }

    void Register_ClientMovie(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "HasMovie")) table.Register("HasMovie", LAG_ClientMovie_HasMovie);
        if (IsMissing(table, "IsPlaying")) table.Register("IsPlaying", LAG_ClientMovie_IsPlaying);
        if (IsMissing(table, "Pause")) table.Register("Pause", LAG_ClientMovie_Pause);
        if (IsMissing(table, "Play")) table.Register("Play", LAG_ClientMovie_Play);
        if (IsMissing(table, "Stop")) table.Register("Stop", LAG_ClientMovie_Stop);
        if (IsMissing(table, "TestPlay")) table.Register("TestPlay", LAG_ClientMovie_TestPlay);
    }
}
