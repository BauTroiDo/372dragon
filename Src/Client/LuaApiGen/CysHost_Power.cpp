// CY cultivation: all 15 scrolls and three books; server is authoritative.
#include "CysHost_Power.h"
#include "LuaApiGen.h"
#include <cstring>
#include <string>

namespace CysHostPower
{
    namespace
    {
        Services g_services;

        const int CYS_MIJI_MAX = 14;   // B: index > 10 is refused (11 scrolls on the wire)
        const int CYS_BOOK_MAX = 2;    // B: index > 1 is refused (B knows 2 books, CY ships 3)

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

        int Level(int miji) { const int v = g_services.xiulianLevel ? g_services.xiulianLevel(miji) : -1; return v < 0 ? 0 : v; }
        int Upper(int miji) { const int v = g_services.xiulianUpperLimit ? g_services.xiulianUpperLimit(miji) : -1; return v < 0 ? 0 : v; }

        // 境界 of one scroll. human.lua gives every scroll upper_limit = 10 to begin with and
        // odali_wuyazi.lua AskXiuLianAdvanceJingJie raises it by exactly 10 per realm, so realm = limit / 10.
        int JingJie(int miji) { const int u=Upper(miji); return u<=60?u/10:6+(u-60)/15; }

        // Both accessors take (index:number, field:string); B returns nothing when either is missing.
        bool Args(LuaPlus::LuaState* s, int* index, std::string* field)
        {
            LuaPlus::LuaStack args(s);
            if (!args[2].IsNumber() || !args[3].IsString()) return false;
            *index = static_cast<int>(args[2].GetNumber());
            *field = args[3].GetString();
            return true;
        }

        // Player:GetXiuLianMiJiInfo(miji, "Name"|"Level"|"JingJie"|"Explain"|"MaxLevel"|"UpLevelNeedMoney"|"UpLevelNeedExp")
        int PlayerGetXiuLianMiJiInfo(LuaPlus::LuaState* s)
        {
            int miji = 0; std::string what;
            if (!Args(s, &miji, &what)) return 0;
            if (miji < 0 || miji > CYS_MIJI_MAX) return 0;      // B: unsigned compare against 10
            if (what == "Name" || what == "Explain")
            {
                const char* text = g_services.mijiText ? g_services.mijiText(miji, what == "Name" ? 0 : 1) : nullptr;
                s->PushString(text ? text : "");
                return 1;
            }
            if (what == "Level") { s->PushInteger(Level(miji)); return 1; }
            if (what == "MaxLevel") { s->PushInteger(Upper(miji)); return 1; }
            if (what == "JingJie") { s->PushInteger(JingJie(miji)); return 1; }
            if (what == "UpLevelNeedExp" || what == "UpLevelNeedMoney")
            {
                const int need = g_services.upLevelNeed ? g_services.upLevelNeed(miji, Level(miji), what == "UpLevelNeedExp" ? 0 : 1) : 0;
                s->PushInteger(need);
                return 1;
            }
            return 0;   // unknown field -> nil (B leaves the stack untouched here too)
        }

        // Player:GetXiuLianBookInfo(book, "Name"|"Explain"|"Level"). B answers "Level" with the highest 境界 of the
        // scrolls of that book: scrolls 0..4 belong to book 0 and 5..10 to book 1 (XiuLianMiJi.txt column 1).
        int PlayerGetXiuLianBookInfo(LuaPlus::LuaState* s)
        {
            int book = 0; std::string what;
            if (!Args(s, &book, &what)) return 0;
            if (book < 0 || book > CYS_BOOK_MAX) return 0;     // B: unsigned compare against 1 (no book 2)
            if (what == "Name" || what == "Explain")
            {
                const char* text = g_services.bookText ? g_services.bookText(book, what == "Name" ? 0 : 1) : nullptr;
                s->PushString(text ? text : "");
                return 1;
            }
            if (what == "HasActived") { s->PushInteger(g_services.bookActive && g_services.bookActive(book)?1:0); return 1; }
            if (what == "Level")
            {
                const int from = book == 0 ? 0 : book == 1 ? 5 : 11;
                const int to = book == 0 ? 4 : book == 1 ? 10 : CYS_MIJI_MAX;
                int best = 0;
                for (int i = from; i <= to; ++i) { const int j = JingJie(i); if (j > best) best = j; }
                s->PushInteger(best);
                return 1;
            }
            return 0;
        }

        // XiuLianPage(): B (RVA 0x21b780) pushes event 0x286 after a guard; the CY window itself names that event
        // Xiulian.lua:64 RegisterEvent("OPEN_XIULIAN_PAGE"). 23 CY windows call it, and without it the two
        // accessors above are unreachable with the mouse. Returns 1/0 the way Infant.lua:1090 expects (`local bRet`).
        int GlobalXiuLianPage(LuaPlus::LuaState* s)
        {
            const bool ok = g_services.openXiulianPage ? g_services.openXiulianPage() : false;
            s->PushInteger(ok ? 1 : 0);
            return 1;
        }

        struct Entry { const char* receiver; const char* name; int (*fn)(LuaPlus::LuaState*); bool force; };
        const Entry kEntries[] = {
            // force: LuaApiGen_Player.cpp / LuaApiGen_Globals.cpp already registered the generated stubs.
            {"Player", "GetXiuLianMiJiInfo", PlayerGetXiuLianMiJiInfo, true},
            {"Player", "GetXiuLianBookInfo", PlayerGetXiuLianBookInfo, true},
            {nullptr, "XiuLianPage", GlobalXiuLianPage, true},
        };
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
            if (!table.IsTable()) continue;
            if (!e.force && !LuaApiGen::IsMissing(table, e.name)) continue;
            table.Register(e.name, e.fn);
            ++registered;
        }
        return registered;
    }
}
