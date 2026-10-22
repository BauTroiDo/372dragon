




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_City_AskBattleList(LuaPlus::LuaState* state) { return Stub(state, "City", "AskBattleList", ""); }


        int LAG_City_AskCityBuildingResearch(LuaPlus::LuaState* state) { return Stub(state, "City", "AskCityBuildingResearch", ""); }


        int LAG_City_AskCityManageInfo(LuaPlus::LuaState* state) { return Stub(state, "City", "AskCityManageInfo", ""); }


        int LAG_City_AskCityResearch(LuaPlus::LuaState* state) { return Stub(state, "City", "AskCityResearch", ""); }


        int LAG_City_AskCityRoad(LuaPlus::LuaState* state) { return Stub(state, "City", "AskCityRoad", ""); }


        int LAG_City_AskCityShop(LuaPlus::LuaState* state) { return Stub(state, "City", "AskCityShop", ""); }


        int LAG_City_AskCityTrend(LuaPlus::LuaState* state) { return Stub(state, "City", "AskCityTrend", ""); }


        int LAG_City_AskEnemyList(LuaPlus::LuaState* state) { return Stub(state, "City", "AskEnemyList", ""); }


        int LAG_City_AskGuildBattleScore(LuaPlus::LuaState* state) { return Stub(state, "City", "AskGuildBattleScore", ""); }

        int LAG_City_ClearPhoenixPlainWarScore(LuaPlus::LuaState* state) { return Stub(state, "City", "ClearPhoenixPlainWarScore", ""); }

        int LAG_City_ClosePhoenixPlainWarScoreMultiTable(LuaPlus::LuaState* state) { return Stub(state, "City", "ClosePhoenixPlainWarScoreMultiTable", ""); }

        int LAG_City_ClosePhoenixPlainWarScoreSingleTable(LuaPlus::LuaState* state) { return Stub(state, "City", "ClosePhoenixPlainWarScoreSingleTable", ""); }


        int LAG_City_CreateCity(LuaPlus::LuaState* state) { return Stub(state, "City", "CreateCity", ""); }


        int LAG_City_DoBuilding(LuaPlus::LuaState* state) { return Stub(state, "City", "DoBuilding", ""); }


        int LAG_City_DoCityRoad(LuaPlus::LuaState* state) { return Stub(state, "City", "DoCityRoad", ""); }


        int LAG_City_DoCityShop(LuaPlus::LuaState* state) { return Stub(state, "City", "DoCityShop", ""); }

        int LAG_City_DoConfirm(LuaPlus::LuaState* state) { return Stub(state, "City", "DoConfirm", ""); }


        int LAG_City_DoResearch(LuaPlus::LuaState* state) { return Stub(state, "City", "DoResearch", ""); }

        int LAG_City_EnumBattleGuild(LuaPlus::LuaState* state) { return Stub(state, "City", "EnumBattleGuild", "n"); }

        int LAG_City_EnumCityEnemy(LuaPlus::LuaState* state) { return Stub(state, "City", "EnumCityEnemy", "n"); }

        int LAG_City_EnumCityShop(LuaPlus::LuaState* state) { return Stub(state, "City", "EnumCityShop", "on"); }

        int LAG_City_EnumResearch(LuaPlus::LuaState* state) { return Stub(state, "City", "EnumResearch", "oon"); }


        int LAG_City_FixCityTrend(LuaPlus::LuaState* state) { return Stub(state, "City", "FixCityTrend", ""); }

        int LAG_City_GetAttackGuildName(LuaPlus::LuaState* state) { return Stub(state, "City", "GetAttackGuildName", "s"); }

        int LAG_City_GetBaseInfo(LuaPlus::LuaState* state) { return Stub(state, "City", "GetBaseInfo", "snnnnoo"); }

        int LAG_City_GetBattleNum(LuaPlus::LuaState* state) { return Stub(state, "City", "GetBattleNum", "n"); }

        int LAG_City_GetBuildingInfo(LuaPlus::LuaState* state) { return Stub(state, "City", "GetBuildingInfo", "nnnnnn"); }

        int LAG_City_GetCityManageInfo(LuaPlus::LuaState* state) { return Stub(state, "City", "GetCityManageInfo", "nssnnnnnnnnnssnnnsnnoooooooooooooooooooooooooooooooooo"); }

        int LAG_City_GetCityMissonMgrInfo(LuaPlus::LuaState* state) { return Stub(state, "City", "GetCityMissonMgrInfo", "n"); }

        int LAG_City_GetCityRoadInfo(LuaPlus::LuaState* state) { return Stub(state, "City", "GetCityRoadInfo", "nnss"); }

        int LAG_City_GetCityShopInfo(LuaPlus::LuaState* state) { return Stub(state, "City", "GetCityShopInfo", "n"); }


        int LAG_City_GetCityTrend(LuaPlus::LuaState* state) { return Stub(state, "City", "GetCityTrend", ""); }

        int LAG_City_GetEnemyNum(LuaPlus::LuaState* state) { return Stub(state, "City", "GetEnemyNum", "n"); }

        int LAG_City_GetGuildBattleScore(LuaPlus::LuaState* state) { return Stub(state, "City", "GetGuildBattleScore", "n"); }

        int LAG_City_GetPhoenixPlainWarScore(LuaPlus::LuaState* state) { return Stub(state, "City", "GetPhoenixPlainWarScore", "nnnnnnnssss"); }

        int LAG_City_GetPortInfo(LuaPlus::LuaState* state) { return Stub(state, "City", "GetPortInfo", "s"); }

        int LAG_City_GetResearchInfo(LuaPlus::LuaState* state) { return Stub(state, "City", "GetResearchInfo", "nnnnnn"); }

        int LAG_City_InputCityName(LuaPlus::LuaState* state) { return Stub(state, "City", "InputCityName", ""); }

        int LAG_City_OpenAddBattleDlg(LuaPlus::LuaState* state) { return Stub(state, "City", "OpenAddBattleDlg", ""); }

        int LAG_City_OpenAddEnemyDlg(LuaPlus::LuaState* state) { return Stub(state, "City", "OpenAddEnemyDlg", ""); }

        int LAG_City_OpenGuildWarDlg(LuaPlus::LuaState* state) { return Stub(state, "City", "OpenGuildWarDlg", ""); }

        int LAG_City_OpenPhoenixPlainWarScoreMultiTable(LuaPlus::LuaState* state) { return Stub(state, "City", "OpenPhoenixPlainWarScoreMultiTable", ""); }

        int LAG_City_OpenPhoenixPlainWarScoreSingleTable(LuaPlus::LuaState* state) { return Stub(state, "City", "OpenPhoenixPlainWarScoreSingleTable", ""); }

        int LAG_City_RebulidLegend(LuaPlus::LuaState* state) { return Stub(state, "City", "RebulidLegend", ""); }


        int LAG_City_ReponseGuildBattle(LuaPlus::LuaState* state) { return Stub(state, "City", "ReponseGuildBattle", ""); }

        int LAG_City_SelectGuildBattle(LuaPlus::LuaState* state) { return Stub(state, "City", "SelectGuildBattle", ""); }


        int LAG_City_SendAddEnemyMsg(LuaPlus::LuaState* state) { return Stub(state, "City", "SendAddEnemyMsg", ""); }


        int LAG_City_SendAddGuildBattleMsg(LuaPlus::LuaState* state) { return Stub(state, "City", "SendAddGuildBattleMsg", ""); }


        int LAG_City_SendCityMissonMgr(LuaPlus::LuaState* state) { return Stub(state, "City", "SendCityMissonMgr", ""); }

        int LAG_City_SetCityGuildFlag(LuaPlus::LuaState* state) { return Stub(state, "City", "SetCityGuildFlag", ""); }

        int LAG_City_SetCityMissonMgrInfo(LuaPlus::LuaState* state) { return Stub(state, "City", "SetCityMissonMgrInfo", ""); }
    }

    void Register_City(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AskBattleList")) table.Register("AskBattleList", LAG_City_AskBattleList);
        if (IsMissing(table, "AskCityBuildingResearch")) table.Register("AskCityBuildingResearch", LAG_City_AskCityBuildingResearch);
        if (IsMissing(table, "AskCityManageInfo")) table.Register("AskCityManageInfo", LAG_City_AskCityManageInfo);
        if (IsMissing(table, "AskCityResearch")) table.Register("AskCityResearch", LAG_City_AskCityResearch);
        if (IsMissing(table, "AskCityRoad")) table.Register("AskCityRoad", LAG_City_AskCityRoad);
        if (IsMissing(table, "AskCityShop")) table.Register("AskCityShop", LAG_City_AskCityShop);
        if (IsMissing(table, "AskCityTrend")) table.Register("AskCityTrend", LAG_City_AskCityTrend);
        if (IsMissing(table, "AskEnemyList")) table.Register("AskEnemyList", LAG_City_AskEnemyList);
        if (IsMissing(table, "AskGuildBattleScore")) table.Register("AskGuildBattleScore", LAG_City_AskGuildBattleScore);
        if (IsMissing(table, "ClearPhoenixPlainWarScore")) table.Register("ClearPhoenixPlainWarScore", LAG_City_ClearPhoenixPlainWarScore);
        if (IsMissing(table, "ClosePhoenixPlainWarScoreMultiTable")) table.Register("ClosePhoenixPlainWarScoreMultiTable", LAG_City_ClosePhoenixPlainWarScoreMultiTable);
        if (IsMissing(table, "ClosePhoenixPlainWarScoreSingleTable")) table.Register("ClosePhoenixPlainWarScoreSingleTable", LAG_City_ClosePhoenixPlainWarScoreSingleTable);
        if (IsMissing(table, "CreateCity")) table.Register("CreateCity", LAG_City_CreateCity);
        if (IsMissing(table, "DoBuilding")) table.Register("DoBuilding", LAG_City_DoBuilding);
        if (IsMissing(table, "DoCityRoad")) table.Register("DoCityRoad", LAG_City_DoCityRoad);
        if (IsMissing(table, "DoCityShop")) table.Register("DoCityShop", LAG_City_DoCityShop);
        if (IsMissing(table, "DoConfirm")) table.Register("DoConfirm", LAG_City_DoConfirm);
        if (IsMissing(table, "DoResearch")) table.Register("DoResearch", LAG_City_DoResearch);
        if (IsMissing(table, "EnumBattleGuild")) table.Register("EnumBattleGuild", LAG_City_EnumBattleGuild);
        if (IsMissing(table, "EnumCityEnemy")) table.Register("EnumCityEnemy", LAG_City_EnumCityEnemy);
        if (IsMissing(table, "EnumCityShop")) table.Register("EnumCityShop", LAG_City_EnumCityShop);
        if (IsMissing(table, "EnumResearch")) table.Register("EnumResearch", LAG_City_EnumResearch);
        if (IsMissing(table, "FixCityTrend")) table.Register("FixCityTrend", LAG_City_FixCityTrend);
        if (IsMissing(table, "GetAttackGuildName")) table.Register("GetAttackGuildName", LAG_City_GetAttackGuildName);
        if (IsMissing(table, "GetBaseInfo")) table.Register("GetBaseInfo", LAG_City_GetBaseInfo);
        if (IsMissing(table, "GetBattleNum")) table.Register("GetBattleNum", LAG_City_GetBattleNum);
        if (IsMissing(table, "GetBuildingInfo")) table.Register("GetBuildingInfo", LAG_City_GetBuildingInfo);
        if (IsMissing(table, "GetCityManageInfo")) table.Register("GetCityManageInfo", LAG_City_GetCityManageInfo);
        if (IsMissing(table, "GetCityMissonMgrInfo")) table.Register("GetCityMissonMgrInfo", LAG_City_GetCityMissonMgrInfo);
        if (IsMissing(table, "GetCityRoadInfo")) table.Register("GetCityRoadInfo", LAG_City_GetCityRoadInfo);
        if (IsMissing(table, "GetCityShopInfo")) table.Register("GetCityShopInfo", LAG_City_GetCityShopInfo);
        if (IsMissing(table, "GetCityTrend")) table.Register("GetCityTrend", LAG_City_GetCityTrend);
        if (IsMissing(table, "GetEnemyNum")) table.Register("GetEnemyNum", LAG_City_GetEnemyNum);
        if (IsMissing(table, "GetGuildBattleScore")) table.Register("GetGuildBattleScore", LAG_City_GetGuildBattleScore);
        if (IsMissing(table, "GetPhoenixPlainWarScore")) table.Register("GetPhoenixPlainWarScore", LAG_City_GetPhoenixPlainWarScore);
        if (IsMissing(table, "GetPortInfo")) table.Register("GetPortInfo", LAG_City_GetPortInfo);
        if (IsMissing(table, "GetResearchInfo")) table.Register("GetResearchInfo", LAG_City_GetResearchInfo);
        if (IsMissing(table, "InputCityName")) table.Register("InputCityName", LAG_City_InputCityName);
        if (IsMissing(table, "OpenAddBattleDlg")) table.Register("OpenAddBattleDlg", LAG_City_OpenAddBattleDlg);
        if (IsMissing(table, "OpenAddEnemyDlg")) table.Register("OpenAddEnemyDlg", LAG_City_OpenAddEnemyDlg);
        if (IsMissing(table, "OpenGuildWarDlg")) table.Register("OpenGuildWarDlg", LAG_City_OpenGuildWarDlg);
        if (IsMissing(table, "OpenPhoenixPlainWarScoreMultiTable")) table.Register("OpenPhoenixPlainWarScoreMultiTable", LAG_City_OpenPhoenixPlainWarScoreMultiTable);
        if (IsMissing(table, "OpenPhoenixPlainWarScoreSingleTable")) table.Register("OpenPhoenixPlainWarScoreSingleTable", LAG_City_OpenPhoenixPlainWarScoreSingleTable);
        if (IsMissing(table, "RebulidLegend")) table.Register("RebulidLegend", LAG_City_RebulidLegend);
        if (IsMissing(table, "ReponseGuildBattle")) table.Register("ReponseGuildBattle", LAG_City_ReponseGuildBattle);
        if (IsMissing(table, "SelectGuildBattle")) table.Register("SelectGuildBattle", LAG_City_SelectGuildBattle);
        if (IsMissing(table, "SendAddEnemyMsg")) table.Register("SendAddEnemyMsg", LAG_City_SendAddEnemyMsg);
        if (IsMissing(table, "SendAddGuildBattleMsg")) table.Register("SendAddGuildBattleMsg", LAG_City_SendAddGuildBattleMsg);
        if (IsMissing(table, "SendCityMissonMgr")) table.Register("SendCityMissonMgr", LAG_City_SendCityMissonMgr);
        if (IsMissing(table, "SetCityGuildFlag")) table.Register("SetCityGuildFlag", LAG_City_SetCityGuildFlag);
        if (IsMissing(table, "SetCityMissonMgrInfo")) table.Register("SetCityMissonMgrInfo", LAG_City_SetCityMissonMgrInfo);
    }
}
