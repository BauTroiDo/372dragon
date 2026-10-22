




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_Guild_AskAnyGuildDetailInfo(LuaPlus::LuaState* state) { return Stub(state, "Guild", "AskAnyGuildDetailInfo", ""); }


        int LAG_Guild_AskAnyGuildMembersInfo(LuaPlus::LuaState* state) { return Stub(state, "Guild", "AskAnyGuildMembersInfo", ""); }


        int LAG_Guild_AskCurCustomPositionName(LuaPlus::LuaState* state) { return Stub(state, "Guild", "AskCurCustomPositionName", ""); }


        int LAG_Guild_AskGuildFirstManInfo(LuaPlus::LuaState* state) { return Stub(state, "Guild", "AskGuildFirstManInfo", ""); }


        int LAG_Guild_AskGuildFirstManName(LuaPlus::LuaState* state) { return Stub(state, "Guild", "AskGuildFirstManName", ""); }


        int LAG_Guild_AskGuildLeaveWord(LuaPlus::LuaState* state) { return Stub(state, "Guild", "AskGuildLeaveWord", ""); }


        int LAG_Guild_AskGuildList4Page(LuaPlus::LuaState* state) { return Stub(state, "Guild", "AskGuildList4Page", ""); }


        int LAG_Guild_AskGuildNameList(LuaPlus::LuaState* state) { return Stub(state, "Guild", "AskGuildNameList", ""); }


        int LAG_Guild_AskModifyCustomPositionName(LuaPlus::LuaState* state) { return Stub(state, "Guild", "AskModifyCustomPositionName", "n"); }

        int LAG_Guild_CityLeagueRnameCheck(LuaPlus::LuaState* state) { return Stub(state, "Guild", "CityLeagueRnameCheck", "n"); }

        int LAG_Guild_CityRnameCheck(LuaPlus::LuaState* state) { return Stub(state, "Guild", "CityRnameCheck", "n"); }

        int LAG_Guild_CityRnameConfirm(LuaPlus::LuaState* state) { return Stub(state, "Guild", "CityRnameConfirm", ""); }

        int LAG_Guild_ClearCustomPositionName(LuaPlus::LuaState* state) { return Stub(state, "Guild", "ClearCustomPositionName", ""); }

        int LAG_Guild_CloseKickGuildBox(LuaPlus::LuaState* state) { return Stub(state, "Guild", "CloseKickGuildBox", ""); }


        int LAG_Guild_DemisGuildOK(LuaPlus::LuaState* state) { return Stub(state, "Guild", "DemisGuildOK", ""); }

        int LAG_Guild_ExchangeBangGong(LuaPlus::LuaState* state) { return Stub(state, "Guild", "ExchangeBangGong", ""); }


        int LAG_Guild_FixGuildInfo(LuaPlus::LuaState* state) { return Stub(state, "Guild", "FixGuildInfo", ""); }

        int LAG_Guild_GetAnyGuildMembersInfo(LuaPlus::LuaState* state) { return Stub(state, "Guild", "GetAnyGuildMembersInfo", "ss"); }

        int LAG_Guild_GetCurCustomPositionName(LuaPlus::LuaState* state) { return Stub(state, "Guild", "GetCurCustomPositionName", "s"); }

        int LAG_Guild_GetGuildContri(LuaPlus::LuaState* state) { return Stub(state, "Guild", "GetGuildContri", "n"); }

        int LAG_Guild_GetGuildLeaveWord(LuaPlus::LuaState* state) { return Stub(state, "Guild", "GetGuildLeaveWord", "s"); }

        int LAG_Guild_GetGuildNumCurPage(LuaPlus::LuaState* state) { return Stub(state, "Guild", "GetGuildNumCurPage", "n"); }

        int LAG_Guild_GetMemberBak(LuaPlus::LuaState* state) { return Stub(state, "Guild", "GetMemberBak", "n"); }

        int LAG_Guild_GetMembersXBHZTInfoByGUID(LuaPlus::LuaState* state) { return Stub(state, "Guild", "GetMembersXBHZTInfoByGUID", "nnnnnnnns"); }

        int LAG_Guild_GetMembersXBHZTInfoByIndex(LuaPlus::LuaState* state) { return Stub(state, "Guild", "GetMembersXBHZTInfoByIndex", "nnnnnnnnns"); }

        int LAG_Guild_GetMyPosition(LuaPlus::LuaState* state) { return Stub(state, "Guild", "GetMyPosition", "n"); }

        int LAG_Guild_GetXBHZTGroupLeaderInfo(LuaPlus::LuaState* state) { return Stub(state, "Guild", "GetXBHZTGroupLeaderInfo", "nnnnnnnns"); }

        int LAG_Guild_GetXBHZTGroupMemNum(LuaPlus::LuaState* state) { return Stub(state, "Guild", "GetXBHZTGroupMemNum", "n"); }

        int LAG_Guild_GetXBHZTGroupMenPaiMemNumInfo(LuaPlus::LuaState* state) { return Stub(state, "Guild", "GetXBHZTGroupMenPaiMemNumInfo", "nnnnnnnnnnnnnn"); }


        int LAG_Guild_InviteToGuild(LuaPlus::LuaState* state) { return Stub(state, "Guild", "InviteToGuild", "o"); }

        int LAG_Guild_IsChiefOrAss(LuaPlus::LuaState* state) { return Stub(state, "Guild", "IsChiefOrAss", "n"); }

        int LAG_Guild_IsGuildKeptOneWeed(LuaPlus::LuaState* state) { return Stub(state, "Guild", "IsGuildKeptOneWeed", "n"); }


        int LAG_Guild_ModifyGuildLeaveWord(LuaPlus::LuaState* state) { return Stub(state, "Guild", "ModifyGuildLeaveWord", "b"); }

        int LAG_Guild_PutGuildMoney(LuaPlus::LuaState* state) { return Stub(state, "Guild", "PutGuildMoney", ""); }


        int LAG_Guild_RealCityRnameConfirm(LuaPlus::LuaState* state) { return Stub(state, "Guild", "RealCityRnameConfirm", ""); }


        int LAG_Guild_RealLeagueRnameConfirm(LuaPlus::LuaState* state) { return Stub(state, "Guild", "RealLeagueRnameConfirm", ""); }


        int LAG_Guild_SendCityRnameMsg(LuaPlus::LuaState* state) { return Stub(state, "Guild", "SendCityRnameMsg", ""); }


        int LAG_Guild_SetFirstMan(LuaPlus::LuaState* state) { return Stub(state, "Guild", "SetFirstMan", ""); }

        int LAG_Guild_SetMembersXBHZTInfoByGUID(LuaPlus::LuaState* state) { return Stub(state, "Guild", "SetMembersXBHZTInfoByGUID", "n"); }

        int LAG_Guild_Show_OfficialPopMenu(LuaPlus::LuaState* state) { return Stub(state, "Guild", "Show_OfficialPopMenu", ""); }

        int LAG_Guild_Show_PopMemu(LuaPlus::LuaState* state) { return Stub(state, "Guild", "Show_PopMemu", ""); }

        int LAG_Guild_Sort2UnSortIndex(LuaPlus::LuaState* state) { return Stub(state, "Guild", "Sort2UnSortIndex", "n"); }

        int LAG_Guild_SortAnyGuildMembersByPosition(LuaPlus::LuaState* state) { return Stub(state, "Guild", "SortAnyGuildMembersByPosition", ""); }

        int LAG_Guild_SortGuildMembersByLevel(LuaPlus::LuaState* state) { return Stub(state, "Guild", "SortGuildMembersByLevel", "n"); }

        int LAG_Guild_SortGuildMembersByMenPai(LuaPlus::LuaState* state) { return Stub(state, "Guild", "SortGuildMembersByMenPai", "n"); }


        int LAG_Guild_SureKickGuild(LuaPlus::LuaState* state) { return Stub(state, "Guild", "SureKickGuild", ""); }

        int LAG_Guild_ToggleGuildDetailInfo(LuaPlus::LuaState* state) { return Stub(state, "Guild", "ToggleGuildDetailInfo", ""); }


        int LAG_Guild_UnSetFirstMan(LuaPlus::LuaState* state) { return Stub(state, "Guild", "UnSetFirstMan", ""); }
    }

    void Register_Guild(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AskAnyGuildDetailInfo")) table.Register("AskAnyGuildDetailInfo", LAG_Guild_AskAnyGuildDetailInfo);
        if (IsMissing(table, "AskAnyGuildMembersInfo")) table.Register("AskAnyGuildMembersInfo", LAG_Guild_AskAnyGuildMembersInfo);
        if (IsMissing(table, "AskCurCustomPositionName")) table.Register("AskCurCustomPositionName", LAG_Guild_AskCurCustomPositionName);
        if (IsMissing(table, "AskGuildFirstManInfo")) table.Register("AskGuildFirstManInfo", LAG_Guild_AskGuildFirstManInfo);
        if (IsMissing(table, "AskGuildFirstManName")) table.Register("AskGuildFirstManName", LAG_Guild_AskGuildFirstManName);
        if (IsMissing(table, "AskGuildLeaveWord")) table.Register("AskGuildLeaveWord", LAG_Guild_AskGuildLeaveWord);
        if (IsMissing(table, "AskGuildList4Page")) table.Register("AskGuildList4Page", LAG_Guild_AskGuildList4Page);
        if (IsMissing(table, "AskGuildNameList")) table.Register("AskGuildNameList", LAG_Guild_AskGuildNameList);
        if (IsMissing(table, "AskModifyCustomPositionName")) table.Register("AskModifyCustomPositionName", LAG_Guild_AskModifyCustomPositionName);
        if (IsMissing(table, "CityLeagueRnameCheck")) table.Register("CityLeagueRnameCheck", LAG_Guild_CityLeagueRnameCheck);
        if (IsMissing(table, "CityRnameCheck")) table.Register("CityRnameCheck", LAG_Guild_CityRnameCheck);
        if (IsMissing(table, "CityRnameConfirm")) table.Register("CityRnameConfirm", LAG_Guild_CityRnameConfirm);
        if (IsMissing(table, "ClearCustomPositionName")) table.Register("ClearCustomPositionName", LAG_Guild_ClearCustomPositionName);
        if (IsMissing(table, "CloseKickGuildBox")) table.Register("CloseKickGuildBox", LAG_Guild_CloseKickGuildBox);
        if (IsMissing(table, "DemisGuildOK")) table.Register("DemisGuildOK", LAG_Guild_DemisGuildOK);
        if (IsMissing(table, "ExchangeBangGong")) table.Register("ExchangeBangGong", LAG_Guild_ExchangeBangGong);
        if (IsMissing(table, "FixGuildInfo")) table.Register("FixGuildInfo", LAG_Guild_FixGuildInfo);
        if (IsMissing(table, "GetAnyGuildMembersInfo")) table.Register("GetAnyGuildMembersInfo", LAG_Guild_GetAnyGuildMembersInfo);
        if (IsMissing(table, "GetCurCustomPositionName")) table.Register("GetCurCustomPositionName", LAG_Guild_GetCurCustomPositionName);
        if (IsMissing(table, "GetGuildContri")) table.Register("GetGuildContri", LAG_Guild_GetGuildContri);
        if (IsMissing(table, "GetGuildLeaveWord")) table.Register("GetGuildLeaveWord", LAG_Guild_GetGuildLeaveWord);
        if (IsMissing(table, "GetGuildNumCurPage")) table.Register("GetGuildNumCurPage", LAG_Guild_GetGuildNumCurPage);
        if (IsMissing(table, "GetMemberBak")) table.Register("GetMemberBak", LAG_Guild_GetMemberBak);
        if (IsMissing(table, "GetMembersXBHZTInfoByGUID")) table.Register("GetMembersXBHZTInfoByGUID", LAG_Guild_GetMembersXBHZTInfoByGUID);
        if (IsMissing(table, "GetMembersXBHZTInfoByIndex")) table.Register("GetMembersXBHZTInfoByIndex", LAG_Guild_GetMembersXBHZTInfoByIndex);
        if (IsMissing(table, "GetMyPosition")) table.Register("GetMyPosition", LAG_Guild_GetMyPosition);
        if (IsMissing(table, "GetXBHZTGroupLeaderInfo")) table.Register("GetXBHZTGroupLeaderInfo", LAG_Guild_GetXBHZTGroupLeaderInfo);
        if (IsMissing(table, "GetXBHZTGroupMemNum")) table.Register("GetXBHZTGroupMemNum", LAG_Guild_GetXBHZTGroupMemNum);
        if (IsMissing(table, "GetXBHZTGroupMenPaiMemNumInfo")) table.Register("GetXBHZTGroupMenPaiMemNumInfo", LAG_Guild_GetXBHZTGroupMenPaiMemNumInfo);
        if (IsMissing(table, "InviteToGuild")) table.Register("InviteToGuild", LAG_Guild_InviteToGuild);
        if (IsMissing(table, "IsChiefOrAss")) table.Register("IsChiefOrAss", LAG_Guild_IsChiefOrAss);
        if (IsMissing(table, "IsGuildKeptOneWeed")) table.Register("IsGuildKeptOneWeed", LAG_Guild_IsGuildKeptOneWeed);
        if (IsMissing(table, "ModifyGuildLeaveWord")) table.Register("ModifyGuildLeaveWord", LAG_Guild_ModifyGuildLeaveWord);
        if (IsMissing(table, "PutGuildMoney")) table.Register("PutGuildMoney", LAG_Guild_PutGuildMoney);
        if (IsMissing(table, "RealCityRnameConfirm")) table.Register("RealCityRnameConfirm", LAG_Guild_RealCityRnameConfirm);
        if (IsMissing(table, "RealLeagueRnameConfirm")) table.Register("RealLeagueRnameConfirm", LAG_Guild_RealLeagueRnameConfirm);
        if (IsMissing(table, "SendCityRnameMsg")) table.Register("SendCityRnameMsg", LAG_Guild_SendCityRnameMsg);
        if (IsMissing(table, "SetFirstMan")) table.Register("SetFirstMan", LAG_Guild_SetFirstMan);
        if (IsMissing(table, "SetMembersXBHZTInfoByGUID")) table.Register("SetMembersXBHZTInfoByGUID", LAG_Guild_SetMembersXBHZTInfoByGUID);
        if (IsMissing(table, "Show_OfficialPopMenu")) table.Register("Show_OfficialPopMenu", LAG_Guild_Show_OfficialPopMenu);
        if (IsMissing(table, "Show_PopMemu")) table.Register("Show_PopMemu", LAG_Guild_Show_PopMemu);
        if (IsMissing(table, "Sort2UnSortIndex")) table.Register("Sort2UnSortIndex", LAG_Guild_Sort2UnSortIndex);
        if (IsMissing(table, "SortAnyGuildMembersByPosition")) table.Register("SortAnyGuildMembersByPosition", LAG_Guild_SortAnyGuildMembersByPosition);
        if (IsMissing(table, "SortGuildMembersByLevel")) table.Register("SortGuildMembersByLevel", LAG_Guild_SortGuildMembersByLevel);
        if (IsMissing(table, "SortGuildMembersByMenPai")) table.Register("SortGuildMembersByMenPai", LAG_Guild_SortGuildMembersByMenPai);
        if (IsMissing(table, "SureKickGuild")) table.Register("SureKickGuild", LAG_Guild_SureKickGuild);
        if (IsMissing(table, "ToggleGuildDetailInfo")) table.Register("ToggleGuildDetailInfo", LAG_Guild_ToggleGuildDetailInfo);
        if (IsMissing(table, "UnSetFirstMan")) table.Register("UnSetFirstMan", LAG_Guild_UnSetFirstMan);
    }
}
