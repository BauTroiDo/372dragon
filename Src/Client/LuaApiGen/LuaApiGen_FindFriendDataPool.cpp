




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_FindFriendDataPool_AddPlayerMsg(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "AddPlayerMsg", "o"); }

        int LAG_FindFriendDataPool_CleanSearchRetInfo(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "CleanSearchRetInfo", "o"); }


        int LAG_FindFriendDataPool_ClearPlayerMsg(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "ClearPlayerMsg", "o"); }

        int LAG_FindFriendDataPool_ContexMenuForVoteInfo(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "ContexMenuForVoteInfo", ""); }


        int LAG_FindFriendDataPool_ContexMenuPingbiOrTousu(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "ContexMenuPingbiOrTousu", ""); }


        int LAG_FindFriendDataPool_EnumPlayerMsg(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "EnumPlayerMsg", "sns"); }


        int LAG_FindFriendDataPool_GetDetailInfo(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetDetailInfo", "nnnn"); }

        int LAG_FindFriendDataPool_GetPlayerBBSADTitle(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetPlayerBBSADTitle", "s"); }

        int LAG_FindFriendDataPool_GetPlayerBBSAdGUID(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetPlayerBBSAdGUID", "s"); }

        int LAG_FindFriendDataPool_GetPlayerBBSAdType(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetPlayerBBSAdType", "n"); }

        int LAG_FindFriendDataPool_GetPlayerMsgNum(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetPlayerMsgNum", "n"); }

        int LAG_FindFriendDataPool_GetSearchRetInfoByPos(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetSearchRetInfoByPos", "nsnnnn"); }

        int LAG_FindFriendDataPool_GetSearchRetInfoNum(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetSearchRetInfoNum", "n"); }

        int LAG_FindFriendDataPool_GetSimpleInfoByPos(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetSimpleInfoByPos", "nsnnnn"); }

        int LAG_FindFriendDataPool_GetSimpleInfoNum(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetSimpleInfoNum", "n"); }

        int LAG_FindFriendDataPool_GetSimpleVoteInfoByPos(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetSimpleVoteInfoByPos", "nsnnnn"); }

        int LAG_FindFriendDataPool_GetTickCount(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetTickCount", "n"); }

        int LAG_FindFriendDataPool_GetVoteInfoByPos(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetVoteInfoByPos", "sn"); }

        int LAG_FindFriendDataPool_GetVoteInfoNum(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "GetVoteInfoNum", "n"); }


        int LAG_FindFriendDataPool_SetADTitle(LuaPlus::LuaState* state) { return Stub(state, "FindFriendDataPool", "SetADTitle", "o"); }
    }

    void Register_FindFriendDataPool(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AddPlayerMsg")) table.Register("AddPlayerMsg", LAG_FindFriendDataPool_AddPlayerMsg);
        if (IsMissing(table, "CleanSearchRetInfo")) table.Register("CleanSearchRetInfo", LAG_FindFriendDataPool_CleanSearchRetInfo);
        if (IsMissing(table, "ClearPlayerMsg")) table.Register("ClearPlayerMsg", LAG_FindFriendDataPool_ClearPlayerMsg);
        if (IsMissing(table, "ContexMenuForVoteInfo")) table.Register("ContexMenuForVoteInfo", LAG_FindFriendDataPool_ContexMenuForVoteInfo);
        if (IsMissing(table, "ContexMenuPingbiOrTousu")) table.Register("ContexMenuPingbiOrTousu", LAG_FindFriendDataPool_ContexMenuPingbiOrTousu);
        if (IsMissing(table, "EnumPlayerMsg")) table.Register("EnumPlayerMsg", LAG_FindFriendDataPool_EnumPlayerMsg);
        if (IsMissing(table, "GetDetailInfo")) table.Register("GetDetailInfo", LAG_FindFriendDataPool_GetDetailInfo);
        if (IsMissing(table, "GetPlayerBBSADTitle")) table.Register("GetPlayerBBSADTitle", LAG_FindFriendDataPool_GetPlayerBBSADTitle);
        if (IsMissing(table, "GetPlayerBBSAdGUID")) table.Register("GetPlayerBBSAdGUID", LAG_FindFriendDataPool_GetPlayerBBSAdGUID);
        if (IsMissing(table, "GetPlayerBBSAdType")) table.Register("GetPlayerBBSAdType", LAG_FindFriendDataPool_GetPlayerBBSAdType);
        if (IsMissing(table, "GetPlayerMsgNum")) table.Register("GetPlayerMsgNum", LAG_FindFriendDataPool_GetPlayerMsgNum);
        if (IsMissing(table, "GetSearchRetInfoByPos")) table.Register("GetSearchRetInfoByPos", LAG_FindFriendDataPool_GetSearchRetInfoByPos);
        if (IsMissing(table, "GetSearchRetInfoNum")) table.Register("GetSearchRetInfoNum", LAG_FindFriendDataPool_GetSearchRetInfoNum);
        if (IsMissing(table, "GetSimpleInfoByPos")) table.Register("GetSimpleInfoByPos", LAG_FindFriendDataPool_GetSimpleInfoByPos);
        if (IsMissing(table, "GetSimpleInfoNum")) table.Register("GetSimpleInfoNum", LAG_FindFriendDataPool_GetSimpleInfoNum);
        if (IsMissing(table, "GetSimpleVoteInfoByPos")) table.Register("GetSimpleVoteInfoByPos", LAG_FindFriendDataPool_GetSimpleVoteInfoByPos);
        if (IsMissing(table, "GetTickCount")) table.Register("GetTickCount", LAG_FindFriendDataPool_GetTickCount);
        if (IsMissing(table, "GetVoteInfoByPos")) table.Register("GetVoteInfoByPos", LAG_FindFriendDataPool_GetVoteInfoByPos);
        if (IsMissing(table, "GetVoteInfoNum")) table.Register("GetVoteInfoNum", LAG_FindFriendDataPool_GetVoteInfoNum);
        if (IsMissing(table, "SetADTitle")) table.Register("SetADTitle", LAG_FindFriendDataPool_SetADTitle);
    }
}
