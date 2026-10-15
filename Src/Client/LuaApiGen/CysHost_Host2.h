#pragma once
// CYS-HOST2: second batch of Lua host functions (agent host-2, 17-18/09/2026) plus the live probe that measures them.
//
// Same split as CysHost_Ride: this LuaApiGen module owns the Lua names AND reaches into the game layer directly
// (item tables, event system, cursor), so no Network/*.cpp seam is needed. Registered (forced) from
// CysModernGame after a world session starts, exactly where CysHostRide::RegisterHost runs.
//
// Every entry copies the disassembly of client_GL\Bin64\Game.exe at the impl_va of Registry/luaapi/catalog.json;
// the annotated listings are in Build/Logs/2026-09-17-host-2/re/. Report: Docs/specs/client/host-2_vi.md.
//
//   DataPool:Lua_GetItemNameByIndex(index)  B 0x140244070 - name column of the item table the index belongs to.
//   _G:ToggleWuhunPage()                    B 0x14021b700 - PushEvent(0x27c "TOGGLE_WUHUN_PAGE", -1) in the main procedure.
//   _G:SetDefaultMouse()                    B 0x140222ce0 - cursor back to the default type ([SL] CURSOR_NORMAL here).
//   DataPool:GetKfsData/GetKfsFixAttrEx/GetKfsBase/GetFixKfsBase  B 0x140270cd0/0x140271540/0x1402716c0/0x140271770 -
//                                           nil without an equipped wuhun (the stubs' "" broke Wuhun_Update).
//
// CYS_HOST2_OFF=1 keeps every entry unregistered (the LuaApiGen stubs stay) - the same-binary control of the A/B runs.
// CYS_HOST2_LIVE=1 runs the probe after the world script: opens the CY windows the batch touches and shoots them.
#include "LuaPlus.h"

namespace CysHostHost2
{
    // Registers the host functions (forced); returns how many. Main thread only.
    int Register(LuaPlus::LuaState* state);
    // Same, resolving the Lua state from CScriptSystem (call site: CysModernGame after a session starts).
    void RegisterHost();
    // True when CYS_HOST2_OFF=1 (read once): nothing of this batch is registered.
    bool Disabled();

    // Game-layer answers, also used by the probe. nullptr / false = "B answers nothing".
    const char* ItemNameByIndex(int index);
    bool ToggleWuhunPage();

    // CYS_HOST2_LIVE=1 driver of the live GUI smoke (CysGlLoginSmoke case 52). Returns true when off or finished.
    bool Tick();
}
