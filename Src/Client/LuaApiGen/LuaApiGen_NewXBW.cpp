




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_NewXBW_AskTeamListInfo(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "AskTeamListInfo", "n"); }


        int LAG_NewXBW_CreateTeam(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "CreateTeam", ""); }


        int LAG_NewXBW_DeleteMember(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "DeleteMember", ""); }


        int LAG_NewXBW_GetExchangedNum(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetExchangedNum", "n"); }

        int LAG_NewXBW_GetMyTeamInfo(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetMyTeamInfo", "nnnnns"); }

        int LAG_NewXBW_GetMyTeamLockedFlag(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetMyTeamLockedFlag", "n"); }

        int LAG_NewXBW_GetMyTeamMemberInfo(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetMyTeamMemberInfo", "nnnnnnnnn"); }

        int LAG_NewXBW_GetMyTeamMemberInfoByName(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetMyTeamMemberInfoByName", "nnnnnnnns"); }

        int LAG_NewXBW_GetMyTeamName(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetMyTeamName", "s"); }


        int LAG_NewXBW_GetRankBaseInfo(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetRankBaseInfo", "n"); }


        int LAG_NewXBW_GetRankMemberInfo(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetRankMemberInfo", "t"); }


        int LAG_NewXBW_GetRankTeamInfo(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetRankTeamInfo", "t"); }


        int LAG_NewXBW_GetShopCoin(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetShopCoin", "n"); }

        int LAG_NewXBW_GetShopItemCount(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetShopItemCount", "n"); }


        int LAG_NewXBW_GetShopItemInfo(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetShopItemInfo", "nnnnnnnn"); }

        int LAG_NewXBW_GetTeamListInfo(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetTeamListInfo", "nnnss"); }

        int LAG_NewXBW_GetTeamMemberCountMax(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetTeamMemberCountMax", "n"); }

        int LAG_NewXBW_GetViewTeamMemberInfo(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetViewTeamMemberInfo", "nnnnnnn"); }


        int LAG_NewXBW_GetXbwHonourWallInfo(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetXbwHonourWallInfo", "t"); }


        int LAG_NewXBW_GetXbwHonourWallSeasonCount(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "GetXbwHonourWallSeasonCount", "n"); }

        int LAG_NewXBW_IsDeputy(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "IsDeputy", "n"); }

        int LAG_NewXBW_IsHasDeputy(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "IsHasDeputy", "n"); }

        int LAG_NewXBW_IsLeader(LuaPlus::LuaState* state) { return Stub(state, "NewXBW", "IsLeader", "n"); }
    }

    void Register_NewXBW(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AskTeamListInfo")) table.Register("AskTeamListInfo", LAG_NewXBW_AskTeamListInfo);
        if (IsMissing(table, "CreateTeam")) table.Register("CreateTeam", LAG_NewXBW_CreateTeam);
        if (IsMissing(table, "DeleteMember")) table.Register("DeleteMember", LAG_NewXBW_DeleteMember);
        if (IsMissing(table, "GetExchangedNum")) table.Register("GetExchangedNum", LAG_NewXBW_GetExchangedNum);
        if (IsMissing(table, "GetMyTeamInfo")) table.Register("GetMyTeamInfo", LAG_NewXBW_GetMyTeamInfo);
        if (IsMissing(table, "GetMyTeamLockedFlag")) table.Register("GetMyTeamLockedFlag", LAG_NewXBW_GetMyTeamLockedFlag);
        if (IsMissing(table, "GetMyTeamMemberInfo")) table.Register("GetMyTeamMemberInfo", LAG_NewXBW_GetMyTeamMemberInfo);
        if (IsMissing(table, "GetMyTeamMemberInfoByName")) table.Register("GetMyTeamMemberInfoByName", LAG_NewXBW_GetMyTeamMemberInfoByName);
        if (IsMissing(table, "GetMyTeamName")) table.Register("GetMyTeamName", LAG_NewXBW_GetMyTeamName);
        if (IsMissing(table, "GetRankBaseInfo")) table.Register("GetRankBaseInfo", LAG_NewXBW_GetRankBaseInfo);
        if (IsMissing(table, "GetRankMemberInfo")) table.Register("GetRankMemberInfo", LAG_NewXBW_GetRankMemberInfo);
        if (IsMissing(table, "GetRankTeamInfo")) table.Register("GetRankTeamInfo", LAG_NewXBW_GetRankTeamInfo);
        if (IsMissing(table, "GetShopCoin")) table.Register("GetShopCoin", LAG_NewXBW_GetShopCoin);
        if (IsMissing(table, "GetShopItemCount")) table.Register("GetShopItemCount", LAG_NewXBW_GetShopItemCount);
        if (IsMissing(table, "GetShopItemInfo")) table.Register("GetShopItemInfo", LAG_NewXBW_GetShopItemInfo);
        if (IsMissing(table, "GetTeamListInfo")) table.Register("GetTeamListInfo", LAG_NewXBW_GetTeamListInfo);
        if (IsMissing(table, "GetTeamMemberCountMax")) table.Register("GetTeamMemberCountMax", LAG_NewXBW_GetTeamMemberCountMax);
        if (IsMissing(table, "GetViewTeamMemberInfo")) table.Register("GetViewTeamMemberInfo", LAG_NewXBW_GetViewTeamMemberInfo);
        if (IsMissing(table, "GetXbwHonourWallInfo")) table.Register("GetXbwHonourWallInfo", LAG_NewXBW_GetXbwHonourWallInfo);
        if (IsMissing(table, "GetXbwHonourWallSeasonCount")) table.Register("GetXbwHonourWallSeasonCount", LAG_NewXBW_GetXbwHonourWallSeasonCount);
        if (IsMissing(table, "IsDeputy")) table.Register("IsDeputy", LAG_NewXBW_IsDeputy);
        if (IsMissing(table, "IsHasDeputy")) table.Register("IsHasDeputy", LAG_NewXBW_IsHasDeputy);
        if (IsMissing(table, "IsLeader")) table.Register("IsLeader", LAG_NewXBW_IsLeader);
    }
}
