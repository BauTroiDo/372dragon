// GCDetailAttrib fixture assembled in server write order, never using packet.write().
#include "CysSelfEquipData.h"
#include "PgPackets_combat.h"
#include <cassert>
#include <cstdio>

static std::vector<uint8_t> Wire(uint8_t f3, uint8_t f9, const uint32_t values[6])
{
    pg::Writer w;
    w.u32(200014);
    for (unsigned i = 0; i < 22; ++i) w.u8(i == 2 ? f3 : i == 8 ? f9 : 0);
    if (f3 & 0x20) w.u32(values[0]);
    if (f3 & 0x40) w.u32(values[1]);
    if (f9 & 0x02) w.u32(values[2]);
    if (f9 & 0x04) w.u32(values[3]);
    if (f9 & 0x08) w.u32(values[4]);
    if (f9 & 0x10) w.u32(values[5]);
    return w.buffer();
}
static pg::GCDetailAttrib Decode(uint8_t f3, uint8_t f9, const uint32_t values[6])
{
    const auto wire = Wire(f3, f9, values);
    pg::Reader r(wire.data(), wire.size()); pg::GCDetailAttrib p;
    assert(p.read(r) && r.remaining() == 0);
    return p;
}
int main()
{
    using namespace CysSelfEquipData;
    Snapshot s; uint32_t value = 123;
    const uint32_t fixture[] = {19, 7, 60, 60, 50, 50}; // Critical numbers are a fixture, not predicted test13 data.
    for (unsigned i = 0; i < KeyCount; ++i) assert(!s.Get(static_cast<Key>(i), value));
    auto full = Decode(0x60, 0x1e, fixture);
    assert(s.Apply(full, false) == 0 && s.present == 0); // Other players must not pollute this snapshot.
    assert(s.Apply(full, true) == 63 && s.present == 63);
    for (unsigned i = 0; i < KeyCount; ++i) assert(s.Get(static_cast<Key>(i), value) && value == fixture[i]);
    assert(s.Apply(full, true) == 0); // Repeated values must not generate spurious UI events.
    // One field at a time: zero is present; the other five retain previous values.
    for (unsigned i = 0; i < KeyCount; ++i)
    {
        s.Apply(full, true);
        uint32_t zeros[6] = {};
        auto delta = Decode(i < 2 ? static_cast<uint8_t>(0x20 << i) : 0,
                            i >= 2 ? static_cast<uint8_t>(0x02 << (i - 2)) : 0, zeros);
        assert(s.Apply(delta, true) == (1u << i));
        for (unsigned j = 0; j < KeyCount; ++j)
            assert(s.Get(static_cast<Key>(j), value) && value == (i == j ? 0 : fixture[j]));
    }
    s.Apply(full, true);
    uint32_t garbage[6] = {1,2,3,4,5,6};
    assert(s.Apply(Decode(0, 0, garbage), true) == 0);
    assert(s.Get(Vigor, value) && value == 60);
    s.ConnectionOpened(2); assert(s.present == 63); // Scene transfer keeps the current display.
    s.ConnectionOpened(1); assert(s.present == 0); // New login cannot inherit another character.
    s.Apply(full, true); s.Clear(); assert(s.present == 0);
    uint32_t high[6] = {0xffffffffu,0,0,0,0,0};
    s.Apply(Decode(0x20, 0, high), true);
    assert(s.Get(CriticalAttack, value) && value == 0xffffffffu);
    assert(FindKey("CRITRATE") == KeyCount && FindKey("BATTLESCORE") == KeyCount);
    assert(FindKey("ENERGY") == Energy && FindKey(nullptr) == KeyCount);
    auto shortWire = Wire(0x60, 0x1e, fixture); shortWire.pop_back();
    pg::Reader r(shortWire.data(), shortWire.size()); pg::GCDetailAttrib shortPacket;
    assert(!shortPacket.read(r));
    std::puts("PASS: raw1772 decode; six isolated deltas; zero/absent; other-player; repeat; transfer/login/close; uint32; no gameplay aliases; truncated rejected.");
}
