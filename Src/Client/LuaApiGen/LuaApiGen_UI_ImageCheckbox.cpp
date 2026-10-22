




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_ImageCheckbox_FlashMe(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ImageCheckbox", "FlashMe", ""); }
    }

    void Register_UI_ImageCheckbox(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "FlashMe")) table.Register("FlashMe", LAG_UI_ImageCheckbox_FlashMe);
    }
}
