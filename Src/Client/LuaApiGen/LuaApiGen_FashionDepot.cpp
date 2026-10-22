




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_FashionDepot_LuaFnGetFashionDataVisualDesc(LuaPlus::LuaState* state) { return Stub(state, "FashionDepot", "LuaFnGetFashionDataVisualDesc", "s"); }

        int LAG_FashionDepot_LuaFnGetFashionDepotItem(LuaPlus::LuaState* state) { return Stub(state, "FashionDepot", "LuaFnGetFashionDepotItem", "nn"); }

        int LAG_FashionDepot_LuaFnGetFashionId(LuaPlus::LuaState* state) { return Stub(state, "FashionDepot", "LuaFnGetFashionId", "n"); }

        int LAG_FashionDepot_LuaFnGetFashionName(LuaPlus::LuaState* state) { return Stub(state, "FashionDepot", "LuaFnGetFashionName", "s"); }

        int LAG_FashionDepot_LuaFnGetFashionProfileDressItem(LuaPlus::LuaState* state) { return Stub(state, "FashionDepot", "LuaFnGetFashionProfileDressItem", "on"); }

        int LAG_FashionDepot_LuaFnJudgeBagItem(LuaPlus::LuaState* state) { return Stub(state, "FashionDepot", "LuaFnJudgeBagItem", "n"); }


        int LAG_FashionDepot_LuaFnRefreshFashionDepot(LuaPlus::LuaState* state) { return Stub(state, "FashionDepot", "LuaFnRefreshFashionDepot", ""); }


        int LAG_FashionDepot_LuaFnSendAskFashionDepotData(LuaPlus::LuaState* state) { return Stub(state, "FashionDepot", "LuaFnSendAskFashionDepotData", ""); }


        int LAG_FashionDepot_LuaFnSendFashionDepotOperation(LuaPlus::LuaState* state) { return Stub(state, "FashionDepot", "LuaFnSendFashionDepotOperation", ""); }
    }

    void Register_FashionDepot(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "LuaFnGetFashionDataVisualDesc")) table.Register("LuaFnGetFashionDataVisualDesc", LAG_FashionDepot_LuaFnGetFashionDataVisualDesc);
        if (IsMissing(table, "LuaFnGetFashionDepotItem")) table.Register("LuaFnGetFashionDepotItem", LAG_FashionDepot_LuaFnGetFashionDepotItem);
        if (IsMissing(table, "LuaFnGetFashionId")) table.Register("LuaFnGetFashionId", LAG_FashionDepot_LuaFnGetFashionId);
        if (IsMissing(table, "LuaFnGetFashionName")) table.Register("LuaFnGetFashionName", LAG_FashionDepot_LuaFnGetFashionName);
        if (IsMissing(table, "LuaFnGetFashionProfileDressItem")) table.Register("LuaFnGetFashionProfileDressItem", LAG_FashionDepot_LuaFnGetFashionProfileDressItem);
        if (IsMissing(table, "LuaFnJudgeBagItem")) table.Register("LuaFnJudgeBagItem", LAG_FashionDepot_LuaFnJudgeBagItem);
        if (IsMissing(table, "LuaFnRefreshFashionDepot")) table.Register("LuaFnRefreshFashionDepot", LAG_FashionDepot_LuaFnRefreshFashionDepot);
        if (IsMissing(table, "LuaFnSendAskFashionDepotData")) table.Register("LuaFnSendAskFashionDepotData", LAG_FashionDepot_LuaFnSendAskFashionDepotData);
        if (IsMissing(table, "LuaFnSendFashionDepotOperation")) table.Register("LuaFnSendFashionDepotOperation", LAG_FashionDepot_LuaFnSendFashionDepotOperation);
    }
}
