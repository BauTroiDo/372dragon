




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_ComplexWindow_AddChatBoardElement(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ComplexWindow", "AddChatBoardElement", ""); }


        int LAG_UI_ComplexWindow_AddJiaoZiElement(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ComplexWindow", "AddJiaoZiElement", ""); }


        int LAG_UI_ComplexWindow_RemoveTopElement(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ComplexWindow", "RemoveTopElement", ""); }
    }

    void Register_UI_ComplexWindow(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AddChatBoardElement")) table.Register("AddChatBoardElement", LAG_UI_ComplexWindow_AddChatBoardElement);
        if (IsMissing(table, "AddJiaoZiElement")) table.Register("AddJiaoZiElement", LAG_UI_ComplexWindow_AddJiaoZiElement);
        if (IsMissing(table, "RemoveTopElement")) table.Register("RemoveTopElement", LAG_UI_ComplexWindow_RemoveTopElement);
    }
}
