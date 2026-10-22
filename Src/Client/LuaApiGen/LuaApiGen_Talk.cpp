




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_Talk_CanDoDoubleAction(LuaPlus::LuaState* state) { return Stub(state, "Talk", "CanDoDoubleAction", ""); }


        int LAG_Talk_CanDoDoubleAction_Bar(LuaPlus::LuaState* state) { return Stub(state, "Talk", "CanDoDoubleAction_Bar", ""); }

        int LAG_Talk_ClearFenpingHisQue(LuaPlus::LuaState* state) { return Stub(state, "Talk", "ClearFenpingHisQue", ""); }

        int LAG_Talk_CloseFenping(LuaPlus::LuaState* state) { return Stub(state, "Talk", "CloseFenping", ""); }

        int LAG_Talk_ConfigFenping(LuaPlus::LuaState* state) { return Stub(state, "Talk", "ConfigFenping", ""); }

        int LAG_Talk_CreateFenping(LuaPlus::LuaState* state) { return Stub(state, "Talk", "CreateFenping", ""); }


        int LAG_Talk_DisclosureToGM(LuaPlus::LuaState* state) { return Stub(state, "Talk", "DisclosureToGM", ""); }

        int LAG_Talk_DoDoubleActionByIndex(LuaPlus::LuaState* state) { return Stub(state, "Talk", "DoDoubleActionByIndex", ""); }

        int LAG_Talk_EnumDoubleChatMood(LuaPlus::LuaState* state) { return Stub(state, "Talk", "EnumDoubleChatMood", "o"); }

        int LAG_Talk_EnumEquipChatMoodId(LuaPlus::LuaState* state) { return Stub(state, "Talk", "EnumEquipChatMoodId", "n"); }

        int LAG_Talk_EnumEquipChatMoodSort(LuaPlus::LuaState* state) { return Stub(state, "Talk", "EnumEquipChatMoodSort", "n"); }

        int LAG_Talk_EnumEquipDoubleMood(LuaPlus::LuaState* state) { return Stub(state, "Talk", "EnumEquipDoubleMood", "o"); }

        int LAG_Talk_EnumEquipSingleMood(LuaPlus::LuaState* state) { return Stub(state, "Talk", "EnumEquipSingleMood", "o"); }

        int LAG_Talk_GetCurTab(LuaPlus::LuaState* state) { return Stub(state, "Talk", "GetCurTab", "n"); }

        int LAG_Talk_GetHyperLinkString(LuaPlus::LuaState* state) { return Stub(state, "Talk", "GetHyperLinkString", "s"); }

        int LAG_Talk_GetNpcTalk(LuaPlus::LuaState* state) { return Stub(state, "Talk", "GetNpcTalk", "sssnnn"); }

        int LAG_Talk_HandleHistoryAction(LuaPlus::LuaState* state) { return Stub(state, "Talk", "HandleHistoryAction", ""); }

        int LAG_Talk_HandleMainBarAction(LuaPlus::LuaState* state) { return Stub(state, "Talk", "HandleMainBarAction", ""); }

        int LAG_Talk_HideContexMenu4Speaker(LuaPlus::LuaState* state) { return Stub(state, "Talk", "HideContexMenu4Speaker", ""); }

        int LAG_Talk_IsValidChatActionByIndex(LuaPlus::LuaState* state) { return Stub(state, "Talk", "IsValidChatActionByIndex", "n"); }


        int LAG_Talk_IsValidChatActionString(LuaPlus::LuaState* state) { return Stub(state, "Talk", "IsValidChatActionString", "n"); }

        int LAG_Talk_IsValidSingleChatActionByIndex(LuaPlus::LuaState* state) { return Stub(state, "Talk", "IsValidSingleChatActionByIndex", "n"); }

        int LAG_Talk_MoveTabHisQue(LuaPlus::LuaState* state) { return Stub(state, "Talk", "MoveTabHisQue", ""); }

        int LAG_Talk_OpenFenpingConfigDlg(LuaPlus::LuaState* state) { return Stub(state, "Talk", "OpenFenpingConfigDlg", ""); }

        int LAG_Talk_OpenFenpingConfigDlgChatFrame(LuaPlus::LuaState* state) { return Stub(state, "Talk", "OpenFenpingConfigDlgChatFrame", ""); }

        int LAG_Talk_OpenSpeakerDlg(LuaPlus::LuaState* state) { return Stub(state, "Talk", "OpenSpeakerDlg", ""); }

        int LAG_Talk_SaveChatHistory(LuaPlus::LuaState* state) { return Stub(state, "Talk", "SaveChatHistory", ""); }


        int LAG_Talk_SendImMessage(LuaPlus::LuaState* state) { return Stub(state, "Talk", "SendImMessage", ""); }

        int LAG_Talk_SetCurTab(LuaPlus::LuaState* state) { return Stub(state, "Talk", "SetCurTab", ""); }

        int LAG_Talk_SetDisappearTime(LuaPlus::LuaState* state) { return Stub(state, "Talk", "SetDisappearTime", ""); }

        int LAG_Talk_SetEditboxActive(LuaPlus::LuaState* state) { return Stub(state, "Talk", "SetEditboxActive", ""); }

        int LAG_Talk_SetNpcTalkTime(LuaPlus::LuaState* state) { return Stub(state, "Talk", "SetNpcTalkTime", "o"); }

        int LAG_Talk_SetTabCfg(LuaPlus::LuaState* state) { return Stub(state, "Talk", "SetTabCfg", ""); }

        int LAG_Talk_ShowContexMenu4SecretSpeaker(LuaPlus::LuaState* state) { return Stub(state, "Talk", "ShowContexMenu4SecretSpeaker", ""); }

        int LAG_Talk_ShowContexMenu4Speaker(LuaPlus::LuaState* state) { return Stub(state, "Talk", "ShowContexMenu4Speaker", ""); }

        int LAG_Talk_ShowContexMenuFromTeamBoard(LuaPlus::LuaState* state) { return Stub(state, "Talk", "ShowContexMenuFromTeamBoard", ""); }
    }

    void Register_Talk(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "CanDoDoubleAction")) table.Register("CanDoDoubleAction", LAG_Talk_CanDoDoubleAction);
        if (IsMissing(table, "CanDoDoubleAction_Bar")) table.Register("CanDoDoubleAction_Bar", LAG_Talk_CanDoDoubleAction_Bar);
        if (IsMissing(table, "ClearFenpingHisQue")) table.Register("ClearFenpingHisQue", LAG_Talk_ClearFenpingHisQue);
        if (IsMissing(table, "CloseFenping")) table.Register("CloseFenping", LAG_Talk_CloseFenping);
        if (IsMissing(table, "ConfigFenping")) table.Register("ConfigFenping", LAG_Talk_ConfigFenping);
        if (IsMissing(table, "CreateFenping")) table.Register("CreateFenping", LAG_Talk_CreateFenping);
        if (IsMissing(table, "DisclosureToGM")) table.Register("DisclosureToGM", LAG_Talk_DisclosureToGM);
        if (IsMissing(table, "DoDoubleActionByIndex")) table.Register("DoDoubleActionByIndex", LAG_Talk_DoDoubleActionByIndex);
        if (IsMissing(table, "EnumDoubleChatMood")) table.Register("EnumDoubleChatMood", LAG_Talk_EnumDoubleChatMood);
        if (IsMissing(table, "EnumEquipChatMoodId")) table.Register("EnumEquipChatMoodId", LAG_Talk_EnumEquipChatMoodId);
        if (IsMissing(table, "EnumEquipChatMoodSort")) table.Register("EnumEquipChatMoodSort", LAG_Talk_EnumEquipChatMoodSort);
        if (IsMissing(table, "EnumEquipDoubleMood")) table.Register("EnumEquipDoubleMood", LAG_Talk_EnumEquipDoubleMood);
        if (IsMissing(table, "EnumEquipSingleMood")) table.Register("EnumEquipSingleMood", LAG_Talk_EnumEquipSingleMood);
        if (IsMissing(table, "GetCurTab")) table.Register("GetCurTab", LAG_Talk_GetCurTab);
        if (IsMissing(table, "GetHyperLinkString")) table.Register("GetHyperLinkString", LAG_Talk_GetHyperLinkString);
        if (IsMissing(table, "GetNpcTalk")) table.Register("GetNpcTalk", LAG_Talk_GetNpcTalk);
        if (IsMissing(table, "HandleHistoryAction")) table.Register("HandleHistoryAction", LAG_Talk_HandleHistoryAction);
        if (IsMissing(table, "HandleMainBarAction")) table.Register("HandleMainBarAction", LAG_Talk_HandleMainBarAction);
        if (IsMissing(table, "HideContexMenu4Speaker")) table.Register("HideContexMenu4Speaker", LAG_Talk_HideContexMenu4Speaker);
        if (IsMissing(table, "IsValidChatActionByIndex")) table.Register("IsValidChatActionByIndex", LAG_Talk_IsValidChatActionByIndex);
        if (IsMissing(table, "IsValidChatActionString")) table.Register("IsValidChatActionString", LAG_Talk_IsValidChatActionString);
        if (IsMissing(table, "IsValidSingleChatActionByIndex")) table.Register("IsValidSingleChatActionByIndex", LAG_Talk_IsValidSingleChatActionByIndex);
        if (IsMissing(table, "MoveTabHisQue")) table.Register("MoveTabHisQue", LAG_Talk_MoveTabHisQue);
        if (IsMissing(table, "OpenFenpingConfigDlg")) table.Register("OpenFenpingConfigDlg", LAG_Talk_OpenFenpingConfigDlg);
        if (IsMissing(table, "OpenFenpingConfigDlgChatFrame")) table.Register("OpenFenpingConfigDlgChatFrame", LAG_Talk_OpenFenpingConfigDlgChatFrame);
        if (IsMissing(table, "OpenSpeakerDlg")) table.Register("OpenSpeakerDlg", LAG_Talk_OpenSpeakerDlg);
        if (IsMissing(table, "SaveChatHistory")) table.Register("SaveChatHistory", LAG_Talk_SaveChatHistory);
        if (IsMissing(table, "SendImMessage")) table.Register("SendImMessage", LAG_Talk_SendImMessage);
        if (IsMissing(table, "SetCurTab")) table.Register("SetCurTab", LAG_Talk_SetCurTab);
        if (IsMissing(table, "SetDisappearTime")) table.Register("SetDisappearTime", LAG_Talk_SetDisappearTime);
        if (IsMissing(table, "SetEditboxActive")) table.Register("SetEditboxActive", LAG_Talk_SetEditboxActive);
        if (IsMissing(table, "SetNpcTalkTime")) table.Register("SetNpcTalkTime", LAG_Talk_SetNpcTalkTime);
        if (IsMissing(table, "SetTabCfg")) table.Register("SetTabCfg", LAG_Talk_SetTabCfg);
        if (IsMissing(table, "ShowContexMenu4SecretSpeaker")) table.Register("ShowContexMenu4SecretSpeaker", LAG_Talk_ShowContexMenu4SecretSpeaker);
        if (IsMissing(table, "ShowContexMenu4Speaker")) table.Register("ShowContexMenu4Speaker", LAG_Talk_ShowContexMenu4Speaker);
        if (IsMissing(table, "ShowContexMenuFromTeamBoard")) table.Register("ShowContexMenuFromTeamBoard", LAG_Talk_ShowContexMenuFromTeamBoard);
    }
}
