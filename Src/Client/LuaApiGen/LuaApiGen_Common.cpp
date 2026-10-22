


#include "LuaApiGen.h"

#include <algorithm>
#include <locale>
#include <map>
#include <sstream>
#include <string>
#include <vector>
#include <windows.h>

namespace LuaApiGen
{
    namespace
    {
        const char* const kNullObject = "LuaApiGen_NullObject";
        const char* const kNullObjectMeta = "LuaApiGen_NullObjectMeta";
        // CYS: retain exact per-stub counts independently of the legacy 32-bit API.
        unsigned long long s_calls = 0;
        typedef std::map<std::string, unsigned long long> CallCounts;
        typedef std::pair<std::string, unsigned long long> CountEntry;

        CallCounts& Counts()
        {
            static CallCounts s_counts;
            return s_counts;
        }

        bool CountOrder(const CountEntry& a, const CountEntry& b)
        {
            return a.second != b.second ? a.second > b.second : a.first < b.first;
        }

        void DefaultSink(const char* line)
        {
            ::OutputDebugStringA(line);
            ::OutputDebugStringA("\n");
        }

        LogSink s_sink = DefaultSink;

        int NullCall(lua_State*) { return 0; }

        // __index of the null object: every key resolves to a function returning nothing
        int NullIndex(lua_State* L)
        {
            lua_pushcclosure(L, NullCall, 0);
            return 1;
        }

        void PushNullObject(LuaPlus::LuaState* state)
        {
            LuaPlus::LuaObject o = state->GetGlobals().GetByName(kNullObject);
            if (o.IsTable())
                o.PushStack();
            else
                state->PushNil();
        }
    }

    void SetLogSink(LogSink sink) { s_sink = sink ? sink : DefaultSink; }
    unsigned int GetMissingCallCount() { return (unsigned int)s_calls; }
    unsigned int GetMissingDistinctCount() { return (unsigned int)Counts().size(); }

    unsigned long long GetMissingCallCountFor(const char* receiver, const char* name)
    {
        if (!receiver || !name)
            return 0;
        const CallCounts& counts = Counts();
        CallCounts::const_iterator found = counts.find(std::string(receiver) + ":" + name);
        return found == counts.end() ? 0 : found->second;
    }

    void ResetMissingCallCounts()
    {
        Counts().clear();
        s_calls = 0;
    }

    void DumpMissingCallCounts(unsigned int limit)
    {
        const CallCounts& counts = Counts();
        std::vector<CountEntry> entries(counts.begin(), counts.end());
        const unsigned long long total = s_calls;
        std::sort(entries.begin(), entries.end(), CountOrder);
        // CYS-HOST2: limit 0 = every function (the shutdown dump), so a session ranks all of its stubs, not 20.
        const size_t shown = (limit == 0 || entries.size() < limit) ? entries.size() : limit;
        std::ostringstream line;
        line.imbue(std::locale::classic());
        line << "LuaApiGen missing calls begin total=" << total
             << " distinct=" << entries.size() << " shown=" << shown;
        s_sink(line.str().c_str());
        for (size_t i = 0; i < shown; ++i)
        {
            line.str("");
            line.clear();
            line << "LuaApiGen missing calls item count=" << entries[i].second
                 << " function=" << entries[i].first;
            s_sink(line.str().c_str());
        }
        s_sink("LuaApiGen missing calls end");
    }

    bool IsMissing(LuaPlus::LuaObject& table, const char* name)
    {
        LuaPlus::LuaObject o = table.GetByName(name);
        return o.IsNil();
    }

    int Stub(LuaPlus::LuaState* state, const char* receiver, const char* name, const char* rets)
    {
        ++s_calls;
        std::string key = std::string(receiver) + ":" + name;
        if (++Counts()[key] == 1)
        {
            std::string line = "missing host function " + key;
            s_sink(line.c_str());
        }
        int n = 0;
        for (const char* p = rets; *p; ++p, ++n)
        {
            switch (*p)
            {
            case 'n': state->PushNumber(0); break;
            case '1': state->PushNumber(1); break;    // CYS-CYGUI2: value decided from CY data
            case 'N': state->PushNumber(-1); break;   // CYS-CYGUI2: end-of-list marker
            case 's': state->PushString(""); break;
            case 'b': state->PushBoolean(false); break;
            case 'z': state->PushNil(); break;
            case 't': state->NewTable(); break;
            default: PushNullObject(state); break;
            }
        }
        return n;
    }

    void CreateNullObject(LuaPlus::LuaObject& objGlobal)
    {
        if (!objGlobal.GetByName(kNullObject).IsNil())
            return;
        LuaPlus::LuaObject meta = objGlobal.CreateTable(kNullObjectMeta);
        meta.Register("__index", NullIndex);
        LuaPlus::LuaObject obj = objGlobal.CreateTable(kNullObject);
        obj.SetMetaTable(meta);
    }
}
