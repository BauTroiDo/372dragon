// Tests/protocol/protocol_tests.cpp - test driver for the generated codec library Src/Shared/ProtocolGen.
//
//   --frames FILE          decode + re-encode every frame of a PGFRAME1 file (run_protocol_tests.py writes
//                          them): strict decode must succeed and re-encode byte-identically for frames
//                          flagged expect_ok; the direction must match the spec
//   --fuzz N               N mutation rounds over the loaded frames, plus truncation / extension sweeps,
//                          cross-id decoding and random bodies for every packet id. Nothing may crash;
//                          whatever decodes strictly must re-encode to exactly the input, whatever decodes
//                          leniently must re-encode to exactly the consumed prefix
//   --seed S               fuzz seed (default 20260912)
//   --dump-accepted FILE   write the fuzz inputs that decoded strictly (PGFRAME1) for the oracle check
//   --report FILE          TSV: set, proto, direction, id, name, body_size, status, frames, detail
//   --unit                 API unit tests (UTF-8 cut, setters, limits, frames, factory)
// Exit code 0 = everything passed.
#include "ProtocolGen.h"

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <set>
#include <string>
#include <tuple>
#include <vector>

namespace {

struct Frame {
    std::string set;
    uint8_t proto = 0;  // 0 game, 1 login
    uint8_t flags = 0;  // bit0 client->server, bit1 expect_ok
    uint16_t id = 0;
    uint16_t idx = 0;
    std::vector<uint8_t> body;
};

pg::Proto protoOf(uint8_t p) { return p ? pg::Proto::Login : pg::Proto::Game; }

bool loadFrames(const char* path, std::vector<Frame>& out) {
    FILE* f = std::fopen(path, "rb");
    if (!f) return false;
    char magic[8];
    if (std::fread(magic, 1, 8, f) != 8 || std::memcmp(magic, "PGFRAME1", 8) != 0) {
        std::fclose(f);
        return false;
    }
    std::string set = path;
    const size_t slash = set.find_last_of("/\\");
    if (slash != std::string::npos) set = set.substr(slash + 1);
    const size_t dot = set.rfind('.');
    if (dot != std::string::npos) set = set.substr(0, dot);
    bool ok = true;
    for (;;) {
        uint8_t h[10];
        const size_t n = std::fread(h, 1, 10, f);
        if (n == 0) break;
        if (n != 10) {
            ok = false;
            break;
        }
        Frame fr;
        fr.set = set;
        fr.proto = h[0];
        fr.flags = h[1];
        fr.id = static_cast<uint16_t>(h[2] | (h[3] << 8));
        fr.idx = static_cast<uint16_t>(h[4] | (h[5] << 8));
        const uint32_t len = static_cast<uint32_t>(h[6]) | (static_cast<uint32_t>(h[7]) << 8) |
                             (static_cast<uint32_t>(h[8]) << 16) | (static_cast<uint32_t>(h[9]) << 24);
        if (len > 0x10000) {
            ok = false;
            break;
        }
        fr.body.resize(len);
        if (len && std::fread(fr.body.data(), 1, len, f) != len) {
            ok = false;
            break;
        }
        out.push_back(std::move(fr));
    }
    std::fclose(f);
    return ok;
}

class FrameWriter {
public:
    explicit FrameWriter(const char* path) : f_(path ? std::fopen(path, "wb") : nullptr) {
        if (f_) std::fwrite("PGFRAME1", 1, 8, f_);
    }
    ~FrameWriter() {
        if (f_) std::fclose(f_);
    }
    bool ok() const { return f_ != nullptr; }
    size_t count() const { return count_; }
    void add(pg::Proto proto, uint16_t id, const std::vector<uint8_t>& body, size_t cap) {
        if (!f_ || count_ >= cap) return;
        const std::string key = std::string(1, static_cast<char>(proto)) + std::string(reinterpret_cast<const char*>(&id), 2) +
                                std::string(body.begin(), body.end());
        if (!seen_.insert(key).second) return;
        uint8_t h[10];
        h[0] = proto == pg::Proto::Login ? 1 : 0;
        h[1] = 2;
        h[2] = static_cast<uint8_t>(id);
        h[3] = static_cast<uint8_t>(id >> 8);
        h[4] = h[5] = 0;
        const uint32_t len = static_cast<uint32_t>(body.size());
        for (int i = 0; i < 4; ++i) h[6 + i] = static_cast<uint8_t>(len >> (8 * i));
        std::fwrite(h, 1, 10, f_);
        if (len) std::fwrite(body.data(), 1, len, f_);
        ++count_;
    }

private:
    FILE* f_;
    size_t count_ = 0;
    std::set<std::string> seen_;
};

// ------------------------------------------------------------------ frame round trip
struct Outcome {
    const char* status;
    std::string detail;
};

Outcome checkFrame(const Frame& fr) {
    const pg::Proto proto = protoOf(fr.proto);
    const pg::PacketInfo* info = pg::findPacket(proto, fr.id);
    if (!info) return {"NO_SPEC", ""};
    if (pg::isClientToServer(info->dir) != ((fr.flags & 1) != 0))
        return {"DIR_MISMATCH", std::string("spec says ") + pg::dirName(info->dir)};
    pg::DecodeResult res;
    std::unique_ptr<pg::Packet> p = pg::decodePacket(proto, fr.id, fr.body.data(), fr.body.size(), &res, true);
    if (!p) {
        char buf[256];
        std::snprintf(buf, sizeof(buf), "%s at %u (%s), used %u of %u", res.error, static_cast<unsigned>(res.errorPos),
                      res.field, static_cast<unsigned>(res.used), static_cast<unsigned>(fr.body.size()));
        return {"DECODE_FAIL", buf};
    }
    std::vector<uint8_t> again;
    pg::encodeBody(*p, again);
    if (again != fr.body) {
        size_t i = 0;
        while (i < again.size() && i < fr.body.size() && again[i] == fr.body[i]) ++i;
        char buf[128];
        std::snprintf(buf, sizeof(buf), "first diff at byte %u (len %u vs %u)", static_cast<unsigned>(i),
                      static_cast<unsigned>(again.size()), static_cast<unsigned>(fr.body.size()));
        return {"ROUNDTRIP_DIFF", buf};
    }
    if (p->wireSize() != fr.body.size()) return {"SIZE_DIFF", "wireSize() differs from the body size"};
    std::vector<uint8_t> frame;
    if (!pg::encodeFrame(*p, fr.idx, frame) || frame.size() != fr.body.size() + 6 || frame[0] != (fr.id & 0xFF) ||
        frame[1] != (fr.id >> 8) || frame[4] != (fr.idx & 0xFF) || frame[5] != (fr.idx >> 8) ||
        !std::equal(fr.body.begin(), fr.body.end(), frame.begin() + 6))
        return {"FRAME_DIFF", "encodeFrame header/body mismatch"};
    return {"OK", ""};
}

// ------------------------------------------------------------------ fuzz
struct Rng {
    uint64_t s;
    explicit Rng(uint64_t seed) : s(seed ? seed : 0x9E3779B97F4A7C15ULL) {}
    uint64_t next() {
        s ^= s << 13;
        s ^= s >> 7;
        s ^= s << 17;
        return s;
    }
    uint32_t below(uint32_t n) { return n ? static_cast<uint32_t>(next() % n) : 0; }
};

struct FuzzStats {
    uint64_t runs = 0, strictOk = 0, lenientOk = 0, violations = 0;
    std::vector<std::string> samples;
};

// --dump-violations: each violation writes two records, the input (expect_ok) and our re-encoding.
FrameWriter* g_violations = nullptr;

void dumpViolation(pg::Proto proto, uint16_t id, const std::vector<uint8_t>& input, const std::vector<uint8_t>& again) {
    if (!g_violations) return;
    g_violations->add(proto, id, input, 2000);
    g_violations->add(proto, id, again, 2000);
}

void fuzzOne(pg::Proto proto, uint16_t id, const std::vector<uint8_t>& body, FuzzStats& st, FrameWriter* dump,
             size_t dumpCap) {
    ++st.runs;
    pg::DecodeResult res;
    std::unique_ptr<pg::Packet> p = pg::decodePacket(proto, id, body.data(), body.size(), &res, true);
    if (p) {
        ++st.strictOk;
        std::vector<uint8_t> again;
        pg::encodeBody(*p, again);
        if (again != body || p->wireSize() != body.size()) {
            dumpViolation(proto, id, body, again);
            ++st.violations;
            if (st.samples.size() < 40) {
                char buf[160];
                std::snprintf(buf, sizeof(buf), "strict re-encode differs: %s id %u (%s) size %u -> %u",
                              pg::protoName(proto), id, p->packetName(), static_cast<unsigned>(body.size()),
                              static_cast<unsigned>(again.size()));
                st.samples.push_back(buf);
            }
        }
        if (dump) dump->add(proto, id, body, dumpCap);
    }
    std::unique_ptr<pg::Packet> q = pg::decodePacket(proto, id, body.data(), body.size(), &res, false);
    if (q) {
        ++st.lenientOk;
        std::vector<uint8_t> again;
        pg::encodeBody(*q, again);
        if (again.size() != res.used || !std::equal(again.begin(), again.end(), body.begin())) {
            dumpViolation(proto, id, std::vector<uint8_t>(body.begin(), body.begin() + res.used), again);
            ++st.violations;
            if (st.samples.size() < 40) {
                char buf[160];
                std::snprintf(buf, sizeof(buf), "lenient re-encode differs from the consumed prefix: id %u (%s) used %u",
                              id, q->packetName(), static_cast<unsigned>(res.used));
                st.samples.push_back(buf);
            }
        }
    }
}

void mutate(std::vector<uint8_t>& b, Rng& rng) {
    static const uint32_t kBoundary[] = {0u, 1u, 0x7Fu, 0x80u, 0xFFu, 0x7FFFu, 0x8000u, 0xFFFFu, 0x7FFFFFFFu,
                                         0x80000000u, 0xFFFFFFFFu, 16u, 30u, 31u, 255u};
    const int ops = 1 + static_cast<int>(rng.below(6));
    for (int k = 0; k < ops; ++k) {
        const uint32_t op = rng.below(7);
        if (b.empty() && op != 3) {
            b.push_back(static_cast<uint8_t>(rng.next()));
            continue;
        }
        const size_t at = rng.below(static_cast<uint32_t>(b.size()));
        switch (op) {
            case 0: b[at] ^= static_cast<uint8_t>(1u << rng.below(8)); break;
            case 1: b[at] = static_cast<uint8_t>(rng.next()); break;
            case 2: {
                static const uint8_t kBytes[] = {0x00, 0xFF, 0x7F, 0x80, 0x01, 0x1E, 0x1F, 0x20};
                b[at] = kBytes[rng.below(8)];
                break;
            }
            case 3: b.insert(b.begin() + (b.empty() ? 0 : at), static_cast<uint8_t>(rng.next())); break;
            case 4: b.erase(b.begin() + at); break;
            default: {
                const uint32_t v = kBoundary[rng.below(sizeof(kBoundary) / sizeof(kBoundary[0]))];
                const size_t w = (op == 5) ? 2 : 4;
                for (size_t i = 0; i < w && at + i < b.size(); ++i) b[at + i] = static_cast<uint8_t>(v >> (8 * i));
                break;
            }
        }
    }
}

// ------------------------------------------------------------------ unit tests
int g_unitFail = 0;
#define UNIT(cond)                                                                  \
    do {                                                                            \
        if (!(cond)) {                                                              \
            ++g_unitFail;                                                           \
            std::printf("  UNIT FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond);   \
        }                                                                           \
    } while (0)

template <class T>
bool roundTrip(const T& in, T& out) {
    std::vector<uint8_t> body;
    pg::encodeBody(in, body);
    pg::Reader r(body.data(), body.size());
    if (!out.read(r) || r.remaining() != 0) return false;
    std::vector<uint8_t> again;
    pg::encodeBody(out, again);
    return again == body && in.wireSize() == body.size();
}

void unitTests();  // defined below main helpers (uses generated classes)

}  // namespace

int main(int argc, char** argv) {
    std::vector<std::string> frameFiles;
    const char* report = nullptr;
    const char* dumpPath = nullptr;
    const char* violPath = nullptr;
    uint64_t fuzzRounds = 0, seed = 20260912ULL;
    bool unit = false;
    for (int i = 1; i < argc; ++i) {
        const std::string a = argv[i];
        if (a == "--frames" && i + 1 < argc)
            frameFiles.push_back(argv[++i]);
        else if (a == "--report" && i + 1 < argc)
            report = argv[++i];
        else if (a == "--dump-accepted" && i + 1 < argc)
            dumpPath = argv[++i];
        else if (a == "--dump-violations" && i + 1 < argc)
            violPath = argv[++i];
        else if (a == "--fuzz" && i + 1 < argc)
            fuzzRounds = std::strtoull(argv[++i], nullptr, 10);
        else if (a == "--seed" && i + 1 < argc)
            seed = std::strtoull(argv[++i], nullptr, 10);
        else if (a == "--unit")
            unit = true;
        else {
            std::printf("usage: %s [--frames FILE]... [--report FILE] [--fuzz N] [--seed S] [--dump-accepted FILE] [--unit]\n",
                        argv[0]);
            return 2;
        }
    }
    const auto t0 = std::chrono::steady_clock::now();
    size_t tableCount = 0;
    const pg::PacketInfo* table = pg::packetTable(&tableCount);
    std::printf("ProtocolGen: %u packets, spec %s (sha256 %.16s)\n", static_cast<unsigned>(tableCount), pg::kSpecGenerated,
                pg::kSpecSha256);
    int failures = 0;

    // ---------------- frames
    std::vector<Frame> frames;
    for (const std::string& f : frameFiles) {
        const size_t before = frames.size();
        if (!loadFrames(f.c_str(), frames)) {
            std::printf("cannot read frame file %s\n", f.c_str());
            return 2;
        }
        std::printf("loaded %u frames from %s\n", static_cast<unsigned>(frames.size() - before), f.c_str());
    }
    typedef std::tuple<std::string, int, int, int, std::string, size_t, std::string> Key;
    std::map<Key, std::pair<unsigned, std::string>> agg;
    std::map<std::string, std::map<std::string, unsigned>> perSet;
    std::map<std::string, std::set<std::pair<int, int>>> idsOk, idsAll;
    for (const Frame& fr : frames) {
        const Outcome o = checkFrame(fr);
        const pg::PacketInfo* info = pg::findPacket(protoOf(fr.proto), fr.id);
        const Key k(fr.set, fr.proto, fr.flags & 1, fr.id, info ? info->name : "?", fr.body.size(), o.status);
        auto& slot = agg[k];
        if (slot.first++ == 0) slot.second = o.detail;
        perSet[fr.set][o.status]++;
        idsAll[fr.set].insert(std::make_pair(static_cast<int>(fr.proto), static_cast<int>(fr.id)));
        const bool ok = std::strcmp(o.status, "OK") == 0;
        if (ok) idsOk[fr.set].insert(std::make_pair(static_cast<int>(fr.proto), static_cast<int>(fr.id)));
        if (!ok && (fr.flags & 2)) ++failures;
    }
    for (auto& s : perSet) {
        unsigned total = 0;
        std::string parts;
        for (auto& kv : s.second) {
            total += kv.second;
            parts += " " + kv.first + "=" + std::to_string(kv.second);
        }
        std::set<std::pair<int, int>> bad;
        for (auto& k : agg)
            if (std::get<0>(k.first) == s.first && std::get<6>(k.first) != "OK")
                bad.insert(std::make_pair(std::get<1>(k.first), std::get<3>(k.first)));
        size_t fullyOk = 0;
        for (auto& id : idsAll[s.first])
            if (!bad.count(id)) ++fullyOk;
        std::printf("set %-10s frames %u:%s; ids fully OK %u/%u\n", s.first.c_str(), total, parts.c_str(),
                    static_cast<unsigned>(fullyOk), static_cast<unsigned>(idsAll[s.first].size()));
    }
    unsigned printed = 0;
    for (auto& k : agg) {
        if (std::get<6>(k.first) == "OK") continue;
        if (printed++ < 60)
            std::printf("  %-8s %s %s id=%-4d %-30s sz=%-5u %-14s x%-4u %s\n", std::get<0>(k.first).c_str(),
                        std::get<1>(k.first) ? "login" : "game ", std::get<2>(k.first) ? "C2S" : "S2C", std::get<3>(k.first),
                        std::get<4>(k.first).c_str(), static_cast<unsigned>(std::get<5>(k.first)), std::get<6>(k.first).c_str(),
                        k.second.first, k.second.second.c_str());
    }
    if (report) {
        FILE* f = std::fopen(report, "w");
        if (f) {
            std::fprintf(f, "set\tproto\tdirection\tid\tname\tbody_size\tstatus\tframes\tdetail\n");
            for (auto& k : agg)
                std::fprintf(f, "%s\t%s\t%s\t%d\t%s\t%u\t%s\t%u\t%s\n", std::get<0>(k.first).c_str(),
                             std::get<1>(k.first) ? "login" : "game", std::get<2>(k.first) ? "C2S" : "S2C",
                             std::get<3>(k.first), std::get<4>(k.first).c_str(), static_cast<unsigned>(std::get<5>(k.first)),
                             std::get<6>(k.first).c_str(), k.second.first, k.second.second.c_str());
            std::fclose(f);
        }
    }

    // ---------------- fuzz
    if (fuzzRounds) {
        Rng rng(seed);
        FrameWriter dump(dumpPath);
        FrameWriter violWriter(violPath);
        if (violPath) g_violations = &violWriter;
        const size_t dumpCap = 50000;
        FuzzStats trunc, ext, mut, cross, rnd;
        // unique seeds
        std::map<std::tuple<int, int, std::vector<uint8_t>>, int> uniq;
        for (const Frame& fr : frames) uniq[std::make_tuple(static_cast<int>(fr.proto), static_cast<int>(fr.id), fr.body)] = 1;
        std::vector<std::tuple<pg::Proto, uint16_t, std::vector<uint8_t>>> seeds;
        for (auto& u : uniq)
            seeds.emplace_back(protoOf(static_cast<uint8_t>(std::get<0>(u.first))), static_cast<uint16_t>(std::get<1>(u.first)),
                               std::get<2>(u.first));
        for (auto& s : seeds) {
            const std::vector<uint8_t>& body = std::get<2>(s);
            const size_t n = body.size();
            const size_t step = n > 384 ? n / 384 : 1;
            for (size_t len = 0; len < n; len += step) {
                std::vector<uint8_t> b(body.begin(), body.begin() + len);
                fuzzOne(std::get<0>(s), std::get<1>(s), b, trunc, &dump, dumpCap);
            }
            if (n) {
                std::vector<uint8_t> b(body.begin(), body.end() - 1);
                fuzzOne(std::get<0>(s), std::get<1>(s), b, trunc, &dump, dumpCap);
            }
            for (int k = 0; k < 4; ++k) {
                std::vector<uint8_t> b = body;
                const uint32_t extra = 1 + rng.below(16);
                for (uint32_t i = 0; i < extra; ++i) b.push_back(static_cast<uint8_t>(rng.next()));
                fuzzOne(std::get<0>(s), std::get<1>(s), b, ext, &dump, dumpCap);
            }
        }
        for (uint64_t k = 0; k < fuzzRounds && !seeds.empty(); ++k) {
            const auto& s = seeds[rng.below(static_cast<uint32_t>(seeds.size()))];
            std::vector<uint8_t> b = std::get<2>(s);
            mutate(b, rng);
            if (b.size() > pg::kMaxBody) b.resize(pg::kMaxBody);
            fuzzOne(std::get<0>(s), std::get<1>(s), b, mut, &dump, dumpCap);
            if ((k & 7) == 0) {  // same bytes, another packet id
                const pg::PacketInfo& other = table[rng.below(static_cast<uint32_t>(tableCount))];
                fuzzOne(other.proto, other.id, b, cross, &dump, dumpCap);
            }
        }
        for (size_t t = 0; t < tableCount; ++t) {
            const pg::PacketInfo& info = table[t];
            const uint32_t base = info.minSize > 4096 ? 4096 : info.minSize;
            for (int k = 0; k < 24; ++k) {
                std::vector<uint8_t> b;
                const uint32_t len = (k == 0) ? base : (k == 1 ? 0 : rng.below(base * 2 + 64));
                const int mode = k % 4;
                for (uint32_t i = 0; i < len; ++i)
                    b.push_back(mode == 0 ? 0 : (mode == 1 ? 0xFF : static_cast<uint8_t>(mode == 2 ? rng.below(4) : rng.next())));
                fuzzOne(info.proto, info.id, b, rnd, &dump, dumpCap);
            }
        }
        const FuzzStats* all[] = {&trunc, &ext, &mut, &cross, &rnd};
        const char* names[] = {"truncate", "extend", "mutate", "cross-id", "random"};
        uint64_t viol = 0;
        for (int i = 0; i < 5; ++i) {
            std::printf("fuzz %-9s runs %8llu  strict-accepted %7llu  lenient-accepted %7llu  violations %llu\n", names[i],
                        static_cast<unsigned long long>(all[i]->runs), static_cast<unsigned long long>(all[i]->strictOk),
                        static_cast<unsigned long long>(all[i]->lenientOk),
                        static_cast<unsigned long long>(all[i]->violations));
            for (const std::string& s : all[i]->samples) std::printf("    %s\n", s.c_str());
            viol += all[i]->violations;
        }
        if (dump.ok()) std::printf("fuzz: %u strictly accepted inputs written to %s\n", static_cast<unsigned>(dump.count()), dumpPath);
        if (viol) ++failures;
    }

    if (unit) {
        unitTests();
        std::printf("unit tests: %s (%d failures)\n", g_unitFail ? "FAILED" : "passed", g_unitFail);
        if (g_unitFail) ++failures;
    }
    const double secs = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    std::printf("result: %s (%.1f s)\n", failures ? "FAILED" : "PASSED", secs);
    return failures ? 1 : 0;
}

namespace {

void unitTests() {
    // UTF-8 cut identical to the server's bostream:write / truncate_utf8_bytes.
    const char* s = "ab\xE4\xBD\xA0\xE5\xA5\xBD";  // "ab" + 2 CJK characters (3 bytes each)
    UNIT(pg::utf8Cut(s, 8, 8) == 8);
    UNIT(pg::utf8Cut(s, 8, 7) == 5);
    UNIT(pg::utf8Cut(s, 8, 5) == 5);
    UNIT(pg::utf8Cut(s, 8, 4) == 2);
    UNIT(pg::utf8Cut(s, 8, 2) == 2);
    UNIT(pg::utf8Cut(s, 8, 0) == 0);
    std::array<uint8_t, 4> fixed4{};
    pg::setText(fixed4, std::string(s));
    UNIT(fixed4[0] == 'a' && fixed4[1] == 'b' && fixed4[2] == 0 && fixed4[3] == 0);
    UNIT(pg::getText(fixed4) == "ab");

    // Reader never overruns; errors carry the position.
    const uint8_t three[3] = {1, 2, 3};
    pg::Reader r(three, 3);
    uint32_t v = 0;
    UNIT(!r.u32(v) && !r.ok() && r.errorPos() == 0);
    UNIT(r.remaining() == 3);

    // Factory table: sorted, complete, unique names, lookups work.
    size_t n = 0;
    const pg::PacketInfo* t = pg::packetTable(&n);
    UNIT(n == pg::kPacketCount);
    for (size_t i = 1; i < n; ++i) UNIT(t[i - 1].proto < t[i].proto || (t[i - 1].proto == t[i].proto && t[i - 1].id < t[i].id));
    std::set<std::string> names;
    for (size_t i = 0; i < n; ++i) {
        UNIT(names.insert(t[i].name).second);
        UNIT(pg::findPacket(t[i].proto, t[i].id) == &t[i]);
        UNIT(pg::findPacketByName(t[i].name) == &t[i]);
        std::unique_ptr<pg::Packet> p(t[i].create());
        UNIT(p && p->packetId() == t[i].id && p->packetProto() == t[i].proto && p->packetDir() == t[i].dir &&
             std::strcmp(p->packetName(), t[i].name) == 0);
        // A default-constructed packet encodes and, when the class is fully decodable, decodes back.
        std::vector<uint8_t> body;
        pg::encodeBody(*p, body);
        UNIT(p->wireSize() == body.size());
        if (t[i].decodability == pg::DecFull) {
            pg::DecodeResult res;
            std::unique_ptr<pg::Packet> q = pg::decodePacket(t[i].proto, t[i].id, body.data(), body.size(), &res, true);
            if (!q) std::printf("  default %s does not decode: %s (%s)\n", t[i].name, res.error, res.field);
            UNIT(q != nullptr);
        }
    }
    UNIT(pg::findPacket(pg::Proto::Game, 0xFFFF) == nullptr);
    UNIT(pg::id::GCEnterScene == 1764 && pg::id::CGCharMove == 352 && pg::id::CGChat == 753);
    // The three ids Tools/stress-test/tlbb_sim has wrong (653 / 568 / None) - the server uses these.
    UNIT(pg::id::GCCharMove == 564 && pg::id::GCCharMoveResult == 1090 && pg::id::CGHeartBeat == 3);
    UNIT(pg::xyid::XYID_GC_CHAR_MOVE == 564 && pg::xyid::XYID_GC_CHAR_MOVE_RESULT == 1090 &&
         pg::xyid::XYID_CG_HEART_BEAT == 3);

    // Setters cut at the spec limit on a UTF-8 boundary (CGMail.source: the server reads <= 30 bytes).
    {
        std::string longName;
        for (int k = 0; k < 12; ++k) longName += "\xE4\xBD\xA0";  // 36 bytes of 3-byte characters
        pg::CGMail m;
        m.set_source(longName);
        UNIT(m.source.size() == 30);
        m.set_dest("dest");
        m.set_content(std::string(300, 'x'));
        UNIT(m.content.size() == 256);
        m.flag = 2;
        m.param_3 = -7;
        pg::CGMail back;
        UNIT(roundTrip(m, back) && back.source == m.source && back.content == m.content && back.param_3 == -7);
        pg::CGMail raw;  // assigned directly: write() applies the same cut
        raw.source = longName + "abc";
        std::vector<uint8_t> body;
        pg::encodeBody(raw, body);
        UNIT(body.size() > 5 && body[4] == 30 && body[5] == 0xE4);
    }
    // Fixed text fields: server cut + NUL padding; the text accessor stops at the first NUL.
    {
        pg::CLConnect c;
        c.set_account("bot_account");
        c.set_ip("127.0.0.1");
        UNIT(c.account_text() == "bot_account" && c.ip_text() == "127.0.0.1");
        std::vector<uint8_t> body;
        pg::encodeBody(c, body);
        UNIT(body.size() == 110);
        pg::CLConnect back;
        UNIT(roundTrip(c, back) && back.account_text() == "bot_account");
    }
    // Arrays: the count field is authoritative; missing elements are written as defaults; the server's
    // guard (1..16 path nodes) decides whether the array is on the wire at all.
    {
        pg::CGCharMove mv;
        mv.handleID = 7;
        mv.posWorld_x = 1.5f;
        mv.targetPos.resize(2);
        mv.targetPos[0].x = 10.f;
        mv.targetPos[1].y = 20.f;
        mv.numTargetPos = 2;
        pg::CGCharMove back;
        UNIT(roundTrip(mv, back) && back.targetPos.size() == 2 && back.targetPos[1].y == 20.f && back.posWorld_x == 1.5f);
        std::vector<uint8_t> body;
        mv.numTargetPos = 3;
        pg::encodeBody(mv, body);
        UNIT(body.size() == 18 + 3 * 8);
        mv.numTargetPos = 17;
        pg::encodeBody(mv, body);
        UNIT(body.size() == 18);
    }
    // Body-size selector: CLAskLogin in the 0x785 client format is 949 bytes with an empty encrypted blob.
    {
        pg::CLAskLogin a;
        a.set_account("acc");
        a.uVersion = 0x785;
        UNIT(a.is_new_format);
        std::vector<uint8_t> body;
        pg::encodeBody(a, body);
        UNIT(body.size() == 949);
        pg::DecodeResult res;
        std::unique_ptr<pg::Packet> p = pg::decodePacket(pg::Proto::Login, pg::id::CLAskLogin, body.data(), body.size(), &res);
        const pg::CLAskLogin* q = dynamic_cast<const pg::CLAskLogin*>(p.get());
        UNIT(q && q->is_new_format && q->uVersion == 0x785 && q->account_text() == "acc");
    }
    // Derived flags: bit 0 of the rebuilt m_uFlags[1] announces `model`.
    {
        pg::GCCharBaseAttrib b;
        b.m_objID = 42;
        b.new_flags[0] = 0x01;
        b.model = 1234;
        std::vector<uint8_t> body;
        pg::encodeBody(b, body);
        UNIT(body.size() == 4 + 1 + 14 + 4);
        pg::GCCharBaseAttrib back;
        UNIT(roundTrip(b, back) && back.model == 1234 && back.m_objID == 42);
    }
    // CY raid rosters flatten five squads; indices in each record locate the cell.
    {
        pg::GCRaidList a, back;
        a.m_RaidID=8; a.member_list.resize(5); a.m_nMemberCount=30;
        for (unsigned squad=0;squad<5;++squad) for(unsigned slot=0;slot<6;++slot) {
            pg::GCRaidList::E_member_list::E_elem m;
            m.guid=100+squad*6+slot;m.anon1=squad;m.anon2=slot;m.m_Position=m.guid==100?0:2;m.text="Member";
            a.member_list[squad].anon1.push_back(m);
        }
        UNIT(roundTrip(a,back) && back.member_list.size()==5 && back.member_list[4].anon1.size()==6);
        std::vector<uint8_t> bytes;pg::encodeBody(a,bytes);pg::DecodeResult result;
        for(size_t n=0;n<bytes.size();++n) UNIT(!pg::decodePacket(pg::Proto::Game,124,bytes.data(),n,&result));
        a.member_list[4].anon1[5].guid=100;pg::encodeBody(a,bytes);
        UNIT(!pg::decodePacket(pg::Proto::Game,124,bytes.data(),bytes.size(),&result));
        a.member_list[4].anon1[5].guid=129;a.member_list[4].anon1[5].anon1=5;pg::encodeBody(a,bytes);
        UNIT(!pg::decodePacket(pg::Proto::Game,124,bytes.data(),bytes.size(),&result));
        a.m_nMemberCount=31;pg::encodeBody(a,bytes);
        UNIT(!pg::decodePacket(pg::Proto::Game,124,bytes.data(),bytes.size(),&result));
        a=pg::GCRaidList();a.m_RaidID=-1;a.m_bLeaveRaid=1;
        UNIT(roundTrip(a,back) && back.m_nMemberCount==0);
    }
    // Frames and bad ids.
    {
        pg::CGHeartBeat hb;
        std::vector<uint8_t> frame;
        UNIT(pg::encodeFrame(hb, 0x1234, frame) && frame.size() == 6 && frame[0] == 3 && frame[1] == 0 && frame[2] == 0 &&
             frame[3] == 0 && frame[4] == 0x34 && frame[5] == 0x12);
        pg::FrameHeader h;
        UNIT(pg::readFrameHeader(frame.data(), frame.size(), h) && h.id == 3 && h.size == 0 && h.idx == 0x1234);
        pg::DecodeResult res;
        UNIT(!pg::decodePacket(pg::Proto::Game, 0xFFFF, nullptr, 0, &res) && std::strcmp(res.error, "unknown packet id") == 0);
        const uint8_t one = 0;
        UNIT(!pg::decodePacket(pg::Proto::Game, pg::id::CGHeartBeat, &one, 1, &res) && std::strcmp(res.error, "trailing bytes") == 0);
        UNIT(pg::decodePacket(pg::Proto::Game, pg::id::CGHeartBeat, &one, 1, &res, false) != nullptr && res.used == 0);
    }
}

}  // namespace
