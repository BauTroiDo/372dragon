#pragma once
#include <cstdint>
#include <cstring>

// CY display-only attributes. These are not the legacy CritRate/RMB/DoubleExp slots.
namespace CysSelfEquipData
{
    enum Key { CriticalAttack, CriticalDefence, Vigor, MaxVigor, Energy, MaxEnergy, KeyCount };
    inline Key FindKey(const char* name)
    {
        static const char* names[] = { "CRITICALATTACK", "CRITICALDEFENCE", "VIGOR", "MAXVIGOR", "ENERGY", "MAXENERGY" };
        for (unsigned i = 0; i < KeyCount; ++i)
            if (name && std::strcmp(name, names[i]) == 0) return static_cast<Key>(i);
        return KeyCount;
    }

    struct Snapshot
    {
        uint32_t values[KeyCount] = {};
        unsigned present = 0;
        void Clear() { *this = Snapshot(); }
        void ConnectionOpened(uint32_t generation) { if (generation == 1) Clear(); }
        bool Get(Key key, uint32_t& value) const
        {
            if (key >= KeyCount || !(present & (1u << key))) return false;
            value = values[key]; return true;
        }
        template<class Packet> unsigned Apply(const Packet& packet, bool self)
        {
            if (!self) return 0;
            const bool has[] = { (packet.flags[2] & 0x20) != 0, (packet.flags[2] & 0x40) != 0,
                (packet.flags[8] & 0x02) != 0, (packet.flags[8] & 0x04) != 0,
                (packet.flags[8] & 0x08) != 0, (packet.flags[8] & 0x10) != 0 };
            const uint32_t next[] = { packet.mind_attack, packet.mind_defend,
                packet.vigor, packet.vigor_max, packet.stamina, packet.stamina_max };
            unsigned changed = 0;
            for (unsigned i = 0; i < KeyCount; ++i)
                if (has[i])
                {
                    const unsigned bit = 1u << i;
                    if (!(present & bit) || values[i] != next[i]) changed |= bit;
                    present |= bit; values[i] = next[i];
                }
            return changed;
        }
    };

    bool Enabled();
    bool Query(Key key, uint32_t& value);
}
