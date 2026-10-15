#pragma once
// CYS-SKILL: Lua host functions of the CY skill book / common skill / xinfa windows (ActionSkill.lua,
// CommonSkill.lua, ActionSkillsStudy.lua, MainMenuBar.lua) that the 0.85 source lacks or answers wrongly.
// Game-layer state comes through Services (implemented in WXClient/Network/CysSkillNet.cpp); this file is Lua glue.
#include "LuaPlus.h"

namespace CysHostSkill
{
    struct Services
    {
        // Xinfa level of the own character (0 = not learned) and level of a learned SkillTemplate (-1 = not learned).
        int (*xinfaLevel)(int xinfaId) = nullptr;
        int (*skillLevel)(int templateId) = nullptr;
        // XinFa_V1 text: 0 name, 1 description, 2 icon (nullptr = no such xinfa).
        const char* (*xinfaText)(int xinfaId, int part) = nullptr;
        // CYS-XINFA: the two steps of the CY xinfa study window, implemented in Network/CysSkillNet.cpp.
        // studyRequest = ActionSkillsStudy.lua:312 SkillsStudyFrame_study(xinfaId): CY checks, then either the
        // STUDY_XINFA confirmation of MessageBox_Self or the packet at once. studySend = MessageBox_Self.lua:6488
        // SendAskStudyXinfa(nowLevel, xinfaId, menpai): CGAskStudyXinfa 555. Both return false when they did nothing.
        bool (*studyRequest)(int xinfaId) = nullptr;
        bool (*studySend)(int xinfaId, int nowLevel, int menpai) = nullptr;
        // CYS-HOST2: inputs of the CY "explain" formatting (Player:GetXinfaInfo(id, "explain") substitutes the
        // "%d" of XinFa_V1 column 3 with the xinfa level cap): the character level and the UI slot of the xinfa
        // (SCLIENT_SKILLCLASS::m_nPosIndex; -1 = not learned).
        int (*playerLevel)() = nullptr;
        int (*xinfaPosIndex)(int xinfaId) = nullptr;
    };

    // Registers every function (forced replacements of 0.85 methods that return nothing, CY helpers only when absent).
    // Returns the number of functions registered.
    int Register(LuaPlus::LuaState* state, const Services& services);
}
