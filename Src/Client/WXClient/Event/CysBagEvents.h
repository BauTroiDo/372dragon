#pragma once
// A/B switches for the live CY bag contract; both default to the corrected path.
namespace CysBagEvents
{
    inline bool OldRefresh()
    {
        static const bool value = []() { char v[4] = {}; return GetEnvironmentVariableA("CYS_BAG_REFRESH_OLD", v, sizeof(v)) == 1 && v[0] == '1'; }();
        return value;
    }
    inline bool OldEnumeration()
    {
        static const bool value = []() { char v[4] = {}; return GetEnvironmentVariableA("CYS_BAG_ENUM_OLD", v, sizeof(v)) == 1 && v[0] == '1'; }();
        return value;
    }
}
