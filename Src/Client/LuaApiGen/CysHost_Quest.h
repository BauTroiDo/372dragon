#pragma once
// CYS-QUEST: Lua host functions of the CY NPC dialogue (Quest.lua), mission tracking frame (MissionTrack.lua) and mission
// log (QuestLog.lua) that the 0.85 source lacks or answers with catalog stubs, plus the Vietnamese mission / NPC / place
// names of the CY descriptors (CysHost_QuestText_vi.inc, Tools/pipeline/cy_quest_text.py). Game-layer state comes through
// Services (implemented in WXClient/Network/CysQuestNet.cpp); this file only does the Lua glue and the text tables.
// Spec: Docs/specs/net/npc-quest_vi.md.
#include "LuaPlus.h"

struct CysQuestText { int script, mission, kind; const char* name; const char* npc; int scene; const char* sceneName; int x, z; };
struct CysQuestPair { const char* zh; const char* vi; };
struct CysQuestKind { int kind; const char* name; };

namespace CysHostQuest
{
    enum Dialog { InfoScript = 0, InfoMission, ContinueScript, ContinueMission, DemandScript, DemandMission };
    enum Display { OkFail = 1, LimitTime = 2, Round = 3, Bill = 4, ScriptId = 7 };

    struct Services
    {
        void* context = nullptr;
        // Script / mission id of the last GCScriptCommand 1 (info), 4 (continue) or 3 (demand) dialogue; -1 when none.
        int (*dialogValue)(void* context, int which) = nullptr;
        // Reward (demand=0) / demand (demand=1) item of the open dialogue: client item object id for
        // DataPool:EnumPlayerMission_ItemAction, -1 for money / no item.
        int (*questItemObject)(void* context, int index, int demand) = nullptr;
        // Item table id of reward `index` of the continue dialogue (DataPool:GetMissionContinue_ItemID), -1 when none.
        int (*continueItemId)(void* context, int index) = nullptr;
        // Reward `index` of the open dialogue: type 0 money, 1 jiaozi money, 2 item, 3 random item, 4 radio item, 5 exp;
        // false when out of range.
        bool (*reward)(void* context, int index, int* type, int* objectId, int* count) = nullptr;
        // Own mission slot (0..19): script id, -1 when the slot is empty.
        int (*slotScript)(void* context, int slot) = nullptr;
        // DataPool:GetPlayerMission_Display(slot, what) for what 1..4 (descriptor flags), 0 when unknown.
        int (*slotDisplay)(void* context, int slot, int what) = nullptr;
    };

    // Registers every function (replacing catalog stubs). Returns the number of functions registered.
    int Register(LuaPlus::LuaState* state, const Services& services);

    // Text tables (nullptr when the script / string is not listed).
    const CysQuestText* FindText(int script);
    const char* CustomVi(const char* zhUtf8);
    const char* KindVi(int kind);
}
