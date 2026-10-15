// A bounded login/list probe, not the full P1-3 NetCore or an in-world bot.
#ifndef CYS_LOGIN_PROBE_H
#define CYS_LOGIN_PROBE_H

#include "PgFactory.h"
#include "PgPackets_login.h"
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

namespace cysbot {

void Wipe(void* data, size_t size);
bool AllowedAccount(const std::string& account);
// Reject truncation, embedded NUL, and separators before touching the output.
bool MakeLogin(const std::string& account, const char* password, size_t length,
               pg::CLAskLogin& output);

// One counter per client session, carried login -> game -> scene transfer.
// idx = (seq & 0xFF) << 8; the server byte-swaps and requires +1 (255 wraps).
class TxSequencer {
public:
    TxSequencer() = default;
    explicit TxSequencer(uint8_t start) : value_(start) {}
    uint16_t next() const { return static_cast<uint16_t>(value_) << 8; }
    uint8_t value() const { return value_; }
    void admitted() { ++value_; }
private:
    uint8_t value_ = 0x7b;
};

struct Frame {
    pg::FrameHeader header{};
    std::vector<uint8_t> body;
};

// Single partial frame, bounded output per feed. No unbounded socket accumulation.
// Login keeps 128 frames per feed; a game socket passes a larger cap because one
// 16 KiB read of in-world bursts (GCDelObject is 12 wire bytes) holds >1000 frames.
class FrameAssembler {
public:
    explicit FrameAssembler(size_t maxFramesPerFeed = 128) : maxFrames_(maxFramesPerFeed) {}
    bool feed(const uint8_t* data, size_t size, std::vector<Frame>& out);
    size_t pending() const { return bytes_.size(); }
    const char* error() const { return error_; }
private:
    std::vector<uint8_t> bytes_;
    size_t target_ = pg::kFrameHeaderSize;
    size_t maxFrames_ = 128;
    const char* error_ = "";
};

struct Decoded {
    pg::Proto proto = pg::Proto::Login;
    pg::DecodeResult result;
    std::unique_ptr<pg::Packet> packet;
};
// A known Login ID that fails strict decoding never falls back to Game.
Decoded DecodeInbound(const Frame& frame);

enum class Action { None, SendLogin, SendCharList, Complete, Failed };
class LoginConversation {
public:
    Action accept(const pg::Packet& packet);
    const char* state() const;
    const char* error() const { return error_; }
    bool hasLoginFlag() const { return haveFlag_; }
    int32_t loginFlag() const { return flag_; }
    uint32_t retryAfterSeconds() const { return retryAfter_; }
    size_t characterCount() const { return characters_; }
private:
    enum Phase { ConnectReply, LoginReply, CharListReply, Done, Failed } phase_ = ConnectReply;
    const char* error_ = "";
    bool haveFlag_ = false;
    int32_t flag_ = 0;
    uint32_t retryAfter_ = 0;
    size_t characters_ = 0;
    Action fail(const char* error);
};

} // namespace cysbot
#endif
