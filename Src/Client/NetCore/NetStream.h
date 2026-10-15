#pragma once
// CYS: data-source seam of NetCore. The login and game workers read and write one
// byte stream through this interface; the default implementation is a Winsock TCP
// socket with exactly the behaviour the workers had before the seam existed. A
// different factory (the offline replay of ReplayStream.h) must be injected
// explicitly through Options::streamFactory / GameOptions::streamFactory; when no
// factory is given the workers use Winsock. No engine types, no packet classes.

#include "NetCommon.h"
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>

namespace cys { namespace net {

class Stream {
public:
    enum class Wait { Idle, Readable, Closed, Failed };
    virtual ~Stream() {}
    // Bounded connect. Polls `stop` and returns early (any code) once it is set;
    // the caller checks `stop` before interpreting the result. `message` receives a
    // fixed diagnostic string on failure.
    virtual ErrorCode connect(const Endpoint& endpoint, uint32_t timeoutMs, const std::atomic<bool>& stop,
                              const char** message) = 0;
    // Writes the whole buffer before the deadline (None, Timeout, Io, PeerClosed).
    virtual ErrorCode write(const uint8_t* data, size_t size, uint32_t timeoutMs, const std::atomic<bool>& stop,
                            const char** message) = 0;
    // Waits up to `ms` for inbound bytes.
    virtual Wait wait(int ms) = 0;
    // > 0 bytes read; 0 peer closed; -1 would block; -2 failure.
    virtual int read(uint8_t* buffer, size_t size) = 0;
    virtual void close() = 0;
};

class StreamFactory {
public:
    virtual ~StreamFactory() {}
    virtual std::unique_ptr<Stream> create() = 0;
};

// The real transport: one non-blocking TCP socket per stream (TCP_NODELAY), WSAPoll
// waits, Winsock initialised per stream.
std::shared_ptr<StreamFactory> WinsockStreamFactory();

}} // namespace cys::net
