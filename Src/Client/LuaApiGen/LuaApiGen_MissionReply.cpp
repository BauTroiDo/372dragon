




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_MissionReply_DoAction(LuaPlus::LuaState* state) { return Stub(state, "MissionReply", "DoAction", ""); }

        int LAG_MissionReply_OpenSecondConfirmFrame(LuaPlus::LuaState* state) { return Stub(state, "MissionReply", "OpenSecondConfirmFrame", ""); }
    }

    void Register_MissionReply(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "DoAction")) table.Register("DoAction", LAG_MissionReply_DoAction);
        if (IsMissing(table, "OpenSecondConfirmFrame")) table.Register("OpenSecondConfirmFrame", LAG_MissionReply_OpenSecondConfirmFrame);
    }
}
