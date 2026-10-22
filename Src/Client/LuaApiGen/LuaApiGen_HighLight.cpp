




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_HighLight_ClearDamageUnitData(LuaPlus::LuaState* state) { return Stub(state, "HighLight", "ClearDamageUnitData", "o"); }

        int LAG_HighLight_GetDamageUnitDataByIndex(LuaPlus::LuaState* state) { return Stub(state, "HighLight", "GetDamageUnitDataByIndex", "nnsnnn"); }

        int LAG_HighLight_Lua_ClearHLMVPData(LuaPlus::LuaState* state) { return Stub(state, "HighLight", "Lua_ClearHLMVPData", ""); }

        int LAG_HighLight_Lua_ClearHLSkillQue(LuaPlus::LuaState* state) { return Stub(state, "HighLight", "Lua_ClearHLSkillQue", ""); }

        int LAG_HighLight_Lua_GetHLMVPCount(LuaPlus::LuaState* state) { return Stub(state, "HighLight", "Lua_GetHLMVPCount", "n"); }

        int LAG_HighLight_Lua_GetHLMVPDataByIndex(LuaPlus::LuaState* state) { return Stub(state, "HighLight", "Lua_GetHLMVPDataByIndex", "nnsnnn"); }

        int LAG_HighLight_Lua_GetHLSkillQueFront(LuaPlus::LuaState* state) { return Stub(state, "HighLight", "Lua_GetHLSkillQueFront", "nsnnn"); }

        int LAG_HighLight_Lua_ShareHLMVP(LuaPlus::LuaState* state) { return Stub(state, "HighLight", "Lua_ShareHLMVP", ""); }


        int LAG_HighLight_Lua_ShareHLSkill(LuaPlus::LuaState* state) { return Stub(state, "HighLight", "Lua_ShareHLSkill", ""); }


        int LAG_HighLight_Lua_UpdateLikeCount(LuaPlus::LuaState* state) { return Stub(state, "HighLight", "Lua_UpdateLikeCount", "n"); }
    }

    void Register_HighLight(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ClearDamageUnitData")) table.Register("ClearDamageUnitData", LAG_HighLight_ClearDamageUnitData);
        if (IsMissing(table, "GetDamageUnitDataByIndex")) table.Register("GetDamageUnitDataByIndex", LAG_HighLight_GetDamageUnitDataByIndex);
        if (IsMissing(table, "Lua_ClearHLMVPData")) table.Register("Lua_ClearHLMVPData", LAG_HighLight_Lua_ClearHLMVPData);
        if (IsMissing(table, "Lua_ClearHLSkillQue")) table.Register("Lua_ClearHLSkillQue", LAG_HighLight_Lua_ClearHLSkillQue);
        if (IsMissing(table, "Lua_GetHLMVPCount")) table.Register("Lua_GetHLMVPCount", LAG_HighLight_Lua_GetHLMVPCount);
        if (IsMissing(table, "Lua_GetHLMVPDataByIndex")) table.Register("Lua_GetHLMVPDataByIndex", LAG_HighLight_Lua_GetHLMVPDataByIndex);
        if (IsMissing(table, "Lua_GetHLSkillQueFront")) table.Register("Lua_GetHLSkillQueFront", LAG_HighLight_Lua_GetHLSkillQueFront);
        if (IsMissing(table, "Lua_ShareHLMVP")) table.Register("Lua_ShareHLMVP", LAG_HighLight_Lua_ShareHLMVP);
        if (IsMissing(table, "Lua_ShareHLSkill")) table.Register("Lua_ShareHLSkill", LAG_HighLight_Lua_ShareHLSkill);
        if (IsMissing(table, "Lua_UpdateLikeCount")) table.Register("Lua_UpdateLikeCount", LAG_HighLight_Lua_UpdateLikeCount);
    }
}
