




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_TLCJ_GetData(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "GetData", "n"); }

        int LAG_TLCJ_GetDropBagItemInfo(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "GetDropBagItemInfo", "nns"); }

        int LAG_TLCJ_GetExchangedNum(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "GetExchangedNum", "n"); }

        int LAG_TLCJ_GetPlayerSelectInfo(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "GetPlayerSelectInfo", "n"); }


        int LAG_TLCJ_GetShopCoinFst(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "GetShopCoinFst", "n"); }


        int LAG_TLCJ_GetShopCoinFstMax(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "GetShopCoinFstMax", "n"); }

        int LAG_TLCJ_GetShopCoinSec(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "GetShopCoinSec", "n"); }

        int LAG_TLCJ_GetShopCoinSecMax(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "GetShopCoinSecMax", "n"); }

        int LAG_TLCJ_GetShopItemCount(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "GetShopItemCount", "n"); }

        int LAG_TLCJ_GetShopItemInfo(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "GetShopItemInfo", "t"); }

        int LAG_TLCJ_GetSkillTips(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "GetSkillTips", "ss"); }


        int LAG_TLCJ_GetTeamMemberInfo(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "GetTeamMemberInfo", "t"); }

        int LAG_TLCJ_IsInTLCJScene(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "IsInTLCJScene", "n"); }

        int LAG_TLCJ_IsInTLCJScene_Team(LuaPlus::LuaState* state) { return Stub(state, "TLCJ", "IsInTLCJScene_Team", "n"); }
    }

    void Register_TLCJ(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetData")) table.Register("GetData", LAG_TLCJ_GetData);
        if (IsMissing(table, "GetDropBagItemInfo")) table.Register("GetDropBagItemInfo", LAG_TLCJ_GetDropBagItemInfo);
        if (IsMissing(table, "GetExchangedNum")) table.Register("GetExchangedNum", LAG_TLCJ_GetExchangedNum);
        if (IsMissing(table, "GetPlayerSelectInfo")) table.Register("GetPlayerSelectInfo", LAG_TLCJ_GetPlayerSelectInfo);
        if (IsMissing(table, "GetShopCoinFst")) table.Register("GetShopCoinFst", LAG_TLCJ_GetShopCoinFst);
        if (IsMissing(table, "GetShopCoinFstMax")) table.Register("GetShopCoinFstMax", LAG_TLCJ_GetShopCoinFstMax);
        if (IsMissing(table, "GetShopCoinSec")) table.Register("GetShopCoinSec", LAG_TLCJ_GetShopCoinSec);
        if (IsMissing(table, "GetShopCoinSecMax")) table.Register("GetShopCoinSecMax", LAG_TLCJ_GetShopCoinSecMax);
        if (IsMissing(table, "GetShopItemCount")) table.Register("GetShopItemCount", LAG_TLCJ_GetShopItemCount);
        if (IsMissing(table, "GetShopItemInfo")) table.Register("GetShopItemInfo", LAG_TLCJ_GetShopItemInfo);
        if (IsMissing(table, "GetSkillTips")) table.Register("GetSkillTips", LAG_TLCJ_GetSkillTips);
        if (IsMissing(table, "GetTeamMemberInfo")) table.Register("GetTeamMemberInfo", LAG_TLCJ_GetTeamMemberInfo);
        if (IsMissing(table, "IsInTLCJScene")) table.Register("IsInTLCJScene", LAG_TLCJ_IsInTLCJScene);
        if (IsMissing(table, "IsInTLCJScene_Team")) table.Register("IsInTLCJScene_Team", LAG_TLCJ_IsInTLCJScene_Team);
    }
}
