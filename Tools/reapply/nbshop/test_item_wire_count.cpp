// Native fixture from server ItemInfo.bos, not a round-trip through its C++ writer.
#include "CysItemWireCount.h"
#include "PgPackets_misc.h"
#include <cassert>
#include <cstdio>

static std::vector<uint8_t> Wire(unsigned cls, unsigned count)
{
    pg::Writer w;
    w.i16(5); w.i32(0); // GCItemInfo: client slot 5, occupied.
    w.u8(10); w.u8(1); w.u16(0); w.u32(74); // GUID from test13 purchase.
    w.i32(cls == 3 ? 38000494 : static_cast<int32_t>(cls * 10000000 + 1));
    w.u8(5); w.u8(2); // rule, status; no creator payload.
    for (unsigned i = 0; i < 12; ++i) w.u8(0); // params
    const unsigned width = cls == 5 ? 56 : 32;
    const unsigned countOffset = cls == 5 ? 48 : 0;
    for (unsigned i = 0; i < width; ++i) w.u8(i == countOffset ? count : 0);
    w.u32(0); w.u16(0); // ItemInfo trailer
    w.u32(0); w.i32(0); // askid, bag_type
    return w.buffer();
}

int main()
{
    unsigned checks = 0;
    for (unsigned cls = 2; cls <= 5; ++cls)
    {
        for (unsigned count : {0u, 1u, 2u, 250u})
        {
            const auto wire = Wire(cls, count);
            pg::Reader reader(wire.data(), wire.size());
            pg::GCItemInfo packet;
            assert(packet.read(reader) && reader.remaining() == 0);
            assert(packet.bagIndex == 5 && packet.item.guid.series == 74);
            assert(CysItemWireCount::Get(packet.item) == count);
            ++checks;
        }
    }
    auto truncated = Wire(3, 2); truncated.pop_back();
    pg::Reader reader(truncated.data(), truncated.size());
    pg::GCItemInfo packet;
    assert(!packet.read(reader)); ++checks;
    std::printf("PASS %u native wire cases: material/common/task/gem new=1, stack=2, zero,250; truncated packet rejected.\n", checks);
    return 0;
}
