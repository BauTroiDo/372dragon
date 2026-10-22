




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_ChatBoard_SetChatString(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ChatBoard", "SetChatString", ""); }
    }

    void Register_UI_ChatBoard(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "SetChatString")) table.Register("SetChatString", LAG_UI_ChatBoard_SetChatString);
    }
}
