




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_StallBbs_DeleteMessageByID(LuaPlus::LuaState* state) { return Stub(state, "StallBbs", "DeleteMessageByID", ""); }
    }

    void Register_StallBbs(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "DeleteMessageByID")) table.Register("DeleteMessageByID", LAG_StallBbs_DeleteMessageByID);
    }
}
