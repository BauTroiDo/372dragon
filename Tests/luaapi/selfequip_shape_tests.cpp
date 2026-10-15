// CYS-SEFIT: offline proof that the host functions the character frame depends on answer with the
// right SHAPE. No sockets, no Game process, no server.
//
// WHY THIS FILE WAS REWRITTEN - the lesson is the point of the file.
//
// Its first version passed 6/6 while the frame was still broken in game. It asserted that the patched
// host "does not throw" for ONE expression, so it could only ever see the one function it already knew
// about. It never asked "is every value this frame reads the right TYPE?", and it never ran the other
// expressions of the real script. That is section 17 form 2 of the project log: a measurement running
// perfectly on an incomplete definition - no symptom, green forever.
//
// Three rules came out of it, and this file is built on them:
//   1. Every host function used by the frame gets a NEGATIVE CONTROL of its own: with only the
//      generated stubs installed, the real CY expression that consumes it MUST throw. A test that
//      cannot fail proves nothing.
//   2. Assert the TYPE the caller needs, not merely the absence of an error. `type(x) == 'number'`
//      would have caught victim 2 the moment it was written; "it did not throw" did not.
//   3. Assert the COUNT of return values too. Victim 3 was a function returning one value where the
//      script binds three; type checks alone would have missed it.
#include "CysHost_Sefit.h"
#include "LuaApiGen.h"
#include "LuaApiGen_Cy.h"
#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <string>

namespace {

unsigned passed = 0, failed = 0;

void Require(bool yes, const char* why) { if (!yes) throw std::runtime_error(why); }

template <class F> void Test(const char* name, F run)
{
    try { run(); ++passed; std::printf("PASS %s\n", name); }
    catch (const LuaPlus::LuaException& e) { ++failed; std::printf("FAIL %s: %s\n", name, e.GetMessage()); }
    catch (const std::exception& e) { ++failed; std::printf("FAIL %s: %s\n", name, e.what()); }
}

struct State
{
    LuaPlus::LuaState* p = LuaPlus::LuaState::Create(true);
    State() { Require(p != nullptr, "Lua state"); LuaApiGen::ResetMissingCallCounts(); }
    ~State() { LuaPlus::LuaState::Destroy(p); }

    // Runs a chunk. Returns "" on success, else the Lua error message (never throws on a Lua error,
    // so a test can assert that a chunk DOES fail).
    std::string Try(const char* code)
    {
        lua_State* raw = p->GetCState();
        const int top = lua_gettop(raw);
        int rc = luaL_loadbuffer(raw, code, std::strlen(code), "sefit-test");
        if (!rc) rc = lua_pcall(raw, 0, 0, 0);
        std::string message;
        if (rc)
        {
            const char* text = lua_tostring(raw, -1);
            message = text ? text : "unknown Lua error";
            if (message.empty()) message = "empty Lua error";
        }
        lua_settop(raw, top);
        return message;
    }

    void Run(const char* code)
    {
        const std::string message = Try(code);
        if (!message.empty()) throw std::runtime_error(message);
    }
};

// ---- the real expressions, copied in shape from the CY script ----------------------------------

// SelfEquip.lua:1464-1465. Binds ONE value and indexes it => the result must be a TABLE.
const char* kGuardCJMaxCur =
    "local cur = WGAch:GetCJMaxCur()\n"
    "hit = 0\n"
    "if cur ~= nil and cur.cur_level >= 1 then hit = 1 end\n";

// SelfEquip.lua:3039 (open handler) then 1480 (update). The variable is overwritten by the host call
// and THEN compared, left-hand side, with no short-circuit in front of it => must be a NUMBER.
const char* kGuardMaxLevelLimit =
    "LEVEL_MAX_ENABLE = Lua_GetMyMaxLevelLimit()\n"
    "local nCompatPKLevel = -1\n"
    "disabled = 0\n"
    "if( LEVEL_MAX_ENABLE <= nCompatPKLevel ) then disabled = 1 end\n";

// Quest.lua:3617 - the second caller of that function, also numeric.
const char* kQuestMaxLevel =
    "local nMaxLevel = Lua_GetMyMaxLevelLimit()\n"
    "assert(type(nMaxLevel) == 'number', 'Quest.lua needs a number, got '..type(nMaxLevel))\n";

// SelfEquip.lua:1721 + 1723. Binds THREE values, then feeds the 2nd and 3rd to a format call.
const char* kGuardZongmenTitle =
    "local fixRate, expAdd, curState = LuaFnGetCurZongmenTitleInfo()\n"
    "sum = expAdd + fixRate\n"
    "active = 0\n"
    "if curState == 1 then active = 1 end\n";

void ExpectThrows(State& s, const char* code, const char* needle, const char* what)
{
    const std::string message = s.Try(code);
    Require(!message.empty(), what);
    Require(message.find(needle) != std::string::npos, "threw, but not the documented error");
    std::printf("     (baseline reproduced: %s)\n", message.c_str());
}

} // namespace

int main()
{
    // ---- NEGATIVE CONTROLS - one per host function ------------------------------------------
    Test("baseline_stub_breaks_GetCJMaxCur_guard", [] {
        State s;
        LuaApiGen::RegisterCyExtras(s.p);
        s.Run("cur = WGAch:GetCJMaxCur()");
        s.Run("assert(cur ~= nil, 'null object must slip through the nil guard')");
        s.Run("assert(type(cur.cur_level) == 'function', 'null object must hand back a function')");
        ExpectThrows(s, kGuardCJMaxCur, "compare",
                     "baseline did NOT throw - negative control is blind");
    });

    Test("baseline_stub_breaks_MaxLevelLimit_comparison", [] {
        State s;
        LuaApiGen::RegisterCyExtras(s.p);
        s.Run("local v = Lua_GetMyMaxLevelLimit()\n"
              "assert(type(v) == 'table', 'the generated stub must hand back the null object')\n");
        // The exact failure seen live at SelfEquip.lua:1480 on 19/09 22:44 and 22:47.
        ExpectThrows(s, kGuardMaxLevelLimit, "compare",
                     "baseline did NOT throw - this is the bug that shipped past the old tests");
    });

    Test("baseline_stub_breaks_ZongmenTitleInfo_multireturn", [] {
        State s;
        LuaApiGen::RegisterCyExtras(s.p);
        // The stub answers ONE null object where the script binds THREE values, so the 2nd and 3rd
        // silently become nil. That is the failure seen live at SelfEquip.lua:1723 on 19/09 23:35.
        s.Run("function count(...) return arg.n end\n"
              "assert(count(LuaFnGetCurZongmenTitleInfo()) == 1, 'stub must return exactly one value')\n");
        ExpectThrows(s, kGuardZongmenTitle, "arith",
                     "baseline did NOT throw - negative control is blind");
    });

    // ---- THE FIX -----------------------------------------------------------------------------
    Test("patched_hosts_let_every_real_guard_run", [] {
        State s;
        Require(CysHostSefit::Register(s.p) == 3, "three host functions must be registered");
        LuaApiGen::RegisterCyExtras(s.p);   // must NOT override the real ones (IsMissing)
        std::string message = s.Try(kGuardCJMaxCur);
        Require(message.empty(), message.empty() ? "" : message.c_str());
        s.Run("assert(hit == 0, 'cur_level 0 means no tier earned, so the branch stays closed')");
        message = s.Try(kGuardMaxLevelLimit);
        Require(message.empty(), message.empty() ? "" : message.c_str());
        s.Run("assert(disabled == 0, '129 <= -1 is false, so the level-up button stays enabled')");
        s.Run(kQuestMaxLevel);
        message = s.Try(kGuardZongmenTitle);
        Require(message.empty(), message.empty() ? "" : message.c_str());
        s.Run("assert(sum == 0 and active == 0, 'no sect title earned')");
    });

    // Rule 2: assert the TYPE each caller needs, not just the absence of a throw.
    Test("every_hosted_value_has_the_type_its_callers_need", [] {
        State s;
        CysHostSefit::Register(s.p);
        s.Run("local c = WGAch:GetCJMaxCur()\n"
              "assert(type(c) == 'table', 'GetCJMaxCur must be a table')\n"
              "for _, k in ipairs({'cur_level','cur_value','max_level','max_value','param0','param1'}) do\n"
              "  assert(type(c[k]) == 'number', 'field '..k..' must be a number, got '..type(c[k]))\n"
              "  assert(c[k] == 0, 'field '..k..' must be zero')\n"
              "end\n"
              "assert(type(c.name) == 'string' and c.name == '', 'name must be an empty string')\n");
        char code[256];
        std::sprintf(code,
                     "local v = Lua_GetMyMaxLevelLimit()\n"
                     "assert(type(v) == 'number', 'Lua_GetMyMaxLevelLimit must be a number, got '..type(v))\n"
                     "assert(v == %d, 'must match the script default')\n",
                     CysHostSefit::MaxLevelLimit());
        s.Run(code);
        s.Run("local a, b, c = LuaFnGetCurZongmenTitleInfo()\n"
              "local got = {a, b, c}\n"
              "for i = 1, 3 do\n"
              "  assert(type(got[i]) == 'number', 'value '..i..' must be a number, got '..type(got[i]))\n"
              "end\n");
    });

    // Rule 3: the COUNT of return values is part of the signature.
    Test("each_host_returns_the_number_of_values_its_callers_bind", [] {
        State s;
        CysHostSefit::Register(s.p);
        s.Run("function count(...) return arg.n end\n"
              "assert(count(WGAch:GetCJMaxCur()) == 1, 'GetCJMaxCur must return exactly one value')\n"
              "assert(count(Lua_GetMyMaxLevelLimit()) == 1, 'Lua_GetMyMaxLevelLimit must return one value')\n"
              "assert(count(LuaFnGetCurZongmenTitleInfo()) == 3, 'ZongmenTitleInfo must return THREE')\n");
    });

    // The four call sites that index the record WITHOUT a nil check. These are why that fix returns a
    // table rather than nil: nil would fix SelfEquip and break these.
    Test("unconditional_call_sites_of_the_cy_scripts_all_survive", [] {
        State s;
        CysHostSefit::Register(s.p);
        // Pretty_Achievement.lua:192 / Pretty_Shop.lua:361
        s.Run("local cur = WGAch:GetCJMaxCur(); assert(type(cur) == 'table')\n"
              "assert(cur.cur_level == cur.max_level)\n");
        // DressPurchase_JiaoGu.lua:75
        s.Run("local curData = WGAch:GetCJMaxCur()\n"
              "local open = (curData.param0 == 1 or curData.cur_level >= 3)\n"
              "assert(open == false)\n");
        // Pretty_Shop_MBuy.lua:44 - arithmetic on the field.
        s.Run("local curData = WGAch:GetCJMaxCur()\n"
              "assert(math.floor(curData.param1 / 10000) == 0)\n");
        // Pretty_Shop.lua:172 - the `if not cur then return` guard must NOT fire.
        s.Run("local cur = WGAch:GetCJMaxCur(); assert(cur)\n");
        // ZongMen_SectTitle.lua:88 binds only the first two of the three.
        s.Run("local fixRate, expAdd = LuaFnGetCurZongmenTitleInfo()\n"
              "assert(type(fixRate) == 'number' and type(expAdd) == 'number')\n");
    });

    Test("registration_is_idempotent_and_survives_the_generated_pass", [] {
        State s;
        Require(CysHostSefit::Register(s.p) == 3, "first registration");
        Require(CysHostSefit::Register(s.p) == 3, "second registration must stay safe");
        LuaApiGen::RegisterCyExtras(s.p);
        s.Run("local c = WGAch:GetCJMaxCur(); assert(type(c) == 'table' and c.cur_level == 0)\n"
              "assert(type(Lua_GetMyMaxLevelLimit()) == 'number')\n");
        Require(LuaApiGen::GetMissingCallCountFor("WGAch", "GetCJMaxCur") == 0,
                "the generated GetCJMaxCur stub must never be reached");
        Require(LuaApiGen::GetMissingCallCountFor("_G", "Lua_GetMyMaxLevelLimit") == 0,
                "the generated Lua_GetMyMaxLevelLimit stub must never be reached");
        Require(LuaApiGen::GetMissingCallCountFor("_G", "LuaFnGetCurZongmenTitleInfo") == 0,
                "the generated LuaFnGetCurZongmenTitleInfo stub must never be reached");
    });

    Test("register_rejects_a_null_state_without_crashing", [] {
        Require(CysHostSefit::Register(nullptr) == 0, "null state must report zero, not crash");
    });

    std::printf("RESULT passed=%u failed=%u total=%u\n", passed, failed, passed + failed);
    return failed ? 1 : 0;
}
