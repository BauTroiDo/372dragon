#pragma once
// CYS-RIDE: Lua host functions of the CY mount window (Ride.lua), wired to the network module
// Src\Client\WXClient\Network\CysRideNet.{h,cpp} that the `ride-core` agent wrote (host-power, 17/09/2026).
//
// Split of work: CysRideNet owns the wire (CGCharAutoRide 636 / GCCharAutoRide 63, mount state, timeouts);
// this file owns only the Lua names, exactly like CysHost_Power does for cultivation. It is allowed to reach
// into CysRideNet and CysModernGame directly, so CysRideNet needs no RegisterHost of its own.
//
// Documented in Docs\specs\client\host-power_vi.md section 8.
#include "LuaPlus.h"

namespace CysHostRide
{
    // Registers the mount host functions; returns how many were registered. Idempotent, main thread only.
    int Register(LuaPlus::LuaState* state);
    // Same, resolving the Lua state from CScriptSystem (call site: CysModernGame after a session starts).
    void RegisterHost();
    // Evidence runs only (CYS_RIDE_PROBE): the body of Lua_CysSelectRide without going through Lua.
    bool ProbeSelectRide(int index);
}
