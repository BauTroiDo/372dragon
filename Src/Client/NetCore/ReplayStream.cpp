#include "ReplayStream.h"
#include "LoginProbe.h" // FrameAssembler and Wipe (already-checked framing code).
#include "PgFactory.h"
#include "PgPackets_combat.h" // CYS-CORE: CGLockTarget, GCCharBaseAttrib
#include "PgPackets_core.h"
#include "PgPackets_item.h"   // CYS-CORE: CGPickBoxItem, GCPickResult
#include "PgPackets_login.h"
#include "PgPackets_misc.h"
#include "PgPackets_mission.h" // CYS-QUEST: GCScriptCommand, CGEventRequest, CGAskMissionList
#include "PgPackets_movement.h"
#include "PgPackets_social.h" // CYS-CORE: CGChat/GCChat
#include <algorithm>
#include <map>
#include <chrono>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <fstream>
#include <mutex>
#include <set>
#include <thread>

namespace cys { namespace net { namespace replay {
namespace {
using Clock = std::chrono::steady_clock;
constexpr size_t MaxLogLines = 512;
constexpr unsigned MaxMoveLogs = 8;

uint32_t little(const uint8_t* p, unsigned n) {
    uint32_t v = 0;
    for (unsigned i = 0; i < n; ++i) v |= static_cast<uint32_t>(p[i]) << (8 * i);
    return v;
}

void sleepMs(int ms) {
    if (ms > 0) std::this_thread::sleep_for(std::chrono::milliseconds(ms));
}
} // namespace

bool LoadFixture(const std::string& path, std::vector<Record>& out, std::string& error) {
    out.clear();
    std::ifstream in(path.c_str(), std::ios::binary);
    char magic[8] = {};
    in.read(magic, 8);
    if (!in || std::memcmp(magic, "PGWORLD1", 8) != 0) { error = "not a PGWORLD1 fixture"; return false; }
    for (;;) {
        uint8_t head[9] = {};
        in.read(reinterpret_cast<char*>(head), 9);
        if (in.gcount() == 0) break;
        if (in.gcount() != 9) { error = "partial fixture record"; return false; }
        Record r;
        r.c2s = head[0] != 0;
        r.id = static_cast<uint16_t>(little(head + 1, 2));
        r.idx = static_cast<uint16_t>(little(head + 3, 2));
        const uint32_t size = little(head + 5, 4);
        if (size > pg::kMaxBody) { error = "fixture body exceeds the frame limit"; return false; }
        r.body.resize(size);
        if (size) {
            in.read(reinterpret_cast<char*>(r.body.data()), size);
            if (static_cast<uint32_t>(in.gcount()) != size) { error = "partial fixture body"; return false; }
        }
        out.push_back(std::move(r));
    }
    std::vector<uint16_t> server;
    bool firstClient = false, sawClient = false;
    for (const auto& r : out) {
        if (r.c2s) { if (!sawClient) { sawClient = true; firstClient = r.id == pg::CGConnect::PACKET_ID; } }
        else server.push_back(r.id);
    }
    if (!sawClient || !firstClient) { error = "fixture C->S stream must begin with CGConnect"; return false; }
    if (server.size() < 4 || server[0] != pg::KeyExchange::PACKET_ID || server[1] != pg::GCConnect::PACKET_ID ||
        server[2] != pg::GCEnterScene::PACKET_ID) {
        error = "fixture S->C stream must begin with KeyExchange, GCConnect, GCEnterScene";
        return false;
    }
    error.clear();
    return true;
}

// CYS-SFX: scenario text (see ReplayStream.h). Unknown keys are an error so a converter mismatch shows at load time.
bool LoadScenario(const std::string& path, Scenario& out, std::string& error) {
    std::ifstream in(path, std::ios::binary);
    if (!in) { error = "cannot open scenario"; return false; }
    out = Scenario();
    std::string line;
    unsigned lineNo = 0;
    bool haveScene = false;
    auto fail = [&](const char* why) {
        char text[160] = {};
        std::snprintf(text, sizeof(text) - 1, "scenario line %u: %s", lineNo, why);
        error = text;
        return false;
    };
    while (std::getline(in, line)) {
        ++lineNo;
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.empty() || line[0] == '#') continue;
        std::vector<std::string> words;
        size_t p = 0;
        while (p < line.size()) {
            while (p < line.size() && line[p] == ' ') ++p;
            if (p >= line.size()) break;
            size_t e = line.find(' ', p);
            // name=... takes the rest of the line (NPC names may hold spaces)
            if (line.compare(p, 5, "name=") == 0) e = std::string::npos;
            words.push_back(line.substr(p, e == std::string::npos ? std::string::npos : e - p));
            p = e == std::string::npos ? line.size() : e + 1;
        }
        if (words.empty()) continue;
        ScenarioStep step;
        size_t w = 0;
        if (words[0].compare(0, 3, "at=") == 0) { step.atMs = static_cast<uint32_t>(std::strtoul(words[0].c_str() + 3, nullptr, 10)); ++w; }
        if (w >= words.size()) return fail("missing kind");
        step.kind = words[w++];
        if (step.kind == "tag") {
            if (w >= words.size()) return fail("tag without a name");
            step.name = words[w];
            out.steps.push_back(step);
            continue;
        }
        for (; w < words.size(); ++w) {
            const std::string& kv = words[w];
            const size_t eq = kv.find('=');
            if (eq == std::string::npos) return fail("expected key=value");
            const std::string key = kv.substr(0, eq), value = kv.substr(eq + 1);
            const char* v = value.c_str();
            if (key == "id" && step.kind == "scene") out.sceneId = static_cast<uint16_t>(std::strtoul(v, nullptr, 10));
            else if (key == "obj") step.obj = static_cast<uint32_t>(std::strtoul(v, nullptr, 10));
            else if (key == "caster" || key == "sender") step.other = static_cast<uint32_t>(std::strtoul(v, nullptr, 10));
            else if (key == "target") step.target = static_cast<int32_t>(std::strtol(v, nullptr, 10));
            else if (key == "race") step.race = static_cast<uint32_t>(std::strtoul(v, nullptr, 10));
            else if (key == "level") step.level = static_cast<uint32_t>(std::strtoul(v, nullptr, 10));
            else if (key == "logic") step.logic = static_cast<uint32_t>(std::strtoul(v, nullptr, 10));
            else if (key == "skill" || key == "id" || key == "hp") step.value = static_cast<int32_t>(std::strtol(v, nullptr, 10));
            else if (key == "x") step.x = static_cast<float>(std::atof(v));
            else if (key == "z") step.z = static_cast<float>(std::atof(v));
            else if (key == "dir") step.dir = static_cast<float>(std::atof(v));
            else if (key == "name") step.name = value;
            else if (key == "ids") {
                for (const char* q = v; *q;) {
                    step.ids.push_back(static_cast<uint16_t>(std::strtoul(q, nullptr, 10)));
                    q = std::strchr(q, ',');
                    if (!q) break;
                    ++q;
                }
            }
            else return fail("unknown key");
        }
        if (step.kind == "scene") { out.x = step.x; out.z = step.z; out.myObj = step.obj; out.selfName = step.name; haveScene = true; continue; }
        if (step.kind != "npc" && step.kind != "skill" && step.kind != "impact" && step.kind != "damage" && step.kind != "impactlist")
            return fail("unknown step kind");
        out.steps.push_back(step);
    }
    if (!haveScene || !out.myObj || !out.sceneId) { error = "scenario needs a scene line with id, x, z, obj"; return false; }
    std::stable_sort(out.steps.begin(), out.steps.end(), [](const ScenarioStep& a, const ScenarioStep& b) { return a.atMs < b.atMs; });
    error.clear();
    return true;
}

struct Session::Impl {
    std::vector<Record> records;
    Options options;
    std::vector<size_t> server;   // indices of the S->C records in order
    std::vector<size_t> world;    // S->C records after GCEnterScene
    std::map<uint32_t, std::pair<float, float>> monsterPos; // CYS-CORE: recorded GCNewMonster(_Move) positions
    uint16_t sceneId = 0;                                   // CYS-CORE: recorded GCEnterScene scene (GCDelObject)
    std::vector<Record> selfFrames;                         // CYS-SFX: own appearance frames moved to the scenario object
    mutable std::mutex mutex;
    Stats stats;
    std::deque<std::string> log;

    void logf(const char* fmt, ...) {
        char line[256] = {};
        va_list args;
        va_start(args, fmt);
        _vsnprintf_s(line, sizeof(line), _TRUNCATE, fmt, args);
        va_end(args);
        std::lock_guard<std::mutex> lock(mutex);
        if (log.size() >= MaxLogLines) log.pop_front();
        log.push_back(line);
    }
    template <class F> void update(F f) {
        std::lock_guard<std::mutex> lock(mutex);
        f(stats);
    }
    static void appendFrame(std::vector<uint8_t>& out, uint16_t id, uint16_t idx, const std::vector<uint8_t>& body) {
        pg::FrameHeader header{};
        header.id = id; header.size = static_cast<uint16_t>(body.size()); header.idx = idx;
        pg::writeFrameHeader(out, header);
        out.insert(out.end(), body.begin(), body.end());
    }
    static void appendPacket(std::vector<uint8_t>& out, const pg::Packet& packet, uint16_t idx) {
        std::vector<uint8_t> frame;
        if (pg::encodeFrame(packet, idx, frame)) out.insert(out.end(), frame.begin(), frame.end());
    }
    const Record& rec(size_t index) const { return records[index]; }
};

namespace {

// Bytes queued for the client with a read cursor; one per stream.
struct Outbound {
    std::vector<uint8_t> bytes;
    size_t offset = 0;
    bool pending() const { return offset < bytes.size(); }
    int read(uint8_t* buffer, size_t size) {
        const size_t available = bytes.size() - offset;
        const size_t take = (std::min)(size, available);
        if (take) std::memcpy(buffer, bytes.data() + offset, take);
        offset += take;
        if (offset == bytes.size()) { cysbot::Wipe(bytes.data(), bytes.size()); bytes.clear(); offset = 0; }
        return static_cast<int>(take);
    }
};

class LoginStream : public Stream {
public:
    explicit LoginStream(std::shared_ptr<Session::Impl> impl) : s_(std::move(impl)) {}
    ~LoginStream() override { close(); }

    ErrorCode connect(const Endpoint& endpoint, uint32_t, const std::atomic<bool>&, const char** message) override {
        *message = "";
        if (connected_) { *message = "replay login stream connected twice"; return ErrorCode::Internal; }
        connected_ = true;
        s_->logf("replay login: connected (offline) endpoint=%s:%u", endpoint.host.c_str(), static_cast<unsigned>(endpoint.port));
        return ErrorCode::None;
    }

    ErrorCode write(const uint8_t* data, size_t size, uint32_t, const std::atomic<bool>&, const char** message) override {
        *message = "";
        if (!connected_ || closed_) { *message = "replay login stream closed"; return ErrorCode::PeerClosed; }
        std::vector<cysbot::Frame> frames;
        if (!assembler_.feed(data, size, frames)) { *message = "replay login frame assembly failed"; return ErrorCode::Io; }
        for (auto& frame : frames) {
            handle(frame);
            cysbot::Wipe(frame.body.data(), frame.body.size());
        }
        return ErrorCode::None;
    }

    Wait wait(int ms) override {
        if (closed_) return Wait::Closed;
        if (out_.pending()) return Wait::Readable;
        sleepMs(ms);
        return Wait::Idle;
    }

    int read(uint8_t* buffer, size_t size) override {
        if (closed_) return 0;
        if (!out_.pending()) return -1;
        return out_.read(buffer, size);
    }

    void close() override {
        if (!closed_ && connected_) s_->logf("replay login: stream closed by the client");
        closed_ = true;
        cysbot::Wipe(out_.bytes.data(), out_.bytes.size());
        out_.bytes.clear(); out_.offset = 0;
    }

private:
    void push(const pg::Packet& packet) {
        Session::Impl::appendPacket(out_.bytes, packet, idx_);
        idx_ = static_cast<uint16_t>(idx_ + 0x100);
        s_->update([](Stats& st) { ++st.loginRx; });
    }
    void handle(const cysbot::Frame& frame) {
        const uint16_t id = frame.header.id;
        const unsigned size = static_cast<unsigned>(frame.body.size());
        s_->update([](Stats& st) { ++st.loginTx; });
        const Options& o = s_->options;
        switch (id) {
        case pg::CLConnect::PACKET_ID: {
            pg::LCRetConnect reply;
            reply.unknow = 0; reply.loginport = 0; reply.set_loginip("127.0.0.1");
            reply.port = 0; reply.set_clientip("127.0.0.1"); reply.unknow1 = 0;
            push(reply);
            s_->logf("replay login: CLConnect (%u B) -> LCRetConnect", size);
            break;
        }
        case pg::CLAskLogin::PACKET_ID: {
            // Any account and password: the text is never inspected or stored.
            pg::LCRetLogin reply;
            reply.set_uuid("cys-world-replay"); reply.flag = 0;
            push(reply);
            pg::LCStatus status;
            push(status);
            s_->logf("replay login: CLAskLogin (%u B) -> LCRetLogin flag=0 + LCStatus (credentials not inspected)", size);
            break;
        }
        case pg::CLAskCharList::PACKET_ID: {
            pg::LCRetCharList list;
            list.unknow = 0; list.set_uuid("cys-world-replay");
            pg::LCRetCharList::E_charlist role;
            role.guid = o.guid; role.sex = o.sex; role.set_nickname(o.nickname); role.level = o.level;
            role.hair = static_cast<uint8_t>(o.hair); role.head = static_cast<int16_t>(o.face);
            role.new_player_set = o.outfit; role.portrait_id = o.portrait; role.sceneid = o.sceneId; role.menpai = o.menpai;
            list.charlist.push_back(role);
            list.charnum = 1;
            push(list);
            s_->logf("replay login: CLAskCharList (%u B) -> LCRetCharList count=1 guid=%u", size, static_cast<unsigned>(o.guid));
            break;
        }
        case pg::CLAskCharLogin::PACKET_ID: {
            pg::DecodeResult result;
            auto packet = pg::decodePacket(pg::Proto::Login, id, frame.body.data(), frame.body.size(), &result, true);
            const uint32_t guid = packet ? static_cast<const pg::CLAskCharLogin&>(*packet).guid : 0;
            pg::LCRetCharLogin reply;
            reply.result = guid == o.guid ? 0 : 1;
            reply.port = o.gamePort; reply.set_ip("127.0.0.1"); reply.key = reply.result == 0 ? o.key : 0;
            push(reply);
            s_->update([&](Stats& st) { if (reply.result == 0) st.loginGranted = true; else ++st.protocolErrors; });
            s_->logf("replay login: CLAskCharLogin guid=%u -> LCRetCharLogin result=%u port=%u", static_cast<unsigned>(guid),
                     static_cast<unsigned>(reply.result), static_cast<unsigned>(o.gamePort));
            break;
        }
        default:
            s_->update([](Stats& st) { ++st.unexpected; });
            s_->logf("replay login: client packet id=%u size=%u recorded; no reply", static_cast<unsigned>(id), size);
            break;
        }
    }

    std::shared_ptr<Session::Impl> s_;
    cysbot::FrameAssembler assembler_{128};
    Outbound out_;
    uint16_t idx_ = 0;
    bool connected_ = false, closed_ = false;
};

class GameStream : public Stream {
public:
    explicit GameStream(std::shared_ptr<Session::Impl> impl) : s_(std::move(impl)) {}
    ~GameStream() override { close(); }

    ErrorCode connect(const Endpoint& endpoint, uint32_t, const std::atomic<bool>&, const char** message) override {
        *message = "";
        if (connected_) { *message = "replay game stream connected twice"; return ErrorCode::Internal; }
        connected_ = true;
        unsigned sockets = 0;
        s_->update([&](Stats& st) { sockets = ++st.gameSockets; });
        s_->logf("replay game: socket %u connected (offline) endpoint=%s:%u", sockets, endpoint.host.c_str(),
                 static_cast<unsigned>(endpoint.port));
        return ErrorCode::None;
    }

    ErrorCode write(const uint8_t* data, size_t size, uint32_t, const std::atomic<bool>&, const char** message) override {
        *message = "";
        if (!connected_ || closed_) { *message = "replay game stream closed"; return ErrorCode::PeerClosed; }
        std::vector<cysbot::Frame> frames;
        if (!assembler_.feed(data, size, frames)) { *message = "replay game frame assembly failed"; return ErrorCode::Io; }
        for (auto& frame : frames) {
            handle(frame);
            cysbot::Wipe(frame.body.data(), frame.body.size());
        }
        return ErrorCode::None;
    }

    Wait wait(int ms) override {
        if (closed_) return Wait::Closed;
        if (out_.pending()) return Wait::Readable;
        if (flushPending()) return Wait::Readable; // CYS-CORE: delayed synthetic frames (corpse removal)
        if (entered_ && scenario() && !closeAfterDrain_) { // CYS-SFX: timed scenario steps
            if (deliverScenario()) return Wait::Readable;
        }
        if (closeAfterDrain_) {
            closed_ = true;
            s_->update([](Stats& st) { st.closed = true; });
            s_->logf("replay game: GCRetAskQuit delivered; closing the game stream like the server");
            return Wait::Closed;
        }
        if (entered_ && worldNext_ < s_->world.size()) {
            const Clock::time_point now = Clock::now();
            if (now >= nextDue_) {
                const uint32_t gap = s_->options.frameGapMs;
                unsigned sent = 0;
                do {
                    const Record& r = s_->rec(s_->world[worldNext_++]);
                    Session::Impl::appendFrame(out_.bytes, r.id, r.idx, r.body);
                    nextDue_ += std::chrono::milliseconds(gap);
                    ++sent;
                } while (worldNext_ < s_->world.size() && (gap == 0 || now >= nextDue_));
                const bool finished = worldNext_ == s_->world.size();
                s_->update([&](Stats& st) { st.worldSent += sent; st.gameRx += sent; if (finished) st.finished = true; });
                if (finished)
                    s_->logf("replay game: world stream finished frames=%u", static_cast<unsigned>(s_->world.size()));
                return Wait::Readable;
            }
            const auto remain = std::chrono::duration_cast<std::chrono::milliseconds>(nextDue_ - now).count();
            sleepMs(static_cast<int>((std::min)(static_cast<long long>(ms), static_cast<long long>(remain))));
            return Wait::Idle;
        }
        sleepMs(ms);
        return Wait::Idle;
    }

    int read(uint8_t* buffer, size_t size) override {
        if (closed_) return 0;
        if (!out_.pending()) return -1;
        return out_.read(buffer, size);
    }

    void close() override {
        if (!closed_ && connected_) s_->logf("replay game: stream closed by the client");
        closed_ = true;
        cysbot::Wipe(out_.bytes.data(), out_.bytes.size());
        out_.bytes.clear(); out_.offset = 0;
    }

private:
    void pushRecord(size_t index) {
        const Record& r = s_->rec(index);
        Session::Impl::appendFrame(out_.bytes, r.id, r.idx, r.body);
        s_->update([](Stats& st) { ++st.gameRx; });
    }
    void pushPacket(const pg::Packet& packet) {
        Session::Impl::appendPacket(out_.bytes, packet, synthIdx_);
        synthIdx_ = static_cast<uint16_t>(synthIdx_ + 0x100);
        s_->update([](Stats& st) { ++st.gameRx; });
    }

    // CYS-SFX ---------------------------------------------------------------------------------------------------------
    bool scenario() const { return !s_->options.scenario.steps.empty(); }

    // The recorded GCConnect / GCEnterScene decoded, moved to the scenario scene/position/object and re-encoded.
    void pushScenarioHandshake(size_t index) {
        const Record& r = s_->rec(index);
        const Scenario& sc = s_->options.scenario;
        auto packet = pg::decodePacket(pg::Proto::Game, r.id, r.body.data(), r.body.size(), nullptr, true);
        if (packet && r.id == pg::GCConnect::PACKET_ID) {
            auto& p = static_cast<pg::GCConnect&>(*packet);
            p.sceneid = sc.sceneId; p.position_x = sc.x; p.position_y = sc.z;
        } else if (packet && r.id == pg::GCEnterScene::PACKET_ID) {
            auto& p = static_cast<pg::GCEnterScene&>(*packet);
            p.sceneid = sc.sceneId; p.client_res = sc.sceneId; p.m_posWorld_x = sc.x; p.m_posWorld_y = sc.z; p.m_objID = sc.myObj;
            s_->update([&](Stats& st) { st.myObjectId = sc.myObj; });
        } else {
            pushRecord(index);
            return;
        }
        Session::Impl::appendPacket(out_.bytes, *packet, r.idx);
        s_->update([](Stats& st) { ++st.gameRx; });
    }

    // Every step whose time (ms after GCEnterScene + scenarioDelayMs) has come, in file order.
    bool deliverScenario() {
        const Scenario& sc = s_->options.scenario;
        const auto now = Clock::now();
        const uint32_t since = static_cast<uint32_t>(std::chrono::duration_cast<std::chrono::milliseconds>(now - enterTime_).count());
        bool any = false;
        if (!selfSent_) {
            selfSent_ = true;
            for (const Record& r : s_->selfFrames) { Session::Impl::appendFrame(out_.bytes, r.id, synthIdx_, r.body); synthIdx_ = static_cast<uint16_t>(synthIdx_ + 0x100); s_->update([](Stats& x) { ++x.gameRx; }); }
            s_->logf("replay scenario: %u recorded own-character frames moved to obj %u", static_cast<unsigned>(s_->selfFrames.size()), sc.myObj);
            any = !s_->selfFrames.empty();
        }
        while (scenarioNext_ < sc.steps.size() && sc.steps[scenarioNext_].atMs + s_->options.scenarioDelayMs <= since) {
            const ScenarioStep& st = sc.steps[scenarioNext_++];
            any = true;
            if (st.kind == "tag") {
                s_->update([&](Stats& x) { ++x.scenarioTags; x.lastTag = st.name; x.lastTagMs = since; ++x.scenarioSent; });
                s_->logf("replay scenario: tag %s at %u ms (step %u ms)", st.name.c_str(), since, st.atMs);
                continue;
            }
            npcPos_[sc.myObj] = std::make_pair(sc.x, sc.z);
            if (st.kind == "npc") {
                pg::GCNewMonster m;
                m.m_objID = st.obj; m.guid = -1; m.worldPos_x = st.x; m.worldPos_y = st.z; m.dir = st.dir; m.speed = 3.5f;
                pushPacket(m);
                // combat.lua set_* bits: uFlags[0] 0x01 model (race), 0x02 name, 0x08 level, 0x10 hp percent
                pg::GCCharBaseAttrib a;
                a.m_objID = st.obj; a.data_id = 0;
                a.new_flags.fill(0); a.new_flags[0] = 0x01 | 0x02 | 0x08 | 0x10;
                a.model = st.race; a.set_m_szName(st.name); a.level = static_cast<uint8_t>(st.level > 255 ? 255 : st.level); a.hp_percent = 100;
                pushPacket(a);
                npcPos_[st.obj] = std::make_pair(st.x, st.z);
            } else if (st.kind == "skill") {
                pg::GCCharSkill_Send s;
                s.m_objID = st.other; s.logic_count = st.logic; s.skill_id = static_cast<uint32_t>(st.value); s.target_id = st.target;
                auto pos = npcPos_.find(static_cast<uint32_t>(st.target));
                if (pos != npcPos_.end()) { s.target_pos_x = pos->second.first; s.target_pos_y = pos->second.second; }
                pushPacket(s);
            } else if (st.kind == "impact") {
                pg::GCCharDirectImpact d;
                d.reciver = static_cast<uint32_t>(st.target); d.sender = static_cast<int32_t>(st.other);
                d.logic_count = static_cast<int32_t>(st.logic); d.impact_id = static_cast<uint16_t>(st.value); d.skill_id = -1;
                pushPacket(d);
            } else if (st.kind == "damage") {
                pg::GCDetailHealsAndDamages h;
                h.dirty_flags = 1; h.reciver = static_cast<uint32_t>(st.target); h.sender = static_cast<int32_t>(st.other);
                h.logic_count = st.logic; h.hp_modification = st.value; h.is_critical_hit = 0;
                pushPacket(h);
            } else if (st.kind == "impactlist") {
                pg::GCCharImpactListUpdate l;
                l.m_nOwnerID = st.obj; l.unknow_1 = 0;
                for (uint16_t id : st.ids) { pg::GCCharImpactListUpdate::E_m_aImpact e; e.buffer_id = static_cast<int16_t>(id); e.sender = st.obj; e.index = 0; l.m_aImpact.push_back(e); }
                l.size = static_cast<uint16_t>(l.m_aImpact.size());
                pushPacket(l);
            }
            s_->update([](Stats& x) { ++x.scenarioSent; });
            s_->logf("replay scenario: %s obj=%u other=%u target=%d value=%d at %u ms", st.kind.c_str(), st.obj, st.other, st.target, st.value, since);
        }
        if (scenarioNext_ == sc.steps.size() && !scenarioFinished_) {
            scenarioFinished_ = true;
            s_->update([](Stats& x) { x.finished = true; });
            s_->logf("replay scenario: all %u steps delivered", static_cast<unsigned>(sc.steps.size()));
        }
        return any;
    }
    size_t scenarioNext_ = 0;
    bool scenarioFinished_ = false, selfSent_ = false;
    std::map<uint32_t, std::pair<float, float>> npcPos_;

    void handle(const cysbot::Frame& frame) {
        const uint16_t id = frame.header.id;
        const uint16_t idx = frame.header.idx;
        const unsigned size = static_cast<unsigned>(frame.body.size());
        bool first = false;
        s_->update([&](Stats& st) {
            first = ++st.gameTx == 1;
            if (first) st.firstGameIdx = idx;
            else if (idx != expectedIdx_) st.gameIdxContiguous = false;
            st.lastGameIdx = idx;
        });
        expectedIdx_ = static_cast<uint16_t>((idx + 0x100) & 0xff00);
        if (first && id != pg::CGConnect::PACKET_ID) {
            // gamed.lua: the first frame of a new fd must be CGConnect; anything else is dropped silently.
            s_->update([](Stats& st) { ++st.protocolErrors; });
            s_->logf("replay game: first frame id=%u is not CGConnect; staying silent like the server", static_cast<unsigned>(id));
            return;
        }
        switch (id) {
        case pg::CGConnect::PACKET_ID: {
            if (phase_ != Phase::Connect) {
                s_->update([](Stats& st) { ++st.protocolErrors; });
                s_->logf("replay game: CGConnect repeated on one socket; ignored");
                return;
            }
            pg::DecodeResult result;
            auto packet = pg::decodePacket(pg::Proto::Game, id, frame.body.data(), frame.body.size(), &result, true);
            const auto* connect = packet ? static_cast<const pg::CGConnect*>(packet.get()) : nullptr;
            const bool ok = connect && connect->guid == s_->options.guid && connect->key == s_->options.key;
            if (!ok) {
                // Unknown GUID or wrong key: the server returns without any reply.
                s_->update([](Stats& st) { ++st.protocolErrors; });
                s_->logf("replay game: CGConnect guid=%u key_ok=0; no reply (server silence)",
                         connect ? static_cast<unsigned>(connect->guid) : 0u);
                return;
            }
            s_->update([&](Stats& st) { st.connectFirst = first; });
            pushRecord(s_->server[0]);
            if (scenario()) pushScenarioHandshake(s_->server[1]); // CYS-SFX
            else pushRecord(s_->server[1]);
            phase_ = Phase::Connected;
            s_->logf("replay game: CGConnect guid=%u idx=%04x -> KeyExchange + GCConnect (recorded)",
                     static_cast<unsigned>(connect->guid), static_cast<unsigned>(idx));
            break;
        }
        case pg::CGEnterScene::PACKET_ID: {
            if (phase_ != Phase::Connected) {
                s_->update([](Stats& st) { ++st.protocolErrors; });
                s_->logf("replay game: CGEnterScene outside the connect handshake; ignored");
                return;
            }
            if (scenario()) pushScenarioHandshake(s_->server[2]); // CYS-SFX
            else pushRecord(s_->server[2]);
            phase_ = Phase::Entered;
            entered_ = true;
            enterTime_ = Clock::now();
            nextDue_ = enterTime_;
            s_->update([](Stats& st) { st.entered = true; });
            s_->logf("replay game: CGEnterScene (%u B) -> GCEnterScene (recorded) obj=%u; world stream %u frames gap=%u ms",
                     size, static_cast<unsigned>(s_->stats.myObjectId), static_cast<unsigned>(s_->world.size()),
                     static_cast<unsigned>(s_->options.frameGapMs));
            break;
        }
        case pg::CGHeartBeat::PACKET_ID:
            s_->update([](Stats& st) { ++st.heartbeats; });
            break;
        case pg::CGCharMove::PACKET_ID: {
            unsigned moves = 0;
            s_->update([&](Stats& st) { moves = ++st.moves; });
            pg::DecodeResult result;
            auto packet = pg::decodePacket(pg::Proto::Game, id, frame.body.data(), frame.body.size(), &result, true);
            const auto* move = packet ? static_cast<const pg::CGCharMove*>(packet.get()) : nullptr;
            if (!move || phase_ != Phase::Entered || !s_->options.moveEcho) {
                if (moves <= MaxMoveLogs) s_->logf("replay game: CGCharMove (%u B) recorded; no echo", size);
                return;
            }
            // The scene broadcasts the mover's path back to it (character.lua broadcast(self, msg, true)).
            pg::GCCharMove echo;
            echo.m_objID = s_->stats.myObjectId;
            echo.start_time = static_cast<uint32_t>(std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - enterTime_).count());
            echo.handleID = static_cast<int32_t>(move->handleID);
            echo.flag = 0;
            for (const auto& target : move->targetPos) {
                if (echo.path.size() >= 16) break;
                pg::GCCharMove::E_path node;
                node.x = target.x; node.y = target.y;
                echo.path.push_back(node);
            }
            echo.size = static_cast<uint8_t>(echo.path.size());
            if (echo.path.empty()) return;
            pushPacket(echo);
            s_->update([](Stats& st) { ++st.moveEchoes; });
            if (moves <= MaxMoveLogs)
                s_->logf("replay game: CGCharMove handle=%u targets=%u -> GCCharMove echo obj=%u", static_cast<unsigned>(move->handleID),
                         static_cast<unsigned>(echo.path.size()), static_cast<unsigned>(echo.m_objID));
            break;
        }
        case pg::CGAskQuit::PACKET_ID: {
            pg::GCRetAskQuit ack;
            ack.flag = 0;
            pushPacket(ack);
            closeAfterDrain_ = true;
            s_->update([](Stats& st) { ++st.quits; st.quitAcked = true; });
            s_->logf("replay game: CGAskQuit -> GCRetAskQuit flag=0; the stream closes after delivery");
            break;
        }
        // CYS-CORE ------------------------------------------------------------------------------------
        case pg::CGLockTarget::PACKET_ID: case pg::CGCharUseSkill::PACKET_ID: case pg::CGChat::PACKET_ID:
        case pg::CGOpenItemBox::PACKET_ID: case pg::CGPickBoxItem::PACKET_ID: case pg::CGAskMyBagList::PACKET_ID:
        case pg::CGAskDetailSkillList::PACKET_ID: case pg::CGPlayerDieResult::PACKET_ID: {
            if (!s_->options.coreLoop || phase_ != Phase::Entered) { recordUnknown(id, size); return; }
            pg::DecodeResult result;
            auto packet = pg::decodePacket(pg::Proto::Game, id, frame.body.data(), frame.body.size(), &result, true);
            if (!packet) {
                s_->update([](Stats& st) { ++st.protocolErrors; });
                s_->logf("replay game: core packet id=%u (%u B) failed strict decode; no reply", static_cast<unsigned>(id), size);
                return;
            }
            core(*packet, size);
            break;
        }
        // CYS-QUEST -----------------------------------------------------------------------------------
        case pg::CGCharDefaultEvent::PACKET_ID: case pg::CGEventRequest::PACKET_ID: case pg::CGAskMissionList::PACKET_ID:
        case pg::CGMissionAccept::PACKET_ID: case pg::CGMissionContinue::PACKET_ID: case pg::CGMissionSubmit::PACKET_ID: {
            if (!s_->options.questLoop || phase_ != Phase::Entered) { recordUnknown(id, size); return; }
            pg::DecodeResult result;
            auto packet = pg::decodePacket(pg::Proto::Game, id, frame.body.data(), frame.body.size(), &result, true);
            if (!packet) {
                s_->update([](Stats& st) { ++st.protocolErrors; });
                s_->logf("replay game: quest packet id=%u (%u B) failed strict decode; no reply", static_cast<unsigned>(id), size);
                return;
            }
            quest(*packet);
            break;
        }
        default:
            recordUnknown(id, size);
            break;
        }
    }

    // CYS-QUEST: synthetic NPC dialogue / mission responder with the private server's layouts (mission.lua /
    // combat.lua bos, script_base.lua Dispatch*). Offline stand-in for Trieu Thien Su (odali_xinshoutian): mission
    // 1400 "So nhap giang ho" (script 210262) is ready to hand in, 1417 "Phao hoa mung le" (210266) can be accepted.
    // The dialogue NPC id is a non-existing object on purpose: Quest.lua cares for the NPC distance (> 3 m closes).
    static const uint32_t kQuestNpc = 0x7FFFFF01;
    void quest(const pg::Packet& packet) {
        const uint32_t my = s_->stats.myObjectId;
        auto line = [](const char* utf8) { pg::GCScriptCommand::E_event_2 e; e.set_str(utf8); return e; };
        switch (packet.packetId()) {
        case pg::CGAskMissionList::PACKET_ID: {
            pg::GCMissionList list;
            list.m_objID = my;
            unsigned n = 0;
            auto put = [&](int32_t id, int32_t script, int32_t p0) {
                auto& m = list.char_missions[n]; m.id = id; m.index = script; m.yFlag = 1; m.params.fill(0); m.params[0] = p0;
                list.m_uMissionListFlags |= 1u << n; ++n;
            };
            if (!questSubmitted_) put(1400, 210262, 1);
            put(1401, 210200, 1);
            if (questAccepted_) put(1417, 210266, 0);
            for (unsigned i = n; i < 20; ++i) { list.char_missions[i].id = -1; list.char_missions[i].index = -1; }
            list.n_char_missions = static_cast<uint8_t>(n);
            list.mission_have_done_flags[1424 >> 5] |= 1u << (1424 & 31);
            if (questSubmitted_) list.mission_have_done_flags[1400 >> 5] |= 1u << (1400 & 31);
            pushPacket(list);
            s_->logf("replay game: CGAskMissionList -> GCMissionList missions=%u", n);
            break;
        }
        case pg::CGCharDefaultEvent::PACKET_ID: {
            pg::GCScriptCommand menu; menu.m_nCmdID = 0; menu.target_id = static_cast<int32_t>(kQuestNpc);
            pg::GCScriptCommand::E_event text; text.flag = 2;
            text.set_str("  CYTest00 Huynh \xc4\x91\xe1\xbb\x87, giang h\xe1\xbb\x93 hi\xe1\xbb\x83m \xc3\xa1\x63, h\xc3\xa3y theo ta h\xe1\xbb\x8d\x63 v\xc3\xb5 ngh\xe1\xbb\x87 tr\xc6\xb0\xe1\xbb\x9b\x63.");
            menu.event.push_back(text);
            auto option = [&](int32_t script, int32_t index, int32_t type, const char* utf8) {
                pg::GCScriptCommand::E_event e; e.flag = 1; e.index = index; e.type = type; e.script_id = script; e.split = -1;
                e.set_str_2(utf8); menu.event.push_back(e);
            };
            option(2030, 60000, 6, "Nh\xe1\xba\xadn b\xc3\xb9 Phi Ho\xc3\xa0ng Th\xe1\xba\xa1\x63h");
            if (!questSubmitted_) option(210262, 1, 2, "S\xc6\xa1 nh\xe1\xba\xadp giang h\xe1\xbb\x93");
            if (!questAccepted_) option(210266, 1, 1, "Ph\xc3\xa1o hoa m\xe1\xbb\xabng l\xe1\xbb\x85");
            else option(210266, 1, 1, "Ph\xc3\xa1o hoa m\xe1\xbb\xabng l\xe1\xbb\x85");
            menu.size = static_cast<uint8_t>(menu.event.size());
            pushPacket(menu);
            s_->logf("replay game: CGCharDefaultEvent -> GCScriptCommand 0 options=%u", static_cast<unsigned>(menu.size - 1));
            break;
        }
        case pg::CGEventRequest::PACKET_ID: {
            const auto& req = static_cast<const pg::CGEventRequest&>(packet);
            if (req.m_objID == 210262) {
                pg::GCScriptCommand demand; demand.m_nCmdID = 3; demand.target_id_2 = kQuestNpc; demand.m_objID_2 = 210262;
                demand.m_idMission_2 = 1400; demand.done = 1;
                pg::GCScriptCommand::E_event_3 a; a.set_str("S\xc6\xa1 nh\xe1\xba\xadp giang h\xe1\xbb\x93");
                pg::GCScriptCommand::E_event_3 b; b.set_str("#{XSRW_100111_2}");
                demand.event_3.push_back(a); demand.event_3.push_back(b); demand.size = 2; demand.m_yDemandCount = 0;
                pushPacket(demand);
                s_->logf("replay game: CGEventRequest 210262 -> GCScriptCommand 3 done=1");
            } else if (req.m_objID == 210266) {
                pg::GCScriptCommand info; info.m_nCmdID = 1; info.target_id_2 = kQuestNpc; info.m_objID = 210266; info.m_idMission = 1417;
                info.event_2.push_back(line("Ph\xc3\xa1o hoa m\xe1\xbb\xabng l\xe1\xbb\x85"));
                info.event_2.push_back(line("#{XSRW_100111_1}"));
                info.size = static_cast<uint8_t>(info.event_2.size()); info.m_yBonusCount = 0;
                pushPacket(info);
                s_->logf("replay game: CGEventRequest 210266 -> GCScriptCommand 1");
            } else {
                recordUnknown(pg::CGEventRequest::PACKET_ID, 16);
            }
            break;
        }
        case pg::CGMissionAccept::PACKET_ID: {
            questAccepted_ = true;
            pg::GCMissionAdd add; add.id = 1417; add.index = 210266; add.yFlag = 1; add.params.fill(0);
            pushPacket(add);
            s_->logf("replay game: CGMissionAccept -> GCMissionAdd 1417/210266");
            break;
        }
        case pg::CGMissionContinue::PACKET_ID: {
            pg::GCScriptCommand cont; cont.m_nCmdID = 4; cont.target_id = static_cast<int32_t>(kQuestNpc); cont.m_objID = 210262; cont.m_idMission = 1400;
            cont.event_4.push_back(line("S\xc6\xa1 nh\xe1\xba\xadp giang h\xe1\xbb\x93"));
            cont.event_4.push_back(line("#{XSRW_100111_2}"));
            cont.size_2 = static_cast<int8_t>(cont.event_4.size());
            pg::GCScriptCommand::E_items money; money.flag = 1; money.item_index = 200;
            pg::GCScriptCommand::E_items item; item.flag = 4; item.count = 10; item.item_index = static_cast<int32_t>(s_->options.coreItemIndex);
            cont.items.push_back(money); cont.items.push_back(item); cont.item_count = 2;
            pushPacket(cont);
            s_->logf("replay game: CGMissionContinue -> GCScriptCommand 4 bonus=2");
            break;
        }
        case pg::CGMissionSubmit::PACKET_ID: {
            questSubmitted_ = true;
            pg::GCMissionRemove remove; remove.id = 1400;
            pushPacket(remove);
            pg::GCMissionHaveDoneFlag done; done.mission_id = 1400; done.flag = 1;
            pushPacket(done);
            s_->logf("replay game: CGMissionSubmit radio=%d -> GCMissionRemove 1400 + GCMissionHaveDoneFlag",
                     static_cast<const pg::CGMissionSubmit&>(packet).select_radio_id);
            break;
        }
        default:
            break;
        }
    }
    bool questAccepted_ = false, questSubmitted_ = false;

    void recordUnknown(uint16_t id, unsigned size) {
        unsigned seen = 0;
        s_->update([&](Stats& st) { ++st.unexpected; });
        for (uint16_t known : loggedIds_) if (known == id) ++seen;
        if (!seen && loggedIds_.size() < 64) {
            loggedIds_.push_back(id);
            s_->logf("replay game: client packet id=%u size=%u recorded; no reply", static_cast<unsigned>(id), size);
        }
    }

    // CYS-CORE: synthetic core-loop responder. Every reply is a ProtocolGen packet encoded with the codec the
    // real server's bos() uses (misc.lua/item.lua/social.lua), so Game.exe exercises the ported handlers.
    struct Pending { Clock::time_point due; std::vector<uint8_t> bytes; };
    bool flushPending() {
        bool any = false;
        const Clock::time_point now = Clock::now();
        while (!pending_.empty() && pending_.front().due <= now) {
            out_.bytes.insert(out_.bytes.end(), pending_.front().bytes.begin(), pending_.front().bytes.end());
            pending_.pop_front();
            s_->update([](Stats& st) { ++st.gameRx; });
            any = true;
        }
        return any;
    }
    void pushLater(const pg::Packet& packet, uint32_t delayMs) {
        Pending p;
        p.due = Clock::now() + std::chrono::milliseconds(delayMs);
        Session::Impl::appendPacket(p.bytes, packet, synthIdx_);
        synthIdx_ = static_cast<uint16_t>(synthIdx_ + 0x100);
        pending_.push_back(std::move(p));
    }
    static pg::ItemInfo_bos MakeItem(uint32_t itemIndex, uint32_t series) {
        pg::ItemInfo_bos item;
        item.guid.world = 1; item.guid.server = 1; item.guid.mask = 0; item.guid.series = series;
        item.item_index = static_cast<int32_t>(itemIndex);
        item.rule = 0; item.status = 0; item.quality = 0;
        return item;
    }
    void core(const pg::Packet& packet, unsigned size) {
        const uint32_t my = s_->stats.myObjectId;
        switch (packet.packetId()) {
        case pg::CGLockTarget::PACKET_ID: {
            lockedTarget_ = static_cast<const pg::CGLockTarget&>(packet).target_id;
            s_->update([](Stats& st) { ++st.coreLocks; });
            s_->logf("replay game: CGLockTarget target=%d (server set_locked_target; no reply)", lockedTarget_);
            break;
        }
        case pg::CGCharUseSkill::PACKET_ID: {
            const auto& use = static_cast<const pg::CGCharUseSkill&>(packet);
            const uint32_t target = static_cast<uint32_t>(use.targetObjID);
            auto pos = s_->monsterPos.find(target);
            if (pos == s_->monsterPos.end() || killed_.count(target)) {
                s_->update([](Stats& st) { ++st.coreUnknownTargets; });
                pg::GCOperateResult refuse; refuse.result = -4; // OR_TARGET_DIE / unknown target
                pushPacket(refuse);
                s_->logf("replay game: CGCharUseSkill skill=%d target=%u unknown or dead -> GCOperateResult -4",
                         use.skillID, static_cast<unsigned>(target));
                break;
            }
            const uint32_t logic = ++logicCount_;
            pg::GCCharSkill_Send send;
            send.m_objID = my; send.logic_count = logic; send.skill_id = static_cast<uint32_t>(use.skillID);
            send.target_id = use.targetObjID; send.target_pos_x = pos->second.first; send.target_pos_y = pos->second.second;
            pushPacket(send);
            pg::GCTargetListAndHitFlags hit;
            hit.data_type = 0; hit.m_objID = my; hit.logic_count = logic; hit.skill_or_special_obj_id = send.skill_id;
            hit.target_pos_x = pos->second.first; hit.target_pos_y = pos->second.second;
            hit.target_list.push_back(target); hit.size = 1;
            pushPacket(hit);
            pg::GCDetailHealsAndDamages dmg;
            dmg.dirty_flags = 1; dmg.reciver = target; dmg.sender = static_cast<int32_t>(my); dmg.logic_count = logic;
            dmg.hp_modification = s_->options.coreDamage; dmg.is_critical_hit = 0;
            pushPacket(dmg);
            const unsigned hits = ++hits_[target];
            const unsigned total = s_->options.coreHitsToKill ? s_->options.coreHitsToKill : 1;
            const unsigned percent = hits >= total ? 0 : 100 - (100 * hits) / total;
            pg::GCCharBaseAttrib attrib;
            attrib.m_objID = target; attrib.data_id = 0;
            attrib.new_flags.fill(0); attrib.new_flags[0] = 0x10; // uFlags[0] & 0x10 = hp_percent (combat.lua set_hp_percent)
            attrib.hp_percent = static_cast<uint8_t>(percent);
            pushPacket(attrib);
            s_->update([](Stats& st) { ++st.coreSkills; });
            if (percent == 0) {
                killed_.insert(target);
                pg::GCNewItemBox box;
                box.m_objID = nextBoxId_++; box.owner_guid = static_cast<int32_t>(s_->options.guid); box.monster_id = static_cast<int32_t>(target);
                box.world_pos_x = pos->second.first; box.world_pos_y = pos->second.second; box.item_box_type = -1; box.unknow_7 = 0;
                pushPacket(box);
                Box entry; entry.x = box.world_pos_x; entry.y = box.world_pos_y;
                entry.items.push_back(MakeItem(s_->options.coreItemIndex, 1000 + box.m_objID));
                boxes_[box.m_objID] = entry;
                pg::GCDelObject corpse; corpse.m_objID = target; corpse.m_idScene = s_->sceneId;
                pushLater(corpse, s_->options.coreDeleteDelayMs);
                s_->update([](Stats& st) { ++st.coreKills; });
                s_->logf("replay game: CGCharUseSkill skill=%d target=%u hit %u/%u -> hp 0, GCNewItemBox obj=%u at %.1f,%.1f, GCDelObject in %u ms",
                         use.skillID, static_cast<unsigned>(target), hits, total, static_cast<unsigned>(box.m_objID),
                         box.world_pos_x, box.world_pos_y, static_cast<unsigned>(s_->options.coreDeleteDelayMs));
            } else {
                s_->logf("replay game: CGCharUseSkill skill=%d target=%u hit %u/%u -> 331+909+1692(%d)+455(hp %u%%)",
                         use.skillID, static_cast<unsigned>(target), hits, total, s_->options.coreDamage, percent);
            }
            break;
        }
        case pg::CGChat::PACKET_ID: {
            const auto& chat = static_cast<const pg::CGChat&>(packet);
            pg::GCChat echo;
            echo.ChatType = chat.ChatType;
            echo.set_Contex(chat.Contex);
            echo.set_SourceName(s_->options.nickname);
            echo.unknow_3 = 1; echo.Sourceid = my; echo.unknow_10 = 0;
            pushPacket(echo);
            s_->update([](Stats& st) { ++st.coreChats; });
            s_->logf("replay game: CGChat type=%u %u B -> GCChat echo (scene broadcast incl. sender)", static_cast<unsigned>(chat.ChatType), size);
            break;
        }
        case pg::CGOpenItemBox::PACKET_ID: {
            const uint32_t boxId = static_cast<const pg::CGOpenItemBox&>(packet).m_objID;
            auto found = boxes_.find(boxId);
            pg::GCBoxItemList list;
            list.m_objID = boxId; list.item_box_type = -1;
            if (found != boxes_.end()) list.item_list = found->second.items;
            list.size = static_cast<uint8_t>(list.item_list.size());
            pushPacket(list);
            s_->update([](Stats& st) { ++st.coreBoxOpens; });
            s_->logf("replay game: CGOpenItemBox obj=%u -> GCBoxItemList items=%u", static_cast<unsigned>(boxId), static_cast<unsigned>(list.size));
            break;
        }
        case pg::CGPickBoxItem::PACKET_ID: {
            const auto& pick = static_cast<const pg::CGPickBoxItem&>(packet);
            auto found = boxes_.find(pick.m_objID);
            pg::GCPickResult res;
            res.m_objID = pick.m_objID; res.item_box_type = -1; res.item_guid = pick.item_guid; res.item_box_guid = pick.item_guid;
            res.result = 2; res.bag_index = 0; // PICK_INVALID_ITEM
            if (found != boxes_.end()) {
                auto& items = found->second.items;
                for (size_t i = 0; i < items.size(); ++i) {
                    const pg::ItemGUID& g = items[i].guid;
                    if (g.world == pick.item_guid.world && g.server == pick.item_guid.server && g.series == pick.item_guid.series) {
                        res.result = 0; res.bag_index = static_cast<uint8_t>(bag_.size());
                        pg::GCItemInfo info;
                        info.bagIndex = res.bag_index; info.unknow_1 = 0; info.item = items[i]; info.askid = 0; info.bag_type = 0;
                        bag_.push_back(items[i]);
                        items.erase(items.begin() + static_cast<std::ptrdiff_t>(i));
                        pushPacket(res);
                        pushPacket(info);
                        if (items.empty()) {
                            pg::GCDelObject gone; gone.m_objID = pick.m_objID; gone.m_idScene = s_->sceneId;
                            pushPacket(gone);
                            boxes_.erase(found);
                        }
                        s_->update([](Stats& st) { ++st.corePicks; });
                        s_->logf("replay game: CGPickBoxItem box=%u -> GCPickResult ok bag_index=%u + GCItemInfo item=%u",
                                 static_cast<unsigned>(pick.m_objID), static_cast<unsigned>(res.bag_index),
                                 static_cast<unsigned>(info.item.item_index));
                        return;
                    }
                }
            }
            pushPacket(res);
            s_->update([](Stats& st) { ++st.corePicks; ++st.protocolErrors; });
            s_->logf("replay game: CGPickBoxItem box=%u unknown item -> GCPickResult result=2", static_cast<unsigned>(pick.m_objID));
            break;
        }
        case pg::CGAskMyBagList::PACKET_ID: {
            pg::GCMyBagList list;
            list.m_Mode = 0;
            for (size_t i = 0; i < bag_.size(); ++i) {
                pg::GCMyBagList::E_list entry;
                entry.index = static_cast<uint8_t>(i); entry.guid = bag_[i].guid;
                entry.item_index = static_cast<uint32_t>(bag_[i].item_index); entry.count = 1;
                list.list.push_back(entry);
            }
            list.m_AskCount = static_cast<uint8_t>(list.list.size());
            pushPacket(list);
            s_->update([](Stats& st) { ++st.coreBagAsks; });
            s_->logf("replay game: CGAskMyBagList -> GCMyBagList items=%u", static_cast<unsigned>(list.m_AskCount));
            break;
        }
        case pg::CGAskDetailSkillList::PACKET_ID: {
            pg::GCDetailSkillList list;
            list.m_objID = my;
            list.m_aSkill.push_back(0); // SkillData 0 = normal attack (skilldata: cooldown 800 ms)
            list.m_wNumSkill = static_cast<uint16_t>(list.m_aSkill.size());
            pushPacket(list);
            s_->update([](Stats& st) { ++st.coreSkillLists; });
            s_->logf("replay game: CGAskDetailSkillList -> GCDetailSkillList skills=%u", static_cast<unsigned>(list.m_wNumSkill));
            break;
        }
        case pg::CGPlayerDieResult::PACKET_ID: {
            pg::GCPlayerRelive relive;
            pushPacket(relive);
            s_->update([](Stats& st) { ++st.coreDieResults; });
            s_->logf("replay game: CGPlayerDieResult -> GCPlayerRelive");
            break;
        }
        default:
            break;
        }
    }

    struct Box { float x = 0, y = 0; std::vector<pg::ItemInfo_bos> items; };
    int32_t lockedTarget_ = -1;
    uint32_t logicCount_ = 0, nextBoxId_ = 0x00FF0001;
    std::map<uint32_t, unsigned> hits_;
    std::set<uint32_t> killed_;
    std::map<uint32_t, Box> boxes_;
    std::vector<pg::ItemInfo_bos> bag_;
    std::deque<Pending> pending_;

    enum class Phase { Connect, Connected, Entered };
    std::shared_ptr<Session::Impl> s_;
    cysbot::FrameAssembler assembler_{4096};
    Outbound out_;
    Phase phase_ = Phase::Connect;
    bool connected_ = false, closed_ = false, closeAfterDrain_ = false, entered_ = false;
    Clock::time_point enterTime_, nextDue_;
    size_t worldNext_ = 0;
    uint16_t expectedIdx_ = 0, synthIdx_ = 0;
    std::vector<uint16_t> loggedIds_;
};

class LoginFactory : public StreamFactory {
public:
    explicit LoginFactory(std::shared_ptr<Session::Impl> impl) : s_(std::move(impl)) {}
    std::unique_ptr<Stream> create() override { return std::unique_ptr<Stream>(new LoginStream(s_)); }
private:
    std::shared_ptr<Session::Impl> s_;
};

class GameFactory : public StreamFactory {
public:
    explicit GameFactory(std::shared_ptr<Session::Impl> impl) : s_(std::move(impl)) {}
    std::unique_ptr<Stream> create() override { return std::unique_ptr<Stream>(new GameStream(s_)); }
private:
    std::shared_ptr<Session::Impl> s_;
};

} // namespace

Session::Session(std::vector<Record> records, const Options& options) : impl_(new Impl) {
    impl_->records = std::move(records);
    impl_->options = options;
    for (size_t i = 0; i < impl_->records.size(); ++i)
        if (!impl_->records[i].c2s) impl_->server.push_back(i);
    for (size_t i = 3; i < impl_->server.size(); ++i) impl_->world.push_back(impl_->server[i]);
    if (!options.scenario.steps.empty()) { // CYS-SFX: the scenario replaces the recorded world frames
        // The own character keeps its recorded appearance/attribute frames (GCCharBaseAttrib 455, GCDetailAttrib 1772,
        // GCDetailEquipList 288) moved to the scenario object id; the name becomes the scenario character name.
        uint32_t recordedSelf = 0;
        if (impl_->server.size() >= 3) {
            const Record& enter = impl_->records[impl_->server[2]];
            auto packet = pg::decodePacket(pg::Proto::Game, enter.id, enter.body.data(), enter.body.size(), nullptr, true);
            if (packet && enter.id == pg::GCEnterScene::PACKET_ID) recordedSelf = static_cast<const pg::GCEnterScene&>(*packet).m_objID;
        }
        for (size_t index : impl_->world) {
            const Record& r = impl_->records[index];
            if (r.body.size() < 4 || little(r.body.data(), 4) != recordedSelf) continue;
            if (r.id != pg::GCCharBaseAttrib::PACKET_ID && r.id != 1772 && r.id != 288) continue;
            Record copy = r;
            if (r.id == pg::GCCharBaseAttrib::PACKET_ID) {
                auto packet = pg::decodePacket(pg::Proto::Game, r.id, r.body.data(), r.body.size(), nullptr, true);
                if (!packet) continue;
                auto& a = static_cast<pg::GCCharBaseAttrib&>(*packet);
                a.m_objID = options.scenario.myObj;
                if (!options.scenario.selfName.empty()) a.set_m_szName(options.scenario.selfName);
                std::vector<uint8_t> frame;
                if (!pg::encodeFrame(*packet, r.idx, frame) || frame.size() < 6) continue;
                copy.body.assign(frame.begin() + 6, frame.end());
            } else {
                const uint32_t me = options.scenario.myObj;
                for (int k = 0; k < 4; ++k) copy.body[k] = static_cast<uint8_t>(me >> (8 * k));
            }
            impl_->selfFrames.push_back(std::move(copy));
        }
        impl_->world.clear();
        impl_->stats.scenarioSteps = static_cast<uint32_t>(options.scenario.steps.size());
    }
    impl_->stats.worldTotal = static_cast<uint32_t>(impl_->world.size());
    if (impl_->server.size() >= 3) {
        const Record& enter = impl_->records[impl_->server[2]];
        auto packet = pg::decodePacket(pg::Proto::Game, enter.id, enter.body.data(), enter.body.size(), nullptr, true);
        if (packet && enter.id == pg::GCEnterScene::PACKET_ID) {
            impl_->stats.myObjectId = static_cast<const pg::GCEnterScene&>(*packet).m_objID;
            impl_->sceneId = static_cast<const pg::GCEnterScene&>(*packet).sceneid;
        }
        if (!options.scenario.steps.empty()) { impl_->stats.myObjectId = options.scenario.myObj; impl_->sceneId = options.scenario.sceneId; } // CYS-SFX
    }
    // CYS-CORE: monster positions of the recorded stream (targets of the synthetic responder).
    if (options.coreLoop) {
        for (size_t index : impl_->world) {
            const Record& r = impl_->records[index];
            if (r.id != pg::GCNewMonster::PACKET_ID && r.id != pg::GCNewMonster_Move::PACKET_ID) continue;
            auto packet = pg::decodePacket(pg::Proto::Game, r.id, r.body.data(), r.body.size(), nullptr, true);
            if (!packet) continue;
            if (r.id == pg::GCNewMonster::PACKET_ID) {
                const auto& m = static_cast<const pg::GCNewMonster&>(*packet);
                impl_->monsterPos[m.m_objID] = std::make_pair(m.worldPos_x, m.worldPos_y);
            } else {
                const auto& m = static_cast<const pg::GCNewMonster_Move&>(*packet);
                impl_->monsterPos[m.m_objID] = std::make_pair(m.world_pos_x, m.world_pos_y);
            }
        }
        impl_->logf("replay: core-loop responder enabled monsters=%u item=%u hits_to_kill=%u",
                    static_cast<unsigned>(impl_->monsterPos.size()), static_cast<unsigned>(options.coreItemIndex),
                    static_cast<unsigned>(options.coreHitsToKill));
    }
    impl_->logf("replay: fixture loaded records=%u server=%u world=%u my_obj=%u guid=%u",
                static_cast<unsigned>(impl_->records.size()), static_cast<unsigned>(impl_->server.size()),
                static_cast<unsigned>(impl_->world.size()), static_cast<unsigned>(impl_->stats.myObjectId),
                static_cast<unsigned>(options.guid));
}

Session::~Session() {}

std::shared_ptr<StreamFactory> Session::loginFactory() { return std::shared_ptr<StreamFactory>(new LoginFactory(impl_)); }
std::shared_ptr<StreamFactory> Session::gameFactory() { return std::shared_ptr<StreamFactory>(new GameFactory(impl_)); }

Stats Session::stats() const {
    std::lock_guard<std::mutex> lock(impl_->mutex);
    return impl_->stats;
}

size_t Session::drainLog(std::vector<std::string>& out) {
    std::lock_guard<std::mutex> lock(impl_->mutex);
    const size_t count = impl_->log.size();
    for (auto& line : impl_->log) out.push_back(std::move(line));
    impl_->log.clear();
    return count;
}

const std::vector<Record>& Session::records() const { return impl_->records; }

std::vector<uint16_t> Session::serverIds() const {
    std::vector<uint16_t> ids;
    for (size_t index : impl_->server) ids.push_back(impl_->records[index].id);
    return ids;
}

}}} // namespace cys::net::replay
