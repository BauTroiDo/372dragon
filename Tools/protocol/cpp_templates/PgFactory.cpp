// ProtocolGen factory and decode / encode API (template: CY-Source/Tools/protocol/cpp_templates/PgFactory.cpp).
#include "PgFactory.h"

#include <cstring>

namespace pg {

namespace detail {
const PacketInfo* tableData(size_t* count);  // PgFactoryTable.cpp (generated)
}

const PacketInfo* packetTable(size_t* count) { return detail::tableData(count); }

const PacketInfo* findPacket(Proto proto, uint16_t id) {
    size_t n = 0;
    const PacketInfo* t = detail::tableData(&n);
    size_t lo = 0, hi = n;
    while (lo < hi) {
        const size_t mid = lo + (hi - lo) / 2;
        if (t[mid].proto < proto || (t[mid].proto == proto && t[mid].id < id))
            lo = mid + 1;
        else
            hi = mid;
    }
    return (lo < n && t[lo].proto == proto && t[lo].id == id) ? &t[lo] : nullptr;
}

const PacketInfo* findPacketByName(const char* name) {
    if (!name) return nullptr;
    size_t n = 0;
    const PacketInfo* t = detail::tableData(&n);
    for (size_t i = 0; i < n; ++i)
        if (std::strcmp(t[i].name, name) == 0) return &t[i];
    return nullptr;
}

std::unique_ptr<Packet> createPacket(Proto proto, uint16_t id) {
    const PacketInfo* info = findPacket(proto, id);
    return std::unique_ptr<Packet>(info ? info->create() : nullptr);
}

std::unique_ptr<Packet> decodePacket(Proto proto, uint16_t id, const void* body, size_t size,
                                     DecodeResult* result, bool strict) {
    DecodeResult local;
    DecodeResult& res = result ? *result : local;
    res = DecodeResult();
    const PacketInfo* info = findPacket(proto, id);
    res.info = info;
    if (!info) {
        res.error = "unknown packet id";
        return nullptr;
    }
    if (size > kMaxBody) {
        res.error = "body larger than 65535 bytes";
        return nullptr;
    }
    try {
        std::unique_ptr<Packet> p(info->create());
        Reader r(body, size);
        const bool ok = p->read(r);
        res.used = r.pos();
        if (!ok) {
            res.error = r.error();
            res.field = r.errorField();
            res.errorPos = r.errorPos();
            return nullptr;
        }
        if (strict && r.remaining() != 0) {
            res.error = "trailing bytes";
            res.errorPos = r.pos();
            return nullptr;
        }
        res.ok = true;
        return p;
    } catch (...) {
        res.error = "exception while decoding";
        return nullptr;
    }
}

void encodeBody(const Packet& p, std::vector<uint8_t>& out) {
    Writer w;
    p.write(w);
    out.swap(w.buffer());
}

bool encodeFrame(const Packet& p, uint16_t idx, std::vector<uint8_t>& out) {
    Writer w;
    p.write(w);
    if (w.size() > kMaxBody) return false;
    FrameHeader h;
    h.id = p.packetId();
    h.size = static_cast<uint16_t>(w.size());
    h.idx = idx;
    out.clear();
    out.reserve(kFrameHeaderSize + w.size());
    writeFrameHeader(out, h);
    out.insert(out.end(), w.buffer().begin(), w.buffer().end());
    return true;
}

}  // namespace pg
