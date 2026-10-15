#include "LoginProbe.h"
#include <algorithm>
#include <cstdlib>
#include <iostream>
#include <random>
#include <string>

namespace {
int passed = 0;
void Check(bool condition, const char* name) {
    if (!condition) { std::cerr << "FAIL " << name << '\n'; std::exit(1); }
    ++passed;
    std::cout << "PASS " << name << '\n';
}
cysbot::Frame Body(const pg::Packet& packet) {
    cysbot::Frame frame;
    frame.header.id = packet.packetId();
    pg::encodeBody(packet, frame.body);
    frame.header.size = static_cast<uint16_t>(frame.body.size());
    return frame;
}
bool ReachLogin(cysbot::LoginConversation& session) {
    return session.accept(pg::LCRetConnect()) == cysbot::Action::SendLogin;
}
bool ReachList(cysbot::LoginConversation& session) {
    return ReachLogin(session) && session.accept(pg::LCRetLogin()) == cysbot::Action::SendCharList;
}
}

int main() {
    using cysbot::Action;
    // CYS-PARALLEL (17/09): the allowlist now holds this project's sixteen measurement accounts test00..test15
    // (parallel menpai runs need more than one queue) and must stay CLOSED - nothing outside that set logs in.
    Check(cysbot::AllowedAccount("test00") && cysbot::AllowedAccount("test01") && cysbot::AllowedAccount("test15") &&
          !cysbot::AllowedAccount("test16") && !cysbot::AllowedAccount("test99") && !cysbot::AllowedAccount("test0") &&
          !cysbot::AllowedAccount("test001") && !cysbot::AllowedAccount("Test00") && !cysbot::AllowedAccount("testxx") &&
          !cysbot::AllowedAccount("") && !cysbot::AllowedAccount("admin"), "explicit account allowlist");
    pg::CLAskLogin login;
    // Synthetic fixture only; it is not a configured account credential.
    const std::string fixture = "unit-value";
    Check(cysbot::MakeLogin("test00", fixture.data(), fixture.size(), login) &&
          login.is_new_format && login.wireSize() == 949, "modern login 949-byte layout");
    Check(login.account_text() == "test00%unit-value" && login.encrypted_data.empty() &&
          login.mac_text() == "CYS-test00" && login.uVersion == 0, "login fields match server parser");
    std::string oversized(43, 'x');
    const std::string embedded("a\0b", 3);
    Check(!cysbot::MakeLogin("test00", "", 0, login) &&
          !cysbot::MakeLogin("test00", oversized.data(), oversized.size(), login) &&
          !cysbot::MakeLogin("test00", embedded.data(), embedded.size(), login) &&
          !cysbot::MakeLogin("test00", "a%b", 3, login) &&
          !cysbot::MakeLogin("test16", fixture.data(), fixture.size(), login), "credentials never truncate or split");
    // CYS-PARALLEL: the mac follows the account so two parallel sessions stay apart in the server login log.
    Check(cysbot::MakeLogin("test07", fixture.data(), fixture.size(), login) &&
          login.account_text() == "test07%unit-value" && login.mac_text() == "CYS-test07", "per-account login fields");
    auto encodedLogin = Body(login);
    pg::DecodeResult loginResult;
    auto decodedLogin = pg::decodePacket(pg::Proto::Login, 299, encodedLogin.body.data(),
                                         encodedLogin.body.size(), &loginResult, true);
    Check(decodedLogin && loginResult.used == 949, "generated modern login strict roundtrip");
    cysbot::TxSequencer sequence;
    Check(sequence.next() == 0x7b00, "sequence starts 0x7b");
    bool sequenceOk = true;
    for (unsigned i = 0; i < 1024; ++i) {
        sequenceOk = sequenceOk && sequence.next() == static_cast<uint16_t>(((0x7b + i) & 255) << 8);
        sequence.admitted();
    }
    Check(sequenceOk, "sequence increments continuously and wraps");

    pg::CLConnect connect;
    connect.set_account("test00"); connect.set_version("tlbb");
    std::vector<uint8_t> wire;
    pg::encodeFrame(connect, 0x7b00, wire);
    bool splits = true;
    for (size_t split = 0; split <= wire.size(); ++split) {
        cysbot::FrameAssembler assembler;
        std::vector<cysbot::Frame> frames;
        splits = splits && assembler.feed(wire.data(), split, frames) &&
            assembler.feed(wire.data() + split, wire.size() - split, frames) &&
            frames.size() == 1 && frames[0].header.id == 355 && frames[0].header.idx == 0x7b00 &&
            frames[0].body.size() == 110 && !assembler.pending();
    }
    Check(splits, "all header and body split positions");
    cysbot::FrameAssembler bytewise;
    std::vector<cysbot::Frame> frames;
    bool bytesOk = true;
    for (auto byte : wire) bytesOk = bytesOk && bytewise.feed(&byte, 1, frames);
    Check(bytesOk && frames.size() == 1 && !bytewise.pending(), "bytewise frame assembly");
    std::vector<uint8_t> merged = wire;
    merged.insert(merged.end(), wire.begin(), wire.end());
    pg::writeFrameHeader(merged, pg::FrameHeader{3, 0, 0x7d00});
    cysbot::FrameAssembler together;
    frames.clear();
    Check(together.feed(merged.data(), merged.size(), frames) && frames.size() == 3 &&
          frames.back().body.empty() && !together.pending(), "merged frames including empty body");
    std::vector<uint8_t> maximum;
    pg::writeFrameHeader(maximum, pg::FrameHeader{65534, 65535, 0});
    maximum.resize(65541, 0x5a);
    cysbot::FrameAssembler largest;
    frames.clear();
    Check(largest.feed(maximum.data(), 65536, frames) && frames.empty() &&
          largest.feed(maximum.data() + 65536, 5, frames) && frames.size() == 1 &&
          frames[0].body.size() == 65535 && !largest.pending(), "maximum u16 body boundary");
    cysbot::FrameAssembler limited;
    frames.clear();
    Check(!limited.feed(maximum.data(), maximum.size(), frames) &&
          !limited.feed(wire.data(), wire.size(), frames), "input limit latches failure");
    std::vector<uint8_t> many;
    for (int i = 0; i < 129; ++i) pg::writeFrameHeader(many, pg::FrameHeader{3, 0, 0});
    cysbot::FrameAssembler frameLimit;
    frames.clear();
    Check(!frameLimit.feed(many.data(), many.size(), frames) && frames.size() == 128,
          "frame output limit bounds empty frame flood");

    auto goodReply = Body(pg::LCRetLogin());
    auto decoded = cysbot::DecodeInbound(goodReply);
    Check(decoded.packet && decoded.proto == pg::Proto::Login && decoded.result.ok,
          "known Login reply strict decode");
    goodReply.body.pop_back();
    decoded = cysbot::DecodeInbound(goodReply);
    Check(!decoded.packet && decoded.proto == pg::Proto::Login &&
          decoded.result.info && std::string(decoded.result.info->name) == "LCRetLogin",
          "known Login malformed packet never falls back to Game");
    goodReply = Body(pg::LCRetLogin()); goodReply.body.push_back(0);
    decoded = cysbot::DecodeInbound(goodReply);
    Check(!decoded.packet && std::string(decoded.result.error) == "trailing bytes",
          "trailing bytes rejected strictly");
    cysbot::Frame unknown;
    unknown.header.id = 397;
    decoded = cysbot::DecodeInbound(unknown);
    Check(!pg::findPacket(pg::Proto::Login, 397) && decoded.proto == pg::Proto::Game &&
          decoded.result.info && std::string(decoded.result.info->name) == "GCScriptCommand",
          "unknown Login id looks up Game table");
    unknown.header.id = 65535;
    decoded = cysbot::DecodeInbound(unknown);
    Check(!decoded.packet && !decoded.result.info, "unknown both tables rejected");
    decoded = cysbot::DecodeInbound(Body(connect));
    Check(!decoded.packet && std::string(decoded.result.error) == "unexpected packet direction",
          "client packet on receive rejected");

    cysbot::LoginConversation happy;
    Check(ReachList(happy) && happy.accept(pg::LCStatus()) == Action::None &&
          happy.accept(pg::LCRetCharList()) == Action::Complete && happy.characterCount() == 0 &&
          happy.hasLoginFlag() && happy.loginFlag() == 0, "handshake auth empty list succeeds");
    cysbot::LoginConversation populated;
    pg::LCRetCharList list; list.charlist.resize(2); list.charnum = 2;
    Check(ReachList(populated) && populated.accept(list) == Action::Complete &&
          populated.characterCount() == 2, "character count without entering game");
    cysbot::LoginConversation early;
    Check(early.accept(pg::LCRetCharList()) == Action::Failed, "list before auth rejected");
    cysbot::LoginConversation wrong;
    pg::LCRetLogin refusal; refusal.flag = 1;
    Check(ReachLogin(wrong) && wrong.accept(refusal) == Action::Failed &&
          wrong.loginFlag() == 1 && !wrong.retryAfterSeconds() &&
          wrong.accept(pg::LCRetLogin()) == Action::Failed, "wrong password terminal no retry");
    cysbot::LoginConversation online;
    refusal.flag = 8;
    Check(ReachLogin(online) && online.accept(refusal) == Action::Failed &&
          online.retryAfterSeconds() == 20, "already online minimum 20 seconds backoff");
    cysbot::LoginConversation wait;
    refusal.flag = 21; refusal.uNeedWaitTime = 25001;
    Check(ReachLogin(wait) && wait.accept(refusal) == Action::Failed &&
          wait.retryAfterSeconds() == 26, "server wait rounds up without retry");
    cysbot::LoginConversation deniedList;
    list.unknow = 1;
    Check(ReachList(deniedList) && deniedList.accept(list) == Action::Failed,
          "character list refusal terminal");

    std::mt19937 random(0xc1752026);
    bool fuzz = true;
    for (unsigned i = 0; i < 100000; ++i) {
        const size_t n = random() % 513;
        std::vector<uint8_t> input(n);
        for (auto& b : input) b = static_cast<uint8_t>(random());
        cysbot::FrameAssembler assembler;
        frames.clear();
        const size_t split = n ? random() % (n + 1) : 0;
        const bool a = assembler.feed(input.data(), split, frames);
        const bool b = a && assembler.feed(input.data() + split, n - split, frames);
        (void)b;
        fuzz = fuzz && assembler.pending() <= 65541 && frames.size() <= 128;
        for (const auto& f : frames) {
            fuzz = fuzz && f.body.size() == f.header.size;
            auto d = cysbot::DecodeInbound(f);
            if (d.packet) fuzz = fuzz && d.result.ok && d.result.used == f.body.size();
        }
    }
    Check(fuzz, "100000 bounded fragmented fuzz inputs and strict decoding");
    std::cout << "RESULT tests=" << passed << " failed=0 fuzz_inputs=100000 live_connections=0\n";
    return 0;
}
