#include "GameClient.h"
#include "LoginProbe.h" // Shared framing, wipe and the session sequencer.
#include "NetStream.h" // CYS: data-source seam; Winsock unless a factory is injected.
#include "PgFactory.h"
#include "PgPackets_core.h"
#include "PgPackets_misc.h"
#include "PgPackets_movement.h"
#include <winsock2.h>
#include <ws2tcpip.h>
#include <algorithm>
#include <atomic>
#include <chrono>
#include <deque>
#include <mutex>
#include <stdexcept>
#include <thread>
#include <vector>

namespace cys { namespace net {

const char* GamePhaseName(GamePhase phase) {
    switch (phase) {
    case GamePhase::Idle: return "idle";
    case GamePhase::Connecting: return "connecting";
    case GamePhase::AwaitConnect: return "await_connect";
    case GamePhase::Connected: return "connected";
    case GamePhase::Entering: return "entering";
    case GamePhase::InWorld: return "in_world";
    case GamePhase::AwaitTransfer: return "await_transfer";
    case GamePhase::Quitting: return "quitting";
    case GamePhase::Closed: return "closed";
    }
    return "unknown";
}

namespace {
using Clock = std::chrono::steady_clock;
using TimePoint = Clock::time_point;
constexpr int PollQuantumMs = 20;
constexpr size_t ReadChunk = 16384;
// 16 KiB of 6-byte frames is 2730 frames; keep the per-feed cap above that.
constexpr size_t MaxFramesPerFeed = 4096;
constexpr size_t MaxPreConnectPackets = 1024;
// Backpressure stops reading at maxQueuedEvents; one read can add at most one feed.
constexpr size_t HardEventSlack = MaxFramesPerFeed + 16;

struct Failure {
    ErrorCode code;
    const char* message;
};
struct Cancelled {};
struct QuitDone {};

struct SecretWriter : pg::Writer {
    ~SecretWriter() { cysbot::Wipe(buffer().data(), buffer().size()); }
};
struct KeyWipe {
    uint32_t& key;
    ~KeyWipe() { cysbot::Wipe(&key, sizeof(key)); }
};

std::chrono::milliseconds Ms(uint32_t value) { return std::chrono::milliseconds(value); }

bool validOptions(const GameOptions& o) {
    return o.connectTimeoutMs >= 50 && o.connectTimeoutMs <= 30000 &&
        o.connectReplyTimeoutMs >= 50 && o.connectReplyTimeoutMs <= 60000 &&
        o.enterReplyTimeoutMs >= 50 && o.enterReplyTimeoutMs <= 120000 &&
        o.transferReplyTimeoutMs >= 50 && o.transferReplyTimeoutMs <= 60000 &&
        o.quitTimeoutMs >= 50 && o.quitTimeoutMs <= 60000 &&
        o.idleTimeoutMs >= 1000 && o.idleTimeoutMs <= 3600000 &&
        o.heartbeatIntervalMs >= 100 && o.heartbeatIntervalMs <= 60000 &&
        o.sendTimeoutMs >= 50 && o.sendTimeoutMs <= 30000 &&
        o.txPerSecond >= 1 && o.txPerSecond <= 200 && o.txBurst >= 1 && o.txBurst <= 400 &&
        o.maxQueuedEvents >= 16 && o.maxQueuedEvents <= 65536 &&
        o.maxQueuedBytes >= 65536 && o.maxQueuedBytes <= 64u * 1024 * 1024 &&
        o.maxOutbound >= 1 && o.maxOutbound <= 4096 &&
        ValidAllowedHosts(o.allowedHosts); // CYS: server profile allow-list
}

const char* phaseTimeout(GamePhase phase) {
    switch (phase) {
    case GamePhase::AwaitConnect: return "no GCConnect after CGConnect (key refused or server busy)";
    case GamePhase::Entering: return "no GCEnterScene after CGEnterScene";
    case GamePhase::AwaitTransfer: return "no GCRetChangeScene after CGAskChangeScene";
    case GamePhase::Quitting: return "quit was not acknowledged and closed in time";
    default: return "game phase deadline exceeded";
    }
}

} // namespace

struct GameClient::Impl {
    const std::thread::id owner = std::this_thread::get_id();
    struct Queued { GameEvent event; size_t bytes; };
    std::mutex mutex;
    std::deque<Queued> events;
    size_t queuedBytes = 0;
    std::deque<std::unique_ptr<pg::Packet>> outbound;
    std::thread worker;
    std::atomic<bool> stop{false}, running{false}, quitRequested{false};
    ErrorCode startError = ErrorCode::None, commandError = ErrorCode::None;
    GameOptions options;
    // Owner-thread view, changed while pumping or admitting a command.
    GamePhase view = GamePhase::Idle;
    bool enterSentView = false, notifyView = false, pumping = false;

    ~Impl() {
        stop.store(true);
        if (worker.joinable()) worker.join();
    }
    bool onOwner() const { return owner == std::this_thread::get_id(); }

    bool backpressured() {
        std::lock_guard<std::mutex> lock(mutex);
        return events.size() >= options.maxQueuedEvents || queuedBytes >= options.maxQueuedBytes;
    }
    void enqueue(GameEvent&& event, size_t bytes) {
        std::lock_guard<std::mutex> lock(mutex);
        if (stop.load()) throw Cancelled{};
        if (events.size() >= options.maxQueuedEvents + HardEventSlack ||
            queuedBytes > options.maxQueuedBytes + 2 * ReadChunk + pg::kMaxBody)
            throw Failure{ErrorCode::Limit, "main event queue limit"};
        queuedBytes += bytes;
        events.push_back(Queued{std::move(event), bytes});
    }
    void finish(GameEvent&& event) {
        std::lock_guard<std::mutex> lock(mutex);
        if (stop.load()) {
            events.clear(); queuedBytes = 0;
            event.type = GameEventType::Cancelled; event.error = ErrorCode::None;
            event.message = "game session cancelled"; event.packet.reset(); event.bodySize = 0;
        }
        const size_t bytes = event.bodySize;
        queuedBytes += bytes;
        events.push_back(Queued{std::move(event), bytes});
        outbound.clear();
        quitRequested.store(false);
        running.store(false); // Same lock as cancel and terminal delivery.
    }

    void run(std::unique_ptr<GameTicket> ticket) {
        const GameOptions o = options;
        GameCounters counters;
        GameEvent terminal;
        cysbot::TxSequencer sequence(ticket->nextSequence_);
        counters.nextTxIndex = sequence.next();
        Endpoint endpoint = ticket->endpoint_;
        uint32_t key = ticket->key_;
        KeyWipe keyGuard{key};
        const uint32_t guid = ticket->guid_;
        const uint16_t approvedPort = o.approvedGamePort ? o.approvedGamePort : endpoint.port;
        ticket.reset();
        uint32_t generation = 0;
        GamePhase phase = GamePhase::Connecting;
        int32_t quitFlag = -1;
        const TimePoint never = TimePoint::max();
        auto publish = [&](GameEventType type, std::unique_ptr<pg::Packet> packet, size_t bodySize, uint16_t id) {
            GameEvent event;
            event.type = type; event.phase = phase; event.generation = generation;
            event.packetId = id; event.bodySize = bodySize; event.counters = counters;
            event.packet = std::move(packet);
            enqueue(std::move(event), bodySize);
        };
        try {
            // CYS: the data source of every socket of this session (Winsock unless injected).
            const std::shared_ptr<StreamFactory> factory = o.streamFactory ? o.streamFactory : WinsockStreamFactory();
            double tokens = static_cast<double>(o.txBurst);
            TimePoint lastRefill = Clock::now();
            for (;;) { // One iteration per game socket; a transfer starts the next.
                if (stop.load()) throw Cancelled{};
                ++generation;
                phase = GamePhase::Connecting;
                std::unique_ptr<Stream> stream = factory->create();
                if (!stream) throw Failure{ErrorCode::Internal, "stream factory returned no stream"};
                {
                    const char* message = "";
                    const ErrorCode code = stream->connect(endpoint, o.connectTimeoutMs, stop, &message);
                    if (stop.load()) throw Cancelled{};
                    if (code == ErrorCode::Timeout) throw Failure{ErrorCode::Timeout, "game connect timeout"};
                    if (code == ErrorCode::Io) throw Failure{ErrorCode::Io, message};
                    if (code != ErrorCode::None) throw Failure{ErrorCode::ConnectFailed, *message ? message : "game connection failed"};
                }
                ++counters.sockets; counters.socketClosed = false;
                auto sendFrame = [&](const pg::Packet& packet) {
                    if (stop.load()) throw Cancelled{};
                    SecretWriter body;
                    packet.write(body);
                    if (body.size() > pg::kMaxBody) throw Failure{ErrorCode::Internal, "modern packet encode failed"};
                    std::vector<uint8_t> wire;
                    wire.reserve(pg::kFrameHeaderSize + body.size());
                    pg::FrameHeader header{};
                    header.id = packet.packetId(); header.size = static_cast<uint16_t>(body.size()); header.idx = sequence.next();
                    pg::writeFrameHeader(wire, header);
                    wire.insert(wire.end(), body.buffer().begin(), body.buffer().end());
                    // Admitted to the single ordered writer: the index is consumed now
                    // and continues across every socket of this session.
                    sequence.admitted();
                    counters.nextTxIndex = sequence.next();
                    ++counters.txFrames;
                    const char* message = "";
                    const ErrorCode code = stream->write(wire.data(), wire.size(), o.sendTimeoutMs, stop, &message);
                    cysbot::Wipe(wire.data(), wire.size());
                    if (stop.load()) throw Cancelled{};
                    if (code == ErrorCode::Timeout) throw Failure{ErrorCode::Timeout, "socket write deadline exceeded"};
                    if (code == ErrorCode::PeerClosed) throw Failure{ErrorCode::PeerClosed, "socket closed or failed"};
                    if (code != ErrorCode::None) throw Failure{ErrorCode::Io, "game socket send failed"};
                };
                {
                    // gamed.lua asserts that the first frame of an unknown fd is CGConnect.
                    pg::CGConnect connect;
                    connect.key = key; connect.guid = guid; connect.set_version("tlbb");
                    KeyWipe wipe{connect.key};
                    sendFrame(connect);
                }
                cysbot::Wipe(&key, sizeof(key));
                phase = GamePhase::AwaitConnect;
                publish(GameEventType::Connected, nullptr, 0, 0);
                TimePoint phaseDeadline = Clock::now() + Ms(o.connectReplyTimeoutMs);
                TimePoint lastRx = Clock::now();
                TimePoint nextHeartbeat = never;
                bool enterSent = false, notifyReceived = false, transfer = false;
                size_t preConnect = 0;
                cysbot::FrameAssembler assembler(MaxFramesPerFeed);
                std::vector<uint8_t> buffer(ReadChunk);
                auto closedByPeer = [&](const char* message) {
                    if (phase == GamePhase::Quitting) throw QuitDone{};
                    throw Failure{ErrorCode::PeerClosed, message};
                };
                while (!transfer) {
                    if (stop.load()) throw Cancelled{};
                    TimePoint now = Clock::now();
                    if (quitRequested.exchange(false)) {
                        if (phase == GamePhase::InWorld) {
                            pg::CGAskQuit quit;
                            quit.unknow_2 = 0; // 0 begins the scene quit tick (msgagent.lua CGAskQuit).
                            sendFrame(quit);
                            phase = GamePhase::Quitting; phaseDeadline = now + Ms(o.quitTimeoutMs); nextHeartbeat = never;
                        } else {
                            ++counters.droppedOutbound;
                        }
                    }
                    const double elapsed = std::chrono::duration<double>(now - lastRefill).count();
                    lastRefill = now;
                    tokens = (std::min)(static_cast<double>(o.txBurst), tokens + elapsed * o.txPerSecond);
                    while (tokens >= 1.0) {
                        std::unique_ptr<pg::Packet> packet;
                        {
                            std::lock_guard<std::mutex> lock(mutex);
                            if (outbound.empty()) break;
                            packet = std::move(outbound.front());
                            outbound.pop_front();
                        }
                        const uint16_t id = packet->packetId();
                        bool allowed = false;
                        if (id == pg::CGEnterScene::PACKET_ID) {
                            // A second CGEnterScene on one agent is logged out as a reconnect.
                            allowed = phase == GamePhase::Connected && !enterSent;
                            if (allowed) { enterSent = true; phase = GamePhase::Entering; phaseDeadline = now + Ms(o.enterReplyTimeoutMs); }
                        } else if (id == pg::CGAskChangeScene::PACKET_ID) {
                            // Without GCNotifyChangeScene the server has no change args and never replies.
                            allowed = phase == GamePhase::InWorld && notifyReceived;
                            if (allowed) { notifyReceived = false; phase = GamePhase::AwaitTransfer; phaseDeadline = now + Ms(o.transferReplyTimeoutMs); }
                        } else {
                            allowed = phase == GamePhase::InWorld;
                        }
                        if (!allowed) { ++counters.droppedOutbound; continue; }
                        sendFrame(*packet);
                        tokens -= 1.0;
                    }
                    if (now >= nextHeartbeat && (phase == GamePhase::Connected || phase == GamePhase::Entering ||
                                                 phase == GamePhase::InWorld || phase == GamePhase::AwaitTransfer)) {
                        pg::CGHeartBeat beat;
                        sendFrame(beat);
                        ++counters.heartbeats;
                        nextHeartbeat = now + Ms(o.heartbeatIntervalMs);
                    }
                    if (phaseDeadline != never && now >= phaseDeadline)
                        throw Failure{ErrorCode::Timeout, phaseTimeout(phase)};
                    if (now - lastRx >= Ms(o.idleTimeoutMs)) throw Failure{ErrorCode::Timeout, "game connection idle timeout"};
                    if (backpressured()) {
                        // Keep order: stop reading until the owner pumps; timers keep running.
                        ++counters.backpressureWaits;
                        Sleep(PollQuantumMs);
                        continue;
                    }
                    const Stream::Wait ready = stream->wait(PollQuantumMs);
                    if (ready == Stream::Wait::Failed) throw Failure{ErrorCode::Io, "socket poll failed"};
                    if (ready == Stream::Wait::Idle) continue;
                    if (ready == Stream::Wait::Closed) closedByPeer("game socket closed or failed");
                    const int count = stream->read(buffer.data(), buffer.size());
                    if (count == -1) continue;
                    if (count == 0) closedByPeer("server closed game connection");
                    if (count < 0) {
                        if (phase == GamePhase::Quitting) throw QuitDone{};
                        throw Failure{ErrorCode::Io, "game socket receive failed"};
                    }
                    lastRx = Clock::now(); now = lastRx;
                    counters.rxBytes += static_cast<uint64_t>(count);
                    std::vector<cysbot::Frame> frames;
                    const bool assembled = assembler.feed(buffer.data(), static_cast<size_t>(count), frames);
                    cysbot::Wipe(buffer.data(), static_cast<size_t>(count));
                    if (!assembled) throw Failure{ErrorCode::Limit, "receive frame assembly limit"};
                    for (auto& frame : frames) {
                        const size_t bodySize = frame.body.size();
                        if (transfer) {
                            // The old scene socket is being replaced; later frames are stale.
                            ++counters.discardedAfterTransfer;
                            cysbot::Wipe(frame.body.data(), bodySize);
                            continue;
                        }
                        if (stop.load()) throw Cancelled{};
                        ++counters.rxFrames;
                        pg::DecodeResult result;
                        auto packet = pg::decodePacket(pg::Proto::Game, frame.header.id, frame.body.data(),
                                                       bodySize, &result, true);
                        cysbot::Wipe(frame.body.data(), bodySize);
                        // CYS-UNKNOWNID 17/09/2026: ID server gửi mà Registry KHÔNG có dòng nào thì
                        // KHÔNG phải "giải mã hỏng" — không có bộ giải mã để mà hỏng. Trước đây bot
                        // chết với rc=5 "strict packet decode failed"; đo được là `cy_four_combat`
                        // gửi 786 GCCharDoAction nên mọi phiên có con rối (3809/3820/3822) và cả
                        // phái 15 đều không đo nổi. Bỏ qua, đếm lại, phiên chạy tiếp. Gói CÓ trong
                        // Registry mà thân sai thì VẪN ném như cũ: đó mới là lệch giao thức thật.
                        if (!packet && !pg::findPacket(pg::Proto::Game, frame.header.id)) {
                            ++counters.unknownPackets;
                            if (counters.firstUnknownId == 0) counters.firstUnknownId = frame.header.id;
                            counters.lastUnknownId = frame.header.id;
                            continue;
                        }
                        if (!packet || (packet->packetDir() != pg::Dir::GC && packet->packetDir() != pg::Dir::WGC)) {
                            ++counters.decodeFailures;
                            terminal.packetId = frame.header.id;
                            terminal.decodeField = packet ? "" : result.field;
                            terminal.errorOffset = result.errorPos; terminal.bodySize = bodySize;
                            throw Failure{ErrorCode::Decode, packet ? "client-direction packet on game socket" :
                                                                   "strict packet decode failed"};
                        }
                        const uint16_t id = frame.header.id;
                        if (id == pg::GCConnect::PACKET_ID) {
                            if (phase != GamePhase::AwaitConnect)
                                throw Failure{ErrorCode::UnexpectedPacket, "GCConnect outside the connect handshake"};
                            phase = GamePhase::Connected; phaseDeadline = never;
                            nextHeartbeat = now + Ms(o.heartbeatIntervalMs);
                        } else if (id == pg::GCEnterScene::PACKET_ID) {
                            if (phase != GamePhase::Entering)
                                throw Failure{ErrorCode::UnexpectedPacket, "GCEnterScene without a pending CGEnterScene"};
                            phase = GamePhase::InWorld; phaseDeadline = never;
                        } else if (id == pg::GCRetChangeScene::PACKET_ID) {
                            // The key is cleared before the packet is published: a scope guard
                            // would write into an object the owner thread may already have freed.
                            auto& reply = static_cast<pg::GCRetChangeScene&>(*packet);
                            if (phase == GamePhase::AwaitTransfer && reply.result == 1) {
                                const std::string host = reply.ip_text();
                                if (!IsHostAllowed(host, o.allowedHosts) || reply.port == 0 || reply.port != approvedPort) { // CYS
                                    cysbot::Wipe(&reply.key, sizeof(reply.key));
                                    throw Failure{ErrorCode::UnexpectedPacket, "transfer endpoint outside the approved profile"};
                                }
                                key = reply.key;
                                cysbot::Wipe(&reply.key, sizeof(reply.key));
                                endpoint.host = host; endpoint.port = reply.port;
                                transfer = true;
                                phase = GamePhase::Connecting;
                                publish(GameEventType::Transfer, std::move(packet), bodySize, id);
                                continue;
                            }
                            cysbot::Wipe(&reply.key, sizeof(reply.key));
                            if (phase == GamePhase::AwaitTransfer) { phase = GamePhase::InWorld; phaseDeadline = never; }
                            else if (phase != GamePhase::Quitting)
                                throw Failure{ErrorCode::UnexpectedPacket, "GCRetChangeScene without a pending CGAskChangeScene"};
                        } else if (id == pg::GCRetAskQuit::PACKET_ID) {
                            quitFlag = static_cast<const pg::GCRetAskQuit&>(*packet).flag;
                            if (phase != GamePhase::Quitting) {
                                phase = GamePhase::Quitting; phaseDeadline = now + Ms(o.quitTimeoutMs); nextHeartbeat = never;
                            }
                        } else if (id == pg::GCNotifyChangeScene::PACKET_ID) {
                            if (phase == GamePhase::InWorld) notifyReceived = true;
                        } else if (phase == GamePhase::AwaitConnect && id != pg::KeyExchange::PACKET_ID) {
                            if (++preConnect > MaxPreConnectPackets)
                                throw Failure{ErrorCode::Limit, "too many packets before GCConnect"};
                        }
                        publish(GameEventType::Packet, std::move(packet), bodySize, id);
                    }
                    if (transfer && assembler.pending()) ++counters.discardedAfterTransfer;
                }
                stream->close();
                counters.socketClosed = true;
                ++counters.transfers;
            }
        } catch (const QuitDone&) {
            terminal.type = GameEventType::QuitComplete;
            terminal.message = quitFlag >= 0 ? "quit acknowledged; server closed the game socket" :
                                               "server closed the game socket during quit";
            terminal.quitFlag = quitFlag;
            terminal.packet.reset();
            phase = GamePhase::Closed;
        } catch (const Cancelled&) {
            terminal.type = GameEventType::Cancelled; terminal.message = "game session cancelled";
            terminal.packet.reset();
            phase = GamePhase::Closed;
        } catch (const Failure& failure) {
            terminal.type = GameEventType::Error; terminal.error = failure.code; terminal.message = failure.message;
            terminal.packet.reset();
        } catch (...) {
            terminal.type = GameEventType::Error; terminal.error = ErrorCode::Internal;
            terminal.message = "game worker failure"; terminal.packet.reset();
        }
        counters.socketClosed = true;
        terminal.phase = phase;
        terminal.generation = generation;
        terminal.counters = counters;
        if (terminal.type != GameEventType::QuitComplete) terminal.quitFlag = quitFlag;
        try { finish(std::move(terminal)); }
        catch (...) { running.store(false); }
    }
};

GameClient::GameClient() : impl_(new Impl) {}
GameClient::~GameClient() {
    impl_->stop.store(true);
    if (impl_->worker.joinable()) impl_->worker.join();
    std::lock_guard<std::mutex> lock(impl_->mutex);
    impl_->events.clear(); impl_->queuedBytes = 0; impl_->outbound.clear();
}

bool GameClient::start(GameTicket&& ticket, const GameOptions& options) {
    if (!impl_->onOwner()) return false;
    impl_->startError = ErrorCode::None;
    if (impl_->running.load() || impl_->pumping) { impl_->startError = ErrorCode::Busy; return false; }
    {
        std::lock_guard<std::mutex> lock(impl_->mutex);
        if (!impl_->events.empty()) { impl_->startError = ErrorCode::Busy; return false; }
    }
    const uint16_t approved = options.approvedGamePort ? options.approvedGamePort : ticket.endpoint().port;
    if (!ticket.valid() || !ticket.guid() || !ticket.endpoint().port || !validOptions(options) ||
        !IsHostAllowed(ticket.endpoint().host, options.allowedHosts) || // CYS: server profile allow-list
        ticket.endpoint().port != approved) {
        impl_->startError = ErrorCode::InvalidInput;
        return false;
    }
    std::unique_ptr<GameTicket> owned(new GameTicket(std::move(ticket)));
    if (impl_->worker.joinable()) impl_->worker.join();
    {
        std::lock_guard<std::mutex> lock(impl_->mutex);
        impl_->options = options;
        impl_->outbound.clear();
        impl_->quitRequested.store(false);
        impl_->commandError = ErrorCode::None;
        impl_->view = GamePhase::Connecting;
        impl_->enterSentView = false; impl_->notifyView = false;
    }
    impl_->stop.store(false); impl_->running.store(true);
    try {
        impl_->worker = std::thread(&Impl::run, impl_.get(), std::move(owned));
    } catch (...) {
        impl_->running.store(false); impl_->view = GamePhase::Closed;
        impl_->startError = ErrorCode::Internal;
        return false;
    }
    return true;
}

ErrorCode GameClient::lastStartError() const {
    return impl_->onOwner() ? impl_->startError : ErrorCode::WrongThread;
}

ErrorCode GameClient::lastCommandError() const {
    return impl_->onOwner() ? impl_->commandError : ErrorCode::WrongThread;
}

GamePhase GameClient::phase() const {
    return impl_->onOwner() ? impl_->view : GamePhase::Closed;
}

bool GameClient::send(std::unique_ptr<pg::Packet> packet) {
    if (!impl_->onOwner()) return false;
    impl_->commandError = ErrorCode::None;
    if (!packet || packet->packetProto() != pg::Proto::Game || !pg::isClientToServer(packet->packetDir())) {
        impl_->commandError = ErrorCode::InvalidInput; return false;
    }
    const uint16_t id = packet->packetId();
    if (id == pg::CGConnect::PACKET_ID || id == pg::CGHeartBeat::PACKET_ID || id == pg::CGAskQuit::PACKET_ID) {
        impl_->commandError = ErrorCode::InvalidInput; return false;
    }
    std::lock_guard<std::mutex> lock(impl_->mutex);
    if (!impl_->running.load() || impl_->stop.load()) { impl_->commandError = ErrorCode::NotReady; return false; }
    GamePhase next = impl_->view;
    if (id == pg::CGEnterScene::PACKET_ID) {
        if (impl_->view != GamePhase::Connected || impl_->enterSentView) { impl_->commandError = ErrorCode::NotReady; return false; }
        next = GamePhase::Entering;
    } else if (id == pg::CGAskChangeScene::PACKET_ID) {
        if (impl_->view != GamePhase::InWorld || !impl_->notifyView) { impl_->commandError = ErrorCode::NotReady; return false; }
        next = GamePhase::AwaitTransfer;
    } else if (impl_->view != GamePhase::InWorld) {
        impl_->commandError = ErrorCode::NotReady; return false;
    }
    if (impl_->outbound.size() >= impl_->options.maxOutbound) { impl_->commandError = ErrorCode::Limit; return false; }
    impl_->outbound.push_back(std::move(packet));
    if (id == pg::CGEnterScene::PACKET_ID) impl_->enterSentView = true;
    if (id == pg::CGAskChangeScene::PACKET_ID) impl_->notifyView = false;
    impl_->view = next;
    return true;
}

bool GameClient::requestQuit() {
    if (!impl_->onOwner()) return false;
    impl_->commandError = ErrorCode::None;
    std::lock_guard<std::mutex> lock(impl_->mutex);
    if (!impl_->running.load() || impl_->stop.load() || impl_->view != GamePhase::InWorld) {
        impl_->commandError = ErrorCode::NotReady; return false;
    }
    impl_->quitRequested.store(true);
    impl_->view = GamePhase::Quitting;
    return true;
}

size_t GameClient::pump(const Handler& handler, size_t maxEvents) {
    const auto state = impl_; // A callback may destroy its owner.
    if (!state->onOwner()) throw std::logic_error("GameClient pump requires its owner thread");
    if (state->pumping || !handler) return 0;
    struct PumpGuard { bool& flag; explicit PumpGuard(bool& f) : flag(f) { flag = true; } ~PumpGuard() { flag = false; } } guard(state->pumping);
    size_t delivered = 0;
    while (delivered < maxEvents) {
        GameEvent event;
        {
            std::lock_guard<std::mutex> lock(state->mutex);
            if (state->events.empty()) break;
            state->queuedBytes -= state->events.front().bytes;
            event = std::move(state->events.front().event);
            state->events.pop_front();
            switch (event.type) {
            case GameEventType::Connected:
                state->view = GamePhase::AwaitConnect; state->enterSentView = false; state->notifyView = false;
                break;
            case GameEventType::Packet:
                if (event.packetId == pg::GCConnect::PACKET_ID && state->view == GamePhase::AwaitConnect)
                    state->view = GamePhase::Connected;
                else if (event.packetId == pg::GCEnterScene::PACKET_ID && state->view == GamePhase::Entering)
                    state->view = GamePhase::InWorld;
                else if (event.packetId == pg::GCRetChangeScene::PACKET_ID && state->view == GamePhase::AwaitTransfer)
                    state->view = GamePhase::InWorld; // refused transfer stays in the scene
                else if (event.packetId == pg::GCNotifyChangeScene::PACKET_ID && state->view == GamePhase::InWorld)
                    state->notifyView = true;
                else if (event.packetId == pg::GCRetAskQuit::PACKET_ID)
                    state->view = GamePhase::Quitting;
                break;
            case GameEventType::Transfer:
                state->view = GamePhase::Connecting; state->enterSentView = false; state->notifyView = false;
                break;
            default:
                state->view = GamePhase::Closed;
                break;
            }
        }
        ++delivered;
        handler(std::move(event));
        if (state->stop.load()) break;
    }
    return delivered;
}

void GameClient::cancel() {
    if (!impl_->onOwner()) throw std::logic_error("GameClient cancel requires its owner thread");
    std::lock_guard<std::mutex> lock(impl_->mutex);
    impl_->stop.store(true);
    impl_->events.clear(); impl_->queuedBytes = 0; impl_->outbound.clear();
    impl_->view = GamePhase::Closed;
}

bool GameClient::active() const { return impl_->running.load(); }

}} // namespace cys::net
