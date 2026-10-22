#include "StdAfx.h"
#include "CysSkillNet.h"

#if defined(CYS_HAVE_NETCORE)
// CYS-SKILL: skills, xinfa, quick bar and cooldowns on the CY skynet protocol (Docs/specs/net/skills-ui_vi.md).
// Server behaviour (read-only clone /home/ubuntu/cys-test-20260913): msgagent.lua CGAskStudyXinfa / CGModifySetting,
// scenecore.lua ask_detail_skill_list / ask_detail_xinfa_list / char_study_xinfa / char_modify_setting / char_use_skill,
// human.lua get_skill_level / send_setting / set_cool_down, script_base.lua DispatchXinfaLevelInfo / LuaFnJoinMenpai.
#include "CysModernGame.h"
#include "CysHost_Skill.h"
#include "..\Script\GMScriptSystem.h"
#include "..\DBC\GMDataBase.h"
#include "TDDBC_Struct.h"
#include "GameStruct_Skill.h"
#include "PgPackets_misc.h"
#include "TDEventDefine.h"
#include "TDUISystem.h"
#include "TDUtil.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\DataPool\GMDataPool.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\Action\GMActionSystem.h"
#include "../Action/CysQuickbarContract.h"
#include "../Procedure/CysAccelTable.h"
#include "..\Event\GMEventSystem.h"
#include "CGModifySetting.h"
#include "CGAskDetailXinFaList.h"
#include "CGAskStudyXinfa.h"
#include "CGReqLevelUp.h"
#include "GCRetSetting.h"
#include <cstdarg>
#include <cstring>
#include <map>
#include <algorithm>
#include <string>
#include "CysBattleAssist.inl"
#include "CysLifeAbility.inl"

namespace
{
    int OpenFormation(LuaPlus::LuaState*) {
        if(CysModernGame::IsInWorld())CEventSystem::GetMe()->PushEventByName("OPEN_ZHENFAFREAM",{});
        return 0;
    }
    int SetMenuBarPageNumber(LuaPlus::LuaState* state)
    {
        LuaPlus::LuaStack args(state);
        if (args[1].IsNumber()) CysAccel::SetMenuBarPage(args[1].GetInteger());
        return 0;
    }
    CysSkillNet::Counters g_counters = {};
    std::vector<uint32_t> g_templates;            // last GCDetailSkillList (+ GCAddSkill)
    bool g_haveSkills = false;
    std::map<int, int> g_xinfa;                    // xinfa id -> level (GCDetailXinFaList / GCStudyXinfa)
    std::vector<std::pair<uint8_t, uint32_t> > g_settings; // GCRetSetting as received (index = SETTING_TYPE)
    bool g_xinfaAsked = false;
    unsigned g_logs = 0;

    bool IsMain() { return CGameProcedure::GetActiveProcedure() == (CGameProcedure*)CGameProcedure::s_pProcMain; }

    void SkillLog(const char* fmt, ...)
    {
        if (g_logs++ >= 96) return;
        char text[512] = {};
        va_list args; va_start(args, fmt);
        _vsnprintf(text, sizeof(text) - 1, fmt, args);
        va_end(args);
        TDU_Log("CYS skill: %s", text);
    }

    CObject_PlayerMySelf* Self()
    {
        return CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : nullptr;
    }

    const _DBC_SKILL_DATA* Template(int id)
    {
        DBC_DEFINEHANDLE(s_pSkillDBC, DBC_SKILL_DATA);
        return s_pSkillDBC ? (const _DBC_SKILL_DATA*)s_pSkillDBC->Search_Index_EQU(id) : nullptr;
    }

    // human.lua get_skill_level: template with a learned xinfa -> ceil(xinfa level / 10) + 1, otherwise
    // character.get_skill_level (1). Capped to the 31 per-level columns of SkillTemplate (CYS_SKILL_BY_LEVEL).
    int LevelOf(int templateId)
    {
        if (templateId == 0) return 0;
        const _DBC_SKILL_DATA* def = Template(templateId);
        int level = 1;
        if (def && def->m_nSkillClass >= 0)
        {
            std::map<int, int>::const_iterator x = g_xinfa.find(def->m_nSkillClass);
            if (x != g_xinfa.end() && x->second > 0) level = (x->second + 9) / 10 + 1;
        }
        return level > 31 ? 31 : level;
    }

    // Bar settings with the CY template ids turned into the SkillData ids of the 0.85 action system.
    void ApplySettings()
    {
        if (g_settings.size() < CysQuickbarContract::SettingFirst + CysQuickbarContract::SlotCount || !IsMain() || !Self()) return;
        GCRetSetting legacy;
        _OWN_SETTING values[SETTING_TYPE_NUMBER];
        for (int i = 0; i < SETTING_TYPE_NUMBER; ++i)
        {
            // Legacy chat indices overlap CY's third F page. Load native chat
            // records separately below, preserving their actual tab IDs.
            values[i].m_SettingType = i >= SETTING_TYPE_CHAT_TAB1_PART1 ? 0 : g_settings[i].first;
            values[i].m_SettingData = i >= SETTING_TYPE_CHAT_TAB1_PART1 ? 0 : static_cast<INT>(g_settings[i].second);
            if (i >= SETTING_TYPE_K0 && i <= SETTING_TYPE_K19 && g_settings[i].first == AOT_SKILL)
            {
                const int tid = static_cast<int>(g_settings[i].second);
                values[i].m_SettingData = tid == 0 ? 0 : tid * 100 + LevelOf(tid);
            }
        }
        legacy.SetSetting(values);
        GCRetSettingHandler::Execute(&legacy, nullptr); // SystemSetup game flags, MainMenuBar_SetID, chat tabs
        for (int i = SETTING_TYPE_K0; i <= SETTING_TYPE_K19; ++i) // 0.85 MainMenuBar_SetID ignores AOT_EMPTY
            if (values[i].m_SettingType == AOT_EMPTY) CActionSystem::GetMe()->MainMenuBar_SetID(i - SETTING_TYPE_K0, INVALID_ID, INVALID_ID);
        for (int slot = 20; slot < CysQuickbarContract::SlotCount; ++slot)
        {
            const auto& setting = g_settings[CysQuickbarContract::SettingFirst + slot];
            const int type = setting.first;
            int data = static_cast<int>(setting.second);
            if (type == AOT_SKILL) data = data == 0 ? 0 : data * 100 + LevelOf(data);
            CActionSystem::GetMe()->MainMenuBar_SetID(slot, type == AOT_EMPTY ? INVALID_ID : type, data);
        }
        for (int tab = 2; tab <= 8; ++tab) {
            const int index = CysQuickbarContract::ChatSetting(tab);
            if (index < 0 || index + 1 >= (int)g_settings.size()) continue;
            const auto& first = g_settings[index]; const auto& second = g_settings[index + 1];
            if (!first.first && !first.second) continue;
            char name[7] = {}; name[0] = (char)first.first;
            memcpy(name + 1, &first.second, 4); name[5] = (char)second.first;
            std::string config;
            for (int bit = 0; bit < 25; ++bit) config += (second.second & (1u << bit)) ? '1' : '0';
            CEventSystem::GetMe()->PushEvent(GE_CHAT_LOAD_TAB_CONFIG, name, config.c_str(), tab);
        }
    }

    void ApplySkills()
    {
        CObject_PlayerMySelf* self = Self();
        if (!g_haveSkills || !IsMain() || !self) return;
        CCharacterData* data = self->GetCharacterData();
        data->Skill_CleanAll();
        // The wire list contains learned skills only. The book also needs the
        // unlearned catalogue and all eight xinfa (including the rage page).
        data->SkillClass_CleanAll();
        DBC_DEFINEHANDLE(xinfaDBC, DBC_SKILL_XINFA);
        if (xinfaDBC && data->Get_MenPai() >= 0 && data->Get_MenPai() != 9)
            for (int i = 0; i < (int)xinfaDBC->GetRecordsNum(); ++i) {
                const auto row = (const _DBC_SKILL_XINFA*)xinfaDBC->Search_LineNum_EQU(i);
                if (row && row->nMenpaiID == data->Get_MenPai())
                    data->Set_SkillClass(row->nID, CysSkillNet::XinfaLevel(row->nID));
            }
        CActionSystem::GetMe()->SkillClass_Update();
        DBC_DEFINEHANDLE(skillDBC, DBC_SKILL_DATA);
        if (skillDBC && data->Get_MenPai() >= 0 && data->Get_MenPai() != 9)
            for (int i = 0; i < (int)skillDBC->GetRecordsNum(); ++i) {
                const auto row = (const _DBC_SKILL_DATA*)skillDBC->Search_LineNum_EQU(i);
                if (row && row->m_nClassByUser == A_SKILL_FOR_PLAYER &&
                    // 788..800 are Murong's borrowed attacks, not learnable
                    // book entries. A server-granted temporary action below
                    // must still be available on the action bar.
                    !(row->m_nID >= 788 && row->m_nID <= 800) &&
                    row->m_nMenPai == data->Get_MenPai() && data->Get_SkillClass(row->m_nSkillClass))
                    data->Set_Skill(row->m_nID, (BYTE)LevelOf(row->m_nID), FALSE);
            }
        int shown = 0;
        std::string list;
        for (size_t i = 0; i < g_templates.size(); ++i)
        {
            const int tid = static_cast<int>(g_templates[i]);
            const int level = LevelOf(tid);
            data->Set_Skill(tid, static_cast<BYTE>(level), TRUE);
            const bool ok = data->Get_Skill(tid == 0 ? 0 : tid * 100 + level) != nullptr;
            shown += ok ? 1 : 0;
            if (list.size() < 200) { char item[32]; _snprintf(item, sizeof(item), "%s%d/%d%s", list.empty() ? "" : ",", tid, level, ok ? "" : "!"); list += item; }
        }
        SkillLog("skills applied %d/%u menpai=%d [%s]", shown, static_cast<unsigned>(g_templates.size()), data->Get_MenPai(), list.c_str());
        ApplySettings();
        CEventSystem::GetMe()->PushEvent(GE_SKILL_UPDATE);
    }

    // CYS-XINFA: cost of one xinfa level, CY table XinFaStudySpend_V1 (DBC 907). what: 0 money, 1 experience.
    // Same lookup as CysXinfaStudySpend of GMGameInterface_Script.cpp (which is static there), so the window and the
    // learn button agree on the number: Lua_GetUplevelXinfaSpendMoney / Exp show it, this decides on it.
    int XinfaStudySpend(int xinfaId, int studyLevel, int what)
    {
        if (xinfaId < 0 || xinfaId >= DBC_XINFA_STUDYSPEND_SLOTS) return 0;
        DBC_DEFINEHANDLE(s_pSpendDBC, DBC_XINFA_STUDYSPEND);
        if (!s_pSpendDBC) return 0;
        const int rows = (int)s_pSpendDBC->GetRecordsNum();
        for (int i = 0; i < rows; ++i)
        {
            const _DBC_XINFA_STUDYSPEND* row = (const _DBC_XINFA_STUDYSPEND*)s_pSpendDBC->Search_LineNum_EQU(i);
            if (!row || row->nStudyLevel != studyLevel) continue;
            return what == 0 ? (int)row->StudySpend[xinfaId].dwSpendMoney : (int)row->StudySpend[xinfaId].dwSpendExperience;
        }
        return 0;
    }


    const int CYS_XINFA_MAX_LEVEL = 119;

    // CY shows its refusals through the chat/debug line with a StrDictionary key (GMDataPool_Info_*); when the key is
    // missing from the dictionary the key itself is shown rather than an empty line.
    void Tell(const char* key)
    {
        if (!key || !*key || !CGameProcedure::s_pUISystem) return;
        const STRING text = CGameProcedure::s_pUISystem->ParserString_NoColor_NoVarParam(key);
        CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE, text.empty() ? key : text.c_str());
    }

    void AskXinfaOnce()
    {
        if (g_xinfaAsked || !Self()) return;
        g_xinfaAsked = true;
        std::unique_ptr<pg::CGAskDetailXinFaList> ask(new pg::CGAskDetailXinFaList);
        ask->m_objID = static_cast<uint32_t>(Self()->GetServerID());
        CysModernGame::SendModern(std::unique_ptr<pg::Packet>(ask.release()));
        SkillLog("CGAskDetailXinFaList sent (after the first skill list)");
        std::unique_ptr<pg::CGAskDetailAbilityInfo> abilities(new pg::CGAskDetailAbilityInfo);
        abilities->m_objID=static_cast<uint32_t>(Self()->GetServerID());
        CysModernGame::SendModern(std::unique_ptr<pg::Packet>(abilities.release()));
    }

    // ---------------------------------------------------------------------------------------------------------
    void OnRetSetting(const pg::GCRetSetting& p)
    {
        ++g_counters.settingLists;
        g_settings.assign(p.setting.size(), std::pair<uint8_t, uint32_t>(0, 0));
        std::string bar;
        for (size_t i = 0; i < p.setting.size(); ++i)
        {
            g_settings[i] = std::make_pair(p.setting[i].type, p.setting[i].data);
            if (i >= SETTING_TYPE_K0 && i <= SETTING_TYPE_K19 && (p.setting[i].type || p.setting[i].data) && bar.size() < 200)
            { char item[40]; _snprintf(item, sizeof(item), "%sK%u=%u/%u", bar.empty() ? "" : " ", static_cast<unsigned>(i - SETTING_TYPE_K0), p.setting[i].type, p.setting[i].data); bar += item; }
        }
        SkillLog("GCRetSetting bar=[%s] game=%u", bar.c_str(), p.setting.size() > 1 ? p.setting[1].data : 0);
        if (!g_haveSkills && Self()) // safety net: GamePro_Main::Init asks 1252 as well
        {
            std::unique_ptr<pg::CGAskDetailSkillList> ask(new pg::CGAskDetailSkillList);
            ask->m_objID = static_cast<uint32_t>(Self()->GetServerID());
            CysModernGame::SendModern(std::unique_ptr<pg::Packet>(ask.release()));
            SkillLog("CGAskDetailSkillList sent");
        }
        ApplySettings();
    }

    void OnXinFaList(const pg::GCDetailXinFaList& p)
    {
        ++g_counters.xinfaLists;
        CObject_PlayerMySelf* self = Self();
        if (!IsMain() || !self || self->GetServerID() != (INT)p.m_objID) return;
        g_xinfa.clear();
        for (size_t i = 0; i < p.m_aXinFa.size(); ++i)
        {
            g_xinfa[(int)p.m_aXinFa[i].m_nXinFaID] = (int)p.m_aXinFa[i].m_nXinFaLevel;
            self->GetCharacterData()->Set_SkillClass((INT)p.m_aXinFa[i].m_nXinFaID, (INT)p.m_aXinFa[i].m_nXinFaLevel);
        }
        CActionSystem::GetMe()->SkillClass_Update();
        SkillLog("GCDetailXinFaList count=%u menpai=%d", static_cast<unsigned>(p.m_aXinFa.size()), self->GetCharacterData()->Get_MenPai());
        ApplySkills(); // skill levels follow the xinfa levels
        CEventSystem::GetMe()->PushEvent(GE_SKILL_UPDATE);
    }

    void OnCooldown(const pg::GCCooldownUpdate& p)
    {
        ++g_counters.cooldownUpdates;
        if (!IsMain() || p.m_uHighSection != 0 || p.m_uLowSection != 0) return; // pet cooldowns carry the pet guid
        std::vector<Cooldown_T> list(p.m_aCooldowns.size());
        for (size_t i = 0; i < p.m_aCooldowns.size(); ++i)
        {
            list[i].SetID(p.m_aCooldowns[i].m_nID);
            list[i].SetCooldownTime(static_cast<Time_t>(p.m_aCooldowns[i].m_nCooldown));
            list[i].SetCooldownElapsed(static_cast<Time_t>(p.m_aCooldowns[i].m_nCooldownElapsed));
            ++g_counters.cooldownEntries;
            if (i < 4) SkillLog("GCCooldownUpdate group=%d total=%u elapsed=%u", p.m_aCooldowns[i].m_nID, p.m_aCooldowns[i].m_nCooldown, p.m_aCooldowns[i].m_nCooldownElapsed);
        }
        if (!list.empty()) CDataPool::GetMe()->CoolDownGroup_UpdateList(&list[0], (INT)list.size());
    }

    void OnStudyXinfa(const pg::GCStudyXinfa& p)
    {
        ++g_counters.studyResults;
        CObject_PlayerMySelf* self = Self();
        if (!IsMain() || !self) return;
        const int before = g_xinfa.count(p.xinfa) ? g_xinfa[p.xinfa] : 0;
        g_xinfa[p.xinfa] = p.now_level;
        self->GetCharacterData()->Set_SkillClass(p.xinfa, p.now_level);
        SkillLog("GCStudyXinfa xinfa=%u level %d -> %u exp=%u money=%u", p.xinfa, before, p.now_level, p.spare_exp, p.spare_money);
        if (p.now_level > before) CEventSystem::GetMe()->PushEvent(GE_SKILLSTUDY_SUCCEED);
        ApplySkills();
    }

    void OnXinfaStudyInfo(const pg::GCXinfaStudyInfo& p)
    {
        ++g_counters.studyInfos;
        CObject* teacher = (CObject*)CObjectManager::GetMe()->FindServerObject((INT)p.teacher);
        SkillLog("GCXinfaStudyInfo menpai=%u teacher=%u (client %d)", p.menpai, p.teacher, teacher ? teacher->GetID() : -1);
        CEventSystem::GetMe()->PushEvent(GE_TOGLE_SKILLSTUDY, teacher ? teacher->GetID() : -1);
    }

    void OnAddSkill(const pg::GCAddSkill& p)
    {
        ++g_counters.addSkills;
        bool listed = false;
        for (size_t i = 0; i < g_templates.size(); ++i) listed = listed || g_templates[i] == p.skill;
        if (!listed) g_templates.push_back(p.skill);
        g_haveSkills = true;
        SkillLog("GCAddSkill template=%u", p.skill);
        ApplySkills();
    }
}

int32_t CysSkillNet::TemplateOfSkillData(int32_t skillDataId)
{
    // CAI_MySelf::SendUseSkillMessage: idSkill * 100 + level; template 0 (normal attack) gives 0..31.
    return skillDataId < 100 ? 0 : skillDataId / 100;
}

void CysSkillNet::OnSkillList(const std::vector<uint32_t>& templates)
{
    ++g_counters.skillLists;
    g_templates = templates;
    g_haveSkills = true;
    ApplySkills();
    AskXinfaOnce();
}

void CysSkillNet::Reset()
{
    g_templates.clear(); g_xinfa.clear(); g_settings.clear();
    g_haveSkills = false; g_xinfaAsked = false; g_logs = 0;
}

void CysSkillNet::OnMenpaiChanged() { ApplySkills(); }

int CysSkillNet::SkillLevel(int templateId)
{
    for (size_t i = 0; i < g_templates.size(); ++i) if ((int)g_templates[i] == templateId) return LevelOf(templateId);
    return -1;
}

int CysSkillNet::XinfaLevel(int xinfaId)
{
    std::map<int, int>::const_iterator x = g_xinfa.find(xinfaId);
    return x == g_xinfa.end() ? 0 : x->second;
}

int CysSkillNet::XinfaCount() { return static_cast<int>(g_xinfa.size()); }

int CysSkillNet::XinfaLevelSum()
{
    int sum = 0;
    for (std::map<int, int>::const_iterator x = g_xinfa.begin(); x != g_xinfa.end(); ++x) sum += x->second;
    return sum;
}





bool CysSkillNet::RequestStudyXinfa(int xinfaId)
{
    ++g_counters.studyRequests;
    CObject_PlayerMySelf* self = Self();
    if (!IsMain() || !self) { SkillLog("study request xinfa=%d ignored: no world character", xinfaId); return false; }
    std::map<int, int>::const_iterator it = g_xinfa.find(xinfaId);
    if (it == g_xinfa.end())
    {
        SkillLog("study request xinfa=%d ignored: not in the own xinfa list (%u known)", xinfaId, (unsigned)g_xinfa.size());
        return false;
    }
    const int level = it->second;
    const int menpai = self->GetCharacterData()->Get_MenPai();
    if (level + 1 > self->GetCharacterData()->Get_Level() + 5) {
        Tell(u8"Tâm pháp không thể cao hơn cấp nhân vật quá 5 cấp.");
        return false;
    }
    if (level >= CYS_XINFA_MAX_LEVEL)
    {
        SkillLog("study request xinfa=%d refused: level %d is the cap", xinfaId, level);
        Tell("GMDataPool_Info_Xinfo_Level_Is_Top");
        return false;
    }
    const int needMoney = XinfaStudySpend(xinfaId, level + 1, 0);
    const int haveMoney = self->GetCharacterData()->Get_Money();
    if (needMoney > 0 && needMoney > haveMoney)
    {
        SkillLog("study request xinfa=%d refused: money %d < %d", xinfaId, haveMoney, needMoney);
        Tell("GMDataPool_Info_Up_Level_Money_Is_Not_Enough");
        return false;
    }
    const int needExp = XinfaStudySpend(xinfaId, level + 1, 1);
    char text[3][24] = {};
    _snprintf(text[0], sizeof(text[0]) - 1, "%d", level);
    _snprintf(text[1], sizeof(text[1]) - 1, "%d", xinfaId);
    _snprintf(text[2], sizeof(text[2]) - 1, "%d", menpai);
    std::vector<STRING> args;
    args.push_back(text[0]); args.push_back(text[1]); args.push_back(text[2]);
    SkillLog("study request xinfa=%d level=%d menpai=%d need money=%d exp=%d -> STUDY_XINFA", xinfaId, level, menpai, needMoney, needExp);
    CEventSystem::GetMe()->PushEvent(GE_STUDY_XINFA, args);
    return true;
}





bool CysSkillNet::AskStudyXinfa(int xinfaId, int nowLevel, int menpai)
{
    CObject_PlayerMySelf* self = Self();
    if (!IsMain() || !self) { SkillLog("CGAskStudyXinfa xinfa=%d dropped: no world character", xinfaId); return false; }
    if (xinfaId < 0 || xinfaId > 65535 || nowLevel < 1 || nowLevel >= CYS_XINFA_MAX_LEVEL
        || menpai != self->GetCharacterData()->Get_MenPai()) return false;
    std::unique_ptr<pg::CGAskStudyXinfa> out(new pg::CGAskStudyXinfa);
    out->menpai = static_cast<uint16_t>(menpai);
    out->xinfa = static_cast<uint16_t>(xinfaId);
    out->now_level = static_cast<uint16_t>(nowLevel);
    ++g_counters.studyAsks;
    SkillLog("CGAskStudyXinfa sent menpai=%u xinfa=%u now_level=%u (lua asked level=%d menpai=%d)",
             out->menpai, out->xinfa, out->now_level, nowLevel, menpai);
    CysModernGame::SendModern(std::unique_ptr<pg::Packet>(out.release()));
    return true;
}

CysSkillNet::Counters CysSkillNet::Get() { return g_counters; }

bool CysSkillNet::IsWorldPacket(uint16_t id)
{
    if (CysLifeAbility::Owns(id)) return true;
    switch (id)
    {
    case pg::GCLevelUpResult::PACKET_ID:
    case pg::GCTeamAskApply::PACKET_ID: return true;
    case pg::GCRetSetting::PACKET_ID: case pg::GCDetailXinFaList::PACKET_ID: case pg::GCCooldownUpdate::PACKET_ID:
    case pg::GCStudyXinfa::PACKET_ID: case pg::GCXinfaStudyInfo::PACKET_ID: case pg::GCAddSkill::PACKET_ID:
        return true;
    default:
        return false;
    }
}

bool CysSkillNet::Dispatch(const pg::Packet& packet)
{
    if (CysLifeAbility::Dispatch(packet)) return true;
    if(CysBattleAssist::TeamApply(packet))return true;
    switch (packet.packetId())
    {
    case pg::GCLevelUpResult::PACKET_ID:
        if(IsMain()&&Self())Self()->GetCharacterData()->Set_Exp(static_cast<int>(static_cast<const pg::GCLevelUpResult&>(packet).remind_exp));
        return true;
    case pg::GCRetSetting::PACKET_ID: OnRetSetting(static_cast<const pg::GCRetSetting&>(packet)); return true;
    case pg::GCDetailXinFaList::PACKET_ID: OnXinFaList(static_cast<const pg::GCDetailXinFaList&>(packet)); return true;
    case pg::GCCooldownUpdate::PACKET_ID: OnCooldown(static_cast<const pg::GCCooldownUpdate&>(packet)); return true;
    case pg::GCStudyXinfa::PACKET_ID: OnStudyXinfa(static_cast<const pg::GCStudyXinfa&>(packet)); return true;
    case pg::GCXinfaStudyInfo::PACKET_ID: OnXinfaStudyInfo(static_cast<const pg::GCXinfaStudyInfo&>(packet)); return true;
    case pg::GCAddSkill::PACKET_ID: OnAddSkill(static_cast<const pg::GCAddSkill&>(packet)); return true;
    default:
        return false;
    }
}

std::unique_ptr<pg::Packet> CysSkillNet::Translate(Packet* legacy)
{
    if (auto out = CysLifeAbility::Translate(legacy)) return out;
    switch (legacy->GetPacketID())
    {
    case PACKET_CG_REQLEVELUP: return std::unique_ptr<pg::Packet>(new pg::CGReqLevelUp);
    case PACKET_CG_MODIFYSETTING:
    {
        // 0.85 CActionSystem::MainMenuBar_Set / SaveAction: bar skills as SkillData ids; the CY server stores the
        // template id (scenecore char_modify_setting; the login bar of CYTest00 holds 0/35/22/21).
        CGModifySetting* in = static_cast<CGModifySetting*>(legacy);
        std::unique_ptr<pg::CGModifySetting> out(new pg::CGModifySetting);
        out->type = in->GetType();
        out->setting_type = in->GetValue()->m_SettingType;
        out->setting_data = static_cast<uint32_t>(in->GetValue()->m_SettingData);
        const bool taggedBar = CysQuickbarContract::IsSlot(out->type - CysQuickbarContract::LegacyTagFirst);
        if (taggedBar) out->type = out->type - CysQuickbarContract::LegacyTagFirst + CysQuickbarContract::SettingFirst;
        else if (out->type >= SETTING_TYPE_CHAT_TAB1_PART1 && out->type <= SETTING_TYPE_CHAT_TAB4_PART2)
            return nullptr; // native chat uses SaveChatTab; old indices are CY action slots
        if (taggedBar || (out->type >= SETTING_TYPE_K0 && out->type <= SETTING_TYPE_K19))
        {
            if (out->setting_type == AOT_SKILL) out->setting_data = static_cast<uint32_t>(TemplateOfSkillData(in->GetValue()->m_SettingData));
            if (out->setting_type == AOT_EMPTY) out->setting_data = 0;
            if (out->type < g_settings.size()) g_settings[out->type] = std::make_pair(out->setting_type, out->setting_data);
        }
        ++g_counters.modifySettings;
        SkillLog("CGModifySetting type=%u setting=%u/%u", out->type, out->setting_type, out->setting_data);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_ASKDETAILXINFALIST:
    {
        std::unique_ptr<pg::CGAskDetailXinFaList> out(new pg::CGAskDetailXinFaList);
        out->m_objID = static_cast<uint32_t>(static_cast<CGAskSkillClass*>(legacy)->getTargetID());
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_ASKSTUDYXINFA:
    {
        // 0.85 CDataPool::SendStudySkillEvent puts the teacher in m_idMenpai; the CY server reads menpai/xinfa/now_level
        // and refuses a now_level different from the stored one (msgagent CGAskStudyXinfa).
        const CGAskStudyXinfa::_STUDYXINFA_INFO info = static_cast<CGAskStudyXinfa*>(legacy)->GetUplevelInfoInfo();
        std::unique_ptr<pg::CGAskStudyXinfa> out(new pg::CGAskStudyXinfa);
        out->menpai = static_cast<uint16_t>(Self() ? Self()->GetCharacterData()->Get_MenPai() : 9);
        out->xinfa = static_cast<uint16_t>(info.m_idXinfa);
        out->now_level = static_cast<uint16_t>(info.m_NowLevel);
        SkillLog("CGAskStudyXinfa menpai=%u xinfa=%u now_level=%u", out->menpai, out->xinfa, out->now_level);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    default:
        return nullptr;
    }
}

bool CysSkillNet::SaveChatTab(int tab, const char* name, const char* config, bool clear)
{
    const int index = CysQuickbarContract::ChatSetting(tab);
    // This server persists 96 records; the CY alliance tab at 112 is outside it.
    if (index < 0 || index + 1 >= 96 || !IsMain()) return false;
    if (!clear && (!name || !*name || strlen(name) > 6 || !config || strlen(config) > 32)) return false;
    char label[6] = {}; uint32_t mask = 0;
    if (!clear) {
        memcpy(label, name, strlen(name));
        for (size_t bit = 0; config[bit]; ++bit) {
            if (config[bit] != '0' && config[bit] != '1') return false;
            if (config[bit] == '1') mask |= 1u << bit;
        }
    }
    uint32_t text = 0; memcpy(&text, label + 1, 4);
    for (int part = 0; part < 2; ++part) {
        std::unique_ptr<pg::CGModifySetting> out(new pg::CGModifySetting);
        out->type = index + part; out->setting_type = (uint8_t)label[part ? 5 : 0];
        out->setting_data = part ? mask : text;
        if (out->type < g_settings.size()) g_settings[out->type] = std::make_pair(out->setting_type, out->setting_data);
        CysModernGame::SendModern(std::unique_ptr<pg::Packet>(out.release()));
    }
    return true;
}

void CysSkillNet::TickAssist(){CysBattleAssist::Tick();}
void CysSkillNet::AssistSnapshot(const int* v,int n){CysBattleAssist::Snapshot(v,n);}
void CysSkillNet::RegisterHost()
{
    CScriptSystem* scripts = CScriptSystem::GetMe();
    if (!scripts || !scripts->GetLuaState()) return;
    // CY MainmenuBar_UpdateAll publishes its visible F page here. The generated
    // no-op left keyboard dispatch on page zero while the UI showed pages 2/3.
    scripts->GetLuaState()->GetGlobals().Register("SetMenuBarPageNumber", SetMenuBarPageNumber);
    scripts->GetLuaState()->GetGlobals().Register("OpenZhenfaFream", OpenFormation);
    CysBattleAssist::Register(scripts->GetLuaState());
    CysLifeAbility::Register(scripts->GetLuaState());
    CysHostSkill::Services services;
    services.xinfaLevel = [](int id) { return CysSkillNet::XinfaLevel(id); };
    services.skillLevel = [](int id) { return CysSkillNet::SkillLevel(id); };
    services.xinfaText = [](int id, int part) -> const char* {
        DBC_DEFINEHANDLE(s_pXinFaDBC, DBC_SKILL_XINFA);
        const _DBC_SKILL_XINFA* def = s_pXinFaDBC ? (const _DBC_SKILL_XINFA*)s_pXinFaDBC->Search_Index_EQU(id) : nullptr;
        if (!def) return nullptr;
        return part == 0 ? def->pszName : part == 1 ? def->pszDesc : def->pszIconName;
    };
    services.playerLevel = []() { CObject_PlayerMySelf* me = CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : nullptr; return me && me->GetCharacterData() ? me->GetCharacterData()->Get_Level() : 0; }; // CYS-HOST2
    services.xinfaPosIndex = [](int id) { CObject_PlayerMySelf* me = CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : nullptr; const SCLIENT_SKILLCLASS* sc = me && me->GetCharacterData() ? me->GetCharacterData()->Get_SkillClass(id) : nullptr; return sc ? sc->m_nPosIndex : -1; }; // CYS-HOST2
    // CYS-XINFA: learn button (SkillsStudyFrame_study) and its confirmation (SendAskStudyXinfa)
    services.studyRequest = [](int xinfaId) { return CysSkillNet::RequestStudyXinfa(xinfaId); };
    services.studySend = [](int xinfaId, int nowLevel, int menpai) { return CysSkillNet::AskStudyXinfa(xinfaId, nowLevel, menpai); };
    const int n = CysHostSkill::Register(scripts->GetLuaState(), services);
    SkillLog("host functions registered=%d", n);
}

#else
void CysSkillNet::TickAssist(){}
void CysSkillNet::AssistSnapshot(const int*,int){}
bool CysSkillNet::SaveChatTab(int, const char*, const char*, bool) { return false; }
std::unique_ptr<pg::Packet> CysSkillNet::Translate(Packet*) { return nullptr; }
int32_t CysSkillNet::TemplateOfSkillData(int32_t id) { return id; }
bool CysSkillNet::IsWorldPacket(uint16_t) { return false; }
bool CysSkillNet::Dispatch(const pg::Packet&) { return false; }
void CysSkillNet::OnSkillList(const std::vector<uint32_t>&) {}
void CysSkillNet::Reset() {}
void CysSkillNet::OnMenpaiChanged() {}
int CysSkillNet::SkillLevel(int) { return -1; }
int CysSkillNet::XinfaLevel(int) { return 0; }
int CysSkillNet::XinfaCount() { return 0; }
int CysSkillNet::XinfaLevelSum() { return 0; }
bool CysSkillNet::RequestStudyXinfa(int) { return false; }
bool CysSkillNet::AskStudyXinfa(int, int, int) { return false; }
CysSkillNet::Counters CysSkillNet::Get() { Counters c = {}; return c; }
void CysSkillNet::RegisterHost() {}
#endif
