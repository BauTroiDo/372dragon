




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_ComboBox_AddTextItem(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ComboBox", "AddTextItem", ""); }


        int LAG_UI_ComboBox_ResetLastSelectIndex(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ComboBox", "ResetLastSelectIndex", ""); }
    }

    void Register_UI_ComboBox(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AddTextItem")) table.Register("AddTextItem", LAG_UI_ComboBox_AddTextItem);
        if (IsMissing(table, "ResetLastSelectIndex")) table.Register("ResetLastSelectIndex", LAG_UI_ComboBox_ResetLastSelectIndex);
    }
}
