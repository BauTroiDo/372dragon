




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_Helper_GotoHelper(LuaPlus::LuaState* state) { return Stub(state, "Helper", "GotoHelper", "n"); }

        int LAG_Helper_GotoPaihang(LuaPlus::LuaState* state) { return Stub(state, "Helper", "GotoPaihang", ""); }

        int LAG_Helper_GotoRecUpdate(LuaPlus::LuaState* state) { return Stub(state, "Helper", "GotoRecUpdate", ""); }
    }

    void Register_Helper(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GotoHelper")) table.Register("GotoHelper", LAG_Helper_GotoHelper);
        if (IsMissing(table, "GotoPaihang")) table.Register("GotoPaihang", LAG_Helper_GotoPaihang);
        if (IsMissing(table, "GotoRecUpdate")) table.Register("GotoRecUpdate", LAG_Helper_GotoRecUpdate);
    }
}
