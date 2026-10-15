// CYS-PLUMB: Lua glue of the shared host plumbing. See CysHost_Plumbing.h.
//
// Every entry below was disassembled in client_GL\Bin64\Game.exe at the impl_va of Registry/luaapi/catalog.json
// (image base 0x140000000); the listings are in Build/Logs/2026-09-17-host-plumbing/measure/disasm/.
//
//   Player:GetLevel   B 0x1402d7770 - ObjectManager[+0x98] (MySelf) -> [+0x1b0] (CharacterData) -> [+0x18][+0x6c],
//       pushed as one number.  That is exactly GetMySelf()->GetCharacterData()->Get_Level().  B only asserts on a
//       null MySelf, so it would fault on the login screen; this host pushes 0 there instead, because the CY frames
//       write "local n = Player:GetLevel(); if n < 30 then" and a nil would raise a Lua error.
//       (catalog impl_085 = SCRIPT_SANDBOX::Character::GetLevel - 0.85 has it on the TARGET only, never on Player.)
//
//   Player:IsVaild    B 0x1402d7810 - pushes 1.0 only when two globals are equal (the active procedure is the main
//       one) AND ObjectManager[+0x98] != 0; otherwise 0.  The CY frames test "~= 1" (PlayerQuicklyEnter.lua:314).
//
//   _G:GetCurClientSize  B 0x140227de0 - pushes two numbers:
//       if (IsIconic(hwnd)) { GetWindowPlacement -> rcNormalPosition, minus the frame that AdjustWindowRectEx
//                             computes from GWL_STYLE / GWL_EXSTYLE }
//       else               { GetClientRect -> right-left, bottom-top }
//       then clamps: width = max(width, 800), height = max(height, 600)   [.rdata 0x1407cb354 = 800, 0x1407cb384 = 600]
//       The minimum matters: the stub pushed (0, 0) and the 15 frames that read "local w,h = GetCurClientSize()"
//       laid themselves out on a 0x0 screen.
//
//   DataPool:GetServerDayTime  B 0x140273de0 - _localtime64 of a time_t, then
//           ((tm_year * 100 + 190001 + tm_mon) * 100) + tm_mday
//       which is (tm_year+1900)*10000 + (tm_mon+1)*100 + tm_mday, i.e. YYYYMMDD.  Checked against the 386 call
//       sites, which compare it with literals such as 20200106 (Alcohol_Shop.lua:11) and 20190426
//       (Anniversary.lua:208).
//   DataPool:GetServerMinuteTime  B 0x140273f30 - the twin of the above, same two clock calls, but
//           ((tm_hour * 100 + tm_min) * 100) + tm_sec
//       i.e. HHMMSS despite the name.  Checked against the call sites, which pair it with GetServerDayTime and
//       compare it with 110000 / 120000 (JieRiHuoDong.lua:302/315 = 11:00:00 and 12:00:00).  Same divergence note
//       as GetServerDayTime below.
//
//       DELIBERATE DIVERGENCE: B does not use the raw clock.  It takes the DataPool server time and adds
//       (8 - local_timezone_hours) * 3600 before calling _localtime64 (and subtracts one hour when tm_isdst > 0),
//       i.e. B answers with the date in UTC+8, the operator's time zone, whatever zone the player sits in.  Here the
//       server is this same machine (WSL), so its day and the client's local day are the same and the shift would
//       only push the client one day ahead of the server for part of every evening.  If this build ever talks to a
//       server in another zone, apply the shift here - the formula above is all that changes.
#include "CysHost_Plumbing.h"
#include "LuaApiGen.h"

#include <ctime>

namespace CysHostPlumbing
{
    namespace
    {
        Services g_services;

        // Same receiver walk as CysHost_Skill/CysHost_Package: a receiver is either a plain table or a boxed
        // object whose metatable (or its __index) carries the methods.
        LuaPlus::LuaObject Receiver(LuaPlus::LuaObject& globals, const char* name)
        {
            LuaPlus::LuaObject o = globals.GetByName(name);
            if (o.IsTable()) return o;
            if (o.IsUserData())
            {
                LuaPlus::LuaObject meta = o.GetMetaTable();
                if (!meta.IsTable()) return LuaPlus::LuaObject();
                LuaPlus::LuaObject index = meta.GetByName("__index");
                return index.IsTable() ? index : meta;
            }
            return LuaPlus::LuaObject();
        }

        int PlayerGetLevel(LuaPlus::LuaState* s)
        {
            const int level = g_services.playerLevel ? g_services.playerLevel(g_services.context) : -1;
            s->PushInteger(level < 0 ? 0 : level);
            return 1;
        }

        int PlayerIsVaild(LuaPlus::LuaState* s)
        {
            const bool valid = g_services.playerValid && g_services.playerValid(g_services.context);
            s->PushInteger(valid ? 1 : 0);
            return 1;
        }

        int GlobalGetCurClientSize(LuaPlus::LuaState* s)
        {
            int width = 0, height = 0;
            if (!g_services.clientSize || !g_services.clientSize(g_services.context, &width, &height))
            {
                width = 800;   // B's floor, so a frame never lays itself out on a 0x0 screen
                height = 600;
            }
            s->PushInteger(width);
            s->PushInteger(height);
            return 2;
        }

        int DataPoolGetServerDayTime(LuaPlus::LuaState* s)
        {
            s->PushInteger(DayStampFromTime(static_cast<long long>(std::time(nullptr))));
            return 1;
        }

        int DataPoolGetServerMinuteTime(LuaPlus::LuaState* s)
        {
            s->PushInteger(TimeStampFromTime(static_cast<long long>(std::time(nullptr))));
            return 1;
        }

        struct Entry { const char* receiver; const char* name; int (*fn)(LuaPlus::LuaState*); };
        const Entry kEntries[] = {
            {"Player", "GetLevel", PlayerGetLevel},
            {"Player", "IsVaild", PlayerIsVaild},
            {nullptr, "GetCurClientSize", GlobalGetCurClientSize},
            {"DataPool", "GetServerDayTime", DataPoolGetServerDayTime},
            {"DataPool", "GetServerMinuteTime", DataPoolGetServerMinuteTime},
        };

        bool LocalParts(long long when, std::tm& parts)
        {
            const std::time_t t = static_cast<std::time_t>(when);
#if defined(_MSC_VER)
            return localtime_s(&parts, &t) == 0;
#else
            const std::tm* p = std::localtime(&t);
            if (!p) return false;
            parts = *p;
            return true;
#endif
        }
    }

    int DayStampFromTime(long long when)
    {
        std::tm parts;
        if (!LocalParts(when, parts)) return 0;
        // B 0x140273de0: ((tm_year * 100 + 190001 + tm_mon) * 100) + tm_mday
        return ((parts.tm_year * 100 + 190001 + parts.tm_mon) * 100) + parts.tm_mday;
    }

    int TimeStampFromTime(long long when)
    {
        std::tm parts;
        if (!LocalParts(when, parts)) return 0;
        // B 0x140273f30: ((tm_hour * 100 + tm_min) * 100) + tm_sec
        return ((parts.tm_hour * 100 + parts.tm_min) * 100) + parts.tm_sec;
    }

    int Register(LuaPlus::LuaState* state, const Services& services)
    {
        g_services = services;
        if (!state) return 0;
        LuaPlus::LuaObject globals = state->GetGlobals();
        int registered = 0;
        for (const Entry& e : kEntries)
        {
            LuaPlus::LuaObject table = e.receiver ? Receiver(globals, e.receiver) : globals;
            if (!table.IsTable()) continue;   // receiver not created by the game layer: leave the stub in place
            table.Register(e.name, e.fn);     // forced: the generated stub may already own the slot
            ++registered;
        }
        return registered;
    }
}
