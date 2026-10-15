#pragma once

#include "NetCommon.h"
#include "NetStream.h"
#include "PgRuntime.h"
#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <string>

namespace cys { namespace net {

enum class SessionMode { Probe, Interactive };

struct Options {
    uint32_t connectTimeoutMs = 5000;
    uint32_t replyTimeoutMs = 10000;
    uint32_t overallTimeoutMs = 90000;
    SessionMode mode = SessionMode::Probe;
    uint32_t idleTimeoutMs = 300000; // Interactive ready state only; overall still bounds the session.
    // Interactive only. The game endpoint returned by LCRetCharLogin must pass
    // IsHostAllowed(allowedHosts) on exactly this port; 0 disables character login
    // unless gamePortFromReply is set.
    uint16_t approvedGamePort = 0;
    // CYS: server profile policy. gamePortFromReply accepts the non-zero port named by
    // LCRetCharLogin (approvedGamePort must then be 0). allowedHosts empty = 127/8 only;
    // otherwise the login endpoint and the reply host must both be listed (NetCommon.h).
    bool gamePortFromReply = false;
    std::vector<std::string> allowedHosts;
    // CYS: data source of the login socket; null = Winsock TCP (the real server).
    std::shared_ptr<StreamFactory> streamFactory;
};

struct CreateCharacterRequest {
    std::string nickname; // Strict UTF-8, 1..29 bytes; never truncate the fixed 30-byte wire field.
    int32_t model = 0, hairStyle = 0, faceStyle = 0, newPlayerSet = 0;
    uint8_t portraitId = 0; // Caller chooses actual CY asset IDs; transport does not invent models.
};

// Values are appended only; the numeric order is part of existing diagnostics.
enum class EventType {
    Connected, Authenticated, Refused, CharacterList, Error, Cancelled, CharacterCreated, CreatePermission,
    CharacterLoginGranted, // terminal: login socket closed, ticket owns the game hand-off
    CharacterLoginRefused  // server tips (GCScriptCommand 397) or non-zero result; session stays ready
};

struct Counters {
    uint32_t txFrames = 0, rxFrames = 0, decodeFailures = 0;
    size_t rxBytes = 0, pendingBytes = 0;
    uint16_t nextTxIndex = 0x7b00;
    bool socketClosed = true;
};

struct Event {
    EventType type = EventType::Error;
    ErrorCode error = ErrorCode::None;
    const char* message = ""; // Fixed diagnostic only, never peer text or credentials.
    int32_t loginFlag = 0;
    int32_t createResult = 0; // CharacterCreated only: 0 success; 1..6/8 server refusal.
    int32_t permissionFlag = -1; // CreatePermission only: server 1 allows, 0 denies.
    bool creationAvailable = false; // Readiness becomes visible only when this event is pumped.
    uint32_t retryAfterSeconds = 0;
    pg::Proto protocol = pg::Proto::Login;
    uint16_t packetId = 0;
    const char* decodeField = "";
    size_t errorOffset = 0, bodySize = 0;
    Counters counters;
    // Owned decoded PG object: LCRetLogin on auth/refused, LCRetCharList on list,
    // LCRetCreateChar on CharacterCreated. Success is followed by a new list.
    // No raw wire body or borrowed parser storage crosses the worker boundary.
    // CharacterLoginGranted carries no packet (the reply holds the game key).
    std::unique_ptr<pg::Packet> packet;
    std::unique_ptr<GameTicket> ticket; // CharacterLoginGranted only.
    Event() = default;
    Event(Event&&) = default;
    Event& operator=(Event&&) = default;
    Event(const Event&) = delete;
    Event& operator=(const Event&) = delete;
};

// One bounded login/auth/list connection. Construct, start, pump and cancel on
// one main thread. All socket waits and strict decoding run on the owned worker.
// Interactive mode also creates characters and asks for the game hand-off on
// the same authenticated connection. No automatic retry of any command.
class LoginClient {
public:
    using Handler = std::function<void(Event&&)>;
    LoginClient();
    ~LoginClient();
    LoginClient(const LoginClient&) = delete;
    LoginClient& operator=(const LoginClient&) = delete;

    // Returns promptly after validation and worker launch. Input strings are
    // borrowed for this call; the caller must wipe its own password afterwards.
    // Generic library policy: ASCII alphanumeric/hyphen account, combined wire
    // field fits 49 bytes, explicit loopback endpoint. Test account/port policy
    // belongs to the Game opt-in profile, not this transport.
    bool start(const Endpoint&, const std::string& account, const std::string& password,
               const Options& options = Options());
    ErrorCode lastStartError() const;
    // One command may be pending. Called on the owner thread, including in a
    // pumped ready event; false never starts networking or sends a partial command.
    bool createCharacter(const CreateCharacterRequest&);
    bool requestCreatePermission();
    bool canRequestCreatePermission() const;
    bool canCreateCharacter() const;
    // CLAskCharLogin for a GUID of the last pumped character list. The reply is
    // either CharacterLoginGranted (terminal, carries the ticket) or
    // CharacterLoginRefused (the list stays usable; the user may retry explicitly).
    bool requestCharacterLogin(uint32_t guid);
    bool canRequestCharacterLogin() const;
    ErrorCode lastCommandError() const;
    size_t pump(const Handler&, size_t maxEvents = 16);
    // No blocking socket operation; suppress queued old UI events. If running,
    // the worker closes the socket and queues one Cancelled terminal event.
    void cancel();
    bool active() const;

private:
    struct Impl;
    std::shared_ptr<Impl> impl_;
};

}} // namespace cys::net
