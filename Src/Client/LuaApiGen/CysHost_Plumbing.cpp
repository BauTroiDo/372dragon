






































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

        return ((parts.tm_year * 100 + 190001 + parts.tm_mon) * 100) + parts.tm_mday;
    }

    int TimeStampFromTime(long long when)
    {
        std::tm parts;
        if (!LocalParts(when, parts)) return 0;

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
