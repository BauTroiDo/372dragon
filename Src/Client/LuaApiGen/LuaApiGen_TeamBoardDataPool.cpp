




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_TeamBoardDataPool_ApplyTeam(LuaPlus::LuaState* state) { return Stub(state, "TeamBoardDataPool", "ApplyTeam", ""); }


        int LAG_TeamBoardDataPool_DelInfo(LuaPlus::LuaState* state) { return Stub(state, "TeamBoardDataPool", "DelInfo", ""); }


        int LAG_TeamBoardDataPool_GetCharNameByRowID(LuaPlus::LuaState* state) { return Stub(state, "TeamBoardDataPool", "GetCharNameByRowID", "sn"); }


        int LAG_TeamBoardDataPool_GetInfoByPos(LuaPlus::LuaState* state) { return Stub(state, "TeamBoardDataPool", "GetInfoByPos", "nssnsn"); }

        int LAG_TeamBoardDataPool_GetTickCount(LuaPlus::LuaState* state) { return Stub(state, "TeamBoardDataPool", "GetTickCount", "n"); }


        int LAG_TeamBoardDataPool_ModifyInfo(LuaPlus::LuaState* state) { return Stub(state, "TeamBoardDataPool", "ModifyInfo", ""); }


        int LAG_TeamBoardDataPool_RequestTeam(LuaPlus::LuaState* state) { return Stub(state, "TeamBoardDataPool", "RequestTeam", ""); }


        int LAG_TeamBoardDataPool_RequestTeamBoardList(LuaPlus::LuaState* state) { return Stub(state, "TeamBoardDataPool", "RequestTeamBoardList", ""); }


        int LAG_TeamBoardDataPool_SendTeamSeekInfo(LuaPlus::LuaState* state) { return Stub(state, "TeamBoardDataPool", "SendTeamSeekInfo", "n"); }


        int LAG_TeamBoardDataPool_SendUserSeekInfo(LuaPlus::LuaState* state) { return Stub(state, "TeamBoardDataPool", "SendUserSeekInfo", "n"); }
    }

    void Register_TeamBoardDataPool(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ApplyTeam")) table.Register("ApplyTeam", LAG_TeamBoardDataPool_ApplyTeam);
        if (IsMissing(table, "DelInfo")) table.Register("DelInfo", LAG_TeamBoardDataPool_DelInfo);
        if (IsMissing(table, "GetCharNameByRowID")) table.Register("GetCharNameByRowID", LAG_TeamBoardDataPool_GetCharNameByRowID);
        if (IsMissing(table, "GetInfoByPos")) table.Register("GetInfoByPos", LAG_TeamBoardDataPool_GetInfoByPos);
        if (IsMissing(table, "GetTickCount")) table.Register("GetTickCount", LAG_TeamBoardDataPool_GetTickCount);
        if (IsMissing(table, "ModifyInfo")) table.Register("ModifyInfo", LAG_TeamBoardDataPool_ModifyInfo);
        if (IsMissing(table, "RequestTeam")) table.Register("RequestTeam", LAG_TeamBoardDataPool_RequestTeam);
        if (IsMissing(table, "RequestTeamBoardList")) table.Register("RequestTeamBoardList", LAG_TeamBoardDataPool_RequestTeamBoardList);
        if (IsMissing(table, "SendTeamSeekInfo")) table.Register("SendTeamSeekInfo", LAG_TeamBoardDataPool_SendTeamSeekInfo);
        if (IsMissing(table, "SendUserSeekInfo")) table.Register("SendUserSeekInfo", LAG_TeamBoardDataPool_SendUserSeekInfo);
    }
}
