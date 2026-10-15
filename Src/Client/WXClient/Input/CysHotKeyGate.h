// CYS: gameplay shortcut state. Raw UI/IME input never passes through this gate.
#pragma once
#include <array>
#include <cstdint>

namespace CysHotKeys
{
    class Gate
    {
    public:
        std::int32_t Value() const { return value_; }

        template<class Cancel> void Set(std::int32_t value, Cancel cancel)
        {
            value_ = value;
            if (value != 0) return;
            const auto toCancel = held_;
            held_.fill(false);
            for (unsigned key = 0; key < toCancel.size(); ++key)
                if (toCancel[key]) blockedRelease_[key] = true;
            // Latch every release before a callback can throw or re-enter.
            for (unsigned key = 0; key < toCancel.size(); ++key)
                if (toCancel[key]) cancel(key);
        }

        bool Allow(unsigned key, bool down, bool up)
        {
            if (!down && !up) return true;
            if (key >= held_.size()) return false;
            if (up)
            {
                const bool blocked = blockedRelease_[key];
                blockedRelease_[key] = false;
                held_[key] = false;
                return value_ != 0 && !blocked;
            }
            held_[key] = value_ != 0;
            blockedRelease_[key] = value_ == 0;
            return value_ != 0;
        }

    private:
        std::int32_t value_ = 1;
        std::array<bool, 256> held_{};
        std::array<bool, 256> blockedRelease_{};
    };
}
