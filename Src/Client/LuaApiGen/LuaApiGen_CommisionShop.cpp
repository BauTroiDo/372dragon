




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_CommisionShop_CloseBuyConfrim(LuaPlus::LuaState* state) { return Stub(state, "CommisionShop", "CloseBuyConfrim", ""); }


        int LAG_CommisionShop_EnumAction(LuaPlus::LuaState* state) { return Stub(state, "CommisionShop", "EnumAction", "ob"); }


        int LAG_CommisionShop_EnumItem(LuaPlus::LuaState* state) { return Stub(state, "CommisionShop", "EnumItem", "sn"); }


        int LAG_CommisionShop_GetNpcId(LuaPlus::LuaState* state) { return Stub(state, "CommisionShop", "GetNpcId", "n"); }

        int LAG_CommisionShop_OnBuyConfrimed(LuaPlus::LuaState* state) { return Stub(state, "CommisionShop", "OnBuyConfrimed", ""); }

        int LAG_CommisionShop_OpenBuyConfrim(LuaPlus::LuaState* state) { return Stub(state, "CommisionShop", "OpenBuyConfrim", ""); }

        int LAG_CommisionShop_SendOpenCommisionShopMsg(LuaPlus::LuaState* state) { return Stub(state, "CommisionShop", "SendOpenCommisionShopMsg", ""); }
    }

    void Register_CommisionShop(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "CloseBuyConfrim")) table.Register("CloseBuyConfrim", LAG_CommisionShop_CloseBuyConfrim);
        if (IsMissing(table, "EnumAction")) table.Register("EnumAction", LAG_CommisionShop_EnumAction);
        if (IsMissing(table, "EnumItem")) table.Register("EnumItem", LAG_CommisionShop_EnumItem);
        if (IsMissing(table, "GetNpcId")) table.Register("GetNpcId", LAG_CommisionShop_GetNpcId);
        if (IsMissing(table, "OnBuyConfrimed")) table.Register("OnBuyConfrimed", LAG_CommisionShop_OnBuyConfrimed);
        if (IsMissing(table, "OpenBuyConfrim")) table.Register("OpenBuyConfrim", LAG_CommisionShop_OpenBuyConfrim);
        if (IsMissing(table, "SendOpenCommisionShopMsg")) table.Register("SendOpenCommisionShopMsg", LAG_CommisionShop_SendOpenCommisionShopMsg);
    }
}
