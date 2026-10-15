// CYS-RIDE: Lua glue of the CY mount window. See CysHost_Ride.h.
//
// Where every behaviour below comes from (no guessing; the uncertain one is marked):
//   * `OpenRidePage()` - B (client_GL\Bin64\Game.exe) RVA 0x21b860 pushes one event after a guard; the event NAME
//     comes from the CY window itself: Ride.lua:20 `this:RegisterEvent("OPEN_RIDE_PAGE", true)`. The 0.85 event
//     system is keyed by name, so GE_OPEN_RIDE_PAGE + one row in g_GlobalEvent is all that is needed - and it IS
//     needed: CEventSystem::RegisterEventHandle (GMEventSystem.cpp:716) does `map[name]` then `if(!pEvent) return;`
//     so an unknown name silently inserts NULL and DROPS the window's handler.
//     Eight CY windows call it (SelfEquip, Pet, JingMai, Infant, OtherInfo, HuanLing, Martial_WuYi, CangPin_ShuXing);
//     Infant.lua:1131 reads `local bRet = OpenRidePage()`, so it answers 1/0.
//   * `GetMountID()` - B has it as a global (_G, RVA 0x222af0, returns a number); Ride.lua calls it as
//     `Player:GetMountID()` (lines 433 and 467) and compares the result with -1 and with an action item id.
//     Registered under BOTH spellings because the two sources disagree only about the receiver table.
//   * `Player:UseSkillInLua_Const()` - CY-only (no entry in Registry/luaapi/catalog.json, so nothing to decompile).
//     Contract read from the caller: Ride.lua:425 `CallInOutRide(1)` = mount, `CallInOutRide(0)` = dismount, both
//     call it with NO arguments and the mount branch tests `if nSucc == 1`. It is mapped to CGCharAutoRide, the one
//     packet the server has for this (scenecore.lua:6172 char_auto_ride -> skill 21).
//     [SL] The DISMOUNT half is NOT proven: char_auto_ride answers an already-mounted character immediately without
//     taking the mount away, so pressing "xuong ngua" will very likely do nothing visible. Left as is on purpose -
//     inventing a second packet would be a guess. See the spec.
//   * `Lua_CysSelectRide(index)` - NOT a CY script name, and marked `Lua_Cys*` so nobody mistakes it for one.
//     It is the selection hook `ride-core` needs: CGExteriorRequest (1027) type 7 with list[0].unknow_1 == 3 is
//     what scenecore.lua:3761 turns into human:set_ride(index), and set_ride is the precondition that makes
//     char_auto_ride case 3 stop returning silently. In the CY UI the mount is chosen by EQUIPPING it
//     (Ride.lua:379 `g_Ride[i]:DoAction()`, HEQUIP_RIDER = 8); the appearance path belongs to the NewExterior_*
//     state machine, which is a different subsystem and is not bound here.
#include "CysHost_Ride.h"
#include "LuaApiGen.h"
#include "Network/CysRideNet.h"
#include "Network/CysModernGame.h"
#include "Event/GMEventSystem.h"
#include "Script/GMScriptSystem.h"
#include "PgPackets_misc.h"
#include "TDUtil.h"
#include <memory>

namespace CysHostRide
{
    namespace
    {
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

        int GlobalOpenRidePage(LuaPlus::LuaState* s)
        {
            CEventSystem* events = CEventSystem::GetMe();
            if (events) events->PushEvent(GE_OPEN_RIDE_PAGE);
            s->PushInteger(events ? 1 : 0);
            return 1;
        }

        // -1 when the character is not on a mount, which is exactly what Ride.lua:468 tests.
        int GetMountID(LuaPlus::LuaState* s) { s->PushInteger(CysRideNet::MountID()); return 1; }

        // Mount up. Returns 1 only when the packet really went out (Ride.lua:443 `if nSucc == 1`).
        int PlayerUseSkillInLuaConst(LuaPlus::LuaState* s)
        {
            s->PushInteger(CysRideNet::RequestAutoRide(1) ? 1 : 0);
            return 1;
        }

        bool SendSelectRide(int index)
        {
            std::unique_ptr<pg::CGExteriorRequest> request(new pg::CGExteriorRequest);
            request->type = 7;
            request->size = 1;
            pg::CGExteriorRequest::E_list entry;
            entry.unknow_1 = 3;                                   // 0 face, 1 hair, 2 portrait, 3 RIDE, 4 pet soul
            entry.unknow_2 = static_cast<uint16_t>(index);
            request->list.push_back(entry);
            return CysModernGame::SendModern(std::unique_ptr<pg::Packet>(request.release()));
        }

        // Lua_CysSelectRide(index): CGExteriorRequest type 7, category 3 (RIDE) -> server human:set_ride(index).
        int GlobalCysSelectRide(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            if (!args[1].IsNumber()) { s->PushInteger(0); return 1; }
            s->PushInteger(SendSelectRide(static_cast<int>(args[1].GetNumber())) ? 1 : 0);
            return 1;
        }

        struct Entry { const char* receiver; const char* name; int (*fn)(LuaPlus::LuaState*); };
        // All forced: LuaApiGen_Globals.cpp / _Player.cpp already registered the generated stubs of these names.
        const Entry kEntries[] = {
            {nullptr,  "OpenRidePage",        GlobalOpenRidePage},
            {nullptr,  "GetMountID",          GetMountID},           // B spelling (_G)
            {"Player", "GetMountID",          GetMountID},           // Ride.lua spelling
            {"Player", "UseSkillInLua_Const", PlayerUseSkillInLuaConst},
            {nullptr,  "Lua_CysSelectRide",   GlobalCysSelectRide},  // CYS-only helper, not a CY name
        };
    }

    int Register(LuaPlus::LuaState* state)
    {
        if (!state) return 0;
        LuaPlus::LuaObject globals = state->GetGlobals();
        int registered = 0;
        for (const Entry& e : kEntries)
        {
            LuaPlus::LuaObject table = e.receiver ? Receiver(globals, e.receiver) : globals;
            if (!table.IsTable()) continue;
            table.Register(e.name, e.fn);
            ++registered;
        }
        return registered;
    }

    bool ProbeSelectRide(int index) { return SendSelectRide(index); }

    void RegisterHost()
    {
        CScriptSystem* scripts = CScriptSystem::GetMe();
        if (!scripts || !scripts->GetLuaState()) return;
        const int n = Register(scripts->GetLuaState());
        TDU_Log("CYS ride: host functions registered=%d", n);
    }
}
