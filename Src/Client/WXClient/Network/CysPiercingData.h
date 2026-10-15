#pragma once
#include <cstdint>
// Private server human_attrib publishes its actual combat totals as MD602/603.
// Keep these outside the legacy 256-entry mission struct (do not change its ABI).
namespace CysPiercingData {
// Private server character:on_damages uses MP = -100000 - damage for
// BeHit rows 13/14. This is a display record; it never changes character MP.
inline int Damage(int encoded) { return encoded < -100000 ? -(encoded+100000) : 0; }
inline unsigned& DamageBoards() { static unsigned count=0;return count; }
struct Snapshot {
    uint32_t values[2] = {}; unsigned present = 0;
    void Clear() { *this = Snapshot(); }
    bool Apply(unsigned id, uint32_t value) {
        if (id < 602 || id > 603) return false;
        const unsigned i=id-602, bit=1u<<i;
        const bool changed=!(present&bit)||values[i]!=value;
        values[i]=value;present|=bit;return changed;
    }
    bool Query(bool defence,uint32_t& value) const {
        const unsigned i=defence?1:0;
        if (!(present&(1u<<i))) return false;
        value=values[i];return true;
    }
};
}
