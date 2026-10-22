




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_ReturnTool_AskToReturn(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "AskToReturn", "n"); }

        int LAG_ReturnTool_EnumReturnItem(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "EnumReturnItem", "ons"); }

        int LAG_ReturnTool_EnumReturnPet(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "EnumReturnPet", "ssns"); }

        int LAG_ReturnTool_EnumReturnResult(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "EnumReturnResult", ""); }

        int LAG_ReturnTool_EnumReturnShop(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "EnumReturnShop", "snns"); }

        int LAG_ReturnTool_GetNowPageNum(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "GetNowPageNum", "n"); }


        int LAG_ReturnTool_GetPageInfo(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "GetPageInfo", ""); }

        int LAG_ReturnTool_GetReturnItemCount(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "GetReturnItemCount", "n"); }

        int LAG_ReturnTool_GetReturnItemPageTatol(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "GetReturnItemPageTatol", "n"); }

        int LAG_ReturnTool_GetReturnPetCount(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "GetReturnPetCount", "n"); }

        int LAG_ReturnTool_GetReturnPetPageTatol(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "GetReturnPetPageTatol", "n"); }

        int LAG_ReturnTool_GetReturnResultCount(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "GetReturnResultCount", "n"); }

        int LAG_ReturnTool_GetReturnShopCount(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "GetReturnShopCount", "n"); }

        int LAG_ReturnTool_GetReturnShopPageTatol(LuaPlus::LuaState* state) { return Stub(state, "ReturnTool", "GetReturnShopPageTatol", "n"); }
    }

    void Register_ReturnTool(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AskToReturn")) table.Register("AskToReturn", LAG_ReturnTool_AskToReturn);
        if (IsMissing(table, "EnumReturnItem")) table.Register("EnumReturnItem", LAG_ReturnTool_EnumReturnItem);
        if (IsMissing(table, "EnumReturnPet")) table.Register("EnumReturnPet", LAG_ReturnTool_EnumReturnPet);
        if (IsMissing(table, "EnumReturnResult")) table.Register("EnumReturnResult", LAG_ReturnTool_EnumReturnResult);
        if (IsMissing(table, "EnumReturnShop")) table.Register("EnumReturnShop", LAG_ReturnTool_EnumReturnShop);
        if (IsMissing(table, "GetNowPageNum")) table.Register("GetNowPageNum", LAG_ReturnTool_GetNowPageNum);
        if (IsMissing(table, "GetPageInfo")) table.Register("GetPageInfo", LAG_ReturnTool_GetPageInfo);
        if (IsMissing(table, "GetReturnItemCount")) table.Register("GetReturnItemCount", LAG_ReturnTool_GetReturnItemCount);
        if (IsMissing(table, "GetReturnItemPageTatol")) table.Register("GetReturnItemPageTatol", LAG_ReturnTool_GetReturnItemPageTatol);
        if (IsMissing(table, "GetReturnPetCount")) table.Register("GetReturnPetCount", LAG_ReturnTool_GetReturnPetCount);
        if (IsMissing(table, "GetReturnPetPageTatol")) table.Register("GetReturnPetPageTatol", LAG_ReturnTool_GetReturnPetPageTatol);
        if (IsMissing(table, "GetReturnResultCount")) table.Register("GetReturnResultCount", LAG_ReturnTool_GetReturnResultCount);
        if (IsMissing(table, "GetReturnShopCount")) table.Register("GetReturnShopCount", LAG_ReturnTool_GetReturnShopCount);
        if (IsMissing(table, "GetReturnShopPageTatol")) table.Register("GetReturnShopPageTatol", LAG_ReturnTool_GetReturnShopPageTatol);
    }
}
