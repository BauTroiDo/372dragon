




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_ProgressBar_GetProgress(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ProgressBar", "GetProgress", "n"); }
    }

    void Register_UI_ProgressBar(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetProgress")) table.Register("GetProgress", LAG_UI_ProgressBar_GetProgress);
    }
}
