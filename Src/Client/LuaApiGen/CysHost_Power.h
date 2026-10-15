#pragma once
// CYS-POWER: Lua host functions of the CY "power" windows that the 0.85 source lacks (host-power, 17/09/2026).
// This pass covers cultivation (修炼): Xiulian.lua and XiulianStudy.lua, the one power system that is proven to
// run on the private server (Docs/specs/net/power-attrib_vi.md section 2.2).
// Game-layer state and tables come through Services (implemented in WXClient/Network/CysPowerNet.cpp); this file
// is Lua glue only. Behaviour is copied from B (client_GL\Bin64\Game.exe): see CysPowerNet.cpp for the addresses.
#include "LuaPlus.h"

namespace CysHostPower
{
    struct Services
    {
        // Cultivation state of the own character, scroll 0..10 (-1 = no GCDetailXiulianList yet).
        int (*xiulianLevel)(int miji) = nullptr;
        int (*xiulianUpperLimit)(int miji) = nullptr;
        // XiuLianMiJi.txt / XiuLianBook.txt text: part 0 = name, 1 = description (nullptr = no such row).
        const char* (*mijiText)(int miji, int part) = nullptr;
        const char* (*bookText)(int book, int part) = nullptr;
        // XiuLianDetail cost of the NEXT level of that scroll: what 0 = experience, 1 = money.
        int (*upLevelNeed)(int miji, int level, int what) = nullptr;
        // Opens the cultivation window (pushes GE_OPEN_XIULIAN_PAGE); false = the event system refused.
        bool (*openXiulianPage)() = nullptr;
        bool (*bookActive)(int book) = nullptr;
    };

    // Replaces the generated stubs (LuaApiGen_Player.cpp) of the functions below; returns how many were registered.
    int Register(LuaPlus::LuaState* state, const Services& services);
}
