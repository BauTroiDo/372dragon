#pragma once
// CYS-POWER: cultivation (修炼) of the CY power windows on the skynet CY protocol. Game.exe main thread only.
//
// What this module owns (host-power, 17/09/2026):
//   * GCDetailXiulianList (1014): the 11 cultivation scrolls of the own character, each {level, upper_limit}.
//   * The three CY tables the Xiulian windows read: XiuLianMiJi.txt (15 scrolls), XiuLianBook.txt (3 books),
//     XiuLianDetail.txt (16 menpai x 151 levels x 15 scrolls: exp / money / bonus of every step).
//   * The Lua host functions Player:GetXiuLianMiJiInfo and Player:GetXiuLianBookInfo (LuaApiGen/CysHost_Power).
//
// Server behaviour (read-only clone /home/ubuntu/cys-test-20260913):
//   human.lua fix_xiulian_list (每 scroll starts at {level = 0, upper_limit = 10}), get_xiulian_list,
//   xiulian_upper_limit_up (进阶境界 adds exactly 10), send_xiulian_list (scenecore.lua:1703 on entering the world),
//   human_attrib.lua get_xiulian_bonus (XiuLianDetail row keyed by BOOKID == menpai and BOOKLEVEL == scroll level).
// Wire layout and the live measurement: Docs/specs/client/host-power_vi.md, Docs/specs/net/power-attrib_vi.md.

#include <cstdint>

namespace pg { class Packet; }

namespace CysPowerNet
{
    // Returns true when the packet was consumed (GCDetailXiulianList).
    bool Dispatch(const pg::Packet& packet);

    // Cultivation state of the own character; index 0..10 as the CY scripts count it (XiuLianMiJi id).
    // -1 = no GCDetailXiulianList seen yet or index out of range.
    int XiulianLevel(int miji);
    int XiulianUpperLimit(int miji);
    bool HaveXiulian();
    void OnGongli(uint32_t value);
    uint32_t Gongli();

    // XiuLianMiJi.txt / XiuLianBook.txt text, GBK exactly as the table stores it (the client is a 936 client).
    // part: 0 = name, 1 = description. nullptr when there is no such row.
    const char* MiJiText(int miji, int part);
    const char* BookText(int book, int part);

    // XiuLianDetail row (menpai, level + 1) of the own character: what the NEXT level of that scroll costs.
    // what: 0 = experience (经验), 1 = money (金币). 0 when the level is at or past the last row (150).
    int UpLevelNeed(int miji, int level, int what);

    struct Counters { unsigned xiulianLists; };
    Counters Get();

    // Lua host functions of the CY cultivation windows (LuaApiGen/CysHost_Power); idempotent, main thread.
    void RegisterHost();
}
