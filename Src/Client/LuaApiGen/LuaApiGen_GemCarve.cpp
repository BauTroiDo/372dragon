




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_GemCarve_CarveItem(LuaPlus::LuaState* state) { return Stub(state, "GemCarve", "CarveItem", ""); }

        int LAG_GemCarve_GetGemCarveInfo(LuaPlus::LuaState* state) { return Stub(state, "GemCarve", "GetGemCarveInfo", "nnn"); }

        int LAG_GemCarve_UpdateProductAction(LuaPlus::LuaState* state) { return Stub(state, "GemCarve", "UpdateProductAction", "ob"); }
    }

    void Register_GemCarve(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "CarveItem")) table.Register("CarveItem", LAG_GemCarve_CarveItem);
        if (IsMissing(table, "GetGemCarveInfo")) table.Register("GetGemCarveInfo", LAG_GemCarve_GetGemCarveInfo);
        if (IsMissing(table, "UpdateProductAction")) table.Register("UpdateProductAction", LAG_GemCarve_UpdateProductAction);
    }
}
