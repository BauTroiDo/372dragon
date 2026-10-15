#include "NetStream.h"
#include <winsock2.h>
#include <ws2tcpip.h>
#include <algorithm>
#include <chrono>

namespace cys { namespace net {
namespace {
using Clock = std::chrono::steady_clock;
constexpr int PollQuantumMs = 20;

// CYS: the Winsock socket the workers used before the data-source seam; connect,
// write, wait and read keep their previous semantics and diagnostics.
class WinsockStream : public Stream {
public:
    WinsockStream() {
        WSADATA data{};
        started_ = WSAStartup(MAKEWORD(2, 2), &data) == 0;
    }
    ~WinsockStream() override {
        close();
        if (started_) WSACleanup();
    }

    ErrorCode connect(const Endpoint& endpoint, uint32_t timeoutMs, const std::atomic<bool>& stop,
                      const char** message) override {
        *message = "";
        if (!started_) { *message = "Winsock initialization failed"; return ErrorCode::ConnectFailed; }
        if (socket_ != INVALID_SOCKET) { *message = "socket already connected"; return ErrorCode::Internal; }
        socket_ = ::socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if (socket_ == INVALID_SOCKET) { *message = "socket creation failed"; return ErrorCode::ConnectFailed; }
        u_long nonblocking = 1;
        BOOL noDelay = TRUE;
        if (ioctlsocket(socket_, FIONBIO, &nonblocking) ||
            setsockopt(socket_, IPPROTO_TCP, TCP_NODELAY, reinterpret_cast<const char*>(&noDelay), sizeof(noDelay))) {
            *message = "socket setup failed"; return ErrorCode::Io;
        }
        sockaddr_in address{};
        address.sin_family = AF_INET; address.sin_port = htons(endpoint.port);
        InetPtonA(AF_INET, endpoint.host.c_str(), &address.sin_addr);
        if (::connect(socket_, reinterpret_cast<const sockaddr*>(&address), sizeof(address)) == SOCKET_ERROR) {
            if (WSAGetLastError() != WSAEWOULDBLOCK) { *message = "connection failed"; return ErrorCode::ConnectFailed; }
            const ErrorCode waited = waitFor(POLLWRNORM, timeoutMs, stop);
            if (waited == ErrorCode::Timeout) { *message = "connect timeout"; return ErrorCode::Timeout; }
            if (waited != ErrorCode::None) { *message = "connection failed"; return ErrorCode::ConnectFailed; }
            int error = 0, length = sizeof(error);
            if (getsockopt(socket_, SOL_SOCKET, SO_ERROR, reinterpret_cast<char*>(&error), &length) || error) {
                *message = "connection refused"; return ErrorCode::ConnectFailed;
            }
        }
        return ErrorCode::None;
    }

    ErrorCode write(const uint8_t* data, size_t size, uint32_t timeoutMs, const std::atomic<bool>& stop,
                    const char** message) override {
        *message = "";
        const auto deadline = Clock::now() + std::chrono::milliseconds(timeoutMs);
        size_t sent = 0;
        while (sent != size) {
            if (stop.load()) return ErrorCode::Io;
            const auto remain = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - Clock::now()).count();
            if (remain <= 0) { *message = "network deadline exceeded"; return ErrorCode::Timeout; }
            WSAPOLLFD poll{};
            poll.fd = socket_; poll.events = POLLWRNORM;
            const int ready = WSAPoll(&poll, 1, static_cast<int>((std::min)(remain, static_cast<decltype(remain)>(PollQuantumMs))));
            if (ready == SOCKET_ERROR) { *message = "socket poll failed"; return ErrorCode::Io; }
            if (!ready) continue;
            if (!(poll.revents & POLLWRNORM)) {
                if (poll.revents & (POLLERR | POLLHUP | POLLNVAL)) { *message = "socket closed or failed"; return ErrorCode::PeerClosed; }
                continue;
            }
            const int count = ::send(socket_, reinterpret_cast<const char*>(data + sent), static_cast<int>(size - sent), 0);
            if (count == SOCKET_ERROR && WSAGetLastError() == WSAEWOULDBLOCK) continue;
            if (count <= 0) { *message = "socket send failed"; return ErrorCode::Io; }
            sent += static_cast<size_t>(count);
        }
        return ErrorCode::None;
    }

    Wait wait(int ms) override {
        WSAPOLLFD poll{};
        poll.fd = socket_; poll.events = POLLRDNORM;
        const int ready = WSAPoll(&poll, 1, ms);
        if (ready == SOCKET_ERROR) return Wait::Failed;
        if (!ready) return Wait::Idle;
        // A peer may close after a complete reply: readable bytes are drained first.
        if (poll.revents & POLLRDNORM) return Wait::Readable;
        if (poll.revents & (POLLERR | POLLHUP | POLLNVAL)) return Wait::Closed;
        return Wait::Idle;
    }

    int read(uint8_t* buffer, size_t size) override {
        const int count = ::recv(socket_, reinterpret_cast<char*>(buffer), static_cast<int>(size), 0);
        if (count == SOCKET_ERROR) return WSAGetLastError() == WSAEWOULDBLOCK ? -1 : -2;
        return count;
    }

    void close() override {
        if (socket_ != INVALID_SOCKET) {
            shutdown(socket_, SD_BOTH);
            closesocket(socket_);
            socket_ = INVALID_SOCKET;
        }
    }

private:
    ErrorCode waitFor(short events, uint32_t timeoutMs, const std::atomic<bool>& stop) {
        const auto deadline = Clock::now() + std::chrono::milliseconds(timeoutMs);
        for (;;) {
            if (stop.load()) return ErrorCode::Io;
            const auto remain = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - Clock::now()).count();
            if (remain <= 0) return ErrorCode::Timeout;
            WSAPOLLFD poll{};
            poll.fd = socket_; poll.events = events;
            const int count = WSAPoll(&poll, 1, static_cast<int>((std::min)(remain, static_cast<decltype(remain)>(PollQuantumMs))));
            if (count == SOCKET_ERROR) return ErrorCode::Io;
            if (!count) continue;
            if (poll.revents & events) return ErrorCode::None;
            if (poll.revents & (POLLERR | POLLHUP | POLLNVAL)) return ErrorCode::PeerClosed;
        }
    }

    SOCKET socket_ = INVALID_SOCKET;
    bool started_ = false;
};

class WinsockFactory : public StreamFactory {
public:
    std::unique_ptr<Stream> create() override { return std::unique_ptr<Stream>(new WinsockStream); }
};
} // namespace

std::shared_ptr<StreamFactory> WinsockStreamFactory() {
    static std::shared_ptr<StreamFactory> factory(new WinsockFactory);
    return factory;
}

}} // namespace cys::net
