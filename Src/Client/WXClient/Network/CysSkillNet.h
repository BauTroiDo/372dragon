#pragma once
// CYS-SKILL: skills on the modern (skynet CY) protocol. Game.exe main thread only.
// Learned skills (GCDetailSkillList = SkillTemplate ids), xinfa (GCDetailXinFaList / CGAskStudyXinfa / GCStudyXinfa /
// GCXinfaStudyInfo), quick bar (GCRetSetting / CGModifySetting), cooldown groups (GCCooldownUpdate), GCAddSkill.
// Wire layouts and server behaviour: Docs/specs/net/skills-ui_vi.md.

#include <cstdint>
#include <memory>
#include <vector>

class Packet;
namespace pg { class Packet; }

namespace CysSkillNet
{
    // Translate one whitelisted 0.85 packet (nullptr = not a skill packet).
    std::unique_ptr<pg::Packet> Translate(Packet* legacy);
    // 0.85 CAI_MySelf sends SkillData ids (template * 100 + level); the CY server wants the template id (0 = attack).
    int32_t TemplateOfSkillData(int32_t skillDataId);
    // A world packet of this module (stashed until the scene is ready).
    bool IsWorldPacket(uint16_t id);
    // Returns true when the packet was consumed.
    bool Dispatch(const pg::Packet& packet);
    // GCDetailSkillList (CysModernHandlers): the CY list of SkillTemplate ids.
    void OnSkillList(const std::vector<uint32_t>& templates);
    void Reset();
    void OnMenpaiChanged();
    // Level of a learned template as the server computes it (human.lua get_skill_level): xinfa level/10 rounded up + 1,
    // 1 without xinfa; -1 when the template is not learned.
    int SkillLevel(int templateId);
    // Xinfa level from GCDetailXinFaList / GCStudyXinfa (0 = unknown).
    int XinfaLevel(int xinfaId);
    int XinfaCount();
    int XinfaLevelSum();
    bool SaveChatTab(int tab, const char* name, const char* config, bool clear = false);
    // CYS-XINFA: step 1 of the CY xinfa study window (SkillsStudyFrame_study of ActionSkillsStudy.lua). Runs the CY
    // checks (learned, not at the level cap, enough money for XinFaStudySpend_V1) and then pushes GE_STUDY_XINFA so
    // MessageBox_Self asks before the character's own experience is spent. false = nothing was sent or asked.
    bool RequestStudyXinfa(int xinfaId);
    // CYS-XINFA: step 2 (SendAskStudyXinfa of MessageBox_Self.lua) - builds and sends CGAskStudyXinfa 555.
    bool AskStudyXinfa(int xinfaId, int nowLevel, int menpai);
    struct Counters { unsigned skillLists, xinfaLists, settingLists, cooldownUpdates, cooldownEntries, studyResults, studyInfos, addSkills, modifySettings, useSkills, studyRequests, studyAsks; };
    Counters Get();
    // Lua host functions of the CY skill book / xinfa windows (LuaApiGen/CysHost_Skill); idempotent, main thread.
    void RegisterHost();
    void TickAssist();
    void AssistSnapshot(const int* values,int count);
}
