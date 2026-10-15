#pragma once
// Modern game-socket session: CGConnect first, enter scene, in-world traffic,
// scene transfer (GCRetChangeScene) and CGAskQuit. One worker thread owns the
// socket(s), strict decoding, the session sequence, heartbeat and rate limits;
// the owner (main) thread submits packets and pumps owned events.

#include "NetCommon.h"
#include "NetStream.h"
#include "PgRuntime.h"
#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>

namespace cys { namespace net {

// Worker phases; the owner thread sees them as events are pumped.
enum class GamePhase { Idle, Connecting, AwaitConnect, Connected, Entering, InWorld, AwaitTransfer, Quitting, Closed };
const char* GamePhaseName(GamePhase phase);

struct GameOptions {
    uint32_t connectTimeoutMs = 5000;        // TCP connect of each game socket
    uint32_t connectReplyTimeoutMs = 10000;  // CGConnect -> GCConnect (a wrong key is dropped silently)
    uint32_t enterReplyTimeoutMs = 30000;    // CGEnterScene -> GCEnterScene
    uint32_t transferReplyTimeoutMs = 15000; // CGAskChangeScene -> GCRetChangeScene
    uint32_t quitTimeoutMs = 20000;          // CGAskQuit -> GCRetAskQuit + server close (quit tick 3..10 s)
    uint32_t idleTimeoutMs = 600000;         // no inbound byte on a connected socket
    uint32_t heartbeatIntervalMs = 15000;    // Aug-27 capture: 15.0..16.0 s between CGHeartBeat
    uint32_t sendTimeoutMs = 10000;          // one frame fully written
    uint32_t txPerSecond = 30, txBurst = 60; // owner packets; heartbeat is exempt
    size_t maxQueuedEvents = 8192;           // backpressure: stop reading, never drop inbound
    size_t maxQueuedBytes = 8 * 1024 * 1024;
    size_t maxOutbound = 256;
    uint16_t approvedGamePort = 0;           // transfer endpoints must match; 0 = the ticket port
    // CYS: server profile allow-list for the ticket and every transfer host; empty = 127/8 only.
    std::vector<std::string> allowedHosts;
    // CYS: data source of every game socket; null = Winsock TCP (the real server).
    std::shared_ptr<StreamFactory> streamFactory;
};

enum class GameEventType { Connected, Packet, Transfer, QuitComplete, Error, Cancelled };

struct GameCounters {
    uint32_t txFrames = 0, rxFrames = 0, decodeFailures = 0, heartbeats = 0, transfers = 0, sockets = 0;
    uint32_t droppedOutbound = 0, discardedAfterTransfer = 0, backpressureWaits = 0;
    // CYS-UNKNOWNID 17/09/2026: gói server gửi mà Registry/protocol/packets.yaml KHÔNG có dòng nào
    // (không phải lỗi giải mã — không có bộ giải mã để mà hỏng). Bỏ qua và đếm thay vì giết phiên.
    uint32_t unknownPackets = 0;
    uint16_t firstUnknownId = 0, lastUnknownId = 0;
    uint64_t rxBytes = 0;
    uint16_t nextTxIndex = 0;
    bool socketClosed = true;
};

struct GameEvent {
    GameEventType type = GameEventType::Error;
    ErrorCode error = ErrorCode::None;
    const char* message = ""; // Fixed diagnostic only, never peer text or keys.
    GamePhase phase = GamePhase::Idle; // Worker phase once this event was queued.
    uint32_t generation = 0;           // 1 = first game socket, +1 per scene transfer.
    uint16_t packetId = 0;
    const char* decodeField = "";
    size_t errorOffset = 0, bodySize = 0;
    int32_t quitFlag = -1;             // QuitComplete: GCRetAskQuit flag, -1 if the server only closed.
    GameCounters counters;
    // Packet/Transfer: owned decoded GC packet. GCRetChangeScene arrives with key = 0.
    std::unique_ptr<pg::Packet> packet;
    GameEvent() = default;
    GameEvent(GameEvent&&) = default;
    GameEvent& operator=(GameEvent&&) = default;
    GameEvent(const GameEvent&) = delete;
    GameEvent& operator=(const GameEvent&) = delete;
};

class GameClient {
public:
    using Handler = std::function<void(GameEvent&&)>;
    GameClient();
    ~GameClient();
    GameClient(const GameClient&) = delete;
    GameClient& operator=(const GameClient&) = delete;

    // Consumes the login hand-off. Returns promptly; the worker connects and
    // sends CGConnect as the first frame, continuing the ticket's sequence.
    bool start(GameTicket&& ticket, const GameOptions& options = GameOptions());
    ErrorCode lastStartError() const;
    // Queue one CG/CGW packet. CGConnect, CGHeartBeat and CGAskQuit belong to the
    // client. CGEnterScene: once per socket after GCConnect. CGAskChangeScene:
    // only after GCNotifyChangeScene. Other packets: in world only.
    bool send(std::unique_ptr<pg::Packet> packet);
    // CGAskQuit (begin) while in world; completion is QuitComplete after the
    // server acknowledges and closes, or Error(Timeout) after quitTimeoutMs.
    bool requestQuit();
    ErrorCode lastCommandError() const;
    GamePhase phase() const; // Owner-thread view.
    size_t pump(const Handler&, size_t maxEvents = 256);
    void cancel();
    bool active() const;

private:
    struct Impl;
    std::shared_ptr<Impl> impl_;
};

}} // namespace cys::net
