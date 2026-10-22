




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_Transfiguration_EnumTransfigeAction(LuaPlus::LuaState* state) { return Stub(state, "Transfiguration", "EnumTransfigeAction", "o"); }

        int LAG_Transfiguration_GetTrans(LuaPlus::LuaState* state) { return Stub(state, "Transfiguration", "GetTrans", "n"); }

        int LAG_Transfiguration_GetTransfigeActionItemCount(LuaPlus::LuaState* state) { return Stub(state, "Transfiguration", "GetTransfigeActionItemCount", "n"); }

        int LAG_Transfiguration_TransfigeActionCanbeCancel(LuaPlus::LuaState* state) { return Stub(state, "Transfiguration", "TransfigeActionCanbeCancel", "n"); }
    }

    void Register_Transfiguration(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "EnumTransfigeAction")) table.Register("EnumTransfigeAction", LAG_Transfiguration_EnumTransfigeAction);
        if (IsMissing(table, "GetTrans")) table.Register("GetTrans", LAG_Transfiguration_GetTrans);
        if (IsMissing(table, "GetTransfigeActionItemCount")) table.Register("GetTransfigeActionItemCount", LAG_Transfiguration_GetTransfigeActionItemCount);
        if (IsMissing(table, "TransfigeActionCanbeCancel")) table.Register("TransfigeActionCanbeCancel", LAG_Transfiguration_TransfigeActionCanbeCancel);
    }
}
