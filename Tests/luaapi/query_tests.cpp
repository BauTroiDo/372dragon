// CYS: LuaPlus query-wrapper tests with a simulated bag; never starts Game.
#include "CysHostQueries.h"
#include "LuaApiGen.h"

#include <array>
#include <cstdint>
#include <cstdio>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

namespace
{
    unsigned passed = 0;
    unsigned failed = 0;
    std::vector<std::string> missingLines;
    void Require(bool value, const char* message)
    { if (!value) throw std::runtime_error(message); }
    void Capture(const char* message) { missingLines.emplace_back(message); }
    template<class F> void Test(const char* name, F run)
    {
        try { run(); ++passed; std::printf("PASS %s\n", name); }
        catch (const LuaPlus::LuaException& error)
        { ++failed; std::printf("FAIL %s: %s\n", name, error.GetMessage()); }
        catch (const std::exception& error)
        { ++failed; std::printf("FAIL %s: %s\n", name, error.what()); }
    }
    struct State
    {
        LuaPlus::LuaState* p = LuaPlus::LuaState::Create(true);
        State()
        {
            Require(p != nullptr, "LuaState creation failed");
            LuaApiGen::SetLogSink(Capture);
            LuaApiGen::ResetMissingCallCounts();
            missingLines.clear();
        }
        ~State() { LuaPlus::LuaState::Destroy(p); }
        State(const State&) = delete;
        State& operator=(const State&) = delete;
        void Run(const char* code)
        {
            lua_State* raw = p->GetCState();
            const int top = lua_gettop(raw);
            const int rc = p->DoString(code);
            if (rc != 0)
            {
                const char* message = lua_tostring(raw, -1);
                const std::string copy = message ? message : "Lua error";
                lua_settop(raw, top);
                throw std::runtime_error(copy);
            }
            Require(lua_gettop(raw) == top, "Lua snippet leaked stack entries");
        }
        void Number(const char* name, double value)
        {
            lua_pushnumber(p->GetCState(), value);
            lua_setglobal(p->GetCState(), name);
        }
    };
    struct SimulatedBag
    {
        std::array<std::int32_t, 60> ids;
        std::vector<std::int32_t> calls;
        int throwKind = 0;
        int activeObjects = 0;
        bool echo = false;
        SimulatedBag() { ids.fill(-1); ids[0] = 10100001; ids[59] = 20100002; }
        static std::int32_t Lookup(void* context, std::int32_t index)
        {
            auto& bag = *static_cast<SimulatedBag*>(context);
            bag.calls.push_back(index);
            struct Scope
            {
                int& count;
                explicit Scope(int& value) : count(value) { ++count; }
                ~Scope() { --count; }
            } scope(bag.activeObjects);
            if (bag.throwKind == 1) throw std::runtime_error("PRIVATE_QUERY_ARGUMENT");
            if (bag.throwKind == 2) throw LuaPlus::LuaException("PRIVATE_QUERY_ARGUMENT");
            if (bag.echo) return index;
            return index >= 0 && index < static_cast<std::int32_t>(bag.ids.size()) ? bag.ids[index] : -1;
        }
        CysHostQueries::Services Services()
        { CysHostQueries::Services value; value.context = this; value.bagItemTableIndex = Lookup; return value; }
    };
    void PublishReceiver(State& state, void* pointer)
    {
        auto globals = state.p->GetGlobals();
        auto meta = globals.CreateTable("FixturePackageMeta");
        meta.SetObject("__index", meta);
        LuaPlus::LuaObject receiver = state.p->BoxPointer(pointer);
        receiver.SetMetaTable(meta);
        globals.SetObject("PlayerPackage", receiver);
        state.Run("savedReceiver=PlayerPackage; savedMeta=getmetatable(PlayerPackage); "
                  "savedMeta.Existing=function() return 917 end");
    }
    struct Fixture
    {
        State state;
        SimulatedBag bag;
        explicit Fixture(bool install = true)
        {
            PublishReceiver(state, &bag);
            if (install) Register(bag.Services());
        }
        unsigned Register(const CysHostQueries::Services& services)
        {
            auto globals = state.p->GetGlobals();
            const int top = lua_gettop(state.p->GetCState());
            const unsigned added = CysHostQueries::Register(globals, services);
            Require(lua_gettop(state.p->GetCState()) == top, "registration leaked stack entries");
            return added;
        }
        void Run(const char* code) { state.Run(code); }
    };
    void ExpectIntegrationError(State& state)
    {
        auto globals = state.p->GetGlobals();
        const int top = lua_gettop(state.p->GetCState());
        bool rejected = false;
        try { CysHostQueries::Register(globals, CysHostQueries::Services{}); }
        catch (const std::runtime_error& error)
        {
            rejected = std::string(error.what()) ==
                "CysHostQueries requires the PlayerPackage receiver and metatable";
        }
        Require(rejected && lua_gettop(state.p->GetCState()) == top, "integration error or stack mismatch");
    }
}

int main()
{
    Test("same_snippet_generated_baseline_two_calls_to_real_query", [] {
        const char* snippet = "occupied=PlayerPackage:GetItemTableIndex(0); empty=PlayerPackage:GetItemTableIndex(1)";
        {
            Fixture before(false);
            auto meta = before.state.p->GetGlobals().GetByName("FixturePackageMeta");
            LuaApiGen::Register_PlayerPackage(meta);
            before.Run(snippet);
            before.Run("assert(occupied==0 and empty==0)");
            Require(LuaApiGen::GetMissingCallCount() == 2 && LuaApiGen::GetMissingDistinctCount() == 1 &&
                    LuaApiGen::GetMissingCallCountFor("PlayerPackage", "GetItemTableIndex") == 2 &&
                    missingLines.size() == 1, "baseline did not reach generated query stub");
        }
        Fixture after;
        auto meta = after.state.p->GetGlobals().GetByName("FixturePackageMeta");
        LuaApiGen::Register_PlayerPackage(meta);
        after.Run(snippet);
        after.Run("assert(occupied==10100001 and empty==-1)");
        Require(LuaApiGen::GetMissingCallCount() == 0 && LuaApiGen::GetMissingDistinctCount() == 0 &&
                missingLines.empty(), "real query reached stub");
        std::printf("BEFORE_AFTER missing_calls=2->0 distinct=1->0 log_lines=1->0 occupied=10100001 empty=-1\n");
    });
    Test("real_receiver_and_metatable_identity_existing_method", [] {
        Fixture f;
        f.Run("assert(PlayerPackage==savedReceiver and getmetatable(PlayerPackage)==savedMeta); "
              "assert(PlayerPackage:Existing()==917 and savedMeta.__index==savedMeta)");
    });
    Test("occupied_first_and_last_supported_slot", [] {
        Fixture f; f.Run("assert(PlayerPackage:GetItemTableIndex(0)==10100001); "
                         "assert(PlayerPackage:GetItemTableIndex(59)==20100002)");
    });
    Test("empty_slot_and_negative_index_return_minus_one", [] {
        Fixture f; f.Run("assert(PlayerPackage:GetItemTableIndex(1)==-1 and PlayerPackage:GetItemTableIndex(-1)==-1)");
    });
    Test("cy60_b240_limit_is_backend_policy_not_adapter_clamp", [] {
        Fixture f; f.Run("assert(PlayerPackage:GetItemTableIndex(60)==-1 and PlayerPackage:GetItemTableIndex(239)==-1); "
                         "assert(PlayerPackage:GetItemTableIndex(240)==-1)");
        Require(f.bag.calls == std::vector<std::int32_t>{60,239,240}, "wrapper clamped bag range");
    });
    Test("fractional_index_truncates_toward_zero", [] {
        Fixture f; f.Run("assert(PlayerPackage:GetItemTableIndex(0.9)==10100001); "
                         "assert(PlayerPackage:GetItemTableIndex(-0.9)==10100001); "
                         "assert(PlayerPackage:GetItemTableIndex(59.9)==20100002); "
                         "assert(PlayerPackage:GetItemTableIndex(-1.9)==-1)");
        Require(f.bag.calls == std::vector<std::int32_t>{0,0,59,-1}, "wrong truncation");
    });
    Test("numeric_string_rejected_number_accepted", [] {
        Fixture f; f.Run("assert(not pcall(function() PlayerPackage:GetItemTableIndex('0') end)); "
                         "assert(PlayerPackage:GetItemTableIndex(0)==10100001)");
        Require(f.bag.calls.size() == 1, "invalid string reached callback");
    });
    Test("missing_nil_boolean_table_function_userdata_rejected", [] {
        Fixture f;
        f.Run("assert(not pcall(function() PlayerPackage:GetItemTableIndex() end)); "
              "assert(not pcall(function() PlayerPackage:GetItemTableIndex(nil) end)); "
              "local bad={true,false,{},function() end,PlayerPackage}; "
              "for i=1,table.getn(bad) do assert(not pcall(function() PlayerPackage:GetItemTableIndex(bad[i]) end)) end");
        Require(f.bag.calls.empty(), "invalid type reached callback");
    });
    Test("dot_call_does_not_shift_index_to_first_argument", [] {
        Fixture f; f.Run("assert(not pcall(function() PlayerPackage.GetItemTableIndex(0) end))");
        Require(f.bag.calls.empty(), "dot call shifted the index");
    });
    Test("exact_one_result_and_extra_arguments_ignored", [] {
        Fixture f; f.Run("function Count(...) return arg.n end; "
                         "assert(Count(PlayerPackage:GetItemTableIndex(1))==1); "
                         "assert(Count(PlayerPackage:GetItemTableIndex(0))==1); "
                         "assert(PlayerPackage:GetItemTableIndex(0,true,{},'ignored')==10100001)");
    });
    Test("nan_infinities_and_out_of_range_use_int32_min", [] {
        Fixture f;
        f.state.Number("query_nan", (std::numeric_limits<double>::quiet_NaN)());
        f.state.Number("query_inf", (std::numeric_limits<double>::infinity)());
        f.Run("PlayerPackage:GetItemTableIndex(query_nan); PlayerPackage:GetItemTableIndex(query_inf); "
              "PlayerPackage:GetItemTableIndex(-query_inf); PlayerPackage:GetItemTableIndex(2147483648); "
              "PlayerPackage:GetItemTableIndex(-2147483649)");
        Require(f.bag.calls == std::vector<std::int32_t>(5, (std::numeric_limits<std::int32_t>::min)()),
                "invalid numeric conversion differs from int32 policy");
    });
    Test("int32_boundaries_and_signed_result_preserved", [] {
        Fixture f; f.bag.echo = true;
        f.Run("assert(PlayerPackage:GetItemTableIndex(2147483647.9)==2147483647); "
              "assert(PlayerPackage:GetItemTableIndex(-2147483648.9)==-2147483648); "
              "assert(PlayerPackage:GetItemTableIndex(-7)==-7)");
    });
    Test("callback_reads_new_state_without_caching_result", [] {
        Fixture f; f.Run("assert(PlayerPackage:GetItemTableIndex(0)==10100001)");
        f.bag.ids[0] = 30303030;
        f.Run("assert(PlayerPackage:GetItemTableIndex(0)==30303030)");
    });
    Test("descriptor_is_copied_and_repeated_registration_is_zero", [] {
        Fixture f(false);
        auto services = f.bag.Services();
        Require(f.Register(services) == 1, "first registration count");
        services.context = nullptr; services.bagItemTableIndex = nullptr;
        Require(f.Register(services) == 0, "repeat registration count");
        f.Run("assert(PlayerPackage:GetItemTableIndex(0)==10100001)");
    });
    Test("registration_keeps_existing_function", [] {
        Fixture f(false);
        f.Run("savedMeta.GetItemTableIndex=function() return 731 end; oldMethod=savedMeta.GetItemTableIndex");
        Require(f.Register(f.bag.Services()) == 0, "existing function overwritten");
        f.Run("assert(savedMeta.GetItemTableIndex==oldMethod and PlayerPackage:GetItemTableIndex(0)==731)");
        Require(f.bag.calls.empty(), "existing method called backend");
    });
    Test("registration_keeps_non_nil_false_zero_and_string", [] {
        Fixture f(false);
        for (const char* value : {"false","0","'existing'"})
        {
            const std::string code = std::string("savedMeta.GetItemTableIndex=") + value;
            f.Run(code.c_str());
            Require(f.Register(f.bag.Services()) == 0, "non-nil field overwritten");
            f.Run((std::string("assert(savedMeta.GetItemTableIndex==") + value + ")").c_str());
        }
    });
    Test("missing_receiver_rejected_without_placeholder", [] {
        State state; ExpectIntegrationError(state); state.Run("assert(PlayerPackage==nil)");
    });
    Test("table_receiver_rejected_without_replacement", [] {
        State state; state.Run("PlayerPackage={}; saved=PlayerPackage"); ExpectIntegrationError(state);
        state.Run("assert(PlayerPackage==saved and next(PlayerPackage)==nil)");
    });
    Test("userdata_without_metatable_rejected", [] {
        State state; lua_newuserdata(state.p->GetCState(), 1); lua_setglobal(state.p->GetCState(), "PlayerPackage");
        state.Run("saved=PlayerPackage; oldMeta=getmetatable(PlayerPackage)"); ExpectIntegrationError(state);
        state.Run("assert(PlayerPackage==saved and getmetatable(PlayerPackage)==oldMeta); "
                  "if oldMeta then assert(oldMeta.GetItemTableIndex==nil) end");
    });
    Test("missing_service_reports_lua_error_instead_of_minus_one", [] {
        Fixture f(false); Require(f.Register(CysHostQueries::Services{}) == 1, "registration failed");
        f.Run("local ok,err=pcall(function() return PlayerPackage:GetItemTableIndex(0) end); "
              "assert(not ok and string.find(err,'service is unavailable',1,true))");
    });
    Test("std_exception_unwinds_and_redacts_payload_then_vm_reusable", [] {
        Fixture f; f.bag.throwKind = 1;
        f.Run("local ok,err=pcall(function() return PlayerPackage:GetItemTableIndex(0) end); "
              "assert(not ok and string.find(err,'service exception',1,true)); "
              "assert(not string.find(err,'PRIVATE_QUERY_ARGUMENT',1,true))");
        Require(f.bag.activeObjects == 0, "C++ callback did not unwind before Lua error");
        f.bag.throwKind = 0; f.Run("assert(PlayerPackage:GetItemTableIndex(0)==10100001)");
    });
    Test("lua_exception_unwinds_and_redacts_payload", [] {
        Fixture f; f.bag.throwKind = 2;
        f.Run("local ok,err=pcall(function() return PlayerPackage:GetItemTableIndex(0) end); "
              "assert(not ok and string.find(err,'service Lua exception',1,true)); "
              "assert(not string.find(err,'PRIVATE_QUERY_ARGUMENT',1,true))");
        Require(f.bag.activeObjects == 0, "LuaException callback did not unwind");
    });
    Test("two_states_keep_independent_service_contexts", [] {
        Fixture a; Fixture b; b.bag.ids[0] = 20404040;
        a.Run("assert(PlayerPackage:GetItemTableIndex(0)==10100001)");
        b.Run("assert(PlayerPackage:GetItemTableIndex(0)==20404040)");
        a.Run("assert(PlayerPackage:GetItemTableIndex(0)==10100001)");
    });
    Test("gc_keeps_borrowed_context_and_live_closure", [] {
        Fixture f;
        f.Run("collectgarbage(); assert(PlayerPackage:GetItemTableIndex(0)==10100001)");
        Require(f.bag.calls.size() == 1, "GC damaged descriptor");
    });
    Test("unrelated_generated_stub_counter_still_operates", [] {
        Fixture f; auto meta = f.state.p->GetGlobals().GetByName("FixturePackageMeta");
        LuaApiGen::Register_PlayerPackage(meta);
        f.Run("PlayerPackage:GetItemTableIndex(0); PlayerPackage:GetBagItemNum(0)");
        Require(LuaApiGen::GetMissingCallCount() == 1 &&
                LuaApiGen::GetMissingCallCountFor("PlayerPackage", "GetItemTableIndex") == 0 &&
                LuaApiGen::GetMissingCallCountFor("PlayerPackage", "GetBagItemNum") == 1,
                "registration disabled unrelated missing counters");
    });
    std::printf("QUERY_TESTS passed=%u failed=%u total=%u simulated_bag=1 game_runtime=0\n", passed,failed,passed+failed);
    return failed ? 1 : 0;
}
