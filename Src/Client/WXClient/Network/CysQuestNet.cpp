#include "StdAfx.h"
#include "CysPiercingData.h"
#include "CysQuestNet.h"
#include <map>
#include <string>

#if defined(CYS_HAVE_NETCORE)
// CYS-QUEST: NPC dialogue / missions on the CY skynet protocol (Docs/specs/net/npc-quest_vi.md).
// Server behaviour (read-only clone /home/ubuntu/cys-test-20260913): mission.lua GCScriptCommand bos (cmd 0-5),
// script_base.lua DispatchEventList / DispatchMissionInfo / DispatchMissionDemandInfo / DispatchMissionContinueInfo /
// DispatchMissionTips, scenecore.lua char_mission_accept / continue / submit / abandon / check, human.lua add_mission /
// del_mission / set_mission_by_index / set_mission_have_done / send_mission_list.
#include "CysModernGame.h"
#include "CysHost_Quest.h"
#include "..\Script\GMScriptSystem.h"
#include "PgPackets_combat.h"
#include "PgPackets_mission.h"
#include "TDEventDefine.h"
#include "TDUtil.h"
#include "ScriptCommandStruct.h"
#include "DB_Struct.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Item\Obj_Item.h"
#include "..\DataPool\GMUIDataPool.h"
#include "..\DataPool\DetailAttrib_Player.h"
#include "..\DataPool\GMDP_Struct_Quest.h"
#include "..\DataPool\DataPoolCommandDef.h"
#include "..\Event\GMEventSystem.h"
#include "..\GameCommand.h"
#include "CGMissionAccept.h"
#include "CGMissionContinue.h"
#include "CGMissionSubmit.h"
#include "CGMissionAbandon.h"
#include "CGMissionCheck.h"
#include <cstdarg>
#include <cstring>
#include <string>
#include <vector>

// Friend of CUIDataPool / CDetailAttrib_Player (their mission members are protected).
class CysQuestAccess
{
public:
    static CDetailAttrib_Player* Player()
    {
        CUIDataPool* pool = CUIDataPool::GetMe();
        return pool ? const_cast<CDetailAttrib_Player*>(pool->GetMySelfDetailAttrib()) : nullptr;
    }
    static _MISSION_LIST* List() { CDetailAttrib_Player* p = Player(); return p ? &p->m_listMission : nullptr; }
    static std::vector<CUIDataPool::QuestRewardItem>* Rewards() { return CUIDataPool::GetMe() ? &CUIDataPool::GetMe()->m_vecQuestRewardItem : nullptr; }
    static std::vector<CUIDataPool::QuestDemandItem>* Demands() { return CUIDataPool::GetMe() ? &CUIDataPool::GetMe()->m_vecQuestDemandItem : nullptr; }
};

namespace
{
    CysQuestNet::Counters g_counters = {};
    unsigned g_logs = 0;
    bool g_trackOpened = false;
    struct DialogIds { int script = -1, mission = -1; } g_info, g_continue, g_demand;
    std::vector<bool> g_rewardJiaozi;          // parallel to CUIDataPool::m_vecQuestRewardItem (continue dialogue)
    struct Option { int index, type, script; };
    std::vector<Option> g_options;             // last event list (GCScriptCommand 0)

    void QuestLog(const char* fmt, ...)
    {
        if (g_logs++ >= 160) return;
        char text[512] = {};
        va_list args; va_start(args, fmt);
        _vsnprintf(text, sizeof(text) - 1, fmt, args);
        va_end(args);
        TDU_Log("CYS quest: %s", text);
    }

    bool IsMain() { return CGameProcedure::GetActiveProcedure() == (CGameProcedure*)CGameProcedure::s_pProcMain; }

    void PoolCommand(INT command, VOID* buffer)
    {
        SCommand_DPC cmd;
        cmd.m_wID = DPC_SCRIPT_COMMAND;
        cmd.m_anParam[0] = command;
        cmd.m_apParam[1] = buffer;
        ((CUIDataPool*)CGameProcedure::s_pDataPool)->OnCommand_(&cmd);
    }

    // true when NewItem knows the table id (the 0.85 dialogue code dereferences the item object without a check)
    bool KnownItem(UINT id)
    {
        tObject_Item* item = CObject_Item::NewItem(id);
        if (!item) return false;
        CObject_Item::DestroyItem((CObject_Item*)item);
        return true;
    }

    bool ValidUtf8(const std::string& s)
    {
        size_t i = 0, n = s.size();
        while (i < n)
        {
            unsigned char c = (unsigned char)s[i];
            size_t len = c < 0x80 ? 1 : (c >> 5) == 6 ? 2 : (c >> 4) == 14 ? 3 : (c >> 3) == 30 ? 4 : 0;
            if (!len || i + len > n) return false;
            for (size_t k = 1; k < len; ++k) if (((unsigned char)s[i + k] >> 6) != 2) return false;
            i += len;
        }
        return true;
    }

    std::string ToUtf8(const std::string& s)
    {
        if (s.empty() || ValidUtf8(s)) return s;
        const int wide = MultiByteToWideChar(936, 0, s.data(), (int)s.size(), nullptr, 0);
        if (wide <= 0) return s;
        std::wstring w((size_t)wide, L'\0');
        MultiByteToWideChar(936, 0, s.data(), (int)s.size(), &w[0], wide);
        const int bytes = WideCharToMultiByte(CP_UTF8, 0, w.data(), wide, nullptr, 0, nullptr, nullptr);
        std::string out((size_t)bytes, '\0');
        WideCharToMultiByte(CP_UTF8, 0, w.data(), wide, &out[0], bytes, nullptr, nullptr);
        return out;
    }

    void PushTrack(int selectSlot)
    {
        if (!g_trackOpened) { g_trackOpened = true; CEventSystem::GetMe()->PushEvent(GE_OPEN_MISSION_TRACK, 1); }
        CEventSystem::GetMe()->PushEvent(GE_UPDATE_MISSION_TRACK, selectSlot);
    }

    int SlotOf(int missionId)
    {
        _MISSION_LIST* list = CysQuestAccess::List();
        if (!list) return -1;
        for (int i = 0; i < MAX_CHAR_MISSION_NUM; ++i) if (list->m_aMission[i].m_idMission == missionId) return i;
        return -1;
    }

    _OWN_MISSION MakeMission(int id, int script, int flags, const int32_t* params)
    {
        _OWN_MISSION m;
        m.Cleanup();
        m.m_idMission = id; m.m_idScript = script; m.m_yFlags = (BYTE)flags;
        for (int k = 0; k < 8 && k < MAX_MISSION_PARAM_NUM; ++k) m.m_anParam[k] = params[k];
        return m;
    }

    // ------------------------------------------------------------------------------------------------------------
    // GCScriptCommand 1 / 3 / 4 / 5 (cmd 0 = event list stays with CysInventoryNet; only its options are recorded here)
    bool OnScriptCommand(const pg::GCScriptCommand& p)
    {
        switch (p.m_nCmdID)
        {
        case 0:
        case 2:
            g_options.clear();
            for (const auto& e : p.event) if (e.flag == 1) g_options.push_back(Option{e.index, e.type, e.script_id});
            return false; // CysInventoryNet::OnScriptCommand builds the 0.85 event list (QUEST_EVENTLIST)
        case 1:
        {
            ++g_counters.missionInfos;
            static ScriptParam_MissionInfo info;
            info.Reset();
            info.m_idNPC = (ObjID_t)p.target_id_2; info.m_idScript = p.m_objID; info.m_idMission = p.m_idMission;
            for (const auto& e : p.event_2) { ScriptString t; t = e.str.c_str(); info.AddText(&t); }
            for (const auto& b : p.m_aBonus)
            {
                SMissionBonus bonus; bonus.Reset();
                if (b.type == 0 || b.type == 1) bonus.SetMoney(b.item_index);
                else if (KnownItem(b.item_index)) { if (b.type == 4) bonus.SetItemRadio(b.item_index, b.count); else bonus.SetItem(b.item_index, b.count); }
                else continue;
                info.AddBonus(&bonus);
            }
            g_info.script = p.m_objID; g_info.mission = p.m_idMission;
            QuestLog("GCScriptCommand 1 mission info npc=%u script=%d mission=%d texts=%u bonus=%u", p.target_id_2, p.m_objID, p.m_idMission, (unsigned)info.m_yTextCount, (unsigned)info.m_yBonusCount);
            if (IsMain()) PoolCommand(SCRIPT_COMMAND_MISSION_RESPONSE, &info);
            return true;
        }
        case 3:
        {
            ++g_counters.missionDemands;
            static ScriptParam_MissionDemandInfo demand;
            demand.Reset();
            demand.m_idNPC = (ObjID_t)p.target_id_2; demand.m_idScript = (ScriptID_t)p.m_objID_2; demand.m_idMission = (MissionID_t)p.m_idMission_2;
            demand.m_bDone = p.done == 1 ? ScriptParam_MissionDemandInfo::MISSION_DONE : p.done == 2 ? ScriptParam_MissionDemandInfo::MISSION_CHECK : ScriptParam_MissionDemandInfo::MISSION_NODONE;
            for (const auto& e : p.event_3) { ScriptString t; t = e.str.c_str(); demand.AddText(&t); }
            for (const auto& d : p.m_aDemandItem)
            {
                if (!KnownItem((UINT)d.itemid)) continue;
                SMissionDemandItem item; item.m_yCount = d.count; item.m_uItemID = (UINT)d.itemid;
                demand.AddDemandItem(&item);
            }
            g_demand.script = (int)p.m_objID_2; g_demand.mission = (int)p.m_idMission_2;
            QuestLog("GCScriptCommand 3 demand npc=%u script=%u mission=%u done=%u texts=%u items=%u", p.target_id_2, p.m_objID_2, p.m_idMission_2, p.done, (unsigned)demand.m_yTextCount, (unsigned)demand.m_yDemandCount);
            if (IsMain()) PoolCommand(SCRIPT_COMMAND_MISSION_DEMAND_RESPONSE, &demand);
            return true;
        }
        case 4:
        {
            ++g_counters.missionContinues;
            static ScriptParam_MissionContinueInfo cont;
            cont.Reset();
            cont.m_idNPC = (ObjID_t)p.target_id; cont.m_idScript = p.m_objID; cont.m_idMission = p.m_idMission;
            for (const auto& e : p.event_4) { ScriptString t; t = e.str.c_str(); cont.AddText(&t); }
            g_rewardJiaozi.clear();
            // script_base.lua: AddMoneyJZBonus flag 0, AddMoneyBonus 1, AddItemBonus / AddRadioItemBonus 4 (count), rand 5
            for (const auto& b : p.items)
            {
                SMissionBonus bonus; bonus.Reset();
                if (b.flag == 0 || b.flag == 1) bonus.SetMoney((UINT)b.item_index);
                else if (!KnownItem((UINT)b.item_index)) continue;
                else if (b.flag == 4) bonus.SetItemRadio((UINT)b.item_index, b.count);
                else if (b.flag == 2) bonus.SetItem((UINT)b.item_index, b.count);
                else { bonus.SetItem((UINT)b.item_index, b.count); bonus.m_nType = MISSION_BONUS_TYPE_ITEM_RAND; }
                if (cont.m_yBonusCount >= MAX_MISSION_DEMAND_COUNT) break;
                cont.AddBonus(&bonus);
                g_rewardJiaozi.push_back(b.flag == 0);
            }
            g_continue.script = p.m_objID; g_continue.mission = p.m_idMission;
            QuestLog("GCScriptCommand 4 continue npc=%d script=%d mission=%d texts=%u bonus=%u", p.target_id, p.m_objID, p.m_idMission, (unsigned)cont.m_yTextCount, (unsigned)cont.m_yBonusCount);
            if (IsMain()) PoolCommand(SCRIPT_COMMAND_MISSION_CONTINUE_RESPONSE, &cont);
            return true;
        }
        case 5:
        {
            ++g_counters.missionTips;
            static ScriptParam_MissionTips tips;
            tips.Reset();
            tips.m_strText = p.event_str.c_str();
            QuestLog("GCScriptCommand 5 tips bytes=%u", (unsigned)p.event_str.size());
            if (IsMain()) PoolCommand(SCRIPT_COMMAND_MISSION_TIPS, &tips);
            return true;
        }
        default:
            return false;
        }
    }

    // ------------------------------------------------------------------------------------------------------------
    // Own mission list (human.lua send_mission_list / on_add_mission / set_mission_by_index / del_mission)
    CysPiercingData::Snapshot piercing;
    void OnMissionList(const pg::GCMissionList& p)
    {
        ++g_counters.missionLists;
        for(unsigned id=602;id<=603;++id)
            if(id<p.mission_datas.size()) piercing.Apply(id,p.mission_datas[id]);
        if(IsMain()) CEventSystem::GetMe()->PushEventByName("CYS_PIERCING_UPDATE",{});
        _MISSION_LIST* list = CysQuestAccess::List();
        if (!list) return;
        list->m_Count = 0;
        for (int i = 0; i < MAX_CHAR_MISSION_NUM; ++i)
        {
            list->m_aMission[i].Cleanup();
            if (i >= (int)p.char_missions.size() || !(p.m_uMissionListFlags & (1u << i))) continue;
            const auto& m = p.char_missions[i];
            list->m_aMission[i] = MakeMission(m.id, m.index, m.yFlag, m.params.data());
            ++list->m_Count;
        }
        const size_t flags = (std::min)((size_t)MAX_CHAR_MISSION_FLAG_LEN, p.mission_have_done_flags.size());
        for (size_t i = 0; i < flags; ++i) list->m_aMissionHaveDoneFlags[i] = p.mission_have_done_flags[i];
        const size_t datas = (std::min)((size_t)MAX_CHAR_MISSION_DATA_NUM, p.mission_datas.size());
        for (size_t i = 0; i < datas; ++i) list->m_aMissionData[i] = (INT)p.mission_datas[i];
        QuestLog("GCMissionList missions=%u flags=0x%x", (unsigned)list->m_Count, p.m_uMissionListFlags);
        if (!IsMain()) return;
        CEventSystem::GetMe()->PushEvent(GE_UPDATE_MISSION);
        PushTrack(-1);
    }

    void OnMissionAdd(const pg::GCMissionAdd& p)
    {
        ++g_counters.missionAdds;
        CDetailAttrib_Player* player = CysQuestAccess::Player();
        if (!player) return;
        const _OWN_MISSION m = MakeMission(p.id, p.index, (unsigned char)p.yFlag, p.params.data());
        player->AddMission(&m);
        const int slot = SlotOf(p.id);
        QuestLog("GCMissionAdd mission=%d script=%d slot=%d p0=%d", p.id, p.index, slot, p.params[0]);
        if (!IsMain()) return;
        CEventSystem::GetMe()->PushEvent(GE_NEW_MISSION, slot);
        CEventSystem::GetMe()->PushEvent(GE_UPDATE_MISSION);
        PushTrack(slot);
    }

    void OnMissionModify(const pg::GCMissionModify& p)
    {
        ++g_counters.missionModifies;
        CDetailAttrib_Player* player = CysQuestAccess::Player();
        if (!player) return;
        if (p.m_nFlag == 1)
        {
            if(piercing.Apply(p.mission_id,p.mission_index)) {
                TDU_Log("CYS-PIERCING: MD%u=%u",p.mission_id,p.mission_index);
                if(IsMain()) CEventSystem::GetMe()->PushEventByName("CYS_PIERCING_UPDATE",{});
            }
            // mission data (human.lua MissionData sync): index u16, value u32
            if (p.mission_id < MAX_CHAR_MISSION_DATA_NUM) player->SetMissionData(p.mission_id, (INT)p.mission_index);
            return;
        }
        const _OWN_MISSION m = MakeMission(p.m_aMissionData_id, p.m_aMissionData_index, (unsigned char)p.m_aMissionData_yFlag, p.m_aMissionData_params.data());
        player->ModifyMission(&m);
        QuestLog("GCMissionModify mission=%d script=%d p0=%d p1=%d", p.m_aMissionData_id, p.m_aMissionData_index, p.m_aMissionData_params[0], p.m_aMissionData_params[1]);
        if (IsMain()) PushTrack(SlotOf(p.m_aMissionData_id));
    }

    void OnMissionRemove(const pg::GCMissionRemove& p)
    {
        ++g_counters.missionRemoves;
        CDetailAttrib_Player* player = CysQuestAccess::Player();
        if (!player) return;
        player->RemoveMission(p.id);
        QuestLog("GCMissionRemove mission=%d", p.id);
        if (!IsMain()) return;
        CEventSystem::GetMe()->PushEvent(GE_UPDATE_MISSION);
        PushTrack(-1);
    }

    void OnMissionDoneFlag(const pg::GCMissionHaveDoneFlag& p)
    {
        ++g_counters.doneFlags;
        _MISSION_LIST* list = CysQuestAccess::List();
        if (!list || p.mission_id < 0 || (p.mission_id >> 5) >= MAX_CHAR_MISSION_FLAG_LEN) return;
        const UINT bit = 1u << (p.mission_id & 31);
        if (p.flag) list->m_aMissionHaveDoneFlags[p.mission_id >> 5] |= bit;
        else list->m_aMissionHaveDoneFlags[p.mission_id >> 5] &= ~bit;
        QuestLog("GCMissionHaveDoneFlag mission=%d flag=%d", p.mission_id, p.flag);
    }
}

namespace
{
    // ------------------------------------------------------------------------------------------------------------
    // Host services (CysHost_Quest)
    int HostDialog(void*, int which)
    {
        switch (which)
        {
        case CysHostQuest::InfoScript: return g_info.script;
        case CysHostQuest::InfoMission: return g_info.mission;
        case CysHostQuest::ContinueScript: return g_continue.script;
        case CysHostQuest::ContinueMission: return g_continue.mission;
        case CysHostQuest::DemandScript: return g_demand.script;
        case CysHostQuest::DemandMission: return g_demand.mission;
        default: return -1;
        }
    }

    int HostQuestItem(void*, int index, int demand)
    {
        if (demand)
        {
            std::vector<CUIDataPool::QuestDemandItem>* items = CysQuestAccess::Demands();
            if (!items || index < 0 || index >= (int)items->size() || !(*items)[index].pItemImpl) return -1;
            return (*items)[index].pItemImpl->GetID();
        }
        std::vector<CUIDataPool::QuestRewardItem>* items = CysQuestAccess::Rewards();
        if (!items || index < 0 || index >= (int)items->size() || !(*items)[index].pItemImpl) return -1;
        return (*items)[index].pItemImpl->GetID();
    }

    int HostContinueItem(void*, int index)
    {
        std::vector<CUIDataPool::QuestRewardItem>* items = CysQuestAccess::Rewards();
        if (!items || index < 0 || index >= (int)items->size() || !(*items)[index].pItemData) return -1;
        const SMissionBonus* b = (*items)[index].pItemData;
        return b->m_nType == MISSION_BONUS_TYPE_MONEY || b->m_nType == MISSION_BONUS_TYPE_EXP ? -1 : (int)b->m_ItemBonus.m_uItemID;
    }

    bool HostReward(void*, int index, int* type, int* object, int* count)
    {
        std::vector<CUIDataPool::QuestRewardItem>* items = CysQuestAccess::Rewards();
        if (!items || index < 0 || index >= (int)items->size() || !(*items)[index].pItemData) return false;
        const CUIDataPool::QuestRewardItem& r = (*items)[index];
        *object = r.pItemImpl ? r.pItemImpl->GetID() : 0;
        switch (r.pItemData->m_nType)
        {
        case MISSION_BONUS_TYPE_MONEY:
            *type = (index < (int)g_rewardJiaozi.size() && g_rewardJiaozi[index]) ? 1 : 0; *object = 0; *count = (int)r.pItemData->m_uMoney; return true;
        case MISSION_BONUS_TYPE_ITEM: *type = 2; *count = r.pItemData->m_ItemBonus.m_yCount; return true;
        case MISSION_BONUS_TYPE_ITEM_RAND: *type = 3; *count = r.pItemData->m_ItemBonus.m_yCount; return true;
        case MISSION_BONUS_TYPE_ITEM_RADIO: *type = 4; *count = r.pItemData->m_ItemBonus.m_yCount; return true;
        case MISSION_BONUS_TYPE_EXP: *type = 5; *object = 0; *count = (int)r.pItemData->m_uExp; return true;
        default: return false;
        }
    }

    int HostSlotScript(void*, int slot) { return CysQuestNet::SlotScript(slot); }

    int HostSlotDisplay(void*, int slot, int what)
    {
        const int script = CysQuestNet::SlotScript(slot);
        if (script < 0) return what == CysHostQuest::Round ? -1 : 0;
        const _MISSION_INFO& info = GetMissionInfo((UINT)script);
        switch (what)
        {
        case CysHostQuest::OkFail: return info.m_nOKFail > 0 ? info.m_nOKFail : 0;
        case CysHostQuest::LimitTime: return info.m_nLimitTime > 0 ? info.m_nLimitTime : 0;
        case CysHostQuest::Round: return info.m_nRound > 0 ? info.m_nRound : -1;
        case CysHostQuest::Bill: return info.m_nBill > 0 ? info.m_nBill : 0;
        default: return 0;
        }
    }
}

bool CysQuestNet::FindOption(int script, int type, int& outScript, int& outIndex)
{
    for (const Option& o : g_options)
    {
        if (script >= 0 && o.script != script) continue;
        if (type >= 0 && o.type != type) continue;
        outScript = o.script; outIndex = o.index;
        return true;
    }
    return false;
}

bool CysQuestNet::FindOptionByIndex(int index, int& outScript)
{
    for (const Option& o : g_options) if (o.index == index) { outScript = o.script; return true; }
    return false;
}

int CysQuestNet::SlotMission(int slot)
{
    _MISSION_LIST* list = CysQuestAccess::List();
    if (!list || slot < 0 || slot >= MAX_CHAR_MISSION_NUM) return -1;
    return list->m_aMission[slot].m_idMission == INVALID_ID ? -1 : list->m_aMission[slot].m_idMission;
}

int CysQuestNet::SlotScript(int slot)
{
    _MISSION_LIST* list = CysQuestAccess::List();
    if (!list || slot < 0 || slot >= MAX_CHAR_MISSION_NUM || list->m_aMission[slot].m_idMission == INVALID_ID) return -1;
    return list->m_aMission[slot].m_idScript;
}

bool CysQuestNet::MissionDone(int missionId)
{
    _MISSION_LIST* list = CysQuestAccess::List();
    if (!list || missionId < 0 || (missionId >> 5) >= MAX_CHAR_MISSION_FLAG_LEN) return false;
    return (list->m_aMissionHaveDoneFlags[missionId >> 5] & (1u << (missionId & 31))) != 0;
}

void CysQuestNet::LocalizeMission(int scriptId, _MISSION_INFO& info)
{
    const CysQuestText* text = CysHostQuest::FindText(scriptId);
    info.m_misName = text && text->name && *text->name ? std::string(text->name) : ToUtf8(info.m_misName);
    info.m_misDesc = ToUtf8(info.m_misDesc);
    info.m_misState = ToUtf8(info.m_misState);
    info.m_misBillName = ToUtf8(info.m_misBillName);
    for (auto& custom : info.m_vecQuestCustom)
    {
        const std::string utf8 = ToUtf8(custom.szCustomString);
        const char* vi = CysHostQuest::CustomVi(utf8.c_str());
        custom.szCustomString = vi ? vi : utf8;
    }
    for (auto& kill : info.m_vecQuestDemandKill) kill.szNPCName = ToUtf8(kill.szNPCName);
}

bool CysQuestNet::Piercing(bool defence,uint32_t& value) { return piercing.Query(defence,value); }

void CysQuestNet::RegisterHost()
{
    piercing.Clear();
    CScriptSystem* scripts = CScriptSystem::GetMe();
    if (!scripts || !scripts->GetLuaState()) return;
    CysHostQuest::Services services;
    services.dialogValue = HostDialog;
    services.questItemObject = HostQuestItem;
    services.continueItemId = HostContinueItem;
    services.reward = HostReward;
    services.slotScript = HostSlotScript;
    services.slotDisplay = HostSlotDisplay;
    const int n = CysHostQuest::Register(scripts->GetLuaState(), services);
    QuestLog("host functions registered=%d (Quest / MissionTrack / QuestLog)", n);
}

std::unique_ptr<pg::Packet> CysQuestNet::Translate(Packet* legacy)
{
    switch (legacy->GetPacketID())
    {
    case PACKET_CG_MISSIONACCEPT:
    {
        CGMissionAccept* in = static_cast<CGMissionAccept*>(legacy);
        std::unique_ptr<pg::CGMissionAccept> out(new pg::CGMissionAccept);
        out->m_idNPC = in->getNPCID(); out->unknow = -1; out->m_idScript = in->getScriptID();
        ++g_counters.accepts;
        QuestLog("CGMissionAccept npc=%d script=%d", out->m_idNPC, out->m_idScript);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_MISSIONCONTINUE:
    {
        CGMissionContinue* in = static_cast<CGMissionContinue*>(legacy);
        std::unique_ptr<pg::CGMissionContinue> out(new pg::CGMissionContinue);
        out->m_idNPC = in->getNPCID(); out->unknow = -1; out->m_idScript = in->getScriptID();
        ++g_counters.continues;
        QuestLog("CGMissionContinue npc=%d script=%d", out->m_idNPC, out->m_idScript);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_MISSIONSUBMIT:
    {
        CGMissionSubmit* in = static_cast<CGMissionSubmit*>(legacy);
        std::unique_ptr<pg::CGMissionSubmit> out(new pg::CGMissionSubmit);
        out->npc_id = in->getNPCID(); out->script_id = in->getScriptID();
        // OnSubmit compares selectRadioId with the item id of the radio reward (edali_zhidao_0200.lua); UINT_MAX = none
        out->select_radio_id = in->getSelectRadioID() == UINT_MAX ? 0 : (int32_t)in->getSelectRadioID();
        out->unknow_4 = 0;
        ++g_counters.submits;
        QuestLog("CGMissionSubmit npc=%d script=%d radio=%d", out->npc_id, out->script_id, out->select_radio_id);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_MISSIONABANDON:
    {
        std::unique_ptr<pg::CGMissionAbandon> out(new pg::CGMissionAbandon);
        out->index = static_cast<CGMissionAbandon*>(legacy)->getScriptID();
        ++g_counters.abandons;
        QuestLog("CGMissionAbandon script=%d", out->index);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_MISSIONCHECK:
    {
        CGMissionCheck* in = static_cast<CGMissionCheck*>(legacy);
        std::unique_ptr<pg::CGMissionCheck> out(new pg::CGMissionCheck);
        out->m_idNPC = in->getNPCID(); out->unknow_2 = -1; out->m_idScript = in->getScriptID();
        const BYTE* list = in->getItemIndexList();
        for (int i = 0; i < 3; ++i) out->m_ItemIndexList[i] = (int8_t)list[i];
        out->pet_index = in->getPetIndex(); out->unknow_5 = 0; out->unknow_6 = 0;
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_MISSIONREFUSE: // the CY server has no refuse request (OnMissionRefuse only re-lists): not sent
    case PACKET_CG_MISSIONDESC:   // the CY client reads the descriptor from ConfigFolder, the server has no description
    default:
        return nullptr;
    }
}

bool CysQuestNet::IsWorldPacket(uint16_t id)
{
    switch (id)
    {
    case pg::GCMissionList::PACKET_ID: case pg::GCMissionAdd::PACKET_ID: case pg::GCMissionModify::PACKET_ID:
    case pg::GCMissionRemove::PACKET_ID: case pg::GCMissionHaveDoneFlag::PACKET_ID: case pg::GCScriptCommand::PACKET_ID:
        return true;
    default:
        return false;
    }
}

bool CysQuestNet::Dispatch(const pg::Packet& packet)
{
    switch (packet.packetId())
    {
    case pg::GCScriptCommand::PACKET_ID: return OnScriptCommand(static_cast<const pg::GCScriptCommand&>(packet));
    case pg::GCMissionList::PACKET_ID: OnMissionList(static_cast<const pg::GCMissionList&>(packet)); return true;
    case pg::GCMissionAdd::PACKET_ID: OnMissionAdd(static_cast<const pg::GCMissionAdd&>(packet)); return true;
    case pg::GCMissionModify::PACKET_ID: OnMissionModify(static_cast<const pg::GCMissionModify&>(packet)); return true;
    case pg::GCMissionRemove::PACKET_ID: OnMissionRemove(static_cast<const pg::GCMissionRemove&>(packet)); return true;
    case pg::GCMissionHaveDoneFlag::PACKET_ID: OnMissionDoneFlag(static_cast<const pg::GCMissionHaveDoneFlag&>(packet)); return true;
    default: return false;
    }
}

CysQuestNet::Counters CysQuestNet::Get() { return g_counters; }

#else // !CYS_HAVE_NETCORE

std::unique_ptr<pg::Packet> CysQuestNet::Translate(Packet*) { return nullptr; }
bool CysQuestNet::IsWorldPacket(uint16_t) { return false; }
bool CysQuestNet::Dispatch(const pg::Packet&) { return false; }
bool CysQuestNet::Piercing(bool,uint32_t&) { return false; }
void CysQuestNet::RegisterHost() {}
CysQuestNet::Counters CysQuestNet::Get() { Counters c = {}; return c; }
int CysQuestNet::SlotMission(int) { return -1; }
int CysQuestNet::SlotScript(int) { return -1; }
bool CysQuestNet::MissionDone(int) { return false; }
bool CysQuestNet::FindOption(int, int, int&, int&) { return false; }
bool CysQuestNet::FindOptionByIndex(int, int&) { return false; }
void CysQuestNet::LocalizeMission(int, _MISSION_INFO&) {}

#endif

// CYS-QUEST: joined event-list texts (independent of CYS_HAVE_NETCORE).
namespace
{
    std::map<int, std::string>& EventTexts() { static std::map<int, std::string> texts; return texts; }
}
void CysQuestNet::ClearEventListTexts() { EventTexts().clear(); }
void CysQuestNet::SetEventListText(int index, const char* text) { if (text) EventTexts()[index] = text; }
const char* CysQuestNet::EventListText(int index)
{
    const std::map<int, std::string>::const_iterator it = EventTexts().find(index);
    return it == EventTexts().end() ? nullptr : it->second.c_str();
}
