#pragma once
// CYS-CORE: recording wrapper of a StreamFactory. Every frame written to or read from the wrapped stream is
// split with the framing code of the login probe and kept per socket (generation order). The bot writes the
// frames of one game socket as a PGWORLD1 fixture (Tests/net/make_world_fixture.py layout) so that the
// offline replay (ReplayStream.h) can play a real core-loop session back into Game.exe.
// Secrets: the CGConnect key (first 4 body bytes) and the GCRetChangeScene key are zeroed in the fixture;
// login sockets are never wrapped by the bot (credentials never reach this code).

#include "NetStream.h"
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace cys { namespace net { namespace record {

struct Frame {
    bool c2s = false;
    uint16_t id = 0, idx = 0;
    std::vector<uint8_t> body;
};

class Recorder {
public:
    // Called by the recording streams (worker thread).
    unsigned openSocket();
    void add(unsigned socket, Frame&& frame);
    // Owner thread, after the session ended.
    unsigned sockets() const;
    std::vector<Frame> frames(unsigned socket) const;
    // PGWORLD1: C->S frames of `socket` first, then its S->C frames. Returns false with a fixed reason when the
    // socket has no CGConnect-first C->S stream or no KeyExchange/GCConnect/GCEnterScene S->C prologue.
    bool writeFixture(const std::string& path, unsigned socket, std::string& error) const;
    // Index of the last socket whose S->C stream carries at least one frame of `id`; 0 when none.
    unsigned lastSocketWith(uint16_t id) const;

private:
    mutable std::mutex mutex_;
    std::vector<std::vector<Frame>> sockets_;
};

std::shared_ptr<StreamFactory> RecordingStreamFactory(std::shared_ptr<StreamFactory> inner, std::shared_ptr<Recorder> recorder);

}}} // namespace cys::net::record
