// CYS-QUEST: Lua glue of the CY NPC dialogue / mission tracking / mission log windows. See CysHost_Quest.h.
#include "CysHost_Quest.h"
#include "LuaApiGen.h"
#include <cstring>
#include <string>

#include "CysHost_QuestText_vi.inc"

namespace CysHostQuest
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
            if (o.IsNil()) return globals.CreateTable(name);
            return LuaPlus::LuaObject();
        }

        // Receiver methods are called as Table:Fn(a, b): stack 1 = self, 2.. = arguments.
        int IntArg(LuaPlus::LuaState* s, int index, int fallback)
        {
            LuaPlus::LuaStack args(s);
            return args[index].IsNumber() ? static_cast<int>(args[index].GetNumber()) : fallback;
        }
        int Dialog(LuaPlus::LuaState* s, int which)
        {
            s->PushInteger(g_services.dialogValue ? g_services.dialogValue(g_services.context, which) : -1);
            return 1;
        }
        int InfoScriptFn(LuaPlus::LuaState* s) { return Dialog(s, InfoScript); }
        int ContinueScriptFn(LuaPlus::LuaState* s) { return Dialog(s, ContinueScript); }
        int ContinueMissionFn(LuaPlus::LuaState* s) { return Dialog(s, ContinueMission); }

        // DataPool:GetMissionContinue_ItemID(index, type) (Quest.lua MissionContinue_Clicked: reward item for the bag tip)
        int ContinueItemIdFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1);
            s->PushInteger(g_services.continueItemId ? g_services.continueItemId(g_services.context, index) : -1);
            return 1;
        }

        // LifeAbility:GetQuestUI_Reward(i) / GetQuestUI_Demand(i): item object of reward / demand i (-1 = none)
        int QuestItem(LuaPlus::LuaState* s, int demand)
        {
            const int index = IntArg(s, 2, -1);
            s->PushInteger(g_services.questItemObject ? g_services.questItemObject(g_services.context, index, demand) : -1);
            return 1;
        }
        int RewardUiFn(LuaPlus::LuaState* s) { return QuestItem(s, 0); }
        int DemandUiFn(LuaPlus::LuaState* s) { return QuestItem(s, 1); }

        // DataPool:GetMissionInfo_Bonus(i) -> type string, item object id, count (CY adds "moneyjz" and "exp")
        int BonusFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1);
            int type = -1, object = 0, count = 0;
            if (!g_services.reward || !g_services.reward(g_services.context, index, &type, &object, &count))
            {
                s->PushString(""); s->PushInteger(0); s->PushInteger(0);
                return 3;
            }
            static const char* const names[] = {"money", "moneyjz", "item", "itemrand", "itemradio", "exp"};
            s->PushString(type >= 0 && type <= 5 ? names[type] : "");
            s->PushInteger(object);
            s->PushInteger(count);
            return 3;
        }

        int SlotScript(int slot) { return g_services.slotScript ? g_services.slotScript(g_services.context, slot) : -1; }

        // DataPool:GetPlayerMission_Display(slot, what): 7 = script id of the mission (MissionTrack.lua special tracks)
        int DisplayFn(LuaPlus::LuaState* s)
        {
            const int slot = IntArg(s, 2, -1), what = IntArg(s, 3, 0);
            if (what == ScriptId) { const int script = SlotScript(slot); s->PushInteger(script < 0 ? 0 : script); return 1; }
            s->PushInteger(g_services.slotDisplay ? g_services.slotDisplay(g_services.context, slot, what) : (what == Round ? -1 : 0));
            return 1;
        }

        // DataPool:GetPlayerMissionTrackType(slot) -> type, sub type. Every accepted mission of the maps is tracked the
        // plain way (type 1: name + goals + finish NPC); 2 (portrait track) needs MissionTrack.txt rows not modelled.
        int TrackTypeFn(LuaPlus::LuaState* s)
        {
            const int slot = IntArg(s, 2, -1);
            s->PushInteger(SlotScript(slot) >= 0 ? 1 : 0);
            s->PushInteger(0);
            return 2;
        }

        // DataPool:GetMissionFinishInfo(slot) -> finish NPC, scene name, scene id, x, z (MissionTrack "Den <scene> tim <npc>")
        int FinishInfoFn(LuaPlus::LuaState* s)
        {
            const CysQuestText* text = FindText(SlotScript(IntArg(s, 2, -1)));
            s->PushString(text ? text->npc : "");
            s->PushString(text ? text->sceneName : "");
            s->PushInteger(text ? text->scene : -1);
            s->PushInteger(text ? text->x : 0);
            s->PushInteger(text ? text->z : 0);
            return 5;
        }

        // DataPool:GetMissionShortName(name) -> changed flag, name. CY cuts long names so "(level) name status" stays on
        // one row of the 230 px tracking column (MissionTrack.lua appends "..." when changed); the Vietnamese names
        // are longer than the Chinese ones, so the cut is by characters (UTF-8 code points) at a word boundary.
        int ShortNameFn(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            const std::string name = args[2].IsString() ? args[2].GetString() : "";
            const size_t kMax = 14;
            size_t points = 0, cut = std::string::npos, lastSpace = std::string::npos;
            for (size_t i = 0; i < name.size(); ++i)
            {
                if ((static_cast<unsigned char>(name[i]) & 0xC0) == 0x80) continue;
                if (points == kMax) { cut = i; break; }
                if (name[i] == ' ') lastSpace = i;
                ++points;
            }
            if (cut == std::string::npos) { s->PushInteger(0); s->PushString(name.c_str()); return 2; }
            if (lastSpace != std::string::npos && lastSpace > cut / 2) cut = lastSpace;
            s->PushInteger(1);
            s->PushString(name.substr(0, cut).c_str());
            return 2;
        }

        // DataPool:GetMissionInfo_Kind(kind) -> kind name (MissionKind.txt, Vietnamese)
        int KindFn(LuaPlus::LuaState* s)
        {
            const char* name = KindVi(IntArg(s, 2, -1));
            s->PushString(name ? name : "");
            return 1;
        }

        int One(LuaPlus::LuaState* s) { s->PushInteger(1); return 1; }
        int Zero(LuaPlus::LuaState* s) { s->PushInteger(0); return 1; }
        int Nothing(LuaPlus::LuaState*) { return 0; }
        int Empty(LuaPlus::LuaState* s) { s->PushString(""); return 1; }

        struct Entry { const char* receiver; const char* name; int (*fn)(LuaPlus::LuaState*); bool force; };
        const Entry kEntries[] = {
            // Quest.lua (NPC dialogue)
            {"DataPool", "GetMissionInfo_ScriptID", InfoScriptFn, true},
            {"DataPool", "GetMissionContinue_ScriptID", ContinueScriptFn, true},
            {"DataPool", "GetMissionContinue_MissionID", ContinueMissionFn, true},
            {"DataPool", "GetMissionContinue_IssueScriptID", ContinueScriptFn, true},
            {"DataPool", "GetMissionContinue_ItemID", ContinueItemIdFn, true},
            {"DataPool", "GetMissionInfo_Bonus", BonusFn, true},
            {"LifeAbility", "GetQuestUI_Reward", RewardUiFn, true},
            {"LifeAbility", "GetQuestUI_Demand", DemandUiFn, true},
            {"_G", "GetFreshManGuideOwner", Empty, true},          // no freshman guide window is driven here
            // MissionTrack.lua / QuestLog.lua (tracking frame and mission log)
            {"DataPool", "GetPlayerMission_Display", DisplayFn, true},
            {"DataPool", "GetPlayerMissionTrackType", TrackTypeFn, true},
            {"DataPool", "IsMissionTrackOpen", One, true},
            {"DataPool", "SetMissionTrackOpen", Nothing, true},
            {"DataPool", "HaveMisstionTrackThisType", One, true},
            {"DataPool", "IsTrackFuncShow", One, true},
            {"DataPool", "SetTrackFuncShow", Nothing, true},
            {"DataPool", "UpdateTrackStateButton", Nothing, true},
            {"DataPool", "UpdateMissionTrack", Nothing, true},
            {"DataPool", "GetMissionFinishInfo", FinishInfoFn, true},
            {"DataPool", "GetMissionShortName", ShortNameFn, true},
            {"DataPool", "GetMissionInfo_Kind", KindFn, true},
            {"DataPool", "GetPlayerMissionRandomCustom_Num", Zero, true},
            {"DataPool", "GetInfantExpMission", Zero, true},
        };
    }

    const CysQuestText* FindText(int script)
    {
        if (script < 0) return nullptr;
        for (const CysQuestText& t : kQuestText) if (t.script == script) return &t;
        return nullptr;
    }

    const char* CustomVi(const char* zhUtf8)
    {
        if (!zhUtf8 || !*zhUtf8) return nullptr;
        for (const CysQuestPair& p : kQuestCustom) if (std::strcmp(p.zh, zhUtf8) == 0) return p.vi;
        return nullptr;
    }

    const char* KindVi(int kind)
    {
        for (const CysQuestKind& k : kQuestKind) if (k.kind == kind) return k.name;
        return nullptr;
    }

    int Register(LuaPlus::LuaState* state, const Services& services)
    {
        g_services = services;
        if (!state) return 0;
        LuaPlus::LuaObject globals = state->GetGlobals();
        int registered = 0;
        for (const Entry& e : kEntries)
        {
            LuaPlus::LuaObject table = std::strcmp(e.receiver, "_G") == 0 ? globals : Receiver(globals, e.receiver);
            if (!table.IsTable()) continue;
            if (!e.force && !LuaApiGen::IsMissing(table, e.name)) continue;
            table.Register(e.name, e.fn);
            ++registered;
        }
        return registered;
    }
}
