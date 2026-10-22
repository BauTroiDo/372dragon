




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_Effect_playEffect(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Effect", "playEffect", ""); }


        int LAG_UI_Effect_replayEffect(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Effect", "replayEffect", ""); }
    }

    void Register_UI_Effect(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "playEffect")) table.Register("playEffect", LAG_UI_Effect_playEffect);
        if (IsMissing(table, "replayEffect")) table.Register("replayEffect", LAG_UI_Effect_replayEffect);
    }
}
