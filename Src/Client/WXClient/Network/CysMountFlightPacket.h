#pragma once
#include "PgRuntime.h"
namespace pg {
// CY 3.71 Game.exe: 1407861a0 / 14083b640; ID 2242. Keep outside generated files.
class CGFlyOperation final : public Packet {
public:
    uint32_t object=0; uint8_t operation=0;
    uint16_t packetId() const override { return 2242; }
    Proto packetProto() const override { return Proto::Game; }
    Dir packetDir() const override { return Dir::CG; }
    const char* packetName() const override { return "CGFlyOperation"; }
    bool read(Reader& r) override { return r.u32(object)&&r.u8(operation); }
    void write(Writer& w) const override { w.u32(object);w.u8(operation); }
};
}
