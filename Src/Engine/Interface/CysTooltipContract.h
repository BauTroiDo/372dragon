#pragma once
#include <cstdlib>
// Same-binary tooltip comparison; defaults to the recovered live contract.
namespace CysTooltipContract
{
    inline bool Probe()
    {
        static const bool enabled = []() {
            const char* value = std::getenv("CYS_FT_TOOLTIP_PROBE");
            return value && value[0] == '1' && value[1] == 0;
        }();
        return enabled;
    }
    inline bool Old()
    {
        static const bool old = []() {
            const char* value = std::getenv("CYS_FT_TOOLTIP_OLD");
            return value && value[0] == '1' && value[1] == 0;
        }();
        return old;
    }
    inline bool ContentOld()
    {
        static const bool old = []() {
            const char* value = std::getenv("CYS_FT_CONTENT_OLD");
            return value && value[0] == '1' && value[1] == 0;
        }();
        return Old() || old;
    }
}
