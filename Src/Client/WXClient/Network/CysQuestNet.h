#pragma once
// CYS-QUEST: NPC dialogue / missions on the CY skynet protocol (Docs/specs/net/npc-quest_vi.md).
// Translates the 0.85 mission requests (CGMissionAccept / Continue / Submit / Abandon / Check) to the CY layouts, ports
// GCScriptCommand 1/3/4/5 (mission info, demand, continue, tips) and GCMissionList / Add / Modify / Remove /
// HaveDoneFlag into the 0.85 data pools, raises the CY tracking events (OPEN_MISSION_TRACK, UPDATE_MISSION_TRACK,
// NEW_MISSION) and registers the Lua host functions of Quest.lua / MissionTrack.lua / QuestLog.lua (CysHost_Quest).
#include <cstdint>
#include <memory>

class Packet;
namespace pg { class Packet; }
struct _MISSION_INFO;

namespace CysQuestNet
{
    struct Counters
    {
        unsigned missionInfos, missionDemands, missionContinues, missionTips;
        unsigned missionLists, missionAdds, missionModifies, missionRemoves, doneFlags;
        unsigned accepts, continues, submits, abandons;
    };
    // Event-list options of the last GCScriptCommand 0 (seen before CysInventoryNet ports it): script id and index of
    // the first option with `script` (any script when script < 0) and one of the given types (type < 0 = any).
    bool FindOption(int script, int type, int& outScript, int& outIndex);
    // Option with exactly this index (station transfers: 1001 Lac Duong, 1010 Dai Ly); its script id.
    bool FindOptionByIndex(int index, int& outScript);
    // nullptr when the legacy packet is not a mission request.
    std::unique_ptr<pg::Packet> Translate(Packet* legacy);
    bool IsWorldPacket(uint16_t id);
    bool Dispatch(const pg::Packet& packet);
    void RegisterHost();
    Counters Get();
    bool Piercing(bool defence,uint32_t& value);
    // Own mission slot -> mission id / script id (-1 when empty); true when mission `id` has its done flag.
    int SlotMission(int slot);
    int SlotScript(int slot);
    bool MissionDone(int missionId);
    // Called after GetPlayerMission_Description parsed the CY descriptor of `scriptId`: GBK -> UTF-8 and the
    // Vietnamese names of CysHost_QuestText_vi.inc.
    void LocalizeMission(int scriptId, _MISSION_INFO& info);
    // Joined event-list texts longer than the 255-byte ScriptEventItem (CysEventTextJoin): set by CysInventoryNet for
    // item `index` of the current list, read by DataPool::GetNPCEventList_Item; nullptr when the item is not long.
    void ClearEventListTexts();
    void SetEventListText(int index, const char* text);
    const char* EventListText(int index);
}
