




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_AnimateButton_PlayWarning(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AnimateButton", "PlayWarning", ""); }


        int LAG_UI_AnimateButton_SetFlash(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AnimateButton", "SetFlash", ""); }
    }

    void Register_UI_AnimateButton(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "PlayWarning")) table.Register("PlayWarning", LAG_UI_AnimateButton_PlayWarning);
        if (IsMissing(table, "SetFlash")) table.Register("SetFlash", LAG_UI_AnimateButton_SetFlash);
    }
}
