// CYS-SKILL: Lua glue of the CY skill book / xinfa windows. See CysHost_Skill.h.
#include "CysHost_Skill.h"
#include "LuaApiGen.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

namespace CysHostSkill
{
    namespace
    {
        Services g_services;

        LuaPlus::LuaObject Receiver(LuaPlus::LuaObject& globals, const char* name)
        {
            LuaPlus::LuaObject o = globals.GetByName(name);
            if (o.IsTable()) return o;
            if (o.IsUserData())
            {
                LuaPlus::LuaObject meta = o.GetMetaTable();
                if (!meta.IsTable()) return LuaPlus::LuaObject();
                LuaPlus::LuaObject index = meta.GetByName("__index");
                return index.IsTable() ? index : meta;
            }
            return LuaPlus::LuaObject();
        }

        int XinfaLevel(int id) { return g_services.xinfaLevel ? g_services.xinfaLevel(id) : 0; }

        // CYS-HOST2: "explain" of CY 3.71 Game.exe (0x14038aac2..0x14038abad, listing Build/Logs/2026-09-17-host-2/re/
        // CY_xinfainfo_region.txt). CY does NOT push XinFa_V1 column 3 raw - every one of its 120 rows ends in
        // "...#r#c54FF00最高等级%d#r..." and CY formats it:
        //     level = MySelf->GetCharacterData()->Get_Level()
        //     max   = level <= 119 ? 119 : 129                              (0x77 / 0x81)
        //     if (pSkillClass->m_nPosIndex == 7)                            (the 8th xinfa slot)
        //         max = level <= 119 ? 250 : 300; if (g_flag[+0x6f5874]) max = 119;   ([SL] flag = 0 here, see below)
        //     _snprintf(buf, 0x400, pszDesc, max); PushString(buf)
        // client_GL (0x1402d2610) pushes pszDesc raw - its data predates the "%d" - which is why the window showed
        // the literal "%d" (ui-fit / host-xinfa screenshots). The flag at CY g+0x6f5874 is set by the handler of
        // packet 0xbfc, which this server never sends, so it stays 0.
        // The substitution is done by hand (only "%d" and "%%"), not by _snprintf on the row text: a translated
        // description with a stray '%' would otherwise corrupt the label, and for a well-formed row the result is
        // byte-identical to CY's.
        bool g_explainOff = false;   // CYS_HOST2_OFF=1: keep the raw text (same-binary control of the A/B runs)

        std::string FormatExplain(const char* desc, int maxLevel)
        {
            char number[16] = {};
            _snprintf(number, sizeof(number) - 1, "%d", maxLevel);
            std::string out;
            for (const char* p = desc; *p; ++p)
            {
                if (p[0] == '%' && p[1] == 'd') { out += number; ++p; }
                else if (p[0] == '%' && p[1] == '%') { out += '%'; ++p; }
                else out += *p;
            }
            return out;
        }

        int ExplainMaxLevel(int xinfaId)
        {
            const int level = g_services.playerLevel ? g_services.playerLevel() : 0;
            const int pos = g_services.xinfaPosIndex ? g_services.xinfaPosIndex(xinfaId) : -1;
            if (pos == 7) return level <= 119 ? 250 : 300;
            return level <= 119 ? 119 : 129;
        }

        // Player:GetXinfaInfo(id, "name"|"level"|"iconname"|"explain") - the 0.85 method has "level" commented out
        // and pushes nothing (ActionSkill.lua concatenates it: "Cấp bậc tâm pháp:" .. level).
        int PlayerGetXinfaInfo(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            if (!args[2].IsNumber() || !args[3].IsString()) { s->PushString(""); return 1; }
            const int id = static_cast<int>(args[2].GetNumber());
            const std::string what = args[3].GetString();
            if (what == "level") { s->PushInteger(XinfaLevel(id)); return 1; }
            const int part = what == "name" ? 0 : what == "explain" ? 1 : what == "iconname" ? 2 : -1;
            const char* text = (part >= 0 && g_services.xinfaText) ? g_services.xinfaText(id, part) : nullptr;
            if (part == 1 && text && !g_explainOff && std::strstr(text, "%d"))
            {
                s->PushString(FormatExplain(text, ExplainMaxLevel(id)).c_str());
                return 1;
            }
            s->PushString(text ? text : "");
            return 1;
        }

        // GetXinfaLevel(id) (global, ActionSkill.lua "add:lby2015"): the 0.85 Lua_GetXinfaLevel is commented out.
        int GlobalGetXinfaLevel(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            s->PushInteger(args[1].IsNumber() ? XinfaLevel(static_cast<int>(args[1].GetNumber())) : 0);
            return 1;
        }

        // SkillsStudyFrame_study(xinfaId) - ActionSkillsStudy.lua:312 "ActionSkillsStudy_UpLevel_Clicked".
        // CY Game.exe 3.71 registers a ONE-argument version (0x140234c20 -> CDataPool::SendStudySkillEvent at
        // 0x1400cd690, catalog nargs_read 1); the 0.85 lua_SkillsStudyFrame_study wants three integers and throws
        // "Wrong Param" on the CY call, so the learn button of the CY window died before any packet was built.
        // Three arguments keep the 0.85 meaning (skill*100+level, teacher, has-previous-level) for GL layouts.
        int GlobalSkillsStudyFrameStudy(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            if (!args[1].IsNumber()) return 0;
            const int first = static_cast<int>(args[1].GetNumber());
            // 0.85 form (three arguments): arg1 is idSkill*100 + level, so the xinfa id is arg1 / 100.
            const int id = args[2].IsNumber() ? first / 100 : first;
            if (g_services.studyRequest) g_services.studyRequest(id);
            return 0;
        }

        // SendAskStudyXinfa(nowLevel, xinfaId, menpai) - MessageBox_Self.lua:6488, the OK button of the CY
        // STUDY_XINFA confirmation. CY Game.exe 3.71 0x140234c90: three lua_tonumber reads, then one CGAskStudyXinfa
        // whose 6 body bytes are written as [+0] = arg3 (menpai), [+2] = arg2 (xinfa), [+4] = arg1 (now_level) -
        // exactly the field order of pg::CGAskStudyXinfa (555).
        int GlobalSendAskStudyXinfa(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            if (!args[1].IsNumber() || !args[2].IsNumber() || !args[3].IsNumber()) return 0;
            const int nowLevel = static_cast<int>(args[1].GetNumber());
            const int xinfa = static_cast<int>(args[2].GetNumber());
            const int menpai = static_cast<int>(args[3].GetNumber());
            if (g_services.studySend) g_services.studySend(xinfa, nowLevel, menpai);
            return 0;
        }

        int Zero(LuaPlus::LuaState* s) { s->PushInteger(0); return 1; }
        // CYS-CY 16/09 (menpai-verify): GetUplevelXinfaSpendMoney / Exp (ActionSkill.lua:306, ActionSkillsStudy.lua:279)
        // are no longer stubbed here. DBC 907 now opens the CY table XinFaStudySpend_V1.txt (GMDataBase.cpp), so
        // Lua_GetUplevelXinfaSpend* of GMGameInterface_Script.cpp shows the real CY cost, the same numbers the server
        // charges (xinfa_study_speed_v1). Before that the two stubs pushed 0 and the window showed a free upgrade.
        int MaxLevel(LuaPlus::LuaState* s) { s->PushInteger(200); return 1; } // Character cap; xinfa is a separate limit.

        // CY 3.71 Game.exe 140240210/2a0/330: second-strike IDs. These
        // variants stay in the skill state but are not extra book buttons.
        int Second(LuaPlus::LuaState* s, int first, int last) {
            LuaPlus::LuaStack args(s);
            const int id = args[1].IsNumber() ? (int)args[1].GetNumber() : -1;
            s->PushInteger(id >= first && id <= last ? 1 : 0); return 1;
        }
        int LMSJSecond(LuaPlus::LuaState* s) { return Second(s, 821, 826); }
        int JYJYSecond(LuaPlus::LuaState* s) { return Second(s, 827, 834); }
        int WJQFSecond(LuaPlus::LuaState* s) { return Second(s, 4465, 4466); }

        struct Entry { const char* receiver; const char* name; int (*fn)(LuaPlus::LuaState*); bool force; };
        const Entry kEntries[] = {
            {"Player", "GetXinfaInfo", PlayerGetXinfaInfo, true},
            {nullptr, "GetXinfaLevel", GlobalGetXinfaLevel, true},
            {"Player", "GetDefineHumanMaxLevel", MaxLevel, true},
            {"Player", "GetDefineHumanMaxLevelSub", MaxLevel, true},
            // CYS-XINFA: the learn button and its confirmation. Both are forced: SkillsStudyFrame_study replaces the
            // 0.85 three-argument version that throws on the CY call, SendAskStudyXinfa replaces the LuaApiGen stub.
            {nullptr, "SkillsStudyFrame_study", GlobalSkillsStudyFrameStudy, true},
            {nullptr, "SendAskStudyXinfa", GlobalSendAskStudyXinfa, true},
            // ActionSkill.lua / CommonSkill.lua filters of CY-only combo skills (龙门/九阴/万剑 second strikes)
            {nullptr, "IsLMSJSecond", LMSJSecond, true},
            {nullptr, "IsJYJYSecond", JYJYSecond, true},
            {nullptr, "IsWJQFSecond", WJQFSecond, true},
        };
    }

    int Register(LuaPlus::LuaState* state, const Services& services)
    {
        g_services = services;
        { const char* off = std::getenv("CYS_HOST2_OFF"); g_explainOff = off && off[0] == '1' && off[1] == 0; } // CYS-HOST2
        if (!state) return 0;
        LuaPlus::LuaObject globals = state->GetGlobals();
        int registered = 0;
        for (const Entry& e : kEntries)
        {
            LuaPlus::LuaObject table = e.receiver ? Receiver(globals, e.receiver) : globals;
            if (!table.IsTable()) continue;
            if (!e.force && !LuaApiGen::IsMissing(table, e.name)) continue;
            table.Register(e.name, e.fn);
            ++registered;
        }
        return registered;
    }
}
