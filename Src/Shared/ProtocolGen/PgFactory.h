// ProtocolGen factory and decode / encode API (template: CY-Source/Tools/protocol/cpp_templates/PgFactory.h,
// copied verbatim into Src/Shared/ProtocolGen by Tools/protocol/codegen_cpp.py). The table itself is
// generated (PgFactoryTable.cpp); one row per packet of Registry/protocol/packets.yaml.
#ifndef CYS_PROTOCOLGEN_PGFACTORY_H
#define CYS_PROTOCOLGEN_PGFACTORY_H

#include "PgRuntime.h"

namespace pg {

enum Confidence : uint8_t { ConfLow = 0, ConfMedium = 1, ConfHigh = 2 };
// How much of the server's layout the generated class can decode (details in PgCoverage.tsv):
//   DecFull    every branch and length is derived from the wire or a hand-checked rule
//   DecPartial some branch depends on server state (a documented default is used) or some length is
//              not on the wire (read() fails with "... not derivable from the wire" if it is reached)
//   DecNone    an unconditional part cannot be decoded (read() always fails); write() still works
enum Decodability : uint8_t { DecNone = 0, DecPartial = 1, DecFull = 2 };

struct PacketInfo {
    uint16_t id;
    Proto proto;
    Dir dir;
    Confidence confidence;      // spec confidence
    Decodability decodability;  // generator verdict
    uint16_t selectors;         // branch selector members in the class (server-state conditions)
    uint32_t minSize;           // spec size.min
    uint32_t maxSize;           // spec size.max, 0xFFFFFFFF when unbounded
    const char* name;           // class name, e.g. "GCChat"
    const char* constName;      // server id constant, e.g. "XYID_GC_CHAT"
    const char* domain;         // server packet_domains file (login for the login protocol)
    Packet* (*create)();
};

// All packets, sorted by (proto, id).
const PacketInfo* packetTable(size_t* count);
const PacketInfo* findPacket(Proto proto, uint16_t id);
const PacketInfo* findPacketByName(const char* name);
std::unique_ptr<Packet> createPacket(Proto proto, uint16_t id);

struct DecodeResult {
    bool ok = false;
    const char* error = "";  // static string
    const char* field = "";  // "Class.member" where it failed, when known
    size_t errorPos = 0;     // body offset of the failure
    size_t used = 0;         // bytes consumed by read()
    const PacketInfo* info = nullptr;
};

// Decode one body. strict = true requires the body to be consumed exactly ("trailing bytes").
// Never throws; returns nullptr on failure (result tells why).
std::unique_ptr<Packet> decodePacket(Proto proto, uint16_t id, const void* body, size_t size,
                                     DecodeResult* result = nullptr, bool strict = true);
// Encode the body only / a full frame {u16 id, u16 size, u16 idx} + body (false if body > 65535).
void encodeBody(const Packet& p, std::vector<uint8_t>& out);
bool encodeFrame(const Packet& p, uint16_t idx, std::vector<uint8_t>& out);

}  // namespace pg

#endif  // CYS_PROTOCOLGEN_PGFACTORY_H
