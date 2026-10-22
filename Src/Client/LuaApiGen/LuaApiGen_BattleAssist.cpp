




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_BattleAssist_CheckConditions(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "CheckConditions", "b"); }

        int LAG_BattleAssist_DebugLog(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "DebugLog", ""); }

        int LAG_BattleAssist_Farm_AddPetUsualData(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_AddPetUsualData", ""); }

        int LAG_BattleAssist_Farm_CheckPetSkill(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_CheckPetSkill", "n"); }

        int LAG_BattleAssist_Farm_DeletePetUsualData(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_DeletePetUsualData", "n"); }

        int LAG_BattleAssist_Farm_GetAttrData(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_GetAttrData", "n"); }


        int LAG_BattleAssist_Farm_GetConfigData(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_GetConfigData", "nnnnnnn"); }

        int LAG_BattleAssist_Farm_GetPetUsualData(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_GetPetUsualData", "t"); }

        int LAG_BattleAssist_Farm_GetPotionIds(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_GetPotionIds", "t"); }

        int LAG_BattleAssist_Farm_GetSkillIds(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_GetSkillIds", "t"); }


        int LAG_BattleAssist_Farm_SetAttrData(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_SetAttrData", ""); }

        int LAG_BattleAssist_Farm_SetAutoSearchNpc(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_SetAutoSearchNpc", ""); }


        int LAG_BattleAssist_Farm_SetConfigData(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_SetConfigData", ""); }

        int LAG_BattleAssist_Farm_UpdateConfig(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_UpdateConfig", ""); }

        int LAG_BattleAssist_Farm_UpdatePetUsualData(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Farm_UpdatePetUsualData", "n"); }

        int LAG_BattleAssist_GetNeiGuaCfgData(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "GetNeiGuaCfgData", "n"); }

        int LAG_BattleAssist_IsWorking(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "IsWorking", "bs"); }

        int LAG_BattleAssist_SetNeiGuaCfgData(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "SetNeiGuaCfgData", ""); }


        int LAG_BattleAssist_Start(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Start", "n"); }

        int LAG_BattleAssist_Stop(LuaPlus::LuaState* state) { return Stub(state, "BattleAssist", "Stop", ""); }
    }

    void Register_BattleAssist(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "CheckConditions")) table.Register("CheckConditions", LAG_BattleAssist_CheckConditions);
        if (IsMissing(table, "DebugLog")) table.Register("DebugLog", LAG_BattleAssist_DebugLog);
        if (IsMissing(table, "Farm_AddPetUsualData")) table.Register("Farm_AddPetUsualData", LAG_BattleAssist_Farm_AddPetUsualData);
        if (IsMissing(table, "Farm_CheckPetSkill")) table.Register("Farm_CheckPetSkill", LAG_BattleAssist_Farm_CheckPetSkill);
        if (IsMissing(table, "Farm_DeletePetUsualData")) table.Register("Farm_DeletePetUsualData", LAG_BattleAssist_Farm_DeletePetUsualData);
        if (IsMissing(table, "Farm_GetAttrData")) table.Register("Farm_GetAttrData", LAG_BattleAssist_Farm_GetAttrData);
        if (IsMissing(table, "Farm_GetConfigData")) table.Register("Farm_GetConfigData", LAG_BattleAssist_Farm_GetConfigData);
        if (IsMissing(table, "Farm_GetPetUsualData")) table.Register("Farm_GetPetUsualData", LAG_BattleAssist_Farm_GetPetUsualData);
        if (IsMissing(table, "Farm_GetPotionIds")) table.Register("Farm_GetPotionIds", LAG_BattleAssist_Farm_GetPotionIds);
        if (IsMissing(table, "Farm_GetSkillIds")) table.Register("Farm_GetSkillIds", LAG_BattleAssist_Farm_GetSkillIds);
        if (IsMissing(table, "Farm_SetAttrData")) table.Register("Farm_SetAttrData", LAG_BattleAssist_Farm_SetAttrData);
        if (IsMissing(table, "Farm_SetAutoSearchNpc")) table.Register("Farm_SetAutoSearchNpc", LAG_BattleAssist_Farm_SetAutoSearchNpc);
        if (IsMissing(table, "Farm_SetConfigData")) table.Register("Farm_SetConfigData", LAG_BattleAssist_Farm_SetConfigData);
        if (IsMissing(table, "Farm_UpdateConfig")) table.Register("Farm_UpdateConfig", LAG_BattleAssist_Farm_UpdateConfig);
        if (IsMissing(table, "Farm_UpdatePetUsualData")) table.Register("Farm_UpdatePetUsualData", LAG_BattleAssist_Farm_UpdatePetUsualData);
        if (IsMissing(table, "GetNeiGuaCfgData")) table.Register("GetNeiGuaCfgData", LAG_BattleAssist_GetNeiGuaCfgData);
        if (IsMissing(table, "IsWorking")) table.Register("IsWorking", LAG_BattleAssist_IsWorking);
        if (IsMissing(table, "SetNeiGuaCfgData")) table.Register("SetNeiGuaCfgData", LAG_BattleAssist_SetNeiGuaCfgData);
        if (IsMissing(table, "Start")) table.Register("Start", LAG_BattleAssist_Start);
        if (IsMissing(table, "Stop")) table.Register("Stop", LAG_BattleAssist_Stop);
    }
}
