#pragma once







#include "LuaPlus.h"

namespace CysHostPlumbing
{
    struct Services
    {
        void* context = nullptr;
        // Level of the local player. < 0 = there is no local player yet (login / character screens).
        int (*playerLevel)(void*) = nullptr;
        // B's Player:IsVaild: the active procedure is the main (in-world) one AND a local player exists.
        bool (*playerValid)(void*) = nullptr;
        // Client area of the game window in pixels, already clamped the way B clamps it. false = no window yet.
        bool (*clientSize)(void*, int* width, int* height) = nullptr;
    };

    // Registers every function, overwriting the generated stub, and returns the number registered.
    int Register(LuaPlus::LuaState* state, const Services& services);

    // Test seams of the DataPool clock pair, both read in local time, 0 when the time_t cannot be converted.
    int DayStampFromTime(long long when);    // GetServerDayTime   -> YYYYMMDD
    int TimeStampFromTime(long long when);   // GetServerMinuteTime -> HHMMSS
}
