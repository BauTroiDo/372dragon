#pragma once
// Types shared by the login and game halves of one modern client session.
// No dependency on WXClient, stdafx or the 0.85 packet classes.

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

namespace cys { namespace net {

struct Endpoint {
    std::string host; // Explicit IPv4 literal (loopback, or an allow-listed local LAN address); no DNS.
    uint16_t port = 0;
};

enum class ErrorCode {
    None, InvalidInput, Busy, WrongThread, ConnectFailed, Timeout, Io,
    PeerClosed, Decode, UnexpectedPacket, Limit, Internal, NotReady
};
const char* ErrorCodeName(ErrorCode code);

// Dotted IPv4 literal inside 127/8 only. Rejects names, IPv6 and other interfaces.
bool IsLoopbackLiteral(const std::string& host);

// CYS: endpoint policy of a configured server profile (Patch/CysServerProfile.txt).
// Dotted IPv4 literal in 10/8, 172.16/12 or 192.168/16. Rejects names and public addresses.
bool IsPrivateLanLiteral(const std::string& host);
// The literal is assigned to an adapter of this machine (address query only, no socket).
bool IsLocalInterfaceAddress(const std::string& host);
// A syntactically valid allow-list entry: loopback or private LAN literal. At most
// MaxAllowedHosts entries (see ValidAllowedHosts).
bool IsAllowListLiteral(const std::string& host);
constexpr size_t MaxAllowedHosts = 8;
bool ValidAllowedHosts(const std::vector<std::string>& allowedHosts);
// Empty list: any 127/8 literal (the historic loopback-only policy). Otherwise the host
// must be listed exactly and be loopback, or a private LAN literal assigned to this
// machine. A server can therefore never redirect the client outside the computer.
bool IsHostAllowed(const std::string& host, const std::vector<std::string>& allowedHosts);

// Opaque hand-off from an authenticated login session to its game socket.
// Only LoginClient creates a valid ticket (from LCRetCharLogin) and only GameClient
// reads the key. The ticket carries the session sequence so the first game frame
// continues the login counter instead of restarting it. Move-only; the key is
// wiped on destruction/move and has no accessor, so it cannot reach a log line.
class GameTicket {
public:
    GameTicket() = default;
    ~GameTicket() { clear(); }
    GameTicket(GameTicket&& other) noexcept { take(other); }
    GameTicket& operator=(GameTicket&& other) noexcept {
        if (this != &other) { clear(); take(other); }
        return *this;
    }
    GameTicket(const GameTicket&) = delete;
    GameTicket& operator=(const GameTicket&) = delete;

    bool valid() const { return valid_; }
    uint32_t guid() const { return guid_; }
    const Endpoint& endpoint() const { return endpoint_; }
    uint8_t nextSequence() const { return nextSequence_; }
    uint16_t nextTxIndex() const { return static_cast<uint16_t>(nextSequence_) << 8; }

private:
    friend class LoginClient;
    friend class GameClient;
    void clear() {
        volatile uint32_t* key = &key_;
        *key = 0;
        valid_ = false; guid_ = 0; nextSequence_ = 0; endpoint_ = Endpoint();
    }
    void take(GameTicket& other) {
        endpoint_ = other.endpoint_; guid_ = other.guid_; key_ = other.key_;
        nextSequence_ = other.nextSequence_; valid_ = other.valid_;
        other.clear();
    }
    Endpoint endpoint_;
    uint32_t guid_ = 0;
    uint32_t key_ = 0;
    uint8_t nextSequence_ = 0;
    bool valid_ = false;
};

}} // namespace cys::net
