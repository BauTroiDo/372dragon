




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_Target_CanGetTargetEquip(LuaPlus::LuaState* state) { return Stub(state, "Target", "CanGetTargetEquip", "b"); }

        int LAG_Target_ChangeNameConfirm(LuaPlus::LuaState* state) { return Stub(state, "Target", "ChangeNameConfirm", ""); }

        int LAG_Target_CharRnameCheck(LuaPlus::LuaState* state) { return Stub(state, "Target", "CharRnameCheck", "n"); }

        int LAG_Target_CharRnameConfirm(LuaPlus::LuaState* state) { return Stub(state, "Target", "CharRnameConfirm", ""); }

        int LAG_Target_CheckBuffImpactExist(LuaPlus::LuaState* state) { return Stub(state, "Target", "CheckBuffImpactExist", "n"); }

        int LAG_Target_GetAllBuffIconName(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetAllBuffIconName", "t"); }

        int LAG_Target_GetBuffIsShowIconByIndex(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetBuffIsShowIconByIndex", "n"); }

        int LAG_Target_GetBuffPriorityByIndex(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetBuffPriorityByIndex", "n"); }

        int LAG_Target_GetDFengAttackMenPai1(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengAttackMenPai1", "n"); }

        int LAG_Target_GetDFengAttackMenPai2(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengAttackMenPai2", "n"); }

        int LAG_Target_GetDFengAttackMenPai3(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengAttackMenPai3", "n"); }

        int LAG_Target_GetDFengAttackXDD1(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengAttackXDD1", "n"); }

        int LAG_Target_GetDFengAttackXDD2(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengAttackXDD2", "n"); }

        int LAG_Target_GetDFengAttackXDD3(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengAttackXDD3", "n"); }

        int LAG_Target_GetDFengAttrNextLevelStr_Essence(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengAttrNextLevelStr_Essence", "nn"); }

        int LAG_Target_GetDFengDFengAttrNextLevelStr(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengDFengAttrNextLevelStr", "ns"); }

        int LAG_Target_GetDFengDefenceMenPai1(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengDefenceMenPai1", "n"); }

        int LAG_Target_GetDFengDefenceMenPai2(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengDefenceMenPai2", "n"); }

        int LAG_Target_GetDFengDefenceMenPai3(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengDefenceMenPai3", "n"); }

        int LAG_Target_GetDFengDefenceXDD1(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengDefenceXDD1", "n"); }

        int LAG_Target_GetDFengDefenceXDD2(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengDefenceXDD2", "n"); }

        int LAG_Target_GetDFengDefenceXDD3(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengDefenceXDD3", "n"); }

        int LAG_Target_GetDFengEssenceAttrAttack(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengEssenceAttrAttack", "n"); }

        int LAG_Target_GetDFengEssenceKWALLLevel(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengEssenceKWALLLevel", "n"); }

        int LAG_Target_GetDFengEssenceLevel(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengEssenceLevel", "n"); }

        int LAG_Target_GetDFengExp(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengExp", "n"); }

        int LAG_Target_GetDFengExtraLevelupTimes(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengExtraLevelupTimes", "n"); }

        int LAG_Target_GetDFengLevel(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengLevel", "n"); }

        int LAG_Target_GetDFengLevelupTimes(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengLevelupTimes", "n"); }

        int LAG_Target_GetDFengNeedExp(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengNeedExp", "n"); }

        int LAG_Target_GetDFengZhuiGanInfo(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDFengZhuiGanInfo", "nn"); }

        int LAG_Target_GetDIYFrameBuffPos(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDIYFrameBuffPos", "ss"); }

        int LAG_Target_GetDIYFrameLayout(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetDIYFrameLayout", "ssssssssssssssssssssssssssnnssssssssssssss"); }

        int LAG_Target_GetFixKfsBase(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetFixKfsBase", "n"); }

        int LAG_Target_GetFullName(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetFullName", "s"); }

        int LAG_Target_GetHdSandBoxPercent(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetHdSandBoxPercent", "n"); }

        int LAG_Target_GetKfsBase(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetKfsBase", "n"); }

        int LAG_Target_GetKfsData(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetKfsData", "s"); }

        int LAG_Target_GetKfsFixAttrEx(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetKfsFixAttrEx", "sn"); }

        int LAG_Target_GetMyPos(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetMyPos", "nnn"); }

        int LAG_Target_GetServerId2ClientId(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetServerId2ClientId", "n"); }

        int LAG_Target_GetTargetGUID(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetTargetGUID", "n"); }

        int LAG_Target_GetXinfaNpcName(LuaPlus::LuaState* state) { return Stub(state, "Target", "GetXinfaNpcName", "s"); }

        int LAG_Target_IsTargetRaidMember(LuaPlus::LuaState* state) { return Stub(state, "Target", "IsTargetRaidMember", "n"); }

        int LAG_Target_LuaFnGetWHWGInSlot(LuaPlus::LuaState* state) { return Stub(state, "Target", "LuaFnGetWHWGInSlot", "n"); }

        int LAG_Target_LuaFnGetWHWGInfo(LuaPlus::LuaState* state) { return Stub(state, "Target", "LuaFnGetWHWGInfo", "s"); }


        int LAG_Target_ReportWaiguaForInfo(LuaPlus::LuaState* state) { return Stub(state, "Target", "ReportWaiguaForInfo", ""); }

        int LAG_Target_SelectThePlayer(LuaPlus::LuaState* state) { return Stub(state, "Target", "SelectThePlayer", ""); }


        int LAG_Target_SendChangeNameMsg(LuaPlus::LuaState* state) { return Stub(state, "Target", "SendChangeNameMsg", ""); }


        int LAG_Target_SendCharRnameMsg(LuaPlus::LuaState* state) { return Stub(state, "Target", "SendCharRnameMsg", ""); }


        int LAG_Target_SendRaidApplication(LuaPlus::LuaState* state) { return Stub(state, "Target", "SendRaidApplication", ""); }


        int LAG_Target_SendRaidInvitation(LuaPlus::LuaState* state) { return Stub(state, "Target", "SendRaidInvitation", ""); }

        int LAG_Target_SetHorseModel(LuaPlus::LuaState* state) { return Stub(state, "Target", "SetHorseModel", ""); }

        int LAG_Target_TargetEquip_DestroyUIModel(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetEquip_DestroyUIModel", ""); }

        int LAG_Target_TargetFrame_Get_HDSandBoxMaxHP_Team(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Get_HDSandBoxMaxHP_Team", "n"); }

        int LAG_Target_TargetFrame_Update_Eng_Raid(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Update_Eng_Raid", "n"); }

        int LAG_Target_TargetFrame_Update_HDSandBoxHP_Team(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Update_HDSandBoxHP_Team", "n"); }

        int LAG_Target_TargetFrame_Update_HP_Raid(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Update_HP_Raid", "n"); }

        int LAG_Target_TargetFrame_Update_HeadFrame_Raid(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Update_HeadFrame_Raid", "nn"); }

        int LAG_Target_TargetFrame_Update_Icon_Raid(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Update_Icon_Raid", "s"); }

        int LAG_Target_TargetFrame_Update_Level_Raid(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Update_Level_Raid", "n"); }

        int LAG_Target_TargetFrame_Update_MP_Raid(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Update_MP_Raid", "n"); }

        int LAG_Target_TargetFrame_Update_Menpai_Raid(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Update_Menpai_Raid", "n"); }

        int LAG_Target_TargetFrame_Update_Menpai_Team(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Update_Menpai_Team", "n"); }

        int LAG_Target_TargetFrame_Update_Name_Raid(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Update_Name_Raid", "s"); }

        int LAG_Target_TargetFrame_Update_Rage_Raid(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Update_Rage_Raid", "n"); }

        int LAG_Target_TargetFrame_Update_TP_Raid(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetFrame_Update_TP_Raid", "n"); }

        int LAG_Target_TargetProfile_ChangeModel(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetProfile_ChangeModel", ""); }

        int LAG_Target_TargetProfile_DestroyUIModel(LuaPlus::LuaState* state) { return Stub(state, "Target", "TargetProfile_DestroyUIModel", ""); }


        int LAG_Target_UpdateActionButton(LuaPlus::LuaState* state) { return Stub(state, "Target", "UpdateActionButton", ""); }

        int LAG_Target_UpdateOtherKFSModel(LuaPlus::LuaState* state) { return Stub(state, "Target", "UpdateOtherKFSModel", ""); }
    }

    void Register_Target(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "CanGetTargetEquip")) table.Register("CanGetTargetEquip", LAG_Target_CanGetTargetEquip);
        if (IsMissing(table, "ChangeNameConfirm")) table.Register("ChangeNameConfirm", LAG_Target_ChangeNameConfirm);
        if (IsMissing(table, "CharRnameCheck")) table.Register("CharRnameCheck", LAG_Target_CharRnameCheck);
        if (IsMissing(table, "CharRnameConfirm")) table.Register("CharRnameConfirm", LAG_Target_CharRnameConfirm);
        if (IsMissing(table, "CheckBuffImpactExist")) table.Register("CheckBuffImpactExist", LAG_Target_CheckBuffImpactExist);
        if (IsMissing(table, "GetAllBuffIconName")) table.Register("GetAllBuffIconName", LAG_Target_GetAllBuffIconName);
        if (IsMissing(table, "GetBuffIsShowIconByIndex")) table.Register("GetBuffIsShowIconByIndex", LAG_Target_GetBuffIsShowIconByIndex);
        if (IsMissing(table, "GetBuffPriorityByIndex")) table.Register("GetBuffPriorityByIndex", LAG_Target_GetBuffPriorityByIndex);
        if (IsMissing(table, "GetDFengAttackMenPai1")) table.Register("GetDFengAttackMenPai1", LAG_Target_GetDFengAttackMenPai1);
        if (IsMissing(table, "GetDFengAttackMenPai2")) table.Register("GetDFengAttackMenPai2", LAG_Target_GetDFengAttackMenPai2);
        if (IsMissing(table, "GetDFengAttackMenPai3")) table.Register("GetDFengAttackMenPai3", LAG_Target_GetDFengAttackMenPai3);
        if (IsMissing(table, "GetDFengAttackXDD1")) table.Register("GetDFengAttackXDD1", LAG_Target_GetDFengAttackXDD1);
        if (IsMissing(table, "GetDFengAttackXDD2")) table.Register("GetDFengAttackXDD2", LAG_Target_GetDFengAttackXDD2);
        if (IsMissing(table, "GetDFengAttackXDD3")) table.Register("GetDFengAttackXDD3", LAG_Target_GetDFengAttackXDD3);
        if (IsMissing(table, "GetDFengAttrNextLevelStr_Essence")) table.Register("GetDFengAttrNextLevelStr_Essence", LAG_Target_GetDFengAttrNextLevelStr_Essence);
        if (IsMissing(table, "GetDFengDFengAttrNextLevelStr")) table.Register("GetDFengDFengAttrNextLevelStr", LAG_Target_GetDFengDFengAttrNextLevelStr);
        if (IsMissing(table, "GetDFengDefenceMenPai1")) table.Register("GetDFengDefenceMenPai1", LAG_Target_GetDFengDefenceMenPai1);
        if (IsMissing(table, "GetDFengDefenceMenPai2")) table.Register("GetDFengDefenceMenPai2", LAG_Target_GetDFengDefenceMenPai2);
        if (IsMissing(table, "GetDFengDefenceMenPai3")) table.Register("GetDFengDefenceMenPai3", LAG_Target_GetDFengDefenceMenPai3);
        if (IsMissing(table, "GetDFengDefenceXDD1")) table.Register("GetDFengDefenceXDD1", LAG_Target_GetDFengDefenceXDD1);
        if (IsMissing(table, "GetDFengDefenceXDD2")) table.Register("GetDFengDefenceXDD2", LAG_Target_GetDFengDefenceXDD2);
        if (IsMissing(table, "GetDFengDefenceXDD3")) table.Register("GetDFengDefenceXDD3", LAG_Target_GetDFengDefenceXDD3);
        if (IsMissing(table, "GetDFengEssenceAttrAttack")) table.Register("GetDFengEssenceAttrAttack", LAG_Target_GetDFengEssenceAttrAttack);
        if (IsMissing(table, "GetDFengEssenceKWALLLevel")) table.Register("GetDFengEssenceKWALLLevel", LAG_Target_GetDFengEssenceKWALLLevel);
        if (IsMissing(table, "GetDFengEssenceLevel")) table.Register("GetDFengEssenceLevel", LAG_Target_GetDFengEssenceLevel);
        if (IsMissing(table, "GetDFengExp")) table.Register("GetDFengExp", LAG_Target_GetDFengExp);
        if (IsMissing(table, "GetDFengExtraLevelupTimes")) table.Register("GetDFengExtraLevelupTimes", LAG_Target_GetDFengExtraLevelupTimes);
        if (IsMissing(table, "GetDFengLevel")) table.Register("GetDFengLevel", LAG_Target_GetDFengLevel);
        if (IsMissing(table, "GetDFengLevelupTimes")) table.Register("GetDFengLevelupTimes", LAG_Target_GetDFengLevelupTimes);
        if (IsMissing(table, "GetDFengNeedExp")) table.Register("GetDFengNeedExp", LAG_Target_GetDFengNeedExp);
        if (IsMissing(table, "GetDFengZhuiGanInfo")) table.Register("GetDFengZhuiGanInfo", LAG_Target_GetDFengZhuiGanInfo);
        if (IsMissing(table, "GetDIYFrameBuffPos")) table.Register("GetDIYFrameBuffPos", LAG_Target_GetDIYFrameBuffPos);
        if (IsMissing(table, "GetDIYFrameLayout")) table.Register("GetDIYFrameLayout", LAG_Target_GetDIYFrameLayout);
        if (IsMissing(table, "GetFixKfsBase")) table.Register("GetFixKfsBase", LAG_Target_GetFixKfsBase);
        if (IsMissing(table, "GetFullName")) table.Register("GetFullName", LAG_Target_GetFullName);
        if (IsMissing(table, "GetHdSandBoxPercent")) table.Register("GetHdSandBoxPercent", LAG_Target_GetHdSandBoxPercent);
        if (IsMissing(table, "GetKfsBase")) table.Register("GetKfsBase", LAG_Target_GetKfsBase);
        if (IsMissing(table, "GetKfsData")) table.Register("GetKfsData", LAG_Target_GetKfsData);
        if (IsMissing(table, "GetKfsFixAttrEx")) table.Register("GetKfsFixAttrEx", LAG_Target_GetKfsFixAttrEx);
        if (IsMissing(table, "GetMyPos")) table.Register("GetMyPos", LAG_Target_GetMyPos);
        if (IsMissing(table, "GetServerId2ClientId")) table.Register("GetServerId2ClientId", LAG_Target_GetServerId2ClientId);
        if (IsMissing(table, "GetTargetGUID")) table.Register("GetTargetGUID", LAG_Target_GetTargetGUID);
        if (IsMissing(table, "GetXinfaNpcName")) table.Register("GetXinfaNpcName", LAG_Target_GetXinfaNpcName);
        if (IsMissing(table, "IsTargetRaidMember")) table.Register("IsTargetRaidMember", LAG_Target_IsTargetRaidMember);
        if (IsMissing(table, "LuaFnGetWHWGInSlot")) table.Register("LuaFnGetWHWGInSlot", LAG_Target_LuaFnGetWHWGInSlot);
        if (IsMissing(table, "LuaFnGetWHWGInfo")) table.Register("LuaFnGetWHWGInfo", LAG_Target_LuaFnGetWHWGInfo);
        if (IsMissing(table, "ReportWaiguaForInfo")) table.Register("ReportWaiguaForInfo", LAG_Target_ReportWaiguaForInfo);
        if (IsMissing(table, "SelectThePlayer")) table.Register("SelectThePlayer", LAG_Target_SelectThePlayer);
        if (IsMissing(table, "SendChangeNameMsg")) table.Register("SendChangeNameMsg", LAG_Target_SendChangeNameMsg);
        if (IsMissing(table, "SendCharRnameMsg")) table.Register("SendCharRnameMsg", LAG_Target_SendCharRnameMsg);
        if (IsMissing(table, "SendRaidApplication")) table.Register("SendRaidApplication", LAG_Target_SendRaidApplication);
        if (IsMissing(table, "SendRaidInvitation")) table.Register("SendRaidInvitation", LAG_Target_SendRaidInvitation);
        if (IsMissing(table, "SetHorseModel")) table.Register("SetHorseModel", LAG_Target_SetHorseModel);
        if (IsMissing(table, "TargetEquip_DestroyUIModel")) table.Register("TargetEquip_DestroyUIModel", LAG_Target_TargetEquip_DestroyUIModel);
        if (IsMissing(table, "TargetFrame_Get_HDSandBoxMaxHP_Team")) table.Register("TargetFrame_Get_HDSandBoxMaxHP_Team", LAG_Target_TargetFrame_Get_HDSandBoxMaxHP_Team);
        if (IsMissing(table, "TargetFrame_Update_Eng_Raid")) table.Register("TargetFrame_Update_Eng_Raid", LAG_Target_TargetFrame_Update_Eng_Raid);
        if (IsMissing(table, "TargetFrame_Update_HDSandBoxHP_Team")) table.Register("TargetFrame_Update_HDSandBoxHP_Team", LAG_Target_TargetFrame_Update_HDSandBoxHP_Team);
        if (IsMissing(table, "TargetFrame_Update_HP_Raid")) table.Register("TargetFrame_Update_HP_Raid", LAG_Target_TargetFrame_Update_HP_Raid);
        if (IsMissing(table, "TargetFrame_Update_HeadFrame_Raid")) table.Register("TargetFrame_Update_HeadFrame_Raid", LAG_Target_TargetFrame_Update_HeadFrame_Raid);
        if (IsMissing(table, "TargetFrame_Update_Icon_Raid")) table.Register("TargetFrame_Update_Icon_Raid", LAG_Target_TargetFrame_Update_Icon_Raid);
        if (IsMissing(table, "TargetFrame_Update_Level_Raid")) table.Register("TargetFrame_Update_Level_Raid", LAG_Target_TargetFrame_Update_Level_Raid);
        if (IsMissing(table, "TargetFrame_Update_MP_Raid")) table.Register("TargetFrame_Update_MP_Raid", LAG_Target_TargetFrame_Update_MP_Raid);
        if (IsMissing(table, "TargetFrame_Update_Menpai_Raid")) table.Register("TargetFrame_Update_Menpai_Raid", LAG_Target_TargetFrame_Update_Menpai_Raid);
        if (IsMissing(table, "TargetFrame_Update_Menpai_Team")) table.Register("TargetFrame_Update_Menpai_Team", LAG_Target_TargetFrame_Update_Menpai_Team);
        if (IsMissing(table, "TargetFrame_Update_Name_Raid")) table.Register("TargetFrame_Update_Name_Raid", LAG_Target_TargetFrame_Update_Name_Raid);
        if (IsMissing(table, "TargetFrame_Update_Rage_Raid")) table.Register("TargetFrame_Update_Rage_Raid", LAG_Target_TargetFrame_Update_Rage_Raid);
        if (IsMissing(table, "TargetFrame_Update_TP_Raid")) table.Register("TargetFrame_Update_TP_Raid", LAG_Target_TargetFrame_Update_TP_Raid);
        if (IsMissing(table, "TargetProfile_ChangeModel")) table.Register("TargetProfile_ChangeModel", LAG_Target_TargetProfile_ChangeModel);
        if (IsMissing(table, "TargetProfile_DestroyUIModel")) table.Register("TargetProfile_DestroyUIModel", LAG_Target_TargetProfile_DestroyUIModel);
        if (IsMissing(table, "UpdateActionButton")) table.Register("UpdateActionButton", LAG_Target_UpdateActionButton);
        if (IsMissing(table, "UpdateOtherKFSModel")) table.Register("UpdateOtherKFSModel", LAG_Target_UpdateOtherKFSModel);
    }
}
