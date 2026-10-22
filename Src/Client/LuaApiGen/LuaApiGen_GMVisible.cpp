




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_GMVisible_LuaFnCanelView(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnCanelView", ""); }


        int LAG_GMVisible_LuaFnGetBaseData(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetBaseData", "t"); }


        int LAG_GMVisible_LuaFnGetBuff(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetBuff", "nn"); }

        int LAG_GMVisible_LuaFnGetBuffInfo(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetBuffInfo", "ss"); }


        int LAG_GMVisible_LuaFnGetChangeData(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetChangeData", "t"); }

        int LAG_GMVisible_LuaFnGetFirstBloodTeam(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetFirstBloodTeam", "n"); }


        int LAG_GMVisible_LuaFnGetGuid(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetGuid", "n"); }


        int LAG_GMVisible_LuaFnGetJoinFlag(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetJoinFlag", "n"); }

        int LAG_GMVisible_LuaFnGetRemainTime(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetRemainTime", "n"); }

        int LAG_GMVisible_LuaFnGetResult(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetResult", "n"); }

        int LAG_GMVisible_LuaFnGetScore(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetScore", "nn"); }


        int LAG_GMVisible_LuaFnGetSkill(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetSkill", "nn"); }

        int LAG_GMVisible_LuaFnGetSkillInfo(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetSkillInfo", "ss"); }


        int LAG_GMVisible_LuaFnGetTeamInfo(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetTeamInfo", "nn"); }

        int LAG_GMVisible_LuaFnGetViewType(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnGetViewType", "n"); }


        int LAG_GMVisible_LuaFnIsFirstBloodPlayer(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnIsFirstBloodPlayer", "n"); }

        int LAG_GMVisible_LuaFnMatchType(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnMatchType", "n"); }


        int LAG_GMVisible_LuaFnSetMainTargetByIdx(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnSetMainTargetByIdx", ""); }

        int LAG_GMVisible_LuaFnSetSpecialObjHp(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnSetSpecialObjHp", ""); }


        int LAG_GMVisible_LuaFnShowObjTitle(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnShowObjTitle", ""); }

        int LAG_GMVisible_LuaFnShowSpecialObjHp(LuaPlus::LuaState* state) { return Stub(state, "GMVisible", "LuaFnShowSpecialObjHp", ""); }
    }

    void Register_GMVisible(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "LuaFnCanelView")) table.Register("LuaFnCanelView", LAG_GMVisible_LuaFnCanelView);
        if (IsMissing(table, "LuaFnGetBaseData")) table.Register("LuaFnGetBaseData", LAG_GMVisible_LuaFnGetBaseData);
        if (IsMissing(table, "LuaFnGetBuff")) table.Register("LuaFnGetBuff", LAG_GMVisible_LuaFnGetBuff);
        if (IsMissing(table, "LuaFnGetBuffInfo")) table.Register("LuaFnGetBuffInfo", LAG_GMVisible_LuaFnGetBuffInfo);
        if (IsMissing(table, "LuaFnGetChangeData")) table.Register("LuaFnGetChangeData", LAG_GMVisible_LuaFnGetChangeData);
        if (IsMissing(table, "LuaFnGetFirstBloodTeam")) table.Register("LuaFnGetFirstBloodTeam", LAG_GMVisible_LuaFnGetFirstBloodTeam);
        if (IsMissing(table, "LuaFnGetGuid")) table.Register("LuaFnGetGuid", LAG_GMVisible_LuaFnGetGuid);
        if (IsMissing(table, "LuaFnGetJoinFlag")) table.Register("LuaFnGetJoinFlag", LAG_GMVisible_LuaFnGetJoinFlag);
        if (IsMissing(table, "LuaFnGetRemainTime")) table.Register("LuaFnGetRemainTime", LAG_GMVisible_LuaFnGetRemainTime);
        if (IsMissing(table, "LuaFnGetResult")) table.Register("LuaFnGetResult", LAG_GMVisible_LuaFnGetResult);
        if (IsMissing(table, "LuaFnGetScore")) table.Register("LuaFnGetScore", LAG_GMVisible_LuaFnGetScore);
        if (IsMissing(table, "LuaFnGetSkill")) table.Register("LuaFnGetSkill", LAG_GMVisible_LuaFnGetSkill);
        if (IsMissing(table, "LuaFnGetSkillInfo")) table.Register("LuaFnGetSkillInfo", LAG_GMVisible_LuaFnGetSkillInfo);
        if (IsMissing(table, "LuaFnGetTeamInfo")) table.Register("LuaFnGetTeamInfo", LAG_GMVisible_LuaFnGetTeamInfo);
        if (IsMissing(table, "LuaFnGetViewType")) table.Register("LuaFnGetViewType", LAG_GMVisible_LuaFnGetViewType);
        if (IsMissing(table, "LuaFnIsFirstBloodPlayer")) table.Register("LuaFnIsFirstBloodPlayer", LAG_GMVisible_LuaFnIsFirstBloodPlayer);
        if (IsMissing(table, "LuaFnMatchType")) table.Register("LuaFnMatchType", LAG_GMVisible_LuaFnMatchType);
        if (IsMissing(table, "LuaFnSetMainTargetByIdx")) table.Register("LuaFnSetMainTargetByIdx", LAG_GMVisible_LuaFnSetMainTargetByIdx);
        if (IsMissing(table, "LuaFnSetSpecialObjHp")) table.Register("LuaFnSetSpecialObjHp", LAG_GMVisible_LuaFnSetSpecialObjHp);
        if (IsMissing(table, "LuaFnShowObjTitle")) table.Register("LuaFnShowObjTitle", LAG_GMVisible_LuaFnShowObjTitle);
        if (IsMissing(table, "LuaFnShowSpecialObjHp")) table.Register("LuaFnShowSpecialObjHp", LAG_GMVisible_LuaFnShowSpecialObjHp);
    }
}
