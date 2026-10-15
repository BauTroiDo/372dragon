#pragma once
#include <cstdint>

namespace CysChatTiming
{
    // CY ChatConfig column 3 and tTimeSystem::CalSubTime are both milliseconds.
    // CY Channel::TalkTimeCheck uses a strict > comparison; the pinned binary
    // evidence is recorded in Timeline/handoff/chat-enter-resume.md.
    inline bool Passed(uint32_t elapsedMs, uint32_t intervalMs, bool legacySeconds)
    {
        return (legacySeconds ? elapsedMs / 1000 : elapsedMs) > intervalMs;
    }
}
