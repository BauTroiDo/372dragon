#include "RecordStream.h"
#include "LoginProbe.h" // cysbot::FrameAssembler (framing code shared with the login probe)
#include "PgPackets_core.h"
#include "PgPackets_misc.h"
#include "PgPackets_movement.h"
#include <cstring>
#include <fstream>

namespace cys { namespace net { namespace record {

unsigned Recorder::openSocket() {
    std::lock_guard<std::mutex> lock(mutex_);
    sockets_.push_back(std::vector<Frame>());
    return static_cast<unsigned>(sockets_.size());
}

void Recorder::add(unsigned socket, Frame&& frame) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!socket || socket > sockets_.size()) return;
    sockets_[socket - 1].push_back(std::move(frame));
}

unsigned Recorder::sockets() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return static_cast<unsigned>(sockets_.size());
}

std::vector<Frame> Recorder::frames(unsigned socket) const {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!socket || socket > sockets_.size()) return std::vector<Frame>();
    return sockets_[socket - 1];
}

unsigned Recorder::lastSocketWith(uint16_t id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    for (size_t s = sockets_.size(); s > 0; --s)
        for (const auto& f : sockets_[s - 1])
            if (!f.c2s && f.id == id) return static_cast<unsigned>(s);
    return 0;
}

namespace {
void putLittle(std::vector<uint8_t>& out, uint32_t v, unsigned n) {
    for (unsigned i = 0; i < n; ++i) out.push_back(static_cast<uint8_t>((v >> (8 * i)) & 0xFF));
}
}

bool Recorder::writeFixture(const std::string& path, unsigned socket, std::string& error) const {
    const std::vector<Frame> all = frames(socket);
    std::vector<const Frame*> c2s, s2c;
    for (const auto& f : all) (f.c2s ? c2s : s2c).push_back(&f);
    if (c2s.empty() || c2s[0]->id != pg::CGConnect::PACKET_ID) { error = "C->S stream does not begin with CGConnect"; return false; }
    if (s2c.size() < 3 || s2c[0]->id != pg::KeyExchange::PACKET_ID || s2c[1]->id != pg::GCConnect::PACKET_ID ||
        s2c[2]->id != pg::GCEnterScene::PACKET_ID) {
        error = "S->C stream does not begin with KeyExchange, GCConnect, GCEnterScene"; return false;
    }
    std::vector<uint8_t> blob(reinterpret_cast<const uint8_t*>("PGWORLD1"), reinterpret_cast<const uint8_t*>("PGWORLD1") + 8);
    auto put = [&](const Frame& f) {
        std::vector<uint8_t> body = f.body;
        // Session keys never enter a fixture: CGConnect.key (first 4 bytes) and GCRetChangeScene.key (offset 27).
        if (f.c2s && f.id == pg::CGConnect::PACKET_ID && body.size() >= 4) std::memset(body.data(), 0, 4);
        if (!f.c2s && f.id == pg::GCRetChangeScene::PACKET_ID && body.size() >= 31) std::memset(body.data() + 27, 0, 4);
        blob.push_back(f.c2s ? 1 : 0);
        putLittle(blob, f.id, 2);
        putLittle(blob, f.idx, 2);
        putLittle(blob, static_cast<uint32_t>(body.size()), 4);
        blob.insert(blob.end(), body.begin(), body.end());
    };
    for (const Frame* f : c2s) put(*f);
    for (const Frame* f : s2c) put(*f);
    std::ofstream out(path.c_str(), std::ios::binary | std::ios::trunc);
    if (!out) { error = "cannot create the fixture file"; return false; }
    out.write(reinterpret_cast<const char*>(blob.data()), static_cast<std::streamsize>(blob.size()));
    if (!out) { error = "fixture write failed"; return false; }
    error.clear();
    return true;
}

namespace {

class RecordingStream : public Stream {
public:
    RecordingStream(std::unique_ptr<Stream> inner, std::shared_ptr<Recorder> recorder)
        : inner_(std::move(inner)), recorder_(std::move(recorder)) {}
    ~RecordingStream() override { close(); }

    ErrorCode connect(const Endpoint& endpoint, uint32_t timeoutMs, const std::atomic<bool>& stop, const char** message) override {
        const ErrorCode code = inner_->connect(endpoint, timeoutMs, stop, message);
        if (code == ErrorCode::None && !socket_) socket_ = recorder_->openSocket();
        return code;
    }
    ErrorCode write(const uint8_t* data, size_t size, uint32_t timeoutMs, const std::atomic<bool>& stop, const char** message) override {
        const ErrorCode code = inner_->write(data, size, timeoutMs, stop, message);
        if (code == ErrorCode::None) feed(c2s_, true, data, size);
        return code;
    }
    Wait wait(int ms) override { return inner_->wait(ms); }
    int read(uint8_t* buffer, size_t size) override {
        const int n = inner_->read(buffer, size);
        if (n > 0) feed(s2c_, false, buffer, static_cast<size_t>(n));
        return n;
    }
    void close() override { inner_->close(); }

private:
    void feed(cysbot::FrameAssembler& assembler, bool c2s, const uint8_t* data, size_t size) {
        if (!socket_) return;
        std::vector<cysbot::Frame> frames;
        if (!assembler.feed(data, size, frames)) return; // framing error: the worker reports it; nothing recorded
        for (auto& frame : frames) {
            Frame out;
            out.c2s = c2s; out.id = frame.header.id; out.idx = frame.header.idx; out.body = std::move(frame.body);
            recorder_->add(socket_, std::move(out));
        }
    }
    std::unique_ptr<Stream> inner_;
    std::shared_ptr<Recorder> recorder_;
    cysbot::FrameAssembler c2s_{4096}, s2c_{4096};
    unsigned socket_ = 0;
};

class RecordingFactory : public StreamFactory {
public:
    RecordingFactory(std::shared_ptr<StreamFactory> inner, std::shared_ptr<Recorder> recorder)
        : inner_(std::move(inner)), recorder_(std::move(recorder)) {}
    std::unique_ptr<Stream> create() override {
        return std::unique_ptr<Stream>(new RecordingStream(inner_->create(), recorder_));
    }
private:
    std::shared_ptr<StreamFactory> inner_;
    std::shared_ptr<Recorder> recorder_;
};

} // namespace

std::shared_ptr<StreamFactory> RecordingStreamFactory(std::shared_ptr<StreamFactory> inner, std::shared_ptr<Recorder> recorder) {
    if (!inner) inner = WinsockStreamFactory();
    return std::shared_ptr<StreamFactory>(new RecordingFactory(std::move(inner), std::move(recorder)));
}

}}} // namespace cys::net::record
