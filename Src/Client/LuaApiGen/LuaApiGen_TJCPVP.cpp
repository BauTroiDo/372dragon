




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_TJCPVP_GetExchangedNum(LuaPlus::LuaState* state) { return Stub(state, "TJCPVP", "GetExchangedNum", "n"); }

        int LAG_TJCPVP_GetShopItemCount(LuaPlus::LuaState* state) { return Stub(state, "TJCPVP", "GetShopItemCount", "n"); }

        int LAG_TJCPVP_GetShopItemInfo(LuaPlus::LuaState* state) { return Stub(state, "TJCPVP", "GetShopItemInfo", "nnnnnnn"); }
    }

    void Register_TJCPVP(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetExchangedNum")) table.Register("GetExchangedNum", LAG_TJCPVP_GetExchangedNum);
        if (IsMissing(table, "GetShopItemCount")) table.Register("GetShopItemCount", LAG_TJCPVP_GetShopItemCount);
        if (IsMissing(table, "GetShopItemInfo")) table.Register("GetShopItemInfo", LAG_TJCPVP_GetShopItemInfo);
    }
}
