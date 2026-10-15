#include "LoginClient.h"
#include "LoginProbe.h" // Reuse the already-checked pure framing/strict/session code.
#include "NetStream.h" // CYS: data-source seam; Winsock unless a factory is injected.
#include <winsock2.h>
#include <ws2tcpip.h>
#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstring>
#include <deque>
#include <mutex>
#include <stdexcept>
#include <thread>

namespace cys { namespace net {
namespace {
using Clock = std::chrono::steady_clock;
using Deadline = Clock::time_point;
constexpr uint32_t MaxRxFrames = 64;
constexpr size_t MaxRxBytes = 256 * 1024;
constexpr size_t MaxEvents = 16;
constexpr int PollQuantumMs = 25;
// Permission, create and character login share one bounded command slot.
constexpr unsigned MaxCreateCommands = 16;
constexpr uint16_t GameScriptCommandId = 397; // GCScriptCommand: login-socket refusal tips.

struct Failure {
    ErrorCode code;
    const char* message;
};
struct Cancelled {};

struct LoginSecret : pg::CLAskLogin {
    ~LoginSecret() { cysbot::Wipe(account.data(), account.size()); }
};
struct SecretFrame {
    std::vector<uint8_t> bytes;
    ~SecretFrame() { cysbot::Wipe(bytes.data(), bytes.size()); }
};
struct SecretWriter : pg::Writer {
    ~SecretWriter() { cysbot::Wipe(buffer().data(), buffer().size()); }
};
struct KeyWipe {
    uint32_t& key;
    ~KeyWipe() { cysbot::Wipe(&key, sizeof(key)); }
};

bool validOptions(const Options& options) {
    return options.connectTimeoutMs >= 50 && options.connectTimeoutMs <= 30000 &&
        options.replyTimeoutMs >= 50 && options.replyTimeoutMs <= 30000 &&
        options.overallTimeoutMs >= 50 &&
        options.overallTimeoutMs <= (options.mode == SessionMode::Interactive ? 900000U : 90000U) &&
        (options.mode == SessionMode::Probe || options.mode == SessionMode::Interactive) &&
        (options.mode != SessionMode::Interactive ||
         (options.idleTimeoutMs >= 50 && options.idleTimeoutMs <= 600000)) &&
        (options.mode == SessionMode::Interactive || (options.approvedGamePort == 0 && !options.gamePortFromReply)) &&
        !(options.gamePortFromReply && options.approvedGamePort != 0) && // CYS: one game-port policy
        ValidAllowedHosts(options.allowedHosts);
}
bool charLoginAllowed(const Options& options) { // CYS: server profile game-port policy
    return options.approvedGamePort != 0 || options.gamePortFromReply;
}

bool makeCreate(const CreateCharacterRequest& request, pg::CLAskCreateChar& packet) {
    if (request.nickname.empty() || request.nickname.size() > 29 || request.model < 0 ||
        request.hairStyle < 0 || request.faceStyle < 0 || request.newPlayerSet < 0) return false;
    for (unsigned char c : request.nickname)
        if (c < 0x20 || c == 0x7f || c == '#' || c == '*') return false;
    if (request.nickname.front() == ' ' || request.nickname.back() == ' ' ||
        !MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, request.nickname.data(),
                            static_cast<int>(request.nickname.size()), nullptr, 0)) return false;
    packet.set_nickname(request.nickname);
    packet.model = request.model; packet.hair_style = request.hairStyle;
    packet.face_style = request.faceStyle; packet.portrait_id = request.portraitId;
    packet.new_player_set = request.newPlayerSet;
    // packet.lua ctor initializes the two unknown bytes and trailing int to zero;
    // playermanager_core:create_char does not read them. Not asset placeholders.
    return true;
}

bool validList(const pg::LCRetCharList& list) {
    if (list.unknow != 0 || list.charnum != list.charlist.size() || list.charlist.size() > 3) return false;
    for (size_t i = 0; i < list.charlist.size(); ++i) {
        if (!list.charlist[i].guid) return false;
        for (size_t j = 0; j < i; ++j)
            if (list.charlist[i].guid == list.charlist[j].guid) return false;
    }
    return true;
}

bool makeLogin(const std::string& account, const std::string& password, LoginSecret& login) {
    if (account.empty() || account.size() > 47 || password.empty() ||
        password.size() > 48 - account.size()) return false;
    for (unsigned char c : account)
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
              (c >= '0' && c <= '9') || c == '-')) return false;
    for (unsigned char c : password)
        if (c < 0x20 || c == 0x7f || c == '%') return false;
    std::memcpy(login.account.data(), account.data(), account.size());
    login.account[account.size()] = '%';
    std::memcpy(login.account.data() + account.size() + 1, password.data(), password.size());
    login.is_new_format = true;
    // This is a disclosed synthetic client marker, not a hardware fingerprint.
    login.set_mac("CYS-GUI");
    return true;
}

// Readable wait on the data source with the login deadline semantics: a pending
// command interrupts the wait (false), the deadline is a Timeout failure.
bool waitReadable(Stream& stream, Deadline deadline, const std::atomic<bool>& stop,
                  const std::atomic<bool>* command = nullptr) {
    for (;;) {
        if (stop.load()) throw Cancelled{};
        const auto remain = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - Clock::now()).count();
        if (remain <= 0) throw Failure{ErrorCode::Timeout, "network deadline exceeded"};
        if (command && command->load()) return false;
        const Stream::Wait ready = stream.wait(static_cast<int>((std::min)(remain, static_cast<decltype(remain)>(PollQuantumMs))));
        if (ready == Stream::Wait::Failed) throw Failure{ErrorCode::Io, "socket poll failed"};
        if (ready == Stream::Wait::Idle) continue;
        // A peer may close after a complete reply. Drain readable bytes first.
        if (ready == Stream::Wait::Readable) return true;
        throw Failure{ErrorCode::PeerClosed, "socket closed or failed"};
    }
}
} // namespace

struct LoginClient::Impl {
    const std::thread::id owner = std::this_thread::get_id();
    struct Queued { Event event; size_t bytes; };
    std::mutex mutex;
    std::deque<Queued> events;
    size_t queuedBytes = 0;
    std::thread worker;
    std::atomic<bool> stop{false}, running{false};
    ErrorCode startError = ErrorCode::None;
    ErrorCode commandError = ErrorCode::None;
    std::unique_ptr<pg::Packet> pendingCommand;
    std::atomic<bool> haveCommand{false};
    // Main-thread view, changed only while pumping or admitting a command.
    bool interactive = false, loginReady = false, creationReady = false, permissionGranted = false;
    std::vector<uint32_t> knownGuids; // GUIDs of the last pumped list.
    bool charLoginEnabled = false; // CYS: approved port or port-from-reply profile
    unsigned commands = 0;
    bool pumping = false;

    ~Impl() {
        stop.store(true);
        if (worker.joinable()) worker.join();
    }
    bool onOwner() const { return owner == std::this_thread::get_id(); }

    void clearCommandState() {
        loginReady = false; creationReady = false; permissionGranted = false;
        pendingCommand.reset(); haveCommand.store(false);
    }

    void enqueue(Event&& event, size_t bytes) {
        std::lock_guard<std::mutex> lock(mutex);
        if (stop.load()) throw Cancelled{};
        if (events.size() >= MaxEvents || bytes > MaxRxBytes - queuedBytes)
            throw Failure{ErrorCode::Limit, "main event queue limit"};
        queuedBytes += bytes;
        events.push_back(Queued{std::move(event), bytes});
    }

    void finish(Event&& event) {
        std::lock_guard<std::mutex> lock(mutex);
        clearCommandState();
        if (stop.load()) {
            events.clear(); queuedBytes = 0;
            event.type = EventType::Cancelled;
            event.error = ErrorCode::None;
            event.message = "login cancelled";
            event.packet.reset();
            event.ticket.reset();
            event.bodySize = 0;
        }
        // Only three events can normally occur. Keep a terminal error observable
        // even if an earlier queue admission has failed.
        if (events.size() >= MaxEvents || event.bodySize > MaxRxBytes - queuedBytes) {
            events.clear(); queuedBytes = 0;
            event.type = EventType::Error; event.error = ErrorCode::Limit;
            event.message = "main event queue limit"; event.packet.reset(); event.ticket.reset(); event.bodySize = 0;
        }
        const size_t bytes = event.bodySize;
        queuedBytes += bytes;
        events.push_back(Queued{std::move(event), bytes});
        running.store(false); // Under the same lock as cancel/terminal delivery.
    }

    void run(Endpoint endpoint, std::string account, Options options, std::unique_ptr<LoginSecret> login) {
        Counters counters;
        Event terminal;
        cysbot::FrameAssembler assembler;
        cysbot::TxSequencer sequence;
        cysbot::LoginConversation conversation;
        const auto overall = Clock::now() + std::chrono::milliseconds(options.overallTimeoutMs);
        auto deadline = [&](uint32_t timeout) {
            return (std::min)(overall, Clock::now() + std::chrono::milliseconds(timeout));
        };
        try {
            // CYS: the data source of the login socket (Winsock unless injected).
            const std::shared_ptr<StreamFactory> factory = options.streamFactory ? options.streamFactory : WinsockStreamFactory();
            std::unique_ptr<Stream> streamOwner = factory->create();
            if (!streamOwner) throw Failure{ErrorCode::Internal, "stream factory returned no stream"};
            Stream& stream = *streamOwner;
            if (stop.load()) throw Cancelled{};
            counters.socketClosed = false;
            {
                const auto connectDeadline = deadline(options.connectTimeoutMs);
                const auto budget = std::chrono::duration_cast<std::chrono::milliseconds>(connectDeadline - Clock::now()).count();
                const char* message = "";
                const ErrorCode code = stream.connect(endpoint, budget > 0 ? static_cast<uint32_t>(budget) : 1, stop, &message);
                if (stop.load()) throw Cancelled{};
                if (code == ErrorCode::Timeout) throw Failure{ErrorCode::Timeout, "network deadline exceeded"};
                if (code == ErrorCode::Io) throw Failure{ErrorCode::Io, message};
                if (code != ErrorCode::None) throw Failure{ErrorCode::ConnectFailed, *message ? message : "connection failed"};
            }

            Event connected; connected.type = EventType::Connected; connected.counters = counters;
            enqueue(std::move(connected), 0);
            auto send = [&](const pg::Packet& packet) {
                if (stop.load()) throw Cancelled{};
                if (counters.txFrames >= (options.mode == SessionMode::Interactive ? 3 + MaxCreateCommands : 3))
                    throw Failure{ErrorCode::Limit, "transmit frame limit"};
                SecretFrame wire;
                SecretWriter body;
                packet.write(body);
                if (body.size() > pg::kMaxBody ||
                    (packet.packetId() == pg::CLAskLogin::PACKET_ID && body.size() != 949))
                    throw Failure{ErrorCode::Internal, "modern packet encode failed"};
                pg::FrameHeader header{};
                header.id = packet.packetId(); header.size = static_cast<uint16_t>(body.size()); header.idx = sequence.next();
                wire.bytes.reserve(pg::kFrameHeaderSize + body.size());
                pg::writeFrameHeader(wire.bytes, header);
                wire.bytes.insert(wire.bytes.end(), body.buffer().begin(), body.buffer().end());
                // The sole outbound queue admits one bounded frame here. The
                // sequencer continues into the game ticket; never reset on IO.
                sequence.admitted();
                counters.nextTxIndex = sequence.next();
                ++counters.txFrames;
                const auto sendDeadline = deadline(options.replyTimeoutMs);
                const auto budget = std::chrono::duration_cast<std::chrono::milliseconds>(sendDeadline - Clock::now()).count();
                const char* message = "";
                const ErrorCode code = stream.write(wire.bytes.data(), wire.bytes.size(),
                                                    budget > 0 ? static_cast<uint32_t>(budget) : 1, stop, &message);
                if (stop.load()) throw Cancelled{};
                if (code == ErrorCode::Timeout) throw Failure{ErrorCode::Timeout, "network deadline exceeded"};
                if (code == ErrorCode::PeerClosed) throw Failure{ErrorCode::PeerClosed, "socket closed or failed"};
                if (code != ErrorCode::None) throw Failure{ErrorCode::Io, "socket send failed"};
            };
            pg::CLConnect connect;
            connect.set_account(account); connect.set_version("tlbb");
            send(connect);
            auto replyDeadline = deadline(options.replyTimeoutMs);
            enum class Phase { Initial, Ready, PermissionReply, CreateReply, CreateList, CharLoginReply };
            Phase phase = Phase::Initial;
            size_t roleCount = 0;
            std::vector<uint32_t> roleGuids;
            uint32_t charLoginGuid = 0;
            auto publishList = [&](std::unique_ptr<pg::Packet> packet, size_t bodySize, bool created) {
                const auto& list = static_cast<const pg::LCRetCharList&>(*packet);
                if (!validList(list)) throw Failure{ErrorCode::UnexpectedPacket, "invalid character list"};
                if (created) {
                    if (list.charlist.size() != roleCount + 1)
                        throw Failure{ErrorCode::UnexpectedPacket, "created character list count mismatch"};
                    for (uint32_t old : roleGuids) {
                        bool found = false;
                        for (const auto& role : list.charlist) if (role.guid == old) found = true;
                        if (!found) throw Failure{ErrorCode::UnexpectedPacket, "created character list identity mismatch"};
                    }
                }
                roleCount = list.charlist.size(); roleGuids.clear();
                for (const auto& role : list.charlist) roleGuids.push_back(role.guid);
                Event event; event.type = EventType::CharacterList; event.packet = std::move(packet);
                event.counters = counters; event.bodySize = bodySize; event.creationAvailable = roleCount < 3;
                enqueue(std::move(event), bodySize);
                phase = Phase::Ready; replyDeadline = deadline(options.idleTimeoutMs);
            };
            auto refuseCharLogin = [&](size_t bodySize, uint16_t id, pg::Proto proto) {
                Event event; event.type = EventType::CharacterLoginRefused;
                event.message = "character login refused by server; no retry performed";
                event.protocol = proto; event.packetId = id; event.bodySize = 0;
                event.counters = counters; event.creationAvailable = roleCount < 3;
                (void)bodySize;
                enqueue(std::move(event), 0);
                phase = Phase::Ready; replyDeadline = deadline(options.idleTimeoutMs);
            };
            bool done = false;
            while (!done) {
                if (phase == Phase::Ready && haveCommand.load()) {
                    std::unique_ptr<pg::Packet> command;
                    {
                        std::lock_guard<std::mutex> lock(mutex);
                        if (stop.load()) throw Cancelled{};
                        command = std::move(pendingCommand); haveCommand.store(false);
                    }
                    if (!command) throw Failure{ErrorCode::Internal, "missing admitted command"};
                    const uint16_t id = command->packetId();
                    if (id == pg::CLAskCharLogin::PACKET_ID) {
                        charLoginGuid = static_cast<const pg::CLAskCharLogin&>(*command).guid;
                        bool known = false;
                        for (uint32_t guid : roleGuids) known = known || guid == charLoginGuid;
                        if (!known || !charLoginAllowed(options))
                            throw Failure{ErrorCode::Internal, "character login outside the current list"};
                    }
                    send(*command);
                    phase = id == pg::CLCheckAllowCreateChar::PACKET_ID ? Phase::PermissionReply :
                        id == pg::CLAskCreateChar::PACKET_ID ? Phase::CreateReply : Phase::CharLoginReply;
                    replyDeadline = deadline(options.replyTimeoutMs);
                }
                if (!waitReadable(stream, replyDeadline, stop, phase == Phase::Ready ? &haveCommand : nullptr)) continue;
                std::array<uint8_t, 16384> buffer{};
                const int count = stream.read(buffer.data(), buffer.size());
                if (count == -1) continue;
                if (!count) throw Failure{ErrorCode::PeerClosed, "server closed connection"};
                if (count < 0) throw Failure{ErrorCode::Io, "socket receive failed"};
                counters.rxBytes += static_cast<size_t>(count);
                if (counters.rxBytes > MaxRxBytes) throw Failure{ErrorCode::Limit, "receive byte limit"};
                std::vector<cysbot::Frame> frames;
                const bool assembled = assembler.feed(buffer.data(), static_cast<size_t>(count), frames);
                cysbot::Wipe(buffer.data(), buffer.size());
                if (!assembled) throw Failure{ErrorCode::Limit, "receive frame assembly limit"};
                for (auto& frame : frames) {
                    if (stop.load()) throw Cancelled{};
                    if (++counters.rxFrames > MaxRxFrames) throw Failure{ErrorCode::Limit, "receive frame limit"};
                    if (done) throw Failure{ErrorCode::UnexpectedPacket, "frame after terminal reply"};
                    auto decoded = cysbot::DecodeInbound(frame);
                    const size_t bodySize = frame.body.size();
                    cysbot::Wipe(frame.body.data(), frame.body.size());
                    if (!decoded.packet) {
                        ++counters.decodeFailures;
                        terminal.protocol = decoded.proto; terminal.packetId = frame.header.id;
                        terminal.decodeField = decoded.result.field;
                        terminal.errorOffset = decoded.result.errorPos; terminal.bodySize = bodySize;
                        throw Failure{ErrorCode::Decode, "strict packet decode failed"};
                    }
                    if (phase != Phase::Initial) {
                        if (phase == Phase::CharLoginReply && decoded.packet->packetProto() == pg::Proto::Game &&
                            decoded.packet->packetId() == GameScriptCommandId) {
                            // Server tips (character already in a scene, MAC cap, not owned...).
                            // Peer text is never shown; the session stays ready for an explicit retry.
                            refuseCharLogin(bodySize, decoded.packet->packetId(), pg::Proto::Game);
                            continue;
                        }
                        if (decoded.packet->packetProto() != pg::Proto::Login)
                            throw Failure{ErrorCode::UnexpectedPacket, "unexpected game packet in creation session"};
                        if (phase == Phase::PermissionReply && decoded.packet->packetId() == pg::LCRetCheckAllowCreateChar::PACKET_ID) {
                            const int32_t flag = static_cast<const pg::LCRetCheckAllowCreateChar&>(*decoded.packet).flag;
                            if (flag != 0 && flag != 1)
                                throw Failure{ErrorCode::UnexpectedPacket, "unknown create permission flag"};
                            Event event; event.type = EventType::CreatePermission; event.permissionFlag = flag;
                            event.packet = std::move(decoded.packet); event.bodySize = bodySize;
                            event.counters = counters; event.creationAvailable = roleCount < 3;
                            enqueue(std::move(event), bodySize);
                            phase = Phase::Ready; replyDeadline = deadline(options.idleTimeoutMs);
                        } else if (phase == Phase::CreateReply && decoded.packet->packetId() == pg::LCRetCreateChar::PACKET_ID) {
                            const int32_t result = static_cast<const pg::LCRetCreateChar&>(*decoded.packet).result;
                            if (result < 0 || result > 8 || result == 7)
                                throw Failure{ErrorCode::UnexpectedPacket, "unknown create result"};
                            Event event; event.type = EventType::CharacterCreated; event.createResult = result;
                            event.packet = std::move(decoded.packet); event.bodySize = bodySize;
                            event.counters = counters; event.creationAvailable = result != 0 && roleCount < 3;
                            enqueue(std::move(event), bodySize);
                            phase = result == 0 ? Phase::CreateList : Phase::Ready;
                            replyDeadline = deadline(result == 0 ? options.replyTimeoutMs : options.idleTimeoutMs);
                        } else if (phase == Phase::CreateList && decoded.packet->packetId() == pg::LCRetCharList::PACKET_ID) {
                            publishList(std::move(decoded.packet), bodySize, true);
                        } else if (phase == Phase::CharLoginReply && decoded.packet->packetId() == pg::LCRetCharLogin::PACKET_ID) {
                            auto& reply = static_cast<pg::LCRetCharLogin&>(*decoded.packet);
                            KeyWipe wipeKey{reply.key};
                            if (reply.result != 0) {
                                refuseCharLogin(bodySize, reply.packetId(), pg::Proto::Login);
                                continue;
                            }
                            const std::string host = reply.ip_text();
                            // CYS: host allow-list and game-port policy of the server profile.
                            if (!IsHostAllowed(host, options.allowedHosts) || reply.port == 0 || reply.port > 65535 ||
                                (!options.gamePortFromReply && reply.port != options.approvedGamePort))
                                throw Failure{ErrorCode::UnexpectedPacket, "game endpoint outside the approved profile"};
                            std::unique_ptr<GameTicket> ticket(new GameTicket);
                            ticket->endpoint_.host = host;
                            ticket->endpoint_.port = static_cast<uint16_t>(reply.port);
                            ticket->guid_ = charLoginGuid;
                            ticket->key_ = reply.key;
                            ticket->nextSequence_ = sequence.value();
                            ticket->valid_ = true;
                            terminal.type = EventType::CharacterLoginGranted;
                            terminal.message = "character login granted; login socket closed";
                            terminal.ticket = std::move(ticket);
                            terminal.packet.reset();
                            terminal.bodySize = 0;
                            done = true;
                            // Continue through coalesced frames: a suffix after the
                            // hand-off is a protocol error, never a second event.
                        } else throw Failure{ErrorCode::UnexpectedPacket, "unexpected creation packet or order"};
                        continue;
                    }
                    const auto action = conversation.accept(*decoded.packet);
                    if (action == cysbot::Action::Failed) {
                        if (conversation.hasLoginFlag() && conversation.loginFlag() != 0) {
                            terminal.type = EventType::Refused;
                            terminal.loginFlag = conversation.loginFlag();
                            terminal.retryAfterSeconds = conversation.retryAfterSeconds();
                            terminal.message = "login refused; no retry performed";
                            terminal.packet = std::move(decoded.packet);
                            terminal.bodySize = bodySize;
                            done = true;
                            break;
                        }
                        throw Failure{ErrorCode::UnexpectedPacket, conversation.error()};
                    }
                    if (action == cysbot::Action::SendLogin) {
                        send(*login);
                        login.reset();
                        replyDeadline = deadline(options.replyTimeoutMs);
                    } else if (action == cysbot::Action::SendCharList) {
                        Event authenticated;
                        authenticated.type = EventType::Authenticated;
                        authenticated.counters = counters;
                        authenticated.packet = std::move(decoded.packet);
                        enqueue(std::move(authenticated), bodySize);
                        pg::CLAskCharList list; list.set_account(account);
                        send(list);
                        replyDeadline = deadline(options.replyTimeoutMs);
                    } else if (action == cysbot::Action::Complete) {
                        if (options.mode == SessionMode::Interactive) {
                            publishList(std::move(decoded.packet), bodySize, false);
                            continue;
                        }
                        terminal.type = EventType::CharacterList;
                        terminal.packet = std::move(decoded.packet);
                        terminal.bodySize = bodySize;
                        done = true;
                        // Continue through coalesced frames: a suffix after the
                        // terminal reply is a protocol error, never a second UI event.
                    }
                }
            }
            if (assembler.pending()) {
                ++counters.decodeFailures;
                throw Failure{ErrorCode::Decode, "partial frame at completion"};
            }
            stream.close(); // The game session owns its own socket; CGAskQuit is not a login packet.
        } catch (const Cancelled&) {
            terminal.type = EventType::Cancelled; terminal.message = "login cancelled";
            terminal.packet.reset(); terminal.ticket.reset();
        } catch (const Failure& failure) {
            terminal.type = EventType::Error; terminal.error = failure.code; terminal.message = failure.message;
            terminal.packet.reset(); terminal.ticket.reset();
        } catch (...) {
            terminal.type = EventType::Error; terminal.error = ErrorCode::Internal;
            terminal.message = "network worker failure"; terminal.packet.reset(); terminal.ticket.reset();
        }
        login.reset();
        counters.socketClosed = true;
        counters.pendingBytes = assembler.pending();
        terminal.counters = counters;
        try { finish(std::move(terminal)); }
        catch (...) { running.store(false); } // Never terminate the process on worker allocation failure.
    }
};

LoginClient::LoginClient() : impl_(new Impl) {}
LoginClient::~LoginClient() {
    impl_->stop.store(true);
    if (impl_->worker.joinable()) impl_->worker.join();
    std::lock_guard<std::mutex> lock(impl_->mutex);
    impl_->events.clear(); impl_->queuedBytes = 0;
}

bool LoginClient::start(const Endpoint& endpoint, const std::string& account, const std::string& password,
                        const Options& options) {
    if (!impl_->onOwner()) return false;
    impl_->startError = ErrorCode::None;
    if (impl_->running.load() || impl_->pumping) { impl_->startError = ErrorCode::Busy; return false; }
    {
        std::lock_guard<std::mutex> lock(impl_->mutex);
        if (!impl_->events.empty()) { impl_->startError = ErrorCode::Busy; return false; }
    }
    // Validate without starting Winsock, making calls outside the approved
    // loopback profile impossible even for a malformed configuration.
    if (!endpoint.port || !validOptions(options) || !IsHostAllowed(endpoint.host, options.allowedHosts)) { // CYS: allow-list
        impl_->startError = ErrorCode::InvalidInput; return false;
    }
    std::unique_ptr<LoginSecret> login(new LoginSecret);
    if (!makeLogin(account, password, *login)) { impl_->startError = ErrorCode::InvalidInput; return false; }
    if (impl_->worker.joinable()) impl_->worker.join();
    {
        std::lock_guard<std::mutex> lock(impl_->mutex);
        impl_->interactive = options.mode == SessionMode::Interactive;
        impl_->clearCommandState();
        impl_->knownGuids.clear();
        impl_->charLoginEnabled = charLoginAllowed(options);
        impl_->commands = 0; impl_->commandError = ErrorCode::None;
    }
    impl_->stop.store(false); impl_->running.store(true);
    try {
        impl_->worker = std::thread(&Impl::run, impl_.get(), endpoint, account, options, std::move(login));
    } catch (...) {
        impl_->running.store(false); impl_->startError = ErrorCode::Internal; return false;
    }
    return true;
}

ErrorCode LoginClient::lastStartError() const {
    return impl_->onOwner() ? impl_->startError : ErrorCode::WrongThread;
}

bool LoginClient::canRequestCreatePermission() const {
    if (!impl_->onOwner()) return false;
    std::lock_guard<std::mutex> lock(impl_->mutex);
    return impl_->interactive && impl_->running.load() && !impl_->stop.load() &&
        impl_->creationReady && !impl_->pendingCommand && impl_->commands < MaxCreateCommands;
}

bool LoginClient::canCreateCharacter() const {
    if (!canRequestCreatePermission()) return false;
    std::lock_guard<std::mutex> lock(impl_->mutex);
    return impl_->permissionGranted;
}

bool LoginClient::canRequestCharacterLogin() const {
    if (!impl_->onOwner()) return false;
    std::lock_guard<std::mutex> lock(impl_->mutex);
    return impl_->interactive && impl_->running.load() && !impl_->stop.load() && impl_->charLoginEnabled &&
        impl_->loginReady && !impl_->pendingCommand && impl_->commands < MaxCreateCommands &&
        !impl_->knownGuids.empty();
}

ErrorCode LoginClient::lastCommandError() const {
    return impl_->onOwner() ? impl_->commandError : ErrorCode::WrongThread;
}

bool LoginClient::requestCreatePermission() {
    if (!impl_->onOwner()) return false;
    impl_->commandError = ErrorCode::None;
    std::lock_guard<std::mutex> lock(impl_->mutex);
    if (!impl_->interactive || !impl_->running.load() || impl_->stop.load()) {
        impl_->commandError = ErrorCode::NotReady; return false;
    }
    if (impl_->commands >= MaxCreateCommands) { impl_->commandError = ErrorCode::Limit; return false; }
    if (!impl_->creationReady || impl_->pendingCommand) { impl_->commandError = ErrorCode::Busy; return false; }
    impl_->pendingCommand.reset(new pg::CLCheckAllowCreateChar);
    impl_->loginReady = false; impl_->creationReady = false; impl_->permissionGranted = false;
    ++impl_->commands; impl_->haveCommand.store(true);
    return true;
}

bool LoginClient::createCharacter(const CreateCharacterRequest& request) {
    if (!impl_->onOwner()) return false;
    impl_->commandError = ErrorCode::None;
    std::unique_ptr<pg::CLAskCreateChar> packet(new pg::CLAskCreateChar);
    if (!makeCreate(request, *packet)) { impl_->commandError = ErrorCode::InvalidInput; return false; }
    std::lock_guard<std::mutex> lock(impl_->mutex);
    if (!impl_->interactive || !impl_->running.load() || impl_->stop.load()) {
        impl_->commandError = ErrorCode::NotReady; return false;
    }
    if (impl_->commands >= MaxCreateCommands) { impl_->commandError = ErrorCode::Limit; return false; }
    if (!impl_->creationReady || !impl_->permissionGranted || impl_->pendingCommand) {
        impl_->commandError = ErrorCode::Busy; return false;
    }
    impl_->pendingCommand = std::move(packet);
    impl_->loginReady = false; impl_->creationReady = false; impl_->permissionGranted = false;
    ++impl_->commands; impl_->haveCommand.store(true);
    return true;
}

bool LoginClient::requestCharacterLogin(uint32_t guid) {
    if (!impl_->onOwner()) return false;
    impl_->commandError = ErrorCode::None;
    std::lock_guard<std::mutex> lock(impl_->mutex);
    if (!impl_->interactive || !impl_->running.load() || impl_->stop.load() || !impl_->charLoginEnabled) {
        impl_->commandError = ErrorCode::NotReady; return false;
    }
    bool known = false;
    for (uint32_t value : impl_->knownGuids) known = known || value == guid;
    if (!guid || !known) { impl_->commandError = ErrorCode::InvalidInput; return false; }
    if (impl_->commands >= MaxCreateCommands) { impl_->commandError = ErrorCode::Limit; return false; }
    if (!impl_->loginReady || impl_->pendingCommand) { impl_->commandError = ErrorCode::Busy; return false; }
    std::unique_ptr<pg::CLAskCharLogin> packet(new pg::CLAskCharLogin);
    packet->guid = guid;
    packet->PlayerID = 0; // packet.lua ctor value; the server reads only the GUID.
    impl_->pendingCommand = std::move(packet);
    impl_->loginReady = false; impl_->creationReady = false; impl_->permissionGranted = false;
    ++impl_->commands; impl_->haveCommand.store(true);
    return true;
}

size_t LoginClient::pump(const Handler& handler, size_t maxEvents) {
    const auto state = impl_; // A callback may release its owning procedure/client.
    if (!state->onOwner()) throw std::logic_error("LoginClient pump requires its owner thread");
    if (state->pumping || !handler) return 0;
    struct PumpGuard { bool& flag; explicit PumpGuard(bool& f) : flag(f) { flag=true; } ~PumpGuard() { flag=false; } } guard(state->pumping);
    size_t delivered = 0;
    while (delivered < (std::min)(maxEvents, MaxEvents)) {
        Event event;
        {
            std::lock_guard<std::mutex> lock(state->mutex);
            if (state->events.empty()) break;
            state->queuedBytes -= state->events.front().bytes;
            event = std::move(state->events.front().event);
            state->events.pop_front();
            if (state->interactive && state->running.load() && !state->stop.load()) {
                switch (event.type) {
                case EventType::CharacterList:
                    state->loginReady = true;
                    state->creationReady = event.creationAvailable;
                    state->permissionGranted = false;
                    state->knownGuids.clear();
                    if (const auto* list = dynamic_cast<const pg::LCRetCharList*>(event.packet.get()))
                        for (const auto& role : list->charlist) state->knownGuids.push_back(role.guid);
                    break;
                case EventType::CreatePermission:
                    state->loginReady = true;
                    state->creationReady = event.creationAvailable;
                    state->permissionGranted = event.permissionFlag == 1;
                    break;
                case EventType::CharacterCreated:
                    state->loginReady = event.createResult != 0;
                    state->creationReady = event.creationAvailable;
                    state->permissionGranted = event.createResult != 0;
                    break;
                case EventType::CharacterLoginRefused:
                    state->loginReady = true;
                    state->creationReady = event.creationAvailable;
                    state->permissionGranted = false;
                    break;
                default: break;
                }
            }
        }
        ++delivered;
        handler(std::move(event));
        if (state->stop.load()) break;
    }
    return delivered;
}

void LoginClient::cancel() {
    if (!impl_->onOwner()) throw std::logic_error("LoginClient cancel requires its owner thread");
    std::lock_guard<std::mutex> lock(impl_->mutex);
    impl_->stop.store(true);
    impl_->events.clear(); impl_->queuedBytes = 0;
    impl_->clearCommandState();
}

bool LoginClient::active() const { return impl_->running.load(); }

}} // namespace cys::net
