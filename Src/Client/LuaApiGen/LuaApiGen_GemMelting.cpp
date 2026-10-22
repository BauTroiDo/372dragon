




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_GemMelting_GetGemMeltingInfo(LuaPlus::LuaState* state) { return Stub(state, "GemMelting", "GetGemMeltingInfo", "nnnn"); }

        int LAG_GemMelting_UpdateProductAction(LuaPlus::LuaState* state) { return Stub(state, "GemMelting", "UpdateProductAction", "ob"); }
    }

    void Register_GemMelting(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetGemMeltingInfo")) table.Register("GetGemMeltingInfo", LAG_GemMelting_GetGemMeltingInfo);
        if (IsMissing(table, "UpdateProductAction")) table.Register("UpdateProductAction", LAG_GemMelting_UpdateProductAction);
    }
}
