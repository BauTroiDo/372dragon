// World-session tests: charlogin hand-off, game socket state machine, strict decode,
// sequence continuity and the resulting world model. Offline only: loopback listeners
// owned by run_world_session_tests.py and a capture fixture kept under Build.
// Reports carry counters and IDs only, never packet bodies or keys.
#include "GameClient.h"
#include "LoginClient.h"
#include "LoginProbe.h"
#include "ReplayStream.h"
#include "ServerProfile.h"
#include "WorldModel.h"
#include "PgFactory.h"
#include "PgPackets_combat.h"
#include "PgPackets_core.h"
#include "PgPackets_item.h"   // CYS-CORE
#include "PgPackets_login.h"
#include "PgPackets_misc.h"
#include "PgPackets_mission.h"
#include "PgPackets_movement.h"
#include "PgPackets_social.h" // CYS-CORE
#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstring>
#include <fcntl.h>
#include <fstream>
#include <io.h>
#include <random>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

using namespace cys::net;
using Clock = std::chrono::steady_clock;
static unsigned checks = 0;
static void check(bool value, const char* name) {
    if (!value) throw std::runtime_error(name);
    ++checks;
    std::printf("PASS %s\n", name);
}
static std::vector<uint8_t> frameOf(const pg::Packet& packet, uint16_t index = 0) {
    std::vector<uint8_t> out;
    if (!pg::encodeFrame(packet, index, out)) throw std::runtime_error("encode fixture");
    return out;
}
static std::vector<uint8_t> bodyOf(const pg::Packet& packet) {
    std::vector<uint8_t> out;
    pg::encodeBody(packet, out);
    return out;
}
static void append(std::vector<uint8_t>& out, const std::vector<uint8_t>& more) { out.insert(out.end(), more.begin(), more.end()); }

// ------------------------------------------------------------------ synthetic fixtures (stdout)
static void monster(std::vector<uint8_t>& out, uint32_t id, float x, float y) {
    pg::GCNewMonster p; p.m_objID = id; p.guid = 1001; p.worldPos_x = x; p.worldPos_y = y; p.dir = 1.5f; p.speed = 3.5f;
    append(out, frameOf(p));
}
static int fixture(const std::string& kind) {
    _setmode(_fileno(stdout), _O_BINARY);
    std::vector<uint8_t> out;
    if (kind == "list1") {
        pg::LCRetCharList list;
        list.set_uuid("unit-world");
        pg::LCRetCharList::E_charlist role;
        role.guid = 200001; role.sex = 1; role.set_nickname("CYWorld00"); role.level = 15; role.sceneid = 2;
        list.charlist.push_back(role);
        list.charnum = 1;
        out = frameOf(list);
    } else if (kind == "objects") {
        monster(out, 7001, 160.0f, 150.0f);
        monster(out, 7003, 170.0f, 151.0f);
        pg::GCNewPlayer player; player.m_objID = 7002; player.m_posWorld_x = 158; player.m_posWorld_y = 152;
        player.m_fDir = 0.5f; player.m_fMoveSpeed = 4.0f; player.m_wEquipVer = 3;
        append(out, frameOf(player));
        pg::GCDelObject remove; remove.m_objID = 7001; remove.m_idScene = 2;
        append(out, frameOf(remove));
        pg::GCDelObject foreign; foreign.m_objID = 7003; foreign.m_idScene = 99;
        append(out, frameOf(foreign));
        pg::GCCharMove move; move.m_objID = 7002; move.start_time = 10; move.handleID = 4; move.flag = 0;
        pg::GCCharMove::E_path node; node.x = 159; node.y = 153;
        move.path.push_back(node); move.size = 1;
        append(out, frameOf(move));
        move.m_objID = 7999;
        append(out, frameOf(move));
    } else if (kind.compare(0, 5, "core-") == 0) {
        // CYS-CORE: synthetic server replies of the core loop (private-server bos layouts encoded by ProtocolGen),
        // consumed by run_world_session_tests.py (loopback + bot scenarios). Own object MY1 = 5001, monster 7003.
        const uint32_t my = 5001, monster = 7003, box = 0x00FF0001;
        auto item = []() {
            pg::ItemInfo_bos it; it.guid.world = 1; it.guid.server = 1; it.guid.mask = 0; it.guid.series = 4242;
            it.item_index = 30001011; return it;
        };
        auto hpFrame = [&](uint8_t percent) {
            pg::GCCharBaseAttrib a; a.m_objID = monster; a.data_id = 0; a.new_flags.fill(0); a.new_flags[0] = 0x10; a.hp_percent = percent;
            return frameOf(a);
        };
        if (kind == "core-skill" || kind == "core-kill") {
            pg::GCCharSkill_Send send; send.m_objID = my; send.logic_count = 7; send.skill_id = 0; send.target_id = monster;
            send.target_pos_x = 170; send.target_pos_y = 151;
            append(out, frameOf(send));
            pg::GCTargetListAndHitFlags hit; hit.data_type = 0; hit.m_objID = my; hit.logic_count = 7; hit.skill_or_special_obj_id = 0;
            hit.target_pos_x = 170; hit.target_pos_y = 151; hit.target_list.push_back(monster); hit.size = 1;
            append(out, frameOf(hit));
            pg::GCDetailHealsAndDamages dmg; dmg.dirty_flags = 1; dmg.reciver = monster; dmg.sender = static_cast<int32_t>(my);
            dmg.logic_count = 7; dmg.hp_modification = -7; dmg.is_critical_hit = 0;
            append(out, frameOf(dmg));
            append(out, hpFrame(kind == "core-kill" ? 0 : 66));
            if (kind == "core-kill") {
                pg::GCNewItemBox drop; drop.m_objID = box; drop.owner_guid = 200001; drop.monster_id = static_cast<int32_t>(monster);
                drop.world_pos_x = 170; drop.world_pos_y = 151; drop.item_box_type = -1; drop.unknow_7 = 0;
                append(out, frameOf(drop));
                pg::GCDelObject corpse; corpse.m_objID = monster; corpse.m_idScene = 2;
                append(out, frameOf(corpse));
            }
        } else if (kind == "core-box") {
            pg::GCBoxItemList list; list.m_objID = box; list.item_box_type = -1; list.item_list.push_back(item()); list.size = 1;
            append(out, frameOf(list));
        } else if (kind == "core-pick") {
            pg::GCPickResult res; res.m_objID = box; res.item_box_guid = item().guid; res.result = 0; res.bag_index = 3;
            res.item_box_type = -1; res.item_guid = item().guid;
            append(out, frameOf(res));
            pg::GCItemInfo info; info.bagIndex = 3; info.unknow_1 = 0; info.item = item(); info.askid = 0; info.bag_type = 0;
            append(out, frameOf(info));
            pg::GCDelObject gone; gone.m_objID = box; gone.m_idScene = 2;
            append(out, frameOf(gone));
        } else if (kind == "core-bag") {
            pg::GCMyBagList list; list.m_Mode = 0;
            pg::GCMyBagList::E_list entry; entry.index = 3; entry.guid = item().guid; entry.item_index = 30001011; entry.count = 1;
            list.list.push_back(entry); list.m_AskCount = 1;
            append(out, frameOf(list));
        } else if (kind == "core-skills") {
            pg::GCDetailSkillList list; list.m_objID = my; list.m_aSkill.push_back(0); list.m_aSkill.push_back(101); list.m_wNumSkill = 2;
            append(out, frameOf(list));
        } else if (kind == "core-chat") {
            pg::GCChat chat; chat.ChatType = 0; chat.set_Contex("unit-chat-echo"); chat.set_SourceName("CYWorld00");
            chat.unknow_3 = 1; chat.Sourceid = my; chat.unknow_10 = 0;
            append(out, frameOf(chat));
        } else if (kind == "core-die") {
            pg::GCPlayerDie die; die.new_player = 0; die.can_relive = 1; die.utime = 30000;
            append(out, frameOf(die));
        } else if (kind == "core-relive") {
            pg::GCPlayerRelive relive;
            append(out, frameOf(relive));
        } else {
            return 3;
        }
    } else {
        return 3;
    }
    std::fwrite(out.data(), 1, out.size(), stdout);
    return 0;
}

// ------------------------------------------------------------------ PGWORLD1 capture fixture
struct Recorded { bool c2s; uint16_t id, idx; std::vector<uint8_t> body; };
static uint32_t little(const uint8_t* p, unsigned n) { uint32_t v = 0; for (unsigned i = 0; i < n; ++i) v |= uint32_t(p[i]) << (8 * i); return v; }
static std::vector<Recorded> loadFixture(const char* path) {
    std::ifstream in(path, std::ios::binary);
    char magic[8]{}; in.read(magic, 8);
    if (!in || std::string(magic, 8) != "PGWORLD1") throw std::runtime_error("world fixture format");
    std::vector<Recorded> out;
    for (;;) {
        uint8_t head[9]{}; in.read(reinterpret_cast<char*>(head), 9);
        if (in.gcount() == 0) break;
        if (in.gcount() != 9) throw std::runtime_error("partial fixture record");
        Recorded r; r.c2s = head[0] != 0; r.id = uint16_t(little(head + 1, 2)); r.idx = uint16_t(little(head + 3, 2));
        const uint32_t size = little(head + 5, 4);
        if (size > pg::kMaxBody) throw std::runtime_error("fixture body cap");
        r.body.resize(size);
        in.read(reinterpret_cast<char*>(r.body.data()), size);
        if (static_cast<uint32_t>(in.gcount()) != size) throw std::runtime_error("partial fixture body");
        out.push_back(std::move(r));
    }
    return out;
}

static void printWorld(const char* label, const WorldModel& world) {
    const auto& s = world.stats();
    std::printf("%s my=%u scene=%u res=%u objects=%zu created=%u refreshed=%u deleted=%u unknown_deletes=%u "
                "foreign_deletes=%u moves=%u self_moves=%u unknown_moves=%u packets=%u enters=%u connects=%u "
                "transfers=%u base_attribs=%u quit_acks=%u\n",
                label, world.myObjectId(), world.sceneId(), world.clientRes(), world.objects().size(), s.created,
                s.refreshed, s.deleted, s.unknownDeletes, s.foreignSceneDeletes, s.moves, s.selfMoves, s.unknownMoves,
                s.packets, s.enters, s.connects, s.transfers, s.baseAttribs, s.quitAcks);
}

// Pure replay of the capture's first world session through strict decode and the
// world model, plus byte checks of this client's CGConnect/CGEnterScene layouts
// against the real client's frames (key and GUID excluded).
static void replayModel(const char* path) {
    const auto records = loadFixture(path);
    WorldModel world;
    world.onConnected(1);
    size_t s2c = 0, c2s = 0;
    for (const auto& r : records) {
        pg::DecodeResult result;
        auto packet = pg::decodePacket(pg::Proto::Game, r.id, r.body.data(), r.body.size(), &result, true);
        if (!packet) throw std::runtime_error("fixture strict decode failed");
        if (r.c2s) { ++c2s; continue; }
        ++s2c;
        const char* reason = "";
        if (!world.apply(*packet, &reason)) throw std::runtime_error(reason);
    }
    check(s2c > 700 && c2s > 70, "fixture holds one full world session in both directions");
    // Sequence of the real client: game C2S continues the login counter (7F00...).
    uint16_t expected = 0x7f00;
    bool contiguous = true, firstConnect = false, oneEnter = true;
    size_t enters = 0;
    for (const auto& r : records) {
        if (!r.c2s) continue;
        if (!firstConnect) firstConnect = r.id == pg::CGConnect::PACKET_ID && r.idx == 0x7f00;
        contiguous = contiguous && r.idx == expected;
        expected = static_cast<uint16_t>(expected + 0x100);
        if (r.id == pg::CGEnterScene::PACKET_ID) ++enters;
    }
    oneEnter = enters == 1;
    check(firstConnect && contiguous, "capture: first game frame is CGConnect at 7F00 and idx stays contiguous");
    check(oneEnter, "capture: exactly one CGEnterScene per game socket");
    // Our encodings against the real client's (non-secret fields).
    const Recorded* realConnect = nullptr; const Recorded* realEnter = nullptr;
    for (const auto& r : records) {
        if (r.c2s && r.id == pg::CGConnect::PACKET_ID && !realConnect) realConnect = &r;
        if (r.c2s && r.id == pg::CGEnterScene::PACKET_ID && !realEnter) realEnter = &r;
    }
    pg::CGConnect ours; ours.key = 1; ours.guid = 2; ours.set_version("tlbb");
    const auto body = bodyOf(ours);
    check(realConnect && realConnect->body.size() == body.size() &&
          std::memcmp(realConnect->body.data() + 8, body.data() + 8, body.size() - 8) == 0,
          "CGConnect matches the real client except key and GUID");
    WorldModel fresh; fresh.onConnected(1);
    for (const auto& r : records) {
        if (r.c2s || r.id != pg::GCConnect::PACKET_ID) continue;
        auto packet = pg::decodePacket(pg::Proto::Game, r.id, r.body.data(), r.body.size(), nullptr, true);
        fresh.apply(*packet);
        break;
    }
    const auto enter = bodyOf(*fresh.makeEnterScene());
    check(realEnter && realEnter->body == enter, "CGEnterScene equals the real client's frame byte for byte");
    printWorld("MODEL", world);
}

// ------------------------------------------------------------------ replay data source (no sockets)
// The offline replay source of CYS_WORLD_REPLAY: LoginClient and GameClient run
// unchanged on the injected streams. Checks: any account is granted, the list holds
// CYTest00/200001, the ticket continues the sequence at 7F00, CGConnect is the first
// game frame and idx stays contiguous, every recorded S->C frame arrives in the
// recorded order, a CGCharMove is echoed, CGAskQuit is acknowledged with flag 0 and
// the stream closes (QuitComplete).
static void replaySource(const char* path) {
    using cys::net::replay::Record;
    using cys::net::replay::Session;
    std::vector<Record> records;
    std::string error;
    check(cys::net::replay::LoadFixture(path, records, error), "replay fixture loads and has the expected shape");
    cys::net::replay::Options replayOptions;
    replayOptions.frameGapMs = 1;
    Session session(std::move(records), replayOptions);
    const std::vector<uint16_t> serverIds = session.serverIds();
    check(serverIds.size() > 700 && serverIds[0] == pg::KeyExchange::PACKET_ID && serverIds[1] == pg::GCConnect::PACKET_ID &&
          serverIds[2] == pg::GCEnterScene::PACKET_ID, "replay session indexes the recorded S->C stream");

    LoginClient login;
    cys::net::Options loginOptions;
    loginOptions.mode = SessionMode::Interactive;
    loginOptions.approvedGamePort = 15734;
    loginOptions.streamFactory = session.loginFactory();
    Endpoint endpoint;
    endpoint.host = "127.0.0.1"; endpoint.port = 15733;
    check(login.start(endpoint, "anyaccount", "any-password", loginOptions), "login starts on the replay stream (any account)");
    std::unique_ptr<GameTicket> ticket;
    bool loginDone = false, loginFailed = false, listSeen = false;
    auto until = Clock::now() + std::chrono::seconds(10);
    while (!loginDone && Clock::now() < until) {
        login.pump([&](Event&& event) {
            if (event.type == EventType::CharacterList) {
                const auto* list = dynamic_cast<const pg::LCRetCharList*>(event.packet.get());
                check(list && list->charlist.size() == 1 && list->charlist[0].guid == 200001 &&
                      list->charlist[0].nickname_text() == "CYTest00", "replay list holds CYTest00 / GUID 200001");
                listSeen = true;
                check(login.requestCharacterLogin(200001), "character login requested for the replay GUID");
            } else if (event.type == EventType::CharacterLoginGranted) {
                ticket = std::move(event.ticket);
                loginDone = true;
            } else if (event.type == EventType::Error || event.type == EventType::Refused ||
                       event.type == EventType::Cancelled || event.type == EventType::CharacterLoginRefused) {
                loginFailed = true; loginDone = true;
            }
        });
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
    check(listSeen && !loginFailed && ticket && ticket->valid() && ticket->guid() == 200001 && ticket->nextTxIndex() == 0x7f00,
          "replay charlogin granted; the ticket continues the sequence at 7F00");
    check(login.pump([](Event&&) {}) == 0 && !login.active(), "login worker finished after the hand-off");

    GameClient game;
    GameOptions gameOptions;
    gameOptions.heartbeatIntervalMs = 300;
    gameOptions.approvedGamePort = 15734;
    gameOptions.streamFactory = session.gameFactory();
    check(game.start(std::move(*ticket), gameOptions), "game client starts on the replay stream");
    WorldModel world;
    std::vector<uint16_t> received;
    GameEvent terminal;
    bool done = false, moveSent = false, quitAsked = false;
    Clock::time_point moveAt;
    const size_t expected = serverIds.size();
    until = Clock::now() + std::chrono::seconds(40);
    while (!done && Clock::now() < until) {
        game.pump([&](GameEvent&& event) {
            switch (event.type) {
            case GameEventType::Connected:
                world.onConnected(event.generation);
                break;
            case GameEventType::Packet: {
                received.push_back(event.packetId);
                const char* reason = "";
                if (!world.apply(*event.packet, &reason)) throw std::runtime_error(reason);
                if (event.packetId == pg::GCConnect::PACKET_ID)
                    check(game.send(world.makeEnterScene()), "CGEnterScene sent after the recorded GCConnect");
                break;
            }
            default:
                terminal = std::move(event);
                done = true;
                break;
            }
        }, 64);
        const auto now = Clock::now();
        if (!moveSent && received.size() >= expected) {
            moveSent = true; moveAt = now;
            check(game.send(world.makeMove(world.myX() + 1, world.myY() + 1)), "move sent after the replayed world");
        } else if (moveSent && !quitAsked && now - moveAt > std::chrono::milliseconds(400)) {
            quitAsked = true;
            check(game.requestQuit(), "quit requested after the replayed world");
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
    check(done, "terminal game event delivered by the replay stream");
    check(received.size() == expected + 2, "every recorded frame, the move echo and the quit ack were delivered");
    check(std::equal(serverIds.begin(), serverIds.end(), received.begin()), "recorded S->C frames arrive in the recorded order");
    check(received[expected] == pg::GCCharMove::PACKET_ID && received[expected + 1] == pg::GCRetAskQuit::PACKET_ID,
          "the move echo follows the world stream and the quit ack is last");
    check(terminal.type == GameEventType::QuitComplete && terminal.quitFlag == 0, "clean quit acknowledged and closed");
    const auto& c = terminal.counters;
    check(c.decodeFailures == 0 && c.heartbeats >= 1 && c.socketClosed, "every frame decoded strictly; heartbeats ran");
    const cys::net::replay::Stats st = session.stats();
    check(st.connectFirst && st.firstGameIdx == 0x7f00 && st.gameIdxContiguous &&
          st.lastGameIdx == static_cast<uint16_t>(c.nextTxIndex - 0x100), "CGConnect first at 7F00 and idx contiguous on the replay stream");
    check(st.loginGranted && st.entered && st.finished && st.quitAcked && st.closed && st.protocolErrors == 0 &&
          st.moves == 1 && st.moveEchoes == 1 && st.quits == 1 && st.heartbeats == c.heartbeats &&
          st.worldSent == st.worldTotal && st.gameTx == c.txFrames, "replay counters agree with the client counters");
    check(world.stats().selfMoves >= 1 && world.myObjectId() == st.myObjectId, "the move echo moved the own object");
    std::printf("REPLAYSRC login_tx=%u login_rx=%u game_tx=%u game_rx=%u heartbeats=%u moves=%u echoes=%u quits=%u unexpected=%u "
                "protocol_errors=%u world=%u/%u first_idx=%04x last_idx=%04x contiguous=%d next_idx=%04x my_obj=%u\n",
                st.loginTx, st.loginRx, st.gameTx, st.gameRx, st.heartbeats, st.moves, st.moveEchoes, st.quits, st.unexpected,
                st.protocolErrors, st.worldSent, st.worldTotal, st.firstGameIdx, st.lastGameIdx, st.gameIdxContiguous ? 1 : 0,
                c.nextTxIndex, st.myObjectId);
    printWorld("STATE", world);
    std::vector<std::string> lines;
    session.drainLog(lines);
    for (const auto& line : lines) std::printf("LOG %s\n", line.c_str());
}

// ------------------------------------------------------------------ CYS-CORE: replay source + core-loop responder
// Same session as replaySource, then the core loop against the synthetic responder: the target is the recorded
// monster nearest to the own object; three CGCharUseSkill kill it, the drop box is opened and looted, a chat is
// echoed, the bag and the skill list are listed. Checks the WorldModel counters and the responder counters.
static void replayCore(const char* path) {
    using cys::net::replay::Record;
    using cys::net::replay::Session;
    std::vector<Record> records;
    std::string error;
    check(cys::net::replay::LoadFixture(path, records, error), "replay fixture loads (core)");
    cys::net::replay::Options replayOptions;
    replayOptions.frameGapMs = 0;
    replayOptions.coreLoop = true;
    replayOptions.coreDeleteDelayMs = 200;
    Session session(std::move(records), replayOptions);
    LoginClient login;
    cys::net::Options loginOptions;
    loginOptions.mode = SessionMode::Interactive;
    loginOptions.approvedGamePort = 15734;
    loginOptions.streamFactory = session.loginFactory();
    Endpoint endpoint; endpoint.host = "127.0.0.1"; endpoint.port = 15733;
    check(login.start(endpoint, "anyaccount", "any-password", loginOptions), "login starts on the replay stream (core)");
    std::unique_ptr<GameTicket> ticket;
    bool loginDone = false;
    auto until = Clock::now() + std::chrono::seconds(10);
    while (!loginDone && Clock::now() < until) {
        login.pump([&](Event&& event) {
            if (event.type == EventType::CharacterList) check(login.requestCharacterLogin(200001), "character login requested (core)");
            else if (event.type == EventType::CharacterLoginGranted) { ticket = std::move(event.ticket); loginDone = true; }
            else if (event.type != EventType::Connected && event.type != EventType::Authenticated) loginDone = true;
        });
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
    check(ticket && ticket->valid(), "replay charlogin granted (core)");
    GameClient game;
    GameOptions gameOptions;
    gameOptions.heartbeatIntervalMs = 300;
    gameOptions.approvedGamePort = 15734;
    gameOptions.streamFactory = session.gameFactory();
    check(game.start(std::move(*ticket), gameOptions), "game client starts on the replay stream (core)");
    WorldModel world;
    GameEvent terminal;
    bool done = false, quitAsked = false;
    int step = 0;
    uint32_t target = 0, hits = 0, chatsBefore = 0;
    size_t received = 0;
    const size_t expected = session.serverIds().size();
    Clock::time_point stepAt = Clock::now();
    until = Clock::now() + std::chrono::seconds(40);
    while (!done && Clock::now() < until) {
        game.pump([&](GameEvent&& event) {
            switch (event.type) {
            case GameEventType::Connected: world.onConnected(event.generation); break;
            case GameEventType::Packet: {
                ++received;
                const char* reason = "";
                if (!world.apply(*event.packet, &reason)) throw std::runtime_error(reason);
                if (event.packetId == pg::GCConnect::PACKET_ID) check(game.send(world.makeEnterScene()), "CGEnterScene sent (core)");
                break;
            }
            default: terminal = std::move(event); done = true; break;
            }
        }, 64);
        const auto& st = world.stats();
        const bool streamDone = received >= expected;
        switch (step) {
        case 0:
            if (streamDone) {
                float distance = 0;
                target = world.nearestMonster(&distance);
                check(target != 0, "a recorded monster is in view after the stream");
                check(game.send(world.makeAskDetailSkillList()), "core: CGAskDetailSkillList");
                check(game.send(world.makeLockTarget(static_cast<int32_t>(target))), "core: CGLockTarget");
                check(game.send(world.makeUseSkill(0, static_cast<int32_t>(target))), "core: CGCharUseSkill 1");
                hits = 1; step = 1; stepAt = Clock::now();
            }
            break;
        case 1:
            if (st.selfSkillSends == hits && st.damageDealt == hits && hits < 3) {
                check(game.send(world.makeUseSkill(0, static_cast<int32_t>(target))), "core: CGCharUseSkill again");
                ++hits;
            } else if (st.targetDeaths == 1 && st.itemBoxes == 1 && world.objects().count(target) == 0) {
                const uint32_t box = world.nearestItemBox(1e9f);
                check(box != 0, "core: drop box created at the corpse");
                check(game.send(world.makeOpenItemBox(box)), "core: CGOpenItemBox");
                step = 2;
            }
            break;
        case 2:
            if (st.boxLists == 1) {
                check(world.boxItems().size() == 1 && world.boxItems()[0].itemIndex == 30001011, "core: GCBoxItemList holds the potion");
                check(game.send(world.makePickBoxItem(world.openBoxId(), world.boxItems()[0].guid)), "core: CGPickBoxItem");
                step = 3;
            }
            break;
        case 3:
            if (st.picksOk == 1 && st.itemInfos == 1 && world.itemBoxes().empty()) {
                check(world.bag().size() == 1, "core: GCItemInfo put the potion into the bag");
                chatsBefore = st.chats; // the Aug-27 fixture already carries system GCChat frames
                check(game.send(world.makeChat(0, "replay-core-chat")), "core: CGChat");
                step = 4;
            }
            break;
        case 4:
            if (st.chats > chatsBefore) {
                check(world.lastChat().text == "replay-core-chat" && world.lastChat().source == "CYTest00", "core: GCChat echo");
                check(game.send(world.makeAskMyBagList()), "core: CGAskMyBagList");
                step = 5;
            }
            break;
        case 5:
            if (st.bagLists == 1 && st.skillLists == 1 && !quitAsked) {
                check(world.bag().size() == 1 && world.skills().size() == 1 && world.skills()[0] == 0, "core: bag list and skill list");
                quitAsked = true;
                check(game.requestQuit(), "core: quit");
                step = 6;
            }
            break;
        default: break;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
    std::printf("REPLAYCORE-TERMINAL done=%d step=%d type=%d error=%s packet=%u field=%s offset=%zu message=%s decode_failures=%u\n",
                done ? 1 : 0, step, static_cast<int>(terminal.type), ErrorCodeName(terminal.error), terminal.packetId, terminal.decodeField,
                terminal.errorOffset, terminal.message, terminal.counters.decodeFailures);
    for (const auto& entry : world.packetCounts()) std::printf("COUNT id=%u n=%u\n", entry.first, entry.second);
    std::printf("COUNT rx=%u tx=%u responder_rx=%u\n", terminal.counters.rxFrames, terminal.counters.txFrames, session.stats().gameRx);
    {
        std::vector<std::string> early;
        session.drainLog(early);
        for (const auto& line : early) std::printf("LOG %s\n", line.c_str());
    }
    check(done && step == 6 && terminal.type == GameEventType::QuitComplete && terminal.quitFlag == 0, "core: clean quit after the loop");
    const cys::net::replay::Stats rs = session.stats();
    check(rs.coreLocks == 1 && rs.coreSkills == 3 && rs.coreKills == 1 && rs.coreBoxOpens == 1 && rs.corePicks == 1 &&
          rs.coreChats == 1 && rs.coreBagAsks == 1 && rs.coreSkillLists == 1 && rs.coreUnknownTargets == 0 && rs.protocolErrors == 0,
          "core: responder counters");
    check(terminal.counters.decodeFailures == 0, "core: every synthetic frame decoded strictly");
    const auto& st = world.stats();
    std::printf("REPLAYCORE target=%u skills=%u kills=%u boxes=%u picks=%u chats=%u bag=%zu skills_listed=%zu damage_dealt=%u "
                "hp_updates=%u deletes=%u decode_failures=%u\n", target, rs.coreSkills, rs.coreKills, rs.coreBoxOpens, rs.corePicks,
                rs.coreChats, world.bag().size(), world.skills().size(), st.damageDealt, st.hpUpdates, st.deleted,
                terminal.counters.decodeFailures);
    std::vector<std::string> lines;
    session.drainLog(lines);
    for (const auto& line : lines) if (line.find("core") != std::string::npos || line.find("CG") != std::string::npos) std::printf("LOG %s\n", line.c_str());
}

// ------------------------------------------------------------------ unit tests (no sockets)
// CYS-QUEST: NPC dialogue / mission packets of the private server (mission.lua / combat.lua bos layouts) through the
// strict codec and the world model: event list, mission info (1), demand (3), continue (4), mission list / add /
// remove / done flag, and the outbound mission requests.
static void questModel() {
    WorldModel world;
    auto feed = [&](const pg::Packet& packet) {
        const std::vector<uint8_t> body = bodyOf(packet);
        pg::DecodeResult result;
        auto decoded = pg::decodePacket(pg::Proto::Game, packet.packetId(), body.data(), body.size(), &result, true);
        if (!decoded) throw std::runtime_error("quest packet strict decode failed");
        world.apply(*decoded);
    };
    pg::GCScriptCommand menu; menu.m_nCmdID = 0; menu.target_id = 141;
    pg::GCScriptCommand::E_event text; text.flag = 2; text.set_str("Tri\xe1\xbb\x87u Thi\xc3\xaan S\xc6\xb0");
    pg::GCScriptCommand::E_event option; option.flag = 1; option.index = 1; option.type = 2; option.script_id = 210262; option.split = -1;
    option.set_str_2("S\xc6\xa1 nh\xe1\xba\xadp giang h\xe1\xbb\x93");
    menu.event.push_back(text); menu.event.push_back(option); menu.size = 2;
    feed(menu);
    check(world.stats().scriptEventLists == 1 && world.scriptTexts() == 1 && world.scriptEvents().size() == 1 &&
          world.scriptEvents()[0].scriptId == 210262 && world.scriptEvents()[0].type == 2, "quest: event list text + mission option");
    pg::GCScriptCommand info; info.m_nCmdID = 1; info.target_id_2 = 141; info.m_objID = 210266; info.m_idMission = 1417;
    pg::GCScriptCommand::E_event_2 line; line.set_str("Ph\xc3\xa1o hoa m\xe1\xbb\xabng l\xe1\xbb\x85");
    info.event_2.push_back(line); info.size = 1; info.m_yBonusCount = 0;
    feed(info);
    check(world.stats().missionInfos == 1 && world.lastMissionDialog().cmd == 1 && world.lastMissionDialog().script == 210266 &&
          world.lastMissionDialog().mission == 1417 && world.lastMissionDialog().npc == 141 && world.lastMissionDialog().texts == 1,
          "quest: GCScriptCommand 1 mission info");
    pg::GCScriptCommand demand; demand.m_nCmdID = 3; demand.target_id_2 = 141; demand.m_objID_2 = 210262; demand.m_idMission_2 = 1400;
    demand.done = 1; demand.event_3.push_back(pg::GCScriptCommand::E_event_3()); demand.event_3[0].set_str("#{XSRW_100111_2}");
    demand.size = 1; demand.m_yDemandCount = 0;
    feed(demand);
    check(world.stats().missionDemands == 1 && world.lastMissionDialog().cmd == 3 && world.lastMissionDialog().done == 1 &&
          world.lastMissionDialog().mission == 1400, "quest: GCScriptCommand 3 demand done");
    pg::GCScriptCommand cont; cont.m_nCmdID = 4; cont.target_id = 141; cont.m_objID = 210200; cont.m_idMission = 1401;
    pg::GCScriptCommand::E_event_2 cline; cline.set_str("V\xc5\xa9 kh\xc3\xad \xc4\x91\xe1\xba\xa7u ti\xc3\xaan");
    cont.event_4.push_back(cline); cont.size_2 = 1;
    pg::GCScriptCommand::E_items money; money.flag = 1; money.item_index = 1;
    pg::GCScriptCommand::E_items radio; radio.flag = 4; radio.count = 1; radio.item_index = 10101000;
    cont.items.push_back(money); cont.items.push_back(radio); cont.item_count = 2;
    feed(cont);
    check(world.stats().missionContinues == 1 && world.lastMissionDialog().bonus.size() == 2 &&
          world.lastMissionDialog().bonus[1].first == 4 && world.lastMissionDialog().bonus[1].second == 10101000,
          "quest: GCScriptCommand 4 continue with money + radio item");
    pg::GCMissionList list; list.m_objID = 5001; list.m_uMissionListFlags = 0x3; list.n_char_missions = 2;
    list.char_missions[0].id = 1400; list.char_missions[0].index = 210262; list.char_missions[0].params[0] = 1;
    list.char_missions[1].id = 1401; list.char_missions[1].index = 210200;
    list.mission_have_done_flags[1424 >> 5] = 1u << (1424 & 31);
    feed(list);
    check(world.missions().size() == 2 && world.findMission(1400) && world.findMission(1400)->script == 210262 &&
          world.findMission(1400)->params[0] == 1 && world.missionHaveDone(1424) && !world.missionHaveDone(1400),
          "quest: GCMissionList slots, params and done flags");
    pg::GCMissionAdd add; add.id = 1417; add.index = 210266; add.yFlag = 1; add.params.fill(0); add.params[0] = 0;
    feed(add);
    check(world.missions().size() == 3 && world.findMission(1417) && world.findMission(1417)->script == 210266, "quest: GCMissionAdd");
    pg::GCMissionRemove remove; remove.id = 1400;
    feed(remove);
    pg::GCMissionHaveDoneFlag done; done.mission_id = 1400; done.flag = 1;
    feed(done);
    check(world.missions().size() == 2 && !world.findMission(1400) && world.missionHaveDone(1400) &&
          world.stats().missionRemoves == 1 && world.stats().missionDoneFlags == 1, "quest: GCMissionRemove + GCMissionHaveDoneFlag");
    const auto accept = world.makeMissionAccept(141, 210266);
    const auto* a = dynamic_cast<const pg::CGMissionAccept*>(accept.get());
    check(a && a->m_idNPC == 141 && a->m_idScript == 210266 && bodyOf(*accept).size() == 12, "quest: CGMissionAccept layout (12 B)");
    const auto submit = world.makeMissionSubmit(141, 210200, 10101000);
    const auto* sb = dynamic_cast<const pg::CGMissionSubmit*>(submit.get());
    check(sb && sb->select_radio_id == 10101000 && bodyOf(*submit).size() == 16, "quest: CGMissionSubmit carries the radio item id");
    check(bodyOf(*world.makeMissionContinue(141, 210262)).size() == 12 && bodyOf(*world.makeAskMissionList()).size() == 4,
          "quest: CGMissionContinue / CGAskMissionList layouts");
}

static void unit() {
    questModel(); // CYS-QUEST
    cysbot::TxSequencer sequence(0x7f);
    check(sequence.next() == 0x7f00 && sequence.value() == 0x7f, "sequencer resumes from the login hand-off");
    for (int i = 0; i < 0x81; ++i) sequence.admitted();
    check(sequence.next() == 0x0000, "sequence wraps FF00 to 0000 like the server check");
    check(IsLoopbackLiteral("127.0.0.1") && IsLoopbackLiteral("127.3.2.1"), "loopback literals accepted");
    check(!IsLoopbackLiteral("10.0.0.5") && !IsLoopbackLiteral("localhost") && !IsLoopbackLiteral("::1") &&
          !IsLoopbackLiteral("127.0.0.1 ") && !IsLoopbackLiteral("") && !IsLoopbackLiteral("0x7f.1"),
          "non-loopback, names and malformed hosts rejected");
    // CYS: server profile allow-list (Patch/CysServerProfile.txt).
    check(IsPrivateLanLiteral("10.1.2.3") && IsPrivateLanLiteral("172.16.0.1") && IsPrivateLanLiteral("172.31.255.254") &&
          IsPrivateLanLiteral("192.168.1.109") && !IsPrivateLanLiteral("172.32.0.1") && !IsPrivateLanLiteral("8.8.8.8") &&
          !IsPrivateLanLiteral("127.0.0.1") && !IsPrivateLanLiteral("192.168.1.1 ") && !IsPrivateLanLiteral("lan"),
          "private LAN literals are 10/8, 172.16/12 and 192.168/16 only");
    check(IsHostAllowed("127.0.0.1", {}) && IsHostAllowed("127.0.0.2", {}) && !IsHostAllowed("192.168.1.109", {}),
          "empty allow-list keeps the loopback-only policy");
    check(IsHostAllowed("127.0.0.1", {"127.0.0.1"}) && !IsHostAllowed("127.0.0.2", {"127.0.0.1"}),
          "a listed allow-list matches exactly");
    check(!IsHostAllowed("8.8.8.8", {"8.8.8.8"}) && !ValidAllowedHosts({"8.8.8.8"}) && !ValidAllowedHosts({"localhost"}),
          "public addresses and names can never be allow-listed");
    check(!IsLocalInterfaceAddress("10.255.254.253") && !IsHostAllowed("10.255.254.253", {"10.255.254.253"}) &&
          IsLocalInterfaceAddress("127.0.0.1"), "a private LAN host must belong to this machine");
    {
        const std::vector<std::string> nine(9, "127.0.0.1");
        check(!ValidAllowedHosts(nine), "allow-list is bounded to 8 entries");
    }
    {
        const std::string good =
            "# comment\r\nVERSION 1\r\n[profile]\r\nname=cys-server\r\nlogin=127.0.0.1:15733\r\ngame_port=15734\r\n"
            "allowed_hosts=127.0.0.1\r\naccounts=test00, bot001\r\n\n; second\n[profile]\nname=lan\n"
            "login=192.168.1.109:5733\ngame_port=reply\nallowed_hosts=192.168.1.109,127.0.0.1\n";
        const ServerProfileParse parsed = ParseServerProfiles(good);
        check(parsed.ok && parsed.profiles.size() == 2, "two profiles parse (CRLF and LF)");
        const ServerProfile* cys = FindServerProfile(parsed.profiles, "127.0.0.1", 15733);
        check(cys && cys->name == "cys-server" && cys->gamePort == 15734 && !cys->gamePortFromReply &&
              cys->allowedHosts.size() == 1 && cys->accounts.size() == 2 && ProfileAllowsAccount(*cys, "bot001") &&
              !ProfileAllowsAccount(*cys, "chen00"), "profile fields and account filter");
        const ServerProfile* lan = FindServerProfile(parsed.profiles, "192.168.1.109", 5733);
        check(lan && lan->gamePortFromReply && lan->gamePort == 0 && lan->accounts.empty() && ProfileAllowsAccount(*lan, "any"),
              "game_port=reply and no account filter");
        check(!FindServerProfile(parsed.profiles, "127.0.0.1", 14400), "unprofiled endpoints stay on the legacy path");
        struct Bad { const char* text; const char* name; };
        const Bad bad[] = {
            {"[profile]\nname=a\nlogin=127.0.0.1:1\ngame_port=2\nallowed_hosts=127.0.0.1\n", "VERSION is required first"},
            {"VERSION 1\n", "at least one profile"},
            {"VERSION 1\n[profile]\nname=a\nlogin=127.0.0.1:1\nallowed_hosts=127.0.0.1\n", "game_port required"},
            {"VERSION 1\n[profile]\nname=a\nlogin=8.8.8.8:5733\ngame_port=2\nallowed_hosts=8.8.8.8\n", "public login host"},
            {"VERSION 1\n[profile]\nname=a\nlogin=127.0.0.1:1\ngame_port=2\nallowed_hosts=127.0.0.2\n", "login host listed"},
            {"VERSION 1\n[profile]\nname=a\nlogin=127.0.0.1:1\ngame_port=70000\nallowed_hosts=127.0.0.1\n", "port range"},
            {"VERSION 1\n[profile]\nname=a\nname=b\nlogin=127.0.0.1:1\ngame_port=2\nallowed_hosts=127.0.0.1\n", "duplicate key"},
            {"VERSION 1\n[profile]\nname=a\nlogin=127.0.0.1:1\ngame_port=2\nallowed_hosts=127.0.0.1\nhost=x\n", "unknown key"},
            {"VERSION 1\n[profile]\nname=a\nlogin=127.0.0.1:1\ngame_port=2\nallowed_hosts=127.0.0.1\n"
             "[profile]\nname=b\nlogin=127.0.0.1:1\ngame_port=3\nallowed_hosts=127.0.0.1\n", "duplicate login endpoint"},
            {"VERSION 1\n[profile]\nname=a\nlogin=127.0.0.1:1\ngame_port=2\nallowed_hosts=127.0.0.1\naccounts=a%b\n", "account charset"},
            {"VERSION 1\n[profile]\nname=\xc3\xa1\nlogin=127.0.0.1:1\ngame_port=2\nallowed_hosts=127.0.0.1\n", "ASCII only"},
            {"VERSION 1\nname=a\n", "key outside a section"},
        };
        for (const auto& b : bad) {
            const ServerProfileParse r = ParseServerProfiles(b.text);
            check(!r.ok && r.profiles.empty() && *r.error, b.name);
        }
        check(!ParseServerProfiles(std::string(MaxServerProfileBytes + 1, '#')).ok, "profile file size is bounded");
    }
    {
        LoginClient guard;
        Options reply; reply.mode = SessionMode::Interactive; reply.gamePortFromReply = true; reply.approvedGamePort = 15734;
        check(!guard.start(Endpoint{"127.0.0.1", 1234}, "unit-world", "unit-value", reply) &&
              guard.lastStartError() == ErrorCode::InvalidInput, "port-from-reply excludes a fixed game port");
        Options lan; lan.mode = SessionMode::Interactive; lan.approvedGamePort = 15734; lan.allowedHosts = {"10.255.254.253"};
        check(!guard.start(Endpoint{"10.255.254.253", 5733}, "unit-world", "unit-value", lan) &&
              guard.lastStartError() == ErrorCode::InvalidInput, "a LAN login host not on this machine never connects");
        Options unlisted; unlisted.mode = SessionMode::Interactive; unlisted.approvedGamePort = 15734;
        unlisted.allowedHosts = {"127.0.0.2"};
        check(!guard.start(Endpoint{"127.0.0.1", 1234}, "unit-world", "unit-value", unlisted) &&
              guard.lastStartError() == ErrorCode::InvalidInput, "the login host must be on the allow-list");
    }
    GameTicket empty;
    GameTicket moved(std::move(empty));
    check(!empty.valid() && !moved.valid() && moved.nextTxIndex() == 0, "default tickets are invalid and move cleanly");

    GameClient client;
    check(!client.start(GameTicket()) && client.lastStartError() == ErrorCode::InvalidInput,
          "game client rejects an invalid ticket before networking");
    check(!client.send(std::unique_ptr<pg::Packet>(new pg::CGCharMove)) && client.lastCommandError() == ErrorCode::NotReady,
          "world packet refused before a session exists");
    check(!client.send(std::unique_ptr<pg::Packet>(new pg::CGConnect)) && client.lastCommandError() == ErrorCode::InvalidInput,
          "CGConnect is reserved for the first frame of each socket");
    check(!client.send(std::unique_ptr<pg::Packet>(new pg::CGHeartBeat)) && client.lastCommandError() == ErrorCode::InvalidInput,
          "heartbeat is owned by the worker");
    check(!client.send(std::unique_ptr<pg::Packet>(new pg::CGAskQuit)) && client.lastCommandError() == ErrorCode::InvalidInput,
          "CGAskQuit only through requestQuit");
    check(!client.send(std::unique_ptr<pg::Packet>(new pg::GCConnect)) && client.lastCommandError() == ErrorCode::InvalidInput,
          "server-direction packet cannot be sent");
    check(!client.send(std::unique_ptr<pg::Packet>(new pg::CLAskCharLogin)) && client.lastCommandError() == ErrorCode::InvalidInput,
          "login packet cannot be sent on the game socket");
    check(!client.requestQuit() && client.lastCommandError() == ErrorCode::NotReady, "quit requires a world session");
    check(client.pump([](GameEvent&&) {}) == 0 && !client.active() && client.phase() == GamePhase::Idle, "no worker without start");
    bool wrongStart = false, wrongPump = false, wrongCancel = false, wrongSend = false;
    std::thread alien([&]() {
        wrongStart = !client.start(GameTicket()) && client.lastStartError() == ErrorCode::WrongThread;
        wrongSend = !client.send(std::unique_ptr<pg::Packet>(new pg::CGCharMove));
        try { client.pump([](GameEvent&&) {}); } catch (const std::logic_error&) { wrongPump = true; }
        try { client.cancel(); } catch (const std::logic_error&) { wrongCancel = true; }
    });
    alien.join();
    check(wrongStart && wrongSend && wrongPump && wrongCancel, "game client API enforces its owner thread");

    LoginClient login;
    check(!login.requestCharacterLogin(200001) && login.lastCommandError() == ErrorCode::NotReady,
          "character login requires an interactive session");
    Options probe; probe.approvedGamePort = 15734;
    check(!login.start(Endpoint{"127.0.0.1", 1234}, "unit-world", "unit-value", probe) &&
          login.lastStartError() == ErrorCode::InvalidInput, "probe sessions cannot carry a game port");
    Options probeReply; probeReply.gamePortFromReply = true;
    check(!login.start(Endpoint{"127.0.0.1", 1234}, "unit-world", "unit-value", probeReply) &&
          login.lastStartError() == ErrorCode::InvalidInput, "probe sessions cannot take a game port from the reply");

    pg::CGConnect connect; connect.key = 0x12345678; connect.guid = 200001; connect.set_version("tlbb");
    auto body = bodyOf(connect);
    bool zeros = true;
    for (size_t i = 8; i < 76; ++i) zeros = zeros && body[i] == 0;
    for (size_t i = 80; i < 108; ++i) zeros = zeros && body[i] == 0;
    check(body.size() == 108 && std::memcmp(body.data() + 76, "tlbb", 4) == 0 && zeros, "CGConnect 108-byte layout");
    pg::CGAskQuit quit;
    body = bodyOf(quit);
    check(body.size() == 13 && body[4] == 0, "CGAskQuit begin form (unknow_2 = 0) is 13 bytes");
    check(bodyOf(pg::CGHeartBeat()).empty(), "CGHeartBeat has an empty body");

    WorldModel world;
    world.onConnected(1);
    pg::GCConnect gc; gc.sceneid = 2; gc.position_x = 162; gc.position_y = 156;
    check(world.apply(gc) && world.connectScene() == 2, "GCConnect records the scene");
    const uint8_t realEnter[11] = {2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    body = bodyOf(*world.makeEnterScene());
    check(body.size() == 11 && std::memcmp(body.data(), realEnter, 11) == 0, "CGEnterScene echoes scene 2, type 0, pos 0");
    const char* reason = "";
    pg::GCEnterScene enter; enter.sceneid = 2; enter.client_res = 2; enter.m_objID = 5001;
    enter.m_posWorld_x = 162; enter.m_posWorld_y = 156;
    check(world.apply(enter) && world.inWorld() && world.myObjectId() == 5001, "GCEnterScene gives the own object");
    check(!world.apply(enter, &reason) && std::strlen(reason) > 0, "second GCEnterScene on one socket is a sequence error");
    auto move = world.makeMove(170, 160);
    body = bodyOf(*move);
    check(body.size() == 26 && little(body.data(), 4) == 1 && little(body.data() + 4, 4) == 5001 && body[16] == 1,
          "CGCharMove: handle 1, own object, one target, 26 bytes like the capture");
    std::vector<uint8_t> objects;
    monster(objects, 7001, 1, 1); monster(objects, 7003, 2, 2);
    cysbot::FrameAssembler assembler;
    std::vector<cysbot::Frame> frames;
    check(assembler.feed(objects.data(), objects.size(), frames) && frames.size() == 2, "synthetic monsters assemble");
    for (auto& frame : frames) {
        auto packet = pg::decodePacket(pg::Proto::Game, frame.header.id, frame.body.data(), frame.body.size(), nullptr, true);
        check(packet && world.apply(*packet), "monster decodes strictly and enters the world model");
    }
    pg::GCDelObject remove; remove.m_objID = 7001; remove.m_idScene = 2;
    pg::GCDelObject foreign; foreign.m_objID = 7003; foreign.m_idScene = 99;
    pg::GCDelObject unknown; unknown.m_objID = 9999; unknown.m_idScene = 2;
    world.apply(remove); world.apply(foreign); world.apply(unknown);
    pg::GCCharMove self; self.m_objID = 5001; self.handleID = 1;
    pg::GCCharMove::E_path node; node.x = 170; node.y = 160;
    self.path.push_back(node); self.size = 1;
    world.apply(self);
    pg::GCCharMoveResult result; result.m_objID = 5001; result.result = -1; result.handle = 1;
    world.apply(result);
    const auto& stats = world.stats();
    check(world.objects().size() == 1 && stats.deleted == 1 && stats.foreignSceneDeletes == 1 && stats.unknownDeletes == 1,
          "deletes: own scene removes, other scene ignored, unknown counted");
    check(stats.selfMoves == 1 && world.myX() == 170 && stats.moveFailures == 1 && world.lastMoveResult() == -1,
          "self echo moves the own position; failed move result recorded");
    pg::GCNotifyChangeScene notify; notify.scene_from = 2; notify.scene_to = 3;
    world.apply(notify);
    body = bodyOf(*world.makeAskChangeScene());
    check(world.changeScenePending() && body.size() == 12 && little(body.data(), 2) == 2 && little(body.data() + 2, 2) == 3,
          "CGAskChangeScene answers the pending notification");
    world.onTransfer();
    check(world.objects().empty() && !world.inWorld() && world.stats().transfers == 1, "transfer clears the old scene");

    // CYS-SKILL: quick bar / xinfa / cooldown layouts of misc.lua (bis of the server, bos of the answers).
    body = bodyOf(*world.makeModifySetting(3, 1, 35));
    check(body.size() == 6 && body[0] == 3 && body[1] == 1 && little(body.data() + 2, 4) == 35, "CGModifySetting: type, setting.type, setting.data (6 bytes)");
    body = bodyOf(*world.makeAskStudyXinfa(10, 64, 12));
    check(body.size() == 6 && little(body.data(), 2) == 10 && little(body.data() + 2, 2) == 64 && little(body.data() + 4, 2) == 12, "CGAskStudyXinfa: menpai, xinfa, now_level u16");
    check(bodyOf(*world.makeAskSetting()).empty(), "CGAskSetting is empty");
    pg::GCRetSetting settings;
    settings.setting[2].type = 1; settings.setting[2].data = 0; settings.setting[9].type = 1; settings.setting[9].data = 35;
    body = bodyOf(settings);
    check(body.size() == 1 + 109 * 5 && body[0] == 1, "GCRetSetting: marker + 109 x (type u8, data u32)");
    auto decodedSettings = pg::decodePacket(pg::Proto::Game, pg::GCRetSetting::PACKET_ID, body.data(), body.size(), nullptr, true);
    check(decodedSettings && world.apply(*decodedSettings) && world.haveSettings() && world.settings().size() == 109 &&
          world.settings()[9].type == 1 && world.settings()[9].data == 35, "GCRetSetting index = SETTING_TYPE (F8 = type 9)");
    pg::GCDetailXinFaList xinfa; xinfa.m_objID = 0; xinfa.unknow = 26;
    pg::GCDetailXinFaList::E_m_aXinFa x1; x1.m_nXinFaID = 64; x1.m_nXinFaLevel = 12; xinfa.m_aXinFa.push_back(x1); xinfa.m_wNumXinFa = 1;
    WorldModel skills;
    check(skills.apply(xinfa) && skills.xinfas().size() == 1 && skills.xinfas()[0].level == 12, "GCDetailXinFaList records id/level");
    pg::GCStudyXinfa study; study.xinfa = 64; study.now_level = 13; study.spare_exp = 5; study.spare_money = 6;
    check(skills.apply(study) && skills.xinfas()[0].level == 13 && skills.lastStudy().valid, "GCStudyXinfa raises the stored level");
    pg::GCCooldownUpdate cool; pg::GCCooldownUpdate::E_m_aCooldowns entry; entry.m_nID = 100; entry.m_nCooldown = 5000;
    cool.m_aCooldowns.push_back(entry); cool.m_nNumCooldown = 1;
    check(skills.apply(cool) && skills.cooldowns().count(100) && skills.cooldowns().at(100).total == 5000, "GCCooldownUpdate keyed by cooldown group");
    cool.m_uLowSection = 7; entry.m_nID = 101; cool.m_aCooldowns[0] = entry;
    check(skills.apply(cool) && !skills.cooldowns().count(101), "pet cooldowns (pet guid) stay out of the own groups");
    pg::GCAddSkill add; add.skill = 775;
    check(skills.apply(add) && skills.skills().size() == 1 && skills.skills()[0] == 775, "GCAddSkill appends a template id");

    std::vector<uint8_t> tiny;
    for (int i = 0; i < 2000; ++i) { pg::FrameHeader header{3, 0, 0}; pg::writeFrameHeader(tiny, header); }
    cysbot::FrameAssembler login128;
    frames.clear();
    check(!login128.feed(tiny.data(), tiny.size(), frames), "login assembler keeps its 128-frame cap");
    cysbot::FrameAssembler game(4096);
    frames.clear();
    check(game.feed(tiny.data(), tiny.size(), frames) && frames.size() == 2000, "game assembler takes a 2000-frame burst");

    const std::string text = "ERROR0001:x";
    std::vector<uint8_t> tips = {5, 0, 0, 0, static_cast<uint8_t>(text.size()), 0};
    tips.insert(tips.end(), text.begin(), text.end());
    check(pg::decodePacket(pg::Proto::Game, 397, tips.data(), tips.size(), nullptr, true) != nullptr,
          "GCScriptCommand notify_tips form decodes strictly");

    // Mutated in-world bodies: whatever decodes strictly must be safe to apply.
    const uint16_t ids[] = {21, 176, 481, 564, 582, 1090, 1340, 1216, 395, 456, 1764, 809, 280, 128, 67,
                            357, 85, 607, 137, 15, 78}; // CYS-SKILL
    std::mt19937 random(0x20260913);
    WorldModel fuzz;
    fuzz.onConnected(1);
    size_t decoded = 0;
    for (unsigned i = 0; i < 20000; ++i) {
        const uint16_t id = ids[random() % (sizeof(ids) / sizeof(ids[0]))];
        std::vector<uint8_t> raw(random() % 80);
        for (auto& b : raw) b = static_cast<uint8_t>(random());
        auto packet = pg::decodePacket(pg::Proto::Game, id, raw.data(), raw.size(), nullptr, true);
        if (!packet) continue;
        ++decoded;
        fuzz.apply(*packet);
        if (random() % 97 == 0) fuzz.onTransfer();
        if (random() % 89 == 0) fuzz.onConnected(2);
    }
    std::printf("FUZZ world_inputs=20000 decoded=%zu objects=%zu\n", decoded, fuzz.objects().size());
    check(true, "20000 mutated world packets never break the model");
}

// ------------------------------------------------------------------ loopback driver
static int loopback(uint16_t loginPort, uint16_t gamePort, const std::string& scenario, size_t expectedPackets) {
    Options lo;
    lo.mode = SessionMode::Interactive; lo.connectTimeoutMs = 2000; lo.replyTimeoutMs = 3000;
    lo.overallTimeoutMs = 60000; lo.idleTimeoutMs = 10000; lo.approvedGamePort = gamePort;
    // CYS: server profile variants. reply-port = game_port=reply; unlisted-host = explicit allow-list.
    if (scenario == "reply-port") { lo.approvedGamePort = 0; lo.gamePortFromReply = true; lo.allowedHosts = {"127.0.0.1"}; }
    if (scenario == "unlisted-host") lo.allowedHosts = {"127.0.0.1"};
    LoginClient login;
    check(login.start(Endpoint{"127.0.0.1", loginPort}, "unit-world", "unit-value", lo), "interactive login started");
    std::unique_ptr<GameTicket> ticket;
    bool loginDone = false, refused = false;
    const auto started = Clock::now();
    while (!loginDone && Clock::now() - started < std::chrono::seconds(10)) {
        login.pump([&](Event&& event) {
            switch (event.type) {
            case EventType::CharacterList: {
                const auto* list = dynamic_cast<const pg::LCRetCharList*>(event.packet.get());
                check(list && list->charlist.size() == 1 && list->charlist[0].guid == 200001, "one listed character");
                check(!login.requestCharacterLogin(123) && login.lastCommandError() == ErrorCode::InvalidInput,
                      "character login refuses a GUID outside the list");
                check(login.canRequestCharacterLogin() && login.requestCharacterLogin(200001), "character login admitted");
                check(!login.requestCharacterLogin(200001) && login.lastCommandError() == ErrorCode::Busy &&
                      !login.canRequestCreatePermission(), "one command in flight blocks the others");
                break;
            }
            case EventType::CharacterLoginRefused:
                refused = true;
                check(scenario == "refuse-then-grant", "refusal only in the refusal scenario");
                check(login.canRequestCharacterLogin() && login.requestCharacterLogin(200001), "explicit retry after refusal");
                break;
            case EventType::CharacterLoginGranted:
                ticket = std::move(event.ticket);
                check(ticket && ticket->valid() && ticket->guid() == 200001 && ticket->endpoint().port == gamePort &&
                      event.counters.socketClosed && !event.packet, "ticket granted; login socket closed; key not published");
                check(ticket->nextTxIndex() == (refused ? 0x8000 : 0x7f00), "ticket continues the login sequence");
                loginDone = true;
                break;
            case EventType::Error:
                std::printf("LOGIN terminal=error code=%s message=%s\n", ErrorCodeName(event.error), event.message);
                loginDone = true;
                break;
            case EventType::Refused: case EventType::Cancelled:
                loginDone = true;
                break;
            default: break;
            }
        }, 4);
        if (!loginDone) std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
    if (scenario == "bad-endpoint" || scenario == "bad-port" || scenario == "unlisted-host") {
        check(!ticket && loginDone, "hand-off outside the approved profile ends the login without a game socket");
        return 0;
    }
    check(ticket != nullptr, "game ticket received");

    GameOptions go;
    go.heartbeatIntervalMs = 150; go.connectTimeoutMs = 2000;
    go.connectReplyTimeoutMs = scenario == "silent-key" ? 600 : 3000;
    go.enterReplyTimeoutMs = scenario == "enter-timeout" ? 600 : 5000;
    go.quitTimeoutMs = scenario == "quit-timeout" ? 600 : 3000;
    go.transferReplyTimeoutMs = 3000; go.idleTimeoutMs = 20000; go.approvedGamePort = gamePort;
    if (scenario == "reply-port") { go.approvedGamePort = 0; go.allowedHosts = {"127.0.0.1"}; } // CYS: ticket port
    if (scenario == "backpressure") { go.maxQueuedEvents = 256; go.maxQueuedBytes = 65536; }
    if (scenario == "rate") { go.txPerSecond = 50; go.txBurst = 5; }
    GameClient game;
    check(game.start(std::move(*ticket), go), "game session started from the ticket");
    check(!ticket->valid(), "the ticket is consumed by the game session");
    WorldModel world;
    GameEvent terminal;
    bool done = false, askedChange = false, paused = false, quitAsked = false, cancelled = false;
    bool actedGen1 = false, actedGen2 = false, movesSent = false;
    int coreStep = 0; // CYS-CORE
    size_t packets = 0;
    uint32_t heartbeatsAtWorld = 0;
    Clock::time_point worldAt{}, movesAt{};
    const auto gameStarted = Clock::now();
    while (!done && Clock::now() - gameStarted < std::chrono::seconds(25)) {
        game.pump([&](GameEvent&& event) {
            switch (event.type) {
            case GameEventType::Connected:
                world.onConnected(event.generation);
                break;
            case GameEventType::Packet: {
                ++packets;
                const char* reason = "";
                if (!world.apply(*event.packet, &reason)) throw std::runtime_error(reason);
                if (event.packetId == pg::GCConnect::PACKET_ID)
                    check(game.send(world.makeEnterScene()), "CGEnterScene queued after GCConnect");
                if (event.packetId == pg::GCEnterScene::PACKET_ID) {
                    check(game.phase() == GamePhase::InWorld, "owner view is in world after GCEnterScene");
                    check(!game.send(world.makeEnterScene()) && game.lastCommandError() == ErrorCode::NotReady,
                          "second CGEnterScene on a socket is refused");
                    if (!world.changeScenePending())
                        check(!game.send(world.makeAskChangeScene()) && game.lastCommandError() == ErrorCode::NotReady,
                              "CGAskChangeScene needs a GCNotifyChangeScene first");
                    worldAt = Clock::now(); heartbeatsAtWorld = event.counters.heartbeats;
                }
                if (event.packetId == pg::GCNotifyChangeScene::PACKET_ID && !askedChange) {
                    askedChange = true;
                    check(game.send(world.makeAskChangeScene()), "CGAskChangeScene queued after the notification");
                }
                break;
            }
            case GameEventType::Transfer:
                check(event.packet && static_cast<const pg::GCRetChangeScene&>(*event.packet).key == 0,
                      "transfer event carries no key");
                world.onTransfer();
                break;
            default:
                terminal = std::move(event);
                done = true;
                break;
            }
        }, scenario == "backpressure" && !paused ? 16 : 256);
        if (done) break;
        const auto now = Clock::now();
        if (!world.inWorld()) { std::this_thread::sleep_for(std::chrono::milliseconds(2)); continue; }
        // Stay in world for more than two heartbeat periods before any clean quit.
        const bool settled = now - worldAt >= std::chrono::milliseconds(450);
        if (scenario == "backpressure" && !paused) {
            paused = true; // Stop pumping; the worker must stop reading, not fail.
            std::this_thread::sleep_for(std::chrono::milliseconds(1500));
            continue;
        }
        if (scenario == "cancel-world" && !cancelled) { cancelled = true; game.cancel(); continue; }
        if (scenario == "enter-quit" || scenario == "reply-port" || scenario == "refuse-then-grant") {
            if (!actedGen1) {
                actedGen1 = true;
                check(game.send(world.makeAskBaseAttrib(world.myObjectId())), "CGCharAskBaseAttrib for the own object");
                check(game.send(world.makeMove(world.myX() + 2, world.myY() + 2)), "CGCharMove queued in world");
            }
            if (!quitAsked && settled && world.stats().selfMoves >= 1 && world.stats().moveResults >= 1 &&
                world.objects().size() == 2) {
                quitAsked = true;
                check(game.requestQuit(), "quit requested in world");
            }
        } else if (scenario == "transfer") {
            if (world.generation() == 2 && !quitAsked && settled) {
                quitAsked = true; actedGen2 = true;
                check(game.requestQuit(), "quit after the transfer");
            }
        } else if (scenario == "transfer-refused") {
            if (world.stats().retChangeScene == 1 && settled && !quitAsked) { quitAsked = true; check(game.requestQuit(), "quit after refusal"); }
        } else if (scenario == "quit-timeout") {
            if (!quitAsked && settled) { quitAsked = true; check(game.requestQuit(), "quit requested"); }
        } else if (scenario == "backpressure") {
            if (world.stats().unknownDeletes >= 20000 && !quitAsked) { quitAsked = true; check(game.requestQuit(), "quit after the flood"); }
        } else if (scenario == "rate") {
            if (!movesSent) {
                movesSent = true; movesAt = now;
                bool all = true;
                for (int i = 0; i < 40; ++i) all = game.send(world.makeMove(world.myX() + i, world.myY())) && all;
                check(all, "forty moves admitted to the bounded outbound queue");
            } else if (!quitAsked && now - movesAt > std::chrono::milliseconds(1500)) {
                quitAsked = true; check(game.requestQuit(), "quit after paced moves");
            }
        } else if (scenario == "replay") {
            if (!movesSent && packets >= expectedPackets) {
                movesSent = true; movesAt = now;
                check(game.send(world.makeMove(world.myX() + 1, world.myY() + 1)), "move after the replayed world");
            } else if (movesSent && !quitAsked && settled && now - movesAt > std::chrono::milliseconds(400)) {
                quitAsked = true; check(game.requestQuit(), "quit after the replayed world");
            }
        } else if (scenario == "core-combat") {
            // CYS-CORE: skill list -> lock -> 3 hits (the third kills, drop box) -> open -> pick -> chat -> bag -> quit.
            const auto& st = world.stats();
            switch (coreStep) {
            case 0:
                check(game.send(world.makeAskBaseAttrib(world.myObjectId())), "CGCharAskBaseAttrib for the own object");
                check(game.send(world.makeAskDetailSkillList()), "CGAskDetailSkillList queued in world");
                coreStep = 1; break;
            case 1:
                if (st.skillLists == 1) {
                    check(world.skills().size() == 2 && world.skills()[0] == 0, "GCDetailSkillList lists skill 0 (normal attack)");
                    float distance = 0;
                    const uint32_t target = world.nearestMonster(&distance);
                    check(target == 7003 && distance > 9.0f && distance < 10.0f, "nearest live monster is 7003 at 9.4 m");
                    check(game.send(world.makeLockTarget(7003)), "CGLockTarget queued");
                    check(game.send(world.makeUseSkill(0, 7003)), "CGCharUseSkill 1 queued");
                    coreStep = 2;
                }
                break;
            case 2:
                if (st.selfSkillSends == 1 && st.damageDealt == 1 && st.hpUpdates == 1) {
                    check(world.objects().at(7003).hpPercent == 66, "monster hp 66% after the first hit");
                    check(game.send(world.makeUseSkill(0, 7003)), "CGCharUseSkill 2 queued");
                    coreStep = 3;
                }
                break;
            case 3:
                if (st.selfSkillSends == 2) { check(game.send(world.makeUseSkill(0, 7003)), "CGCharUseSkill 3 queued"); coreStep = 4; }
                break;
            case 4:
                if (st.itemBoxes == 1 && st.targetDeaths == 1) {
                    check(world.objects().count(7003) == 0 && world.itemBoxes().size() == 1, "monster deleted; one drop box");
                    const uint32_t box = world.nearestItemBox(12.0f);
                    check(box == 0x00FF0001, "drop box within 12 m of the own object");
                    check(game.send(world.makeOpenItemBox(box)), "CGOpenItemBox queued");
                    coreStep = 5;
                }
                break;
            case 5:
                if (st.boxLists == 1) {
                    check(world.openBoxId() == 0x00FF0001 && world.boxItems().size() == 1 && world.boxItems()[0].itemIndex == 30001011,
                          "GCBoxItemList holds the potion");
                    check(game.send(world.makePickBoxItem(world.openBoxId(), world.boxItems()[0].guid)), "CGPickBoxItem queued");
                    coreStep = 6;
                }
                break;
            case 6:
                if (st.picksOk == 1 && st.itemInfos == 1) {
                    check(world.lastPick().bagIndex == 3 && world.bag().count(3) == 1 && world.bag().at(3).itemIndex == 30001011 &&
                          world.boxItems().empty() && world.itemBoxes().empty(), "pick moved the potion to bag slot 3; box gone");
                    check(game.send(world.makeChat(0, "unit-chat-echo")), "CGChat queued");
                    coreStep = 7;
                }
                break;
            case 7:
                if (st.chats == 1) {
                    check(st.selfChats == 1 && world.lastChat().text == "unit-chat-echo" && world.lastChat().source == "CYWorld00",
                          "GCChat echo carries the own text and name");
                    check(game.send(world.makeAskMyBagList()), "CGAskMyBagList queued");
                    coreStep = 8;
                }
                break;
            case 8:
                if (st.bagLists == 1 && !quitAsked && settled) {
                    check(world.bag().size() == 1 && world.bag().at(3).count == 1, "GCMyBagList rebuilt the bag");
                    quitAsked = true; check(game.requestQuit(), "quit after the core loop");
                }
                break;
            default: break;
            }
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
    check(done, "terminal game event delivered");
    const auto& c = terminal.counters;
    const char* type = terminal.type == GameEventType::QuitComplete ? "QuitComplete" :
        terminal.type == GameEventType::Cancelled ? "Cancelled" : terminal.type == GameEventType::Error ? "Error" : "Other";
    std::printf("WORLD scenario=%s terminal=%s error=%s quit_flag=%d generation=%u heartbeats=%u transfers=%u tx=%u rx=%u "
                "next_idx=%04x dropped=%u discarded=%u backpressure=%u sockets=%u decode_failures=%u driver_packets=%zu "
                "heartbeats_before_world=%u\n",
                scenario.c_str(), type, ErrorCodeName(terminal.error), terminal.quitFlag, terminal.generation, c.heartbeats,
                c.transfers, c.txFrames, c.rxFrames, c.nextTxIndex, c.droppedOutbound, c.discardedAfterTransfer,
                c.backpressureWaits, c.sockets, c.decodeFailures, packets, heartbeatsAtWorld);
    printWorld("STATE", world);
    check(c.socketClosed && game.pump([](GameEvent&&) {}) == 0 && game.phase() == GamePhase::Closed,
          "terminal follows a closed socket and nothing trails it");
    if (scenario == "core-combat")
        check(coreStep == 8 && world.stats().skillSends == 3 && world.stats().targetLists == 3 && world.stats().damages == 3 &&
              world.stats().pickResults == 1, "core loop ran to the end (3 hits, box, pick, chat, bag)");
    if (scenario == "enter-quit" || scenario == "reply-port" || scenario == "refuse-then-grant" || scenario == "transfer" ||
        scenario == "transfer-refused" || scenario == "backpressure" || scenario == "rate" || scenario == "replay" ||
        scenario == "core-combat") {
        check(terminal.type == GameEventType::QuitComplete && terminal.quitFlag == 0, "clean quit acknowledged and closed");
        check(c.heartbeats >= 2 && c.decodeFailures == 0, "heartbeat cadence ran and every frame decoded strictly");
    }
    if (scenario == "transfer") check(actedGen2 && terminal.generation == 2 && c.transfers == 1 && c.sockets == 2 &&
                                      world.myObjectId() == 6002 && world.sceneId() == 3, "transfer reconnected and re-entered");
    if (scenario == "backpressure") check(c.backpressureWaits > 0 && world.stats().unknownDeletes == 20000,
                                          "backpressure paused reading without losing frames");
    if (scenario == "silent-key") check(terminal.type == GameEventType::Error && terminal.error == ErrorCode::Timeout &&
                                        terminal.phase == GamePhase::AwaitConnect, "no GCConnect ends in a bounded timeout");
    if (scenario == "enter-timeout") check(terminal.type == GameEventType::Error && terminal.error == ErrorCode::Timeout &&
                                           terminal.phase == GamePhase::Entering, "no GCEnterScene ends in a bounded timeout");
    if (scenario == "peer-close-world") check(terminal.type == GameEventType::Error && terminal.error == ErrorCode::PeerClosed,
                                              "server close in world is an explicit error");
    if (scenario == "unsolicited-transfer") check(terminal.type == GameEventType::Error &&
                                                  terminal.error == ErrorCode::UnexpectedPacket, "unsolicited transfer rejected");
    if (scenario == "decode-failure") check(terminal.type == GameEventType::Error && terminal.error == ErrorCode::Decode &&
                                            terminal.packetId == pg::GCConnect::PACKET_ID, "malformed GCConnect is a strict decode failure");
    if (scenario == "quit-timeout") check(terminal.type == GameEventType::Error && terminal.error == ErrorCode::Timeout &&
                                          terminal.quitFlag == 0, "acknowledged quit without close is bounded");
    if (scenario == "cancel-world") check(terminal.type == GameEventType::Cancelled, "cancel in world ends with one Cancelled");
    return 0;
}

int main(int argc, char** argv) {
    try {
        if (argc == 1) unit();
        else if (argc == 3 && std::string(argv[1]) == "--fixture") return fixture(argv[2]);
        else if (argc == 3 && std::string(argv[1]) == "--replay-model") replayModel(argv[2]);
        else if (argc == 3 && std::string(argv[1]) == "--replay-source") replaySource(argv[2]);
        else if (argc == 3 && std::string(argv[1]) == "--replay-core") replayCore(argv[2]); // CYS-CORE
        else if (argc >= 5 && std::string(argv[1]) == "--loopback") {
            const unsigned loginPort = static_cast<unsigned>(std::stoul(argv[2]));
            const unsigned gamePort = static_cast<unsigned>(std::stoul(argv[3]));
            const size_t expected = argc >= 6 ? static_cast<size_t>(std::stoul(argv[5])) : 0;
            if (!loginPort || loginPort > 65535 || !gamePort || gamePort > 65535) return 3;
            loopback(static_cast<uint16_t>(loginPort), static_cast<uint16_t>(gamePort), argv[4], expected);
        } else return 3;
        std::printf("RESULT checks=%u status=PASS\n", checks);
        return 0;
    } catch (const std::exception& e) {
        std::fprintf(stderr, "FAIL %s\n", e.what());
        return 2;
    }
}
