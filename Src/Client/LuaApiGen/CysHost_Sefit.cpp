// CYS-SEFIT: see CysHost_Sefit.h for the measured failure chain behind each function here.
#include "CysHost_Sefit.h"
#include "LuaApiGen.h"

namespace CysHostSefit
{
    namespace
    {
        // SelfEquip.lua:65 declares `local LEVEL_MAX_ENABLE = 129` with the comment
        // "目前允许的最高级为129". Line 3039 then overwrites it from this host function on every open,
        // so answering with the script's own default keeps the frame behaving exactly as written.
        const int kMaxLevelLimit = 200; // Private server character cap (HUMAN_MAX_LEVEL is exclusive 201).

        void SetNumberField(lua_State* s, const char* key, lua_Number value)
        {
            lua_pushstring(s, key);
            lua_pushnumber(s, value);
            lua_rawset(s, -3);
        }

        void SetStringField(lua_State* s, const char* key, const char* value)
        {
            lua_pushstring(s, key);
            lua_pushstring(s, value);
            lua_rawset(s, -3);
        }

        // WGAch:GetCJMaxCur() -> table. One return value, always a table, never nil and never the null
        // object: the CY scripts both nil-guard it (SelfEquip, Pretty_Shop) and index it with no guard
        // (DressPurchase_JiaoGu, Pretty_Shop_MBuy), so only a real record satisfies every call site.
        //
        // Zero-filled = "no achievement tier earned". cur_level 0 makes the CY guards
        // `cur.cur_level >= 1` and `curData.cur_level >= g_ZNQ_ShopUIInd` fall through to the
        // locked/default branch, which is the correct presentation for this server.
        int WGAchGetCJMaxCur(LuaPlus::LuaState* state)
        {
            lua_State* s = state->GetCState();
            lua_newtable(s);
            SetNumberField(s, "cur_level", 0);
            SetNumberField(s, "cur_value", 0);
            SetNumberField(s, "max_level", 0);
            SetNumberField(s, "max_value", 0);
            SetNumberField(s, "param0", 0);
            SetNumberField(s, "param1", 0);
            SetStringField(s, "name", "");
            return 1;
        }

        // _G:Lua_GetMyMaxLevelLimit() -> number. Used numerically by both callers; the null object the
        // generated stub returned made `LEVEL_MAX_ENABLE <= nCompatPKLevel` throw.
        int LuaGetMyMaxLevelLimit(LuaPlus::LuaState* state)
        {
            state->PushNumber(kMaxLevelLimit);
            return 1;
        }

        // _G:LuaFnGetCurZongmenTitleInfo() -> fixRate, expAdd, curState (THREE numbers).
        // The generated stub answers "o" = ONE null object, so `local fixRate, expAdd, curState = ...`
        // bound a table plus two nils and SelfEquip.lua:1723 then handed a nil to ScriptGlobal_Format
        // ("argument 3 must be a string or number") - measured live 19/09 23:35, live-2/WXClient.log,
        // the third and last throw of this function. Shape recovered from all five call sites:
        //   SelfEquip.lua:695/714/1721, MainMenuBar.lua:2136 (3 values), ZongMen_SectTitle.lua:88 (2).
        // They use the values as format arguments and compare curState against 1, so all three are
        // numbers. Zeros = "no sect title earned", the honest state on this server.
        int LuaFnGetCurZongmenTitleInfo(LuaPlus::LuaState* state)
        {
            state->PushNumber(0);   // fixRate
            state->PushNumber(0);   // expAdd
            state->PushNumber(0);   // curState (1 would mean "title active")
            return 3;
        }

        // Install `name` on `table`, replacing whatever the generated pass may have put there.
        void Install(LuaPlus::LuaObject& table, const char* name, int (*fn)(LuaPlus::LuaState*))
        {
            table.Register(name, fn);
        }

        // Resolve (creating if absent) the receiver that carries `name`, then install on it.
        // NOTE: never hold a default-constructed LuaPlus::LuaObject - it carries a null m_state and
        // every accessor on it throws. Resolve into a valid object on each branch instead, the way
        // LuaApiGen_Cy.cpp::ResolveReceiver does. (The first version of this file got that wrong; the
        // offline test caught it, a clean compile did not.)
        int RegisterOn(LuaPlus::LuaObject& globals, const char* receiver, const char* name,
                       int (*fn)(LuaPlus::LuaState*))
        {
            LuaPlus::LuaObject existing = globals.GetByName(receiver);
            if (existing.IsTable())
            {
                Install(existing, name, fn);
                return 1;
            }
            if (existing.IsUserData())
            {
                LuaPlus::LuaObject meta = existing.GetMetaTable();
                if (!meta.IsTable()) return 0;
                LuaPlus::LuaObject index = meta.GetByName("__index");
                if (index.IsTable()) Install(index, name, fn);
                else Install(meta, name, fn);
                return 1;
            }
            if (existing.IsNil())
            {
                LuaPlus::LuaObject created = globals.CreateTable(receiver);
                if (!created.IsTable()) return 0;
                Install(created, name, fn);
                return 1;
            }
            return 0;   // the name is taken by something that cannot carry methods
        }
    }

    int MaxLevelLimit() { return kMaxLevelLimit; }

    int Register(LuaPlus::LuaState* state)
    {
        if (!state) return 0;
        LuaPlus::LuaObject globals = state->GetGlobals();
        int registered = 0;
        registered += RegisterOn(globals, "WGAch", "GetCJMaxCur", WGAchGetCJMaxCur);
        // A "_G" function is a plain global, not a method on a receiver table.
        globals.Register("Lua_GetMyMaxLevelLimit", LuaGetMyMaxLevelLimit);
        ++registered;
        globals.Register("LuaFnGetCurZongmenTitleInfo", LuaFnGetCurZongmenTitleInfo);
        ++registered;
        return registered;
    }
}
