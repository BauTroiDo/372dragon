

























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
