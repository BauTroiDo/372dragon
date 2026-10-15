#pragma once

namespace CysInput
{
    // Samples the toggle bit, never the key-down bit. Repeated key messages
    // do not become repeated change events; activation can resynchronise it.
    class CapsLockState
    {
    public:
        explicit CapsLockState(int state = 0) : m_enabled((state & 1) != 0) {}
        bool sample(int state)
        {
            const bool enabled = (state & 1) != 0;
            if (enabled == m_enabled) return false;
            m_enabled = enabled;
            return true;
        }
    private:
        bool m_enabled;
    };
}
