




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_ChatChannel_GetHoverChannelName(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ChatChannel", "GetHoverChannelName", "s"); }
    }

    void Register_UI_ChatChannel(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetHoverChannelName")) table.Register("GetHoverChannelName", LAG_UI_ChatChannel_GetHoverChannelName);
    }
}
