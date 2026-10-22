




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_Player_ChangeCoupleTitle(LuaPlus::LuaState* state) { return Stub(state, "Player", "ChangeCoupleTitle", "o"); }

        int LAG_Player_ChangePVPMode(LuaPlus::LuaState* state) { return Stub(state, "Player", "ChangePVPMode", ""); }

        int LAG_Player_ChangePVPModeWithPassword(LuaPlus::LuaState* state) { return Stub(state, "Player", "ChangePVPModeWithPassword", ""); }


        int LAG_Player_ChangeSwearTitle(LuaPlus::LuaState* state) { return Stub(state, "Player", "ChangeSwearTitle", "o"); }

        int LAG_Player_CheckBuffImpactExist(LuaPlus::LuaState* state) { return Stub(state, "Player", "CheckBuffImpactExist", ""); }

        int LAG_Player_CheckIfCanDena(LuaPlus::LuaState* state) { return Stub(state, "Player", "CheckIfCanDena", "n"); }

        int LAG_Player_CheckSwearTitle(LuaPlus::LuaState* state) { return Stub(state, "Player", "CheckSwearTitle", "n"); }


        int LAG_Player_ClearUpdateBtnFlashFlag(LuaPlus::LuaState* state) { return Stub(state, "Player", "ClearUpdateBtnFlashFlag", "o"); }

        int LAG_Player_ConfirmDismissTeam(LuaPlus::LuaState* state) { return Stub(state, "Player", "ConfirmDismissTeam", ""); }

        int LAG_Player_CreateDenaObj(LuaPlus::LuaState* state) { return Stub(state, "Player", "CreateDenaObj", "n"); }


        int LAG_Player_CreateRaidSelf(LuaPlus::LuaState* state) { return Stub(state, "Player", "CreateRaidSelf", ""); }

        int LAG_Player_DelDenaObj(LuaPlus::LuaState* state) { return Stub(state, "Player", "DelDenaObj", ""); }


        int LAG_Player_DrawCoupleTitle(LuaPlus::LuaState* state) { return Stub(state, "Player", "DrawCoupleTitle", "o"); }


        int LAG_Player_DrawSwearTitle(LuaPlus::LuaState* state) { return Stub(state, "Player", "DrawSwearTitle", "o"); }

        int LAG_Player_EnumAllTitles(LuaPlus::LuaState* state) { return Stub(state, "Player", "EnumAllTitles", "s"); }

        int LAG_Player_EnumBoardType(LuaPlus::LuaState* state) { return Stub(state, "Player", "EnumBoardType", "ssnnnnnnnn"); }

        int LAG_Player_EnumFlashType(LuaPlus::LuaState* state) { return Stub(state, "Player", "EnumFlashType", "nnn"); }

        int LAG_Player_FeatchVaildTitle(LuaPlus::LuaState* state) { return Stub(state, "Player", "FeatchVaildTitle", "nnnnnnnssnns"); }

        int LAG_Player_GetAccMD5String(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetAccMD5String", "s"); }

        int LAG_Player_GetAllTitlesNum(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetAllTitlesNum", "n"); }

        int LAG_Player_GetAttackMenPai1(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetAttackMenPai1", "n"); }

        int LAG_Player_GetAttackMenPai2(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetAttackMenPai2", "n"); }

        int LAG_Player_GetAttackMenPai3(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetAttackMenPai3", "n"); }

        int LAG_Player_GetAttackMenPaiXDD1(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetAttackMenPaiXDD1", "n"); }

        int LAG_Player_GetAttackMenPaiXDD2(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetAttackMenPaiXDD2", "n"); }

        int LAG_Player_GetAttackMenPaiXDD3(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetAttackMenPaiXDD3", "n"); }

        int LAG_Player_GetBuffIsShowIconByIndex(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetBuffIsShowIconByIndex", "n"); }

        int LAG_Player_GetBuffPriorityByIndex(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetBuffPriorityByIndex", "n"); }

        int LAG_Player_GetCurTitleID(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetCurTitleID", "s"); }

        int LAG_Player_GetDFengAttrNextLevelStr_Essence(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengAttrNextLevelStr_Essence", "n"); }

        int LAG_Player_GetDFengAttrStrValue_Essence_ByLevel(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengAttrStrValue_Essence_ByLevel", "nn"); }

        int LAG_Player_GetDFengDFengAttrEquipSpecialAttName(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengDFengAttrEquipSpecialAttName", "ns"); }

        int LAG_Player_GetDFengDFengAttrNextLevelStr(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengDFengAttrNextLevelStr", "ns"); }

        int LAG_Player_GetDFengDFengAttrStr(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengDFengAttrStr", "nn"); }

        int LAG_Player_GetDFengDFengAttrStr_Value_ByLevel(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengDFengAttrStr_Value_ByLevel", "ns"); }

        int LAG_Player_GetDFengDFengAttrValueINT(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengDFengAttrValueINT", "n"); }

        int LAG_Player_GetDFengDFengAttrValueStr(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengDFengAttrValueStr", "nn"); }

        int LAG_Player_GetDFengDFengAttrValueType(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengDFengAttrValueType", "nn"); }

        int LAG_Player_GetDFengDFengQNDValueINT(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengDFengQNDValueINT", "n"); }

        int LAG_Player_GetDFengEssenceAttrAttack(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengEssenceAttrAttack", "n"); }

        int LAG_Player_GetDFengEssenceAttrEquipSpecialAttName(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengEssenceAttrEquipSpecialAttName", "ns"); }

        int LAG_Player_GetDFengEssenceAttrValueINT(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengEssenceAttrValueINT", "n"); }

        int LAG_Player_GetDFengEssenceAttrValueStr(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengEssenceAttrValueStr", "nn"); }

        int LAG_Player_GetDFengEssenceKWAllLevel(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengEssenceKWAllLevel", "n"); }

        int LAG_Player_GetDFengEssenceLevel(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengEssenceLevel", "n"); }

        int LAG_Player_GetDFengExp(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengExp", "n"); }

        int LAG_Player_GetDFengExtraLevelupTimes(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengExtraLevelupTimes", "n"); }

        int LAG_Player_GetDFengLevel(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengLevel", "n"); }

        int LAG_Player_GetDFengLevelupTimes(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengLevelupTimes", "n"); }

        int LAG_Player_GetDFengNeedExp(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengNeedExp", "n"); }

        int LAG_Player_GetDFengZhuiGanInfo(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDFengZhuiGanInfo", "nn"); }

        int LAG_Player_GetDIYFrameLayout(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDIYFrameLayout", "ssssssssssssssssssssssssssnnssssssssssssss"); }

        int LAG_Player_GetDefenceMenPai1(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDefenceMenPai1", "n"); }

        int LAG_Player_GetDefenceMenPai2(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDefenceMenPai2", "n"); }

        int LAG_Player_GetDefenceMenPai3(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDefenceMenPai3", "n"); }

        int LAG_Player_GetDefenceMenPaiXDD1(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDefenceMenPaiXDD1", "n"); }

        int LAG_Player_GetDefenceMenPaiXDD2(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDefenceMenPaiXDD2", "n"); }

        int LAG_Player_GetDefenceMenPaiXDD3(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDefenceMenPaiXDD3", "n"); }

        int LAG_Player_GetDefengEssenceMaxLevelWeekLimitTimes(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDefengEssenceMaxLevelWeekLimitTimes", "n"); }

        int LAG_Player_GetDenaAttr(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDenaAttr", "nnnnn"); }

        int LAG_Player_GetDfengEssenceInfo(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetDfengEssenceInfo", "nn"); }

        int LAG_Player_GetFatigueOnlineTime(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetFatigueOnlineTime", "n"); }


        int LAG_Player_GetGUID(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetGUID", "n"); }

        int LAG_Player_GetIsFatigue(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetIsFatigue", "n"); }


        int LAG_Player_GetLevel(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetLevel", "n"); }

        int LAG_Player_GetLevelMoneyLimit(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetLevelMoneyLimit", "bb"); }

        int LAG_Player_GetMPComboBookInfo(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetMPComboBookInfo", "nn"); }

        int LAG_Player_GetMyHorse(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetMyHorse", "s"); }

        int LAG_Player_GetMyPos(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetMyPos", "nnn"); }

        int LAG_Player_GetMyRaidIndex(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetMyRaidIndex", "nn"); }

        int LAG_Player_GetMySex(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetMySex", "n"); }

        int LAG_Player_GetOwnerIndexByTitleID(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetOwnerIndexByTitleID", "n"); }

        int LAG_Player_GetPKMode(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetPKMode", "n"); }

        int LAG_Player_GetPetCallUpCDPer(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetPetCallUpCDPer", "n"); }

        int LAG_Player_GetReputation(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetReputation", "n"); }

        int LAG_Player_GetSystemColorText(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetSystemColorText", "s"); }

        int LAG_Player_GetTeamMemberName(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetTeamMemberName", "s"); }

        int LAG_Player_GetTimeToPeace(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetTimeToPeace", "n"); }

        int LAG_Player_GetTitleAnimateInfo(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetTitleAnimateInfo", "nnn"); }

        int LAG_Player_GetTitleDisableTimeByTitleID(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetTitleDisableTimeByTitleID", "n"); }

        int LAG_Player_GetTotalHorseNum(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetTotalHorseNum", "n"); }

        int LAG_Player_GetXiuLianBookInfo(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetXiuLianBookInfo", "n"); }

        int LAG_Player_GetXiuLianMiJiInfo(LuaPlus::LuaState* state) { return Stub(state, "Player", "GetXiuLianMiJiInfo", "n"); }

        int LAG_Player_HaveTitle(LuaPlus::LuaState* state) { return Stub(state, "Player", "HaveTitle", "nnssn"); }

        int LAG_Player_IsHaveCurrentPet(LuaPlus::LuaState* state) { return Stub(state, "Player", "IsHaveCurrentPet", "b"); }

        int LAG_Player_IsHaveItem(LuaPlus::LuaState* state) { return Stub(state, "Player", "IsHaveItem", "n"); }


        int LAG_Player_IsHavePassword(LuaPlus::LuaState* state) { return Stub(state, "Player", "IsHavePassword", "n"); }

        int LAG_Player_IsInRaid(LuaPlus::LuaState* state) { return Stub(state, "Player", "IsInRaid", "n"); }

        int LAG_Player_IsInTeam(LuaPlus::LuaState* state) { return Stub(state, "Player", "IsInTeam", "n"); }

        int LAG_Player_IsLeader(LuaPlus::LuaState* state) { return Stub(state, "Player", "IsLeader", "n"); }


        int LAG_Player_IsLocked(LuaPlus::LuaState* state) { return Stub(state, "Player", "IsLocked", "n"); }

        int LAG_Player_IsOnHorse(LuaPlus::LuaState* state) { return Stub(state, "Player", "IsOnHorse", "n"); }

        int LAG_Player_IsRaidAssitant(LuaPlus::LuaState* state) { return Stub(state, "Player", "IsRaidAssitant", "n"); }

        int LAG_Player_IsRaidLeader(LuaPlus::LuaState* state) { return Stub(state, "Player", "IsRaidLeader", "n"); }

        int LAG_Player_IsVaild(LuaPlus::LuaState* state) { return Stub(state, "Player", "IsVaild", "n"); }


        int LAG_Player_KickRaidMemberByIdx(LuaPlus::LuaState* state) { return Stub(state, "Player", "KickRaidMemberByIdx", ""); }


        int LAG_Player_LeaveRiad(LuaPlus::LuaState* state) { return Stub(state, "Player", "LeaveRiad", ""); }


        int LAG_Player_Lua_AskBuyFestivalShopItem(LuaPlus::LuaState* state) { return Stub(state, "Player", "Lua_AskBuyFestivalShopItem", ""); }


        int LAG_Player_Lua_AskSectOper(LuaPlus::LuaState* state) { return Stub(state, "Player", "Lua_AskSectOper", ""); }

        int LAG_Player_Lua_CreateSectShare(LuaPlus::LuaState* state) { return Stub(state, "Player", "Lua_CreateSectShare", "n"); }

        int LAG_Player_Lua_GetXbwData(LuaPlus::LuaState* state) { return Stub(state, "Player", "Lua_GetXbwData", "n"); }

        int LAG_Player_OpenCreateRaidConfirmWindow(LuaPlus::LuaState* state) { return Stub(state, "Player", "OpenCreateRaidConfirmWindow", ""); }

        int LAG_Player_OpenDismissTeamMsgbox(LuaPlus::LuaState* state) { return Stub(state, "Player", "OpenDismissTeamMsgbox", ""); }

        int LAG_Player_PVP_Challenge(LuaPlus::LuaState* state) { return Stub(state, "Player", "PVP_Challenge", ""); }

        int LAG_Player_PVP_Duel(LuaPlus::LuaState* state) { return Stub(state, "Player", "PVP_Duel", ""); }

        int LAG_Player_PVP_ShowMenu(LuaPlus::LuaState* state) { return Stub(state, "Player", "PVP_ShowMenu", "oooooo"); }

        int LAG_Player_Player_GetTitleType(LuaPlus::LuaState* state) { return Stub(state, "Player", "Player_GetTitleType", "n"); }


        int LAG_Player_RaidAppointByIdx(LuaPlus::LuaState* state) { return Stub(state, "Player", "RaidAppointByIdx", ""); }

        int LAG_Player_SaveDenaAttr(LuaPlus::LuaState* state) { return Stub(state, "Player", "SaveDenaAttr", ""); }


        int LAG_Player_SendAcceptRaidInvitation(LuaPlus::LuaState* state) { return Stub(state, "Player", "SendAcceptRaidInvitation", ""); }


        int LAG_Player_SendAgreeRaidApplication(LuaPlus::LuaState* state) { return Stub(state, "Player", "SendAgreeRaidApplication", ""); }


        int LAG_Player_SendOpposeRaidApplication(LuaPlus::LuaState* state) { return Stub(state, "Player", "SendOpposeRaidApplication", ""); }


        int LAG_Player_SendRejectRaidInvitation(LuaPlus::LuaState* state) { return Stub(state, "Player", "SendRejectRaidInvitation", ""); }


        int LAG_Player_SendReliveMessage_Fool(LuaPlus::LuaState* state) { return Stub(state, "Player", "SendReliveMessage_Fool", ""); }

        int LAG_Player_SendReportMsg(LuaPlus::LuaState* state) { return Stub(state, "Player", "SendReportMsg", "o"); }


        int LAG_Player_SendSpeakerMessage(LuaPlus::LuaState* state) { return Stub(state, "Player", "SendSpeakerMessage", "o"); }

        int LAG_Player_SetDIYFramePreview(LuaPlus::LuaState* state) { return Stub(state, "Player", "SetDIYFramePreview", "oo"); }


        int LAG_Player_SetExpAssgin(LuaPlus::LuaState* state) { return Stub(state, "Player", "SetExpAssgin", "o"); }

        int LAG_Player_SetHorseModel(LuaPlus::LuaState* state) { return Stub(state, "Player", "SetHorseModel", ""); }


        int LAG_Player_SetIPRegion(LuaPlus::LuaState* state) { return Stub(state, "Player", "SetIPRegion", ""); }

        int LAG_Player_ShowRaidApplicationList(LuaPlus::LuaState* state) { return Stub(state, "Player", "ShowRaidApplicationList", ""); }


        int LAG_Player_UseItem(LuaPlus::LuaState* state) { return Stub(state, "Player", "UseItem", ""); }


        int LAG_Player_UseRose(LuaPlus::LuaState* state) { return Stub(state, "Player", "UseRose", ""); }


        int LAG_Player_YuanBaoToBind(LuaPlus::LuaState* state) { return Stub(state, "Player", "YuanBaoToBind", "n"); }


        int LAG_Player_YuanBaoToTicket(LuaPlus::LuaState* state) { return Stub(state, "Player", "YuanBaoToTicket", "n"); }

        int LAG_Player_calcAllEffectAgname(LuaPlus::LuaState* state) { return Stub(state, "Player", "calcAllEffectAgname", "s"); }
    }

    void Register_Player(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ChangeCoupleTitle")) table.Register("ChangeCoupleTitle", LAG_Player_ChangeCoupleTitle);
        if (IsMissing(table, "ChangePVPMode")) table.Register("ChangePVPMode", LAG_Player_ChangePVPMode);
        if (IsMissing(table, "ChangePVPModeWithPassword")) table.Register("ChangePVPModeWithPassword", LAG_Player_ChangePVPModeWithPassword);
        if (IsMissing(table, "ChangeSwearTitle")) table.Register("ChangeSwearTitle", LAG_Player_ChangeSwearTitle);
        if (IsMissing(table, "CheckBuffImpactExist")) table.Register("CheckBuffImpactExist", LAG_Player_CheckBuffImpactExist);
        if (IsMissing(table, "CheckIfCanDena")) table.Register("CheckIfCanDena", LAG_Player_CheckIfCanDena);
        if (IsMissing(table, "CheckSwearTitle")) table.Register("CheckSwearTitle", LAG_Player_CheckSwearTitle);
        if (IsMissing(table, "ClearUpdateBtnFlashFlag")) table.Register("ClearUpdateBtnFlashFlag", LAG_Player_ClearUpdateBtnFlashFlag);
        if (IsMissing(table, "ConfirmDismissTeam")) table.Register("ConfirmDismissTeam", LAG_Player_ConfirmDismissTeam);
        if (IsMissing(table, "CreateDenaObj")) table.Register("CreateDenaObj", LAG_Player_CreateDenaObj);
        if (IsMissing(table, "CreateRaidSelf")) table.Register("CreateRaidSelf", LAG_Player_CreateRaidSelf);
        if (IsMissing(table, "DelDenaObj")) table.Register("DelDenaObj", LAG_Player_DelDenaObj);
        if (IsMissing(table, "DrawCoupleTitle")) table.Register("DrawCoupleTitle", LAG_Player_DrawCoupleTitle);
        if (IsMissing(table, "DrawSwearTitle")) table.Register("DrawSwearTitle", LAG_Player_DrawSwearTitle);
        if (IsMissing(table, "EnumAllTitles")) table.Register("EnumAllTitles", LAG_Player_EnumAllTitles);
        if (IsMissing(table, "EnumBoardType")) table.Register("EnumBoardType", LAG_Player_EnumBoardType);
        if (IsMissing(table, "EnumFlashType")) table.Register("EnumFlashType", LAG_Player_EnumFlashType);
        if (IsMissing(table, "FeatchVaildTitle")) table.Register("FeatchVaildTitle", LAG_Player_FeatchVaildTitle);
        if (IsMissing(table, "GetAccMD5String")) table.Register("GetAccMD5String", LAG_Player_GetAccMD5String);
        if (IsMissing(table, "GetAllTitlesNum")) table.Register("GetAllTitlesNum", LAG_Player_GetAllTitlesNum);
        if (IsMissing(table, "GetAttackMenPai1")) table.Register("GetAttackMenPai1", LAG_Player_GetAttackMenPai1);
        if (IsMissing(table, "GetAttackMenPai2")) table.Register("GetAttackMenPai2", LAG_Player_GetAttackMenPai2);
        if (IsMissing(table, "GetAttackMenPai3")) table.Register("GetAttackMenPai3", LAG_Player_GetAttackMenPai3);
        if (IsMissing(table, "GetAttackMenPaiXDD1")) table.Register("GetAttackMenPaiXDD1", LAG_Player_GetAttackMenPaiXDD1);
        if (IsMissing(table, "GetAttackMenPaiXDD2")) table.Register("GetAttackMenPaiXDD2", LAG_Player_GetAttackMenPaiXDD2);
        if (IsMissing(table, "GetAttackMenPaiXDD3")) table.Register("GetAttackMenPaiXDD3", LAG_Player_GetAttackMenPaiXDD3);
        if (IsMissing(table, "GetBuffIsShowIconByIndex")) table.Register("GetBuffIsShowIconByIndex", LAG_Player_GetBuffIsShowIconByIndex);
        if (IsMissing(table, "GetBuffPriorityByIndex")) table.Register("GetBuffPriorityByIndex", LAG_Player_GetBuffPriorityByIndex);
        if (IsMissing(table, "GetCurTitleID")) table.Register("GetCurTitleID", LAG_Player_GetCurTitleID);
        if (IsMissing(table, "GetDFengAttrNextLevelStr_Essence")) table.Register("GetDFengAttrNextLevelStr_Essence", LAG_Player_GetDFengAttrNextLevelStr_Essence);
        if (IsMissing(table, "GetDFengAttrStrValue_Essence_ByLevel")) table.Register("GetDFengAttrStrValue_Essence_ByLevel", LAG_Player_GetDFengAttrStrValue_Essence_ByLevel);
        if (IsMissing(table, "GetDFengDFengAttrEquipSpecialAttName")) table.Register("GetDFengDFengAttrEquipSpecialAttName", LAG_Player_GetDFengDFengAttrEquipSpecialAttName);
        if (IsMissing(table, "GetDFengDFengAttrNextLevelStr")) table.Register("GetDFengDFengAttrNextLevelStr", LAG_Player_GetDFengDFengAttrNextLevelStr);
        if (IsMissing(table, "GetDFengDFengAttrStr")) table.Register("GetDFengDFengAttrStr", LAG_Player_GetDFengDFengAttrStr);
        if (IsMissing(table, "GetDFengDFengAttrStr_Value_ByLevel")) table.Register("GetDFengDFengAttrStr_Value_ByLevel", LAG_Player_GetDFengDFengAttrStr_Value_ByLevel);
        if (IsMissing(table, "GetDFengDFengAttrValueINT")) table.Register("GetDFengDFengAttrValueINT", LAG_Player_GetDFengDFengAttrValueINT);
        if (IsMissing(table, "GetDFengDFengAttrValueStr")) table.Register("GetDFengDFengAttrValueStr", LAG_Player_GetDFengDFengAttrValueStr);
        if (IsMissing(table, "GetDFengDFengAttrValueType")) table.Register("GetDFengDFengAttrValueType", LAG_Player_GetDFengDFengAttrValueType);
        if (IsMissing(table, "GetDFengDFengQNDValueINT")) table.Register("GetDFengDFengQNDValueINT", LAG_Player_GetDFengDFengQNDValueINT);
        if (IsMissing(table, "GetDFengEssenceAttrAttack")) table.Register("GetDFengEssenceAttrAttack", LAG_Player_GetDFengEssenceAttrAttack);
        if (IsMissing(table, "GetDFengEssenceAttrEquipSpecialAttName")) table.Register("GetDFengEssenceAttrEquipSpecialAttName", LAG_Player_GetDFengEssenceAttrEquipSpecialAttName);
        if (IsMissing(table, "GetDFengEssenceAttrValueINT")) table.Register("GetDFengEssenceAttrValueINT", LAG_Player_GetDFengEssenceAttrValueINT);
        if (IsMissing(table, "GetDFengEssenceAttrValueStr")) table.Register("GetDFengEssenceAttrValueStr", LAG_Player_GetDFengEssenceAttrValueStr);
        if (IsMissing(table, "GetDFengEssenceKWAllLevel")) table.Register("GetDFengEssenceKWAllLevel", LAG_Player_GetDFengEssenceKWAllLevel);
        if (IsMissing(table, "GetDFengEssenceLevel")) table.Register("GetDFengEssenceLevel", LAG_Player_GetDFengEssenceLevel);
        if (IsMissing(table, "GetDFengExp")) table.Register("GetDFengExp", LAG_Player_GetDFengExp);
        if (IsMissing(table, "GetDFengExtraLevelupTimes")) table.Register("GetDFengExtraLevelupTimes", LAG_Player_GetDFengExtraLevelupTimes);
        if (IsMissing(table, "GetDFengLevel")) table.Register("GetDFengLevel", LAG_Player_GetDFengLevel);
        if (IsMissing(table, "GetDFengLevelupTimes")) table.Register("GetDFengLevelupTimes", LAG_Player_GetDFengLevelupTimes);
        if (IsMissing(table, "GetDFengNeedExp")) table.Register("GetDFengNeedExp", LAG_Player_GetDFengNeedExp);
        if (IsMissing(table, "GetDFengZhuiGanInfo")) table.Register("GetDFengZhuiGanInfo", LAG_Player_GetDFengZhuiGanInfo);
        if (IsMissing(table, "GetDIYFrameLayout")) table.Register("GetDIYFrameLayout", LAG_Player_GetDIYFrameLayout);
        if (IsMissing(table, "GetDefenceMenPai1")) table.Register("GetDefenceMenPai1", LAG_Player_GetDefenceMenPai1);
        if (IsMissing(table, "GetDefenceMenPai2")) table.Register("GetDefenceMenPai2", LAG_Player_GetDefenceMenPai2);
        if (IsMissing(table, "GetDefenceMenPai3")) table.Register("GetDefenceMenPai3", LAG_Player_GetDefenceMenPai3);
        if (IsMissing(table, "GetDefenceMenPaiXDD1")) table.Register("GetDefenceMenPaiXDD1", LAG_Player_GetDefenceMenPaiXDD1);
        if (IsMissing(table, "GetDefenceMenPaiXDD2")) table.Register("GetDefenceMenPaiXDD2", LAG_Player_GetDefenceMenPaiXDD2);
        if (IsMissing(table, "GetDefenceMenPaiXDD3")) table.Register("GetDefenceMenPaiXDD3", LAG_Player_GetDefenceMenPaiXDD3);
        if (IsMissing(table, "GetDefengEssenceMaxLevelWeekLimitTimes")) table.Register("GetDefengEssenceMaxLevelWeekLimitTimes", LAG_Player_GetDefengEssenceMaxLevelWeekLimitTimes);
        if (IsMissing(table, "GetDenaAttr")) table.Register("GetDenaAttr", LAG_Player_GetDenaAttr);
        if (IsMissing(table, "GetDfengEssenceInfo")) table.Register("GetDfengEssenceInfo", LAG_Player_GetDfengEssenceInfo);
        if (IsMissing(table, "GetFatigueOnlineTime")) table.Register("GetFatigueOnlineTime", LAG_Player_GetFatigueOnlineTime);
        if (IsMissing(table, "GetGUID")) table.Register("GetGUID", LAG_Player_GetGUID);
        if (IsMissing(table, "GetIsFatigue")) table.Register("GetIsFatigue", LAG_Player_GetIsFatigue);
        if (IsMissing(table, "GetLevel")) table.Register("GetLevel", LAG_Player_GetLevel);
        if (IsMissing(table, "GetLevelMoneyLimit")) table.Register("GetLevelMoneyLimit", LAG_Player_GetLevelMoneyLimit);
        if (IsMissing(table, "GetMPComboBookInfo")) table.Register("GetMPComboBookInfo", LAG_Player_GetMPComboBookInfo);
        if (IsMissing(table, "GetMyHorse")) table.Register("GetMyHorse", LAG_Player_GetMyHorse);
        if (IsMissing(table, "GetMyPos")) table.Register("GetMyPos", LAG_Player_GetMyPos);
        if (IsMissing(table, "GetMyRaidIndex")) table.Register("GetMyRaidIndex", LAG_Player_GetMyRaidIndex);
        if (IsMissing(table, "GetMySex")) table.Register("GetMySex", LAG_Player_GetMySex);
        if (IsMissing(table, "GetOwnerIndexByTitleID")) table.Register("GetOwnerIndexByTitleID", LAG_Player_GetOwnerIndexByTitleID);
        if (IsMissing(table, "GetPKMode")) table.Register("GetPKMode", LAG_Player_GetPKMode);
        if (IsMissing(table, "GetPetCallUpCDPer")) table.Register("GetPetCallUpCDPer", LAG_Player_GetPetCallUpCDPer);
        if (IsMissing(table, "GetReputation")) table.Register("GetReputation", LAG_Player_GetReputation);
        if (IsMissing(table, "GetSystemColorText")) table.Register("GetSystemColorText", LAG_Player_GetSystemColorText);
        if (IsMissing(table, "GetTeamMemberName")) table.Register("GetTeamMemberName", LAG_Player_GetTeamMemberName);
        if (IsMissing(table, "GetTimeToPeace")) table.Register("GetTimeToPeace", LAG_Player_GetTimeToPeace);
        if (IsMissing(table, "GetTitleAnimateInfo")) table.Register("GetTitleAnimateInfo", LAG_Player_GetTitleAnimateInfo);
        if (IsMissing(table, "GetTitleDisableTimeByTitleID")) table.Register("GetTitleDisableTimeByTitleID", LAG_Player_GetTitleDisableTimeByTitleID);
        if (IsMissing(table, "GetTotalHorseNum")) table.Register("GetTotalHorseNum", LAG_Player_GetTotalHorseNum);
        if (IsMissing(table, "GetXiuLianBookInfo")) table.Register("GetXiuLianBookInfo", LAG_Player_GetXiuLianBookInfo);
        if (IsMissing(table, "GetXiuLianMiJiInfo")) table.Register("GetXiuLianMiJiInfo", LAG_Player_GetXiuLianMiJiInfo);
        if (IsMissing(table, "HaveTitle")) table.Register("HaveTitle", LAG_Player_HaveTitle);
        if (IsMissing(table, "IsHaveCurrentPet")) table.Register("IsHaveCurrentPet", LAG_Player_IsHaveCurrentPet);
        if (IsMissing(table, "IsHaveItem")) table.Register("IsHaveItem", LAG_Player_IsHaveItem);
        if (IsMissing(table, "IsHavePassword")) table.Register("IsHavePassword", LAG_Player_IsHavePassword);
        if (IsMissing(table, "IsInRaid")) table.Register("IsInRaid", LAG_Player_IsInRaid);
        if (IsMissing(table, "IsInTeam")) table.Register("IsInTeam", LAG_Player_IsInTeam);
        if (IsMissing(table, "IsLeader")) table.Register("IsLeader", LAG_Player_IsLeader);
        if (IsMissing(table, "IsLocked")) table.Register("IsLocked", LAG_Player_IsLocked);
        if (IsMissing(table, "IsOnHorse")) table.Register("IsOnHorse", LAG_Player_IsOnHorse);
        if (IsMissing(table, "IsRaidAssitant")) table.Register("IsRaidAssitant", LAG_Player_IsRaidAssitant);
        if (IsMissing(table, "IsRaidLeader")) table.Register("IsRaidLeader", LAG_Player_IsRaidLeader);
        if (IsMissing(table, "IsVaild")) table.Register("IsVaild", LAG_Player_IsVaild);
        if (IsMissing(table, "KickRaidMemberByIdx")) table.Register("KickRaidMemberByIdx", LAG_Player_KickRaidMemberByIdx);
        if (IsMissing(table, "LeaveRiad")) table.Register("LeaveRiad", LAG_Player_LeaveRiad);
        if (IsMissing(table, "Lua_AskBuyFestivalShopItem")) table.Register("Lua_AskBuyFestivalShopItem", LAG_Player_Lua_AskBuyFestivalShopItem);
        if (IsMissing(table, "Lua_AskSectOper")) table.Register("Lua_AskSectOper", LAG_Player_Lua_AskSectOper);
        if (IsMissing(table, "Lua_CreateSectShare")) table.Register("Lua_CreateSectShare", LAG_Player_Lua_CreateSectShare);
        if (IsMissing(table, "Lua_GetXbwData")) table.Register("Lua_GetXbwData", LAG_Player_Lua_GetXbwData);
        if (IsMissing(table, "OpenCreateRaidConfirmWindow")) table.Register("OpenCreateRaidConfirmWindow", LAG_Player_OpenCreateRaidConfirmWindow);
        if (IsMissing(table, "OpenDismissTeamMsgbox")) table.Register("OpenDismissTeamMsgbox", LAG_Player_OpenDismissTeamMsgbox);
        if (IsMissing(table, "PVP_Challenge")) table.Register("PVP_Challenge", LAG_Player_PVP_Challenge);
        if (IsMissing(table, "PVP_Duel")) table.Register("PVP_Duel", LAG_Player_PVP_Duel);
        if (IsMissing(table, "PVP_ShowMenu")) table.Register("PVP_ShowMenu", LAG_Player_PVP_ShowMenu);
        if (IsMissing(table, "Player_GetTitleType")) table.Register("Player_GetTitleType", LAG_Player_Player_GetTitleType);
        if (IsMissing(table, "RaidAppointByIdx")) table.Register("RaidAppointByIdx", LAG_Player_RaidAppointByIdx);
        if (IsMissing(table, "SaveDenaAttr")) table.Register("SaveDenaAttr", LAG_Player_SaveDenaAttr);
        if (IsMissing(table, "SendAcceptRaidInvitation")) table.Register("SendAcceptRaidInvitation", LAG_Player_SendAcceptRaidInvitation);
        if (IsMissing(table, "SendAgreeRaidApplication")) table.Register("SendAgreeRaidApplication", LAG_Player_SendAgreeRaidApplication);
        if (IsMissing(table, "SendOpposeRaidApplication")) table.Register("SendOpposeRaidApplication", LAG_Player_SendOpposeRaidApplication);
        if (IsMissing(table, "SendRejectRaidInvitation")) table.Register("SendRejectRaidInvitation", LAG_Player_SendRejectRaidInvitation);
        if (IsMissing(table, "SendReliveMessage_Fool")) table.Register("SendReliveMessage_Fool", LAG_Player_SendReliveMessage_Fool);
        if (IsMissing(table, "SendReportMsg")) table.Register("SendReportMsg", LAG_Player_SendReportMsg);
        if (IsMissing(table, "SendSpeakerMessage")) table.Register("SendSpeakerMessage", LAG_Player_SendSpeakerMessage);
        if (IsMissing(table, "SetDIYFramePreview")) table.Register("SetDIYFramePreview", LAG_Player_SetDIYFramePreview);
        if (IsMissing(table, "SetExpAssgin")) table.Register("SetExpAssgin", LAG_Player_SetExpAssgin);
        if (IsMissing(table, "SetHorseModel")) table.Register("SetHorseModel", LAG_Player_SetHorseModel);
        if (IsMissing(table, "SetIPRegion")) table.Register("SetIPRegion", LAG_Player_SetIPRegion);
        if (IsMissing(table, "ShowRaidApplicationList")) table.Register("ShowRaidApplicationList", LAG_Player_ShowRaidApplicationList);
        if (IsMissing(table, "UseItem")) table.Register("UseItem", LAG_Player_UseItem);
        if (IsMissing(table, "UseRose")) table.Register("UseRose", LAG_Player_UseRose);
        if (IsMissing(table, "YuanBaoToBind")) table.Register("YuanBaoToBind", LAG_Player_YuanBaoToBind);
        if (IsMissing(table, "YuanBaoToTicket")) table.Register("YuanBaoToTicket", LAG_Player_YuanBaoToTicket);
        if (IsMissing(table, "calcAllEffectAgname")) table.Register("calcAllEffectAgname", LAG_Player_calcAllEffectAgname);
    }
}
