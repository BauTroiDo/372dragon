#pragma once
// CYS: offline replay data source for one modern client session (CYS_WORLD_REPLAY).
// A replay::Session holds one PGWORLD1 fixture (Tests/net/make_world_fixture.py:
// the first world session of the Aug-27 capture, 83 C->S and 741 S->C frames) and
// hands out two StreamFactory objects:
//   * the login stream answers CLConnect/CLAskLogin/CLAskCharList/CLAskCharLogin
//     locally (any account, one character, game hand-off to 127.0.0.1:gamePort);
//   * the game stream answers CGConnect with the recorded KeyExchange+GCConnect,
//     CGEnterScene with the recorded GCEnterScene, then paces the remaining
//     recorded S->C frames, counts CGHeartBeat, echoes CGCharMove as the own
//     GCCharMove broadcast, answers CGAskQuit with GCRetAskQuit(0) and closes.
// Every other client packet is counted and logged by id/size; nothing is sent to
// any socket. Diagnostics never carry bodies, keys or the login text.
// No engine dependency: Game.exe (CysWorldReplay.cpp) and the tests share it.

#include "NetStream.h"
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace cys { namespace net { namespace replay {

struct Record {
    bool c2s = false;
    uint16_t id = 0, idx = 0;
    std::vector<uint8_t> body;
};

// PGWORLD1: 8-byte magic, then {u8 c2s, u16 id, u16 idx, u32 size, body} records.
// The S->C stream must begin with KeyExchange (67), GCConnect (456), GCEnterScene
// (1764) and the C->S stream with CGConnect (49); otherwise `error` names the reason.
bool LoadFixture(const std::string& path, std::vector<Record>& out, std::string& error);











struct ScenarioStep {
    uint32_t atMs = 0;
    std::string kind, name;
    uint32_t obj = 0, other = 0, race = 0, level = 1, logic = 0;
    int32_t value = 0, target = -1;
    float x = 0, z = 0, dir = 0;
    std::vector<uint16_t> ids;
};
struct Scenario {
    uint16_t sceneId = 0;
    float x = 0, z = 0;
    uint32_t myObj = 0;
    std::string selfName;            // scene ... name=<own character name>
    std::vector<ScenarioStep> steps; // sorted by atMs (stable)
};
bool LoadScenario(const std::string& path, Scenario& out, std::string& error);

struct Options {
    uint32_t frameGapMs = 20;      // pacing of the world frames after GCEnterScene; 0 = all at once
    uint32_t guid = 200001;        // the one character of the replayed account
    std::string nickname = "CYTest00";
    uint16_t gamePort = 15734;     // LCRetCharLogin endpoint (must equal the approved game port)
    uint32_t key = 0x52455041;     // any value; CGConnect must echo it
    int32_t sex = 1, level = 15, face = 100, hair = 5, outfit = 0, portrait = 13, sceneId = 2, menpai = 0;
    bool moveEcho = true;          // CGCharMove -> GCCharMove of the own object (as the scene broadcast)
    // CYS-CORE: synthetic core-loop responder (chat echo, skill -> damage -> death -> drop box -> loot -> bag).
    // Frame layouts follow the private server (misc.lua/item.lua/social.lua bos); positions come from the
    // recorded GCNewMonster frames of the fixture.
    bool coreLoop = false;
    uint32_t coreItemIndex = 30001011; // CommonItem 鸳鸯补血丹 (stackable potion) present in the CY client table
    uint32_t coreHitsToKill = 3;       // CGCharUseSkill hits until hp_percent 0 + GCNewItemBox
    int32_t coreDamage = -7;           // GCDetailHealsAndDamages hp_modification per hit
    uint32_t coreDeleteDelayMs = 1500; // GCDelObject of the corpse after the death frames (die animation)
    // CYS-QUEST: synthetic NPC dialogue / mission responder (CGCharDefaultEvent, CGEventRequest, CGAskMissionList,
    // CGMissionAccept / Continue / Submit) with the private server's GCScriptCommand / GCMission* layouts.
    bool questLoop = false;
    // CYS-SFX: when scenario.steps is not empty the recorded world frames are skipped; GCConnect/GCEnterScene are
    // re-encoded with the scenario scene, position and own object id, then the steps are delivered at their times.
    Scenario scenario;
    uint32_t scenarioDelayMs = 0; // added to every step time (slow scene loads)
};

struct Stats {
    uint32_t loginTx = 0, loginRx = 0, gameTx = 0, gameRx = 0;
    uint32_t heartbeats = 0, moves = 0, moveEchoes = 0, quits = 0, unexpected = 0, protocolErrors = 0;
    // CYS-CORE responder counters (client packets answered)
    uint32_t coreLocks = 0, coreSkills = 0, coreKills = 0, coreBoxOpens = 0, corePicks = 0, coreChats = 0;
    uint32_t coreBagAsks = 0, coreSkillLists = 0, coreDieResults = 0, coreUnknownTargets = 0;
    uint32_t worldTotal = 0, worldSent = 0;     // recorded S->C frames after GCEnterScene
    uint32_t gameSockets = 0;
    uint16_t firstGameIdx = 0, lastGameIdx = 0;
    bool gameIdxContiguous = true, connectFirst = false;
    bool loginGranted = false, entered = false, finished = false, quitAcked = false, closed = false;
    uint32_t myObjectId = 0;
    // CYS-SFX: scenario progress (tags count up in delivery order; lastTagMs = ms after GCEnterScene)
    uint32_t scenarioSteps = 0, scenarioSent = 0, scenarioTags = 0, lastTagMs = 0;
    std::string lastTag;
};

class Session {
public:
    Session(std::vector<Record> records, const Options& options);
    ~Session();
    std::shared_ptr<StreamFactory> loginFactory();
    std::shared_ptr<StreamFactory> gameFactory();
    Stats stats() const;
    // Bounded fixed-text diagnostics (ids, sizes, counters) for the owner thread.
    size_t drainLog(std::vector<std::string>& out);
    const std::vector<Record>& records() const;
    // Ids of the recorded S->C frames in delivery order (67, 456, 1764, world...).
    std::vector<uint16_t> serverIds() const;

    struct Impl;
private:
    std::shared_ptr<Impl> impl_;
};

}}} // namespace cys::net::replay
