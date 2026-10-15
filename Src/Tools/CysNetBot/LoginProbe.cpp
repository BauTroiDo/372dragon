#include "LoginProbe.h"
#include <algorithm>
#include <cstring>

namespace cysbot {

void Wipe(void* data, size_t size) {
    volatile unsigned char* p = static_cast<volatile unsigned char*>(data);
    while (size--) *p++ = 0;
}

// CYS-PARALLEL (17/09): the allowlist stays CLOSED and explicit - it just holds this project's own sixteen test
// accounts instead of one. test00..test15 are the private server's measurement accounts (characters CYTest00..
// CYTest15, guid 200001..200016); parallel menpai measurement needs more than a single queue, and nothing outside
// that fixed set may ever log in. Exactly six lowercase characters: "test" + 00..15. No wildcard, no env override.
bool AllowedAccount(const std::string& account) {
    if (account.size() != 6 || account.compare(0, 4, "test") != 0) return false;
    const char tens = account[4], ones = account[5];
    if (ones < '0' || ones > '9') return false;
    if (tens == '0') return true;          // test00..test09
    return tens == '1' && ones <= '5';     // test10..test15
}

bool MakeLogin(const std::string& account, const char* password, size_t length,
               pg::CLAskLogin& output) {
    if (!AllowedAccount(account) || !password || !length ||
        length > 49 - account.size() - 1) return false;
    for (size_t i = 0; i < length; ++i)
        if (password[i] == '\0' || password[i] == '%' ||
            static_cast<unsigned char>(password[i]) < 0x20) return false;
    output = pg::CLAskLogin();
    std::memcpy(output.account.data(), account.data(), account.size());
    output.account[account.size()] = '%';
    std::memcpy(output.account.data() + account.size() + 1, password, length);
    output.is_new_format = true;
    // This non-hardware identifier belongs only to this explicit test account (CYS-test00 .. CYS-test15);
    // it is derived from the account so two parallel sessions stay apart in the server login log.
    output.set_mac("CYS-" + account);
    return true;
}

bool FrameAssembler::feed(const uint8_t* data, size_t size, std::vector<Frame>& out) {
    if (*error_) return false;
    if ((size && !data) || size > 65536 || out.size() > maxFrames_) {
        error_ = "receive input limit";
        return false;
    }
    while (size || bytes_.size() == target_) {
        const size_t take = (std::min)(size, target_ - bytes_.size());
        if (take) {
            bytes_.insert(bytes_.end(), data, data + take);
            data += take;
            size -= take;
        }
        if (bytes_.size() != target_) break;
        pg::FrameHeader header{};
        if (!pg::readFrameHeader(bytes_.data(), bytes_.size(), header)) {
            error_ = "invalid frame header";
            return false;
        }
        if (target_ == pg::kFrameHeaderSize && header.size) {
            target_ += header.size;
            continue;
        }
        if (out.size() == maxFrames_) {
            error_ = "receive frame limit";
            return false;
        }
        Frame frame;
        frame.header = header;
        frame.body.assign(bytes_.begin() + pg::kFrameHeaderSize, bytes_.end());
        out.push_back(std::move(frame));
        Wipe(bytes_.data(), bytes_.size());
        bytes_.clear();
        target_ = pg::kFrameHeaderSize;
        if (!size) break;
    }
    return true;
}

Decoded DecodeInbound(const Frame& frame) {
    Decoded d;
    const auto* login = pg::findPacket(pg::Proto::Login, frame.header.id);
    d.proto = login ? pg::Proto::Login : pg::Proto::Game;
    d.packet = pg::decodePacket(d.proto, frame.header.id, frame.body.data(),
                               frame.body.size(), &d.result, true);
    if (d.packet && d.packet->packetDir() != pg::Dir::LC &&
        d.packet->packetDir() != pg::Dir::GC && d.packet->packetDir() != pg::Dir::WGC) {
        d.packet.reset();
        d.result.ok = false;
        d.result.error = "unexpected packet direction";
        d.result.field = "";
        d.result.errorPos = 0;
    }
    return d;
}

Action LoginConversation::fail(const char* error) {
    phase_ = Failed;
    error_ = error;
    return Action::Failed;
}

Action LoginConversation::accept(const pg::Packet& packet) {
    if (phase_ == Failed || phase_ == Done) return fail("packet after terminal state");
    if (packet.packetProto() != pg::Proto::Login)
        return fail(packet.packetId() == 397 ? "server script refusal" : "unexpected Game packet");
    if (phase_ == ConnectReply && packet.packetId() == pg::LCRetConnect::PACKET_ID) {
        phase_ = LoginReply;
        return Action::SendLogin;
    }
    if (phase_ == LoginReply && packet.packetId() == pg::LCRetLogin::PACKET_ID) {
        const auto& reply = static_cast<const pg::LCRetLogin&>(packet);
        haveFlag_ = true;
        flag_ = reply.flag;
        if (flag_ != 0) {
            if (flag_ == 8 || flag_ == 21) {
                const uint32_t waitMs = reply.uNeedWaitTime > 0 ?
                    static_cast<uint32_t>(reply.uNeedWaitTime) : 0;
                retryAfter_ = (std::max)(20U, waitMs / 1000 + (waitMs % 1000 != 0));
            }
            return fail("login refused; no retry performed");
        }
        phase_ = CharListReply;
        return Action::SendCharList;
    }
    if (phase_ == CharListReply && packet.packetId() == pg::LCStatus::PACKET_ID)
        return Action::None;
    if (phase_ == CharListReply && packet.packetId() == pg::LCRetCharList::PACKET_ID) {
        const auto& reply = static_cast<const pg::LCRetCharList&>(packet);
        if (reply.unknow != 0) return fail("character list refused");
        characters_ = reply.charlist.size();
        phase_ = Done;
        return Action::Complete;
    }
    return fail("unexpected login packet or order");
}

const char* LoginConversation::state() const {
    switch (phase_) {
    case ConnectReply: return "connect_reply";
    case LoginReply: return "login_reply";
    case CharListReply: return "character_list_reply";
    case Done: return "complete";
    default: return "failed";
    }
}

} // namespace cysbot
