




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_RongYuUI_DoRongYuShopBuy(LuaPlus::LuaState* state) { return Stub(state, "RongYuUI", "DoRongYuShopBuy", ""); }

        int LAG_RongYuUI_EnumRongYuShop(LuaPlus::LuaState* state) { return Stub(state, "RongYuUI", "EnumRongYuShop", "on"); }

        int LAG_RongYuUI_GetRongYuShopInfo(LuaPlus::LuaState* state) { return Stub(state, "RongYuUI", "GetRongYuShopInfo", "n"); }

        int LAG_RongYuUI_GetRongYuShopItemNum(LuaPlus::LuaState* state) { return Stub(state, "RongYuUI", "GetRongYuShopItemNum", "n"); }
    }

    void Register_RongYuUI(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "DoRongYuShopBuy")) table.Register("DoRongYuShopBuy", LAG_RongYuUI_DoRongYuShopBuy);
        if (IsMissing(table, "EnumRongYuShop")) table.Register("EnumRongYuShop", LAG_RongYuUI_EnumRongYuShop);
        if (IsMissing(table, "GetRongYuShopInfo")) table.Register("GetRongYuShopInfo", LAG_RongYuUI_GetRongYuShopInfo);
        if (IsMissing(table, "GetRongYuShopItemNum")) table.Register("GetRongYuShopItemNum", LAG_RongYuUI_GetRongYuShopItemNum);
    }
}
