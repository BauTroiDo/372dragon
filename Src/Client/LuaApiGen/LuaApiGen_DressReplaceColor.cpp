




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_DressReplaceColor_ConditionCheck(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "ConditionCheck", "n"); }

        int LAG_DressReplaceColor_DressCanPaint(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "DressCanPaint", "n"); }

        int LAG_DressReplaceColor_DressCanWash(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "DressCanWash", "n"); }

        int LAG_DressReplaceColor_DressIsCanColour(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "DressIsCanColour", "n"); }

        int LAG_DressReplaceColor_DressOpenDressJian(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "DressOpenDressJian", ""); }

        int LAG_DressReplaceColor_EnableDressPaintTracing(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "EnableDressPaintTracing", ""); }

        int LAG_DressReplaceColor_FittingOnDress(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "FittingOnDress", ""); }

        int LAG_DressReplaceColor_FittingOnDressByDressJian(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "FittingOnDressByDressJian", ""); }

        int LAG_DressReplaceColor_FittingOnDressByYuanBaoShop(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "FittingOnDressByYuanBaoShop", ""); }

        int LAG_DressReplaceColor_GetDressDesc(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "GetDressDesc", "nsn"); }

        int LAG_DressReplaceColor_GetDressPaint_TipsBind(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "GetDressPaint_TipsBind", "n"); }

        int LAG_DressReplaceColor_GetDressVisualID(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "GetDressVisualID", "n"); }

        int LAG_DressReplaceColor_GetDressVisualIndex(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "GetDressVisualIndex", "nn"); }

        int LAG_DressReplaceColor_GetDressVisualInfo(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "GetDressVisualInfo", "snn"); }

        int LAG_DressReplaceColor_OpenDressPaintFitting(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "OpenDressPaintFitting", ""); }

        int LAG_DressReplaceColor_RestoreDressPaintFitting(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "RestoreDressPaintFitting", ""); }

        int LAG_DressReplaceColor_SetDressPaint_TipsBind(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "SetDressPaint_TipsBind", ""); }

        int LAG_DressReplaceColor_ShopFittingOnDress(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "ShopFittingOnDress", ""); }

        int LAG_DressReplaceColor_StoreDressByIndex(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "StoreDressByIndex", ""); }

        int LAG_DressReplaceColor_StoreDressType(LuaPlus::LuaState* state) { return Stub(state, "DressReplaceColor", "StoreDressType", ""); }
    }

    void Register_DressReplaceColor(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ConditionCheck")) table.Register("ConditionCheck", LAG_DressReplaceColor_ConditionCheck);
        if (IsMissing(table, "DressCanPaint")) table.Register("DressCanPaint", LAG_DressReplaceColor_DressCanPaint);
        if (IsMissing(table, "DressCanWash")) table.Register("DressCanWash", LAG_DressReplaceColor_DressCanWash);
        if (IsMissing(table, "DressIsCanColour")) table.Register("DressIsCanColour", LAG_DressReplaceColor_DressIsCanColour);
        if (IsMissing(table, "DressOpenDressJian")) table.Register("DressOpenDressJian", LAG_DressReplaceColor_DressOpenDressJian);
        if (IsMissing(table, "EnableDressPaintTracing")) table.Register("EnableDressPaintTracing", LAG_DressReplaceColor_EnableDressPaintTracing);
        if (IsMissing(table, "FittingOnDress")) table.Register("FittingOnDress", LAG_DressReplaceColor_FittingOnDress);
        if (IsMissing(table, "FittingOnDressByDressJian")) table.Register("FittingOnDressByDressJian", LAG_DressReplaceColor_FittingOnDressByDressJian);
        if (IsMissing(table, "FittingOnDressByYuanBaoShop")) table.Register("FittingOnDressByYuanBaoShop", LAG_DressReplaceColor_FittingOnDressByYuanBaoShop);
        if (IsMissing(table, "GetDressDesc")) table.Register("GetDressDesc", LAG_DressReplaceColor_GetDressDesc);
        if (IsMissing(table, "GetDressPaint_TipsBind")) table.Register("GetDressPaint_TipsBind", LAG_DressReplaceColor_GetDressPaint_TipsBind);
        if (IsMissing(table, "GetDressVisualID")) table.Register("GetDressVisualID", LAG_DressReplaceColor_GetDressVisualID);
        if (IsMissing(table, "GetDressVisualIndex")) table.Register("GetDressVisualIndex", LAG_DressReplaceColor_GetDressVisualIndex);
        if (IsMissing(table, "GetDressVisualInfo")) table.Register("GetDressVisualInfo", LAG_DressReplaceColor_GetDressVisualInfo);
        if (IsMissing(table, "OpenDressPaintFitting")) table.Register("OpenDressPaintFitting", LAG_DressReplaceColor_OpenDressPaintFitting);
        if (IsMissing(table, "RestoreDressPaintFitting")) table.Register("RestoreDressPaintFitting", LAG_DressReplaceColor_RestoreDressPaintFitting);
        if (IsMissing(table, "SetDressPaint_TipsBind")) table.Register("SetDressPaint_TipsBind", LAG_DressReplaceColor_SetDressPaint_TipsBind);
        if (IsMissing(table, "ShopFittingOnDress")) table.Register("ShopFittingOnDress", LAG_DressReplaceColor_ShopFittingOnDress);
        if (IsMissing(table, "StoreDressByIndex")) table.Register("StoreDressByIndex", LAG_DressReplaceColor_StoreDressByIndex);
        if (IsMissing(table, "StoreDressType")) table.Register("StoreDressType", LAG_DressReplaceColor_StoreDressType);
    }
}
