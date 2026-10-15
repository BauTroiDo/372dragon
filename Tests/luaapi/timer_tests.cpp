// CYS: offline Lua/production-manager timer contract tests; never starts Game.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include "CysHostTimers.h"
#include "CysHostTimerLua.h"
#include "LuaApiGen.h"

#include <cstdio>
#include <cstring>
#include <deque>
#include <functional>
#include <limits>
#include <memory>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace
{
    using CysHostTimers::TimerId;
    using CysHostTimers::Manager;
    unsigned passed = 0;
    unsigned failed = 0;
    std::vector<std::string> missingLines;

    void Require(bool condition, const char* message)
    { if (!condition) throw std::runtime_error(message); }
    void Capture(const char* message)
    { missingLines.emplace_back(message ? message : ""); }
    template<class F> void Test(const char* name, F run)
    {
        try { run(); ++passed; std::printf("PASS %s\n", name); }
        catch (const LuaPlus::LuaException& error)
        { ++failed; std::printf("FAIL %s: %s\n", name, error.GetMessage()); }
        catch (const std::exception& error)
        { ++failed; std::printf("FAIL %s: %s\n", name, error.what()); }
        catch (...) { ++failed; std::printf("FAIL %s: unknown exception\n", name); }
    }
    struct State
    {
        LuaPlus::LuaState* p = LuaPlus::LuaState::Create(true);
        State()
        {
            Require(p != nullptr, "LuaState::Create failed");
            LuaApiGen::ResetMissingCallCounts();
            LuaApiGen::SetLogSink(Capture);
            missingLines.clear();
        }
        ~State() { LuaPlus::LuaState::Destroy(p); }
        State(const State&) = delete;
        State& operator=(const State&) = delete;
    };
    void Lua(LuaPlus::LuaState* state, const char* code)
    {
        lua_State* raw = state->GetCState();
        const int top = lua_gettop(raw);
        const int rc = state->DoString(code);
        if (rc != 0)
        {
            const char* message = lua_tostring(raw, -1);
            const std::string text = message ? message : "Lua returned nonzero";
            lua_settop(raw, top);
            throw std::runtime_error(text);
        }
        Require(lua_gettop(raw) == top, "test snippet leaked Lua stack entries");
    }
    void Number(LuaPlus::LuaState* state, const char* name, double value)
    {
        lua_pushnumber(state->GetCState(), value);
        lua_setglobal(state->GetCState(), name);
    }
    struct MockBackend : CysHostTimers::Backend
    {
        std::deque<TimerId> ids;
        TimerId next = 1;
        std::vector<std::uint32_t> intervals;
        std::vector<TimerId> killed;
        std::vector<TimerId> forgotten;
        std::vector<std::pair<std::string, std::string>> evaluated;
        std::vector<std::string> errors;
        std::weak_ptr<Manager> bound;
        std::function<void(const std::string&, const std::string&)> evaluate;
        std::function<void(TimerId)> kill;
        bool failStart = false;
        void Bind(const std::weak_ptr<Manager>& manager) override { bound = manager; }
        TimerId Start(std::uint32_t milliseconds) override
        {
            intervals.push_back(milliseconds);
            if (failStart) throw std::runtime_error("fixture start failure");
            if (ids.empty()) return next++;
            const TimerId id = ids.front(); ids.pop_front(); return id;
        }
        void Kill(TimerId id) override
        { killed.push_back(id); if (kill) kill(id); }
        void Forget(TimerId id) override { forgotten.push_back(id); }
        void Evaluate(const std::string& owner, const std::string& expression) override
        {
            evaluated.emplace_back(owner, expression);
            if (evaluate) evaluate(owner, expression);
        }
        void ReportError(const std::string& message) noexcept override
        { try { errors.push_back(message); } catch (...) {} }
    };
    struct Fixture
    {
        // Destruction order deliberately releases manager before its Lua state.
        State state;
        std::shared_ptr<MockBackend> backend = std::make_shared<MockBackend>();
        std::shared_ptr<Manager> manager = Manager::Create(backend);
        explicit Fixture(bool registerNow = true)
        {
            if (registerNow)
            {
                auto globals = state.p->GetGlobals();
                Require(CysHostTimers::Register(globals, manager) == 3, "timer registration count");
            }
        }
        void Run(const char* code) { Lua(state.p, code); }
        void Dispatch(TimerId id) { manager->Dispatch(id); }
    };

    void PumpFor(DWORD milliseconds)
    {
        const ULONGLONG end = GetTickCount64() + milliseconds;
        while (GetTickCount64() < end)
        {
            MSG message{};
            if (PeekMessageW(&message, nullptr, 0, 0, PM_REMOVE))
            {
                Require(message.message != WM_QUIT, "unexpected WM_QUIT in isolated timer test");
                TranslateMessage(&message);
                DispatchMessageW(&message);
            }
            else Sleep(1);
        }
    }

    int ThrowAcrossLua(lua_State*)
    { throw std::runtime_error("synthetic native callback exception"); }

    // This child deliberately abandons a poisoned Lua VM and exits the process.
    // No Lua API, LuaState destructor, or subsequent dispatch may touch that VM.
    int NativeExceptionChild()
    {
        State state;
        Lua(state.p,"Old_Env={}; Owner_Env={}; setmetatable(_G,{__index=Old_Env})");
        lua_pushcfunction(state.p->GetCState(),ThrowAcrossLua);
        lua_setglobal(state.p->GetCState(),"ThrowAcrossLua");
        std::string active="Old_Env";
        const auto result=CysHostTimerLua::Execute(state.p,active,"Owner","ThrowAcrossLua()");
        const bool okay=!result.ok() && !result.stateUsable && result.status==CysHostTimerLua::CppException &&
            result.phase==CysHostTimerLua::Phase::ExpressionCall && active=="Owner_Env";
        std::printf("NATIVE_EXCEPTION state_usable=%d status=%d phase=%s no_vm_reentry=1 passed=%d\n",
                    result.stateUsable ? 1 : 0,result.status,CysHostTimerLua::PhaseName(result.phase),okay ? 1 : 0);
        std::fflush(stdout);
        ExitProcess(okay ? 0 : 1);
    }
}

int main(int argc, char** argv)
{
    if(argc==2 && std::strcmp(argv[1],"--native-exception-child")==0) return NativeExceptionChild();
    Test("same_lua_snippet_three_missing_calls_to_real_stale_dispatch", [] {
        const char* snippet = "ClearAllTimer(); counter=0; timerId=SetTimer('Owner','counter=counter+1',25); KillTimer(timerId)";
        unsigned before = 0;
        {
            State state;
            auto globals = state.p->GetGlobals();
            LuaApiGen::Register_Globals(globals);
            Lua(state.p, snippet);
            Lua(state.p, "assert(timerId==nil and counter==0)");
            before = LuaApiGen::GetMissingCallCount();
            Require(before == 3 && LuaApiGen::GetMissingDistinctCount() == 3 && missingLines.size() == 3,
                    "baseline must call all three generated timer stubs");
        }
        Fixture f;
        f.backend->ids = {37};
        f.backend->evaluate = [&](const std::string&, const std::string& expression) { f.Run(expression.c_str()); };
        auto globals = f.state.p->GetGlobals();
        LuaApiGen::Register_Globals(globals);
        f.Run(snippet);
        f.Run("assert(timerId==37 and counter==0)");
        f.Dispatch(37);
        f.Dispatch(37);
        f.Run("assert(counter==2)");
        Require(LuaApiGen::GetMissingCallCount() == 0 && missingLines.empty(), "real timers reached stubs");
        Require(f.backend->killed == std::vector<TimerId>{37}, "numeric kill must reach backend");
        std::printf("BEFORE_AFTER missing_calls=%u->0 distinct=3->0 missing_lines=3->0 id=37 lua_effects=2\n", before);
    });
    Test("set_argument_types_returns_one_minus_one_without_start", [] {
        Fixture f;
        lua_newuserdata(f.state.p->GetCState(), 1);
        lua_setglobal(f.state.p->GetCState(), "fixture_userdata");
        f.Run("function Count(...) return arg.n end; "
              "assert(Count(SetTimer())==1 and SetTimer()==-1); "
              "assert(SetTimer(nil,'E',1)==-1 and SetTimer(true,'E',1)==-1); "
              "assert(SetTimer({},'E',1)==-1 and SetTimer(function() end,'E',1)==-1); "
              "assert(SetTimer(fixture_userdata,'E',1)==-1); "
              "assert(SetTimer('O',nil,1)==-1 and SetTimer('O',false,1)==-1); "
              "assert(SetTimer('O',{},1)==-1 and SetTimer('O',function() end,1)==-1); "
              "assert(SetTimer('O',fixture_userdata,1)==-1); "
              "assert(SetTimer('O','E')==-1 and SetTimer('O','E','1000')==-1); "
              "assert(SetTimer('O','E',true)==-1 and SetTimer('O','E',{})==-1)");
        Require(f.backend->intervals.empty(), "invalid argument types started a timer");
    });
    Test("set_numeric_strings_for_owner_expression_and_extra_arguments", [] {
        Fixture f;
        f.backend->ids = {93};
        f.Run("function Count(...) return arg.n end; assert(Count(SetTimer(12,34,1000,'ignored'))==1)");
        f.Dispatch(93);
        Require(f.backend->intervals == std::vector<std::uint32_t>{1000}, "milliseconds changed");
        Require(f.backend->evaluated == std::vector<std::pair<std::string,std::string>>{{"12","34"}},
                "numeric owner/expression conversion changed");
    });
    Test("interval_truncation_uint_bits_and_invalid_conversion_policy", [] {
        Fixture f;
        const std::vector<double> inputs = {1000,1.9,0,-1,-1.9,2147483647.75,-2147483648.75,
            2147483648.0,-2147483649.0,(std::numeric_limits<double>::infinity)(),
            -(std::numeric_limits<double>::infinity)(),(std::numeric_limits<double>::quiet_NaN)()};
        const std::vector<std::uint32_t> expected = {1000,1,0,0xffffffffu,0xffffffffu,0x7fffffffu,
            0x80000000u,0x80000000u,0x80000000u,0x80000000u,0x80000000u,0x80000000u};
        for (double value : inputs)
        { Number(f.state.p,"interval",value); f.Run("assert(SetTimer('O','E',interval)>0)"); }
        Require(f.backend->intervals == expected, "int32 truncate/invalid-to-INT_MIN policy differs");
    });
    Test("backend_zero_and_exact_backend_id_without_local_counter", [] {
        Fixture f;
        f.backend->ids = {0, 617};
        f.Run("assert(SetTimer('O','failed',10)==0); assert(SetTimer('O','live',10)==617)");
        f.Dispatch(0); f.Dispatch(1); f.Dispatch(617);
        Require(f.backend->evaluated.size() == 1 && f.backend->evaluated[0].second == "live", "failed start created a record");
        Require(f.backend->killed.empty(), "zero ID must not be killed");
    });
    Test("high_backend_id_rejected_and_full_pointer_width_cancelled", [] {
        Fixture f;
        const TimerId high = (TimerId(1) << 40) | 0x1234;
        f.backend->ids = {high, TimerId(0x80000000u), TimerId(0x7fffffffu)};
        f.Run("assert(SetTimer('O','E',1)==0); assert(SetTimer('O','E',1)==0); assert(SetTimer('O','last',1)==2147483647)");
        Require(f.backend->killed == std::vector<TimerId>{high,TimerId(0x80000000u)}, "high ID kill truncated pointer bits");
        Require(f.backend->forgotten == f.backend->killed && f.backend->errors.size() == 2, "rejected ID cleanup/log missing");
        f.Dispatch(high); f.Dispatch(0x1234); f.Dispatch(0x80000000u); f.Dispatch(0x7fffffffu);
        Require(f.backend->evaluated.size() == 1 && f.backend->evaluated[0].second == "last", "high ID aliased accepted record");
        std::printf("HIGH_ID rejected=0x%llx cancelled=0x%llx id_bytes=%zu\n",
                    static_cast<unsigned long long>(high),static_cast<unsigned long long>(f.backend->killed[0]),sizeof(TimerId));
    });
    Test("lua_and_cpp_strings_stop_at_nul", [] {
        Fixture f;
        f.backend->ids = {31,32};
        f.Run("assert(SetTimer('Owner\\000tail','Expr\\000tail',1)==31)");
        Require(f.manager->Set(std::string("Other\0tail",10),std::string("Body\0tail",9),1)==32,"direct Set ID");
        f.Dispatch(31); f.Dispatch(32);
        Require(f.backend->evaluated == std::vector<std::pair<std::string,std::string>>{{"Owner","Expr"},{"Other","Body"}}, "C-string boundary mismatch");
        f.Run("assert(KillTimer('Expr\\000other')==true)");
        f.manager->KillExpression(std::string("Body\0other",10));
        Require(f.backend->killed == std::vector<TimerId>{31,32}, "expression NUL suffix prevented exact prefix match");
    });
    Test("empty_owner_or_expression_starts_but_never_evaluates", [] {
        Fixture f;
        f.Run("assert(SetTimer('','E',1)==1); assert(SetTimer('O','',1)==2); assert(SetTimer('','',1)==3)");
        f.Dispatch(1); f.Dispatch(2); f.Dispatch(3);
        Require(f.backend->intervals.size()==3 && f.backend->evaluated.empty(), "empty strings dispatch or fail start");
    });
    Test("repeating_dispatch_keeps_record_and_same_expression_duplicates", [] {
        Fixture f;
        f.backend->ids = {70,90};
        f.Run("assert(SetTimer('O','E',10)==70); assert(SetTimer('O','E',10)==90)");
        f.Dispatch(70); f.Dispatch(70); f.Dispatch(90); f.Dispatch(90);
        Require(f.backend->intervals.size()==2 && f.backend->evaluated.size()==4, "timer was one-shot or expression replaced");
    });
    Test("kill_expression_uses_lowest_unsigned_id_across_owners", [] {
        Fixture f;
        f.backend->ids = {900,4,500};
        f.Run("SetTimer('OwnerA','Same()',1); SetTimer('OwnerB','Same()',1); SetTimer('OwnerC','Same()',1); assert(KillTimer('Same()')==true)");
        Require(f.backend->killed == std::vector<TimerId>{4}, "expression cancelled insertion order or all matches");
        f.Dispatch(4); f.Dispatch(900); f.Dispatch(500);
        Require(f.backend->evaluated.size()==2 && f.backend->evaluated[0].first=="OwnerA" && f.backend->evaluated[1].first=="OwnerC", "wrong owner records survived");
    });
    Test("expression_match_is_byte_exact_without_parenthesis_or_case_alias", [] {
        Fixture f;
        f.backend->ids = {42,77};
        f.Run("SetTimer('O','Tick()',1); SetTimer('O','42',1); assert(KillTimer('Tick')==true); "
              "assert(KillTimer('tick()')==true and KillTimer(' Tick()')==true and KillTimer('Tick() ')==true)");
        Require(f.backend->killed.empty(), "expression normalization changed B matching");
        f.Run("assert(KillTimer('42')==true)");
        Require(f.backend->killed == std::vector<TimerId>{77}, "numeric string treated as ID");
        f.Dispatch(42); f.Dispatch(77);
        Require(f.backend->evaluated.size()==1 && f.backend->evaluated[0].second=="Tick()", "numeric string erased numeric ID");
    });
    Test("numeric_kill_truncates_returns_true_and_preserves_stale_record", [] {
        Fixture f;
        f.backend->ids = {37};
        f.Run("SetTimer('O','E',1); assert(KillTimer(37.9)==true and KillTimer(37)==true and KillTimer(99)==true)");
        Require(f.backend->killed == std::vector<TimerId>{37,37} && f.backend->forgotten.empty(), "numeric kill erased or touched unknown ID");
        f.Dispatch(37);
        Require(f.backend->evaluated.size()==1, "queued callback after numeric kill was lost");
        Number(f.state.p,"invalid",(std::numeric_limits<double>::quiet_NaN)());
        f.Run("assert(KillTimer(invalid)==true and KillTimer(-1)==true and KillTimer(2147483648)==true)");
        Require(f.backend->killed.size()==2, "invalid numeric ID aliased valid record");
    });
    Test("string_kill_removes_one_record_and_suppresses_queued_dispatch", [] {
        Fixture f;
        f.Run("SetTimer('O','E',1); SetTimer('O','E',1); assert(KillTimer('E')==true and KillTimer('unknown')==true)");
        f.Dispatch(1); f.Dispatch(2);
        Require(f.backend->killed==std::vector<TimerId>{1} && f.backend->forgotten==std::vector<TimerId>{1}, "string kill cleanup differs");
        Require(f.backend->evaluated.size()==1, "queued callback survived string erase or all records erased");
    });
    Test("invalid_kill_argument_types_return_one_false_without_backend", [] {
        Fixture f;
        lua_newuserdata(f.state.p->GetCState(),1);
        lua_setglobal(f.state.p->GetCState(),"fixture_userdata");
        f.Run("function Count(...) return arg.n end; assert(Count(KillTimer())==1); "
              "assert(KillTimer()==false and KillTimer(nil)==false and KillTimer(false)==false and KillTimer(true)==false); "
              "assert(KillTimer({})==false and KillTimer(function() end)==false and KillTimer(fixture_userdata)==false)");
        Require(f.backend->killed.empty(), "invalid KillTimer called backend");
    });
    Test("stale_low_id_consumes_first_string_kill_leaving_live_timer", [] {
        Fixture f;
        f.backend->ids = {7,23};
        f.Run("SetTimer('A','E',1); SetTimer('B','E',1); KillTimer(7); KillTimer('E')");
        Require(f.backend->killed==std::vector<TimerId>{7,7}, "string kill skipped stale first record");
        f.Dispatch(7); f.Dispatch(23);
        Require(f.backend->evaluated.size()==1 && f.backend->evaluated[0].first=="B", "live duplicate was cancelled");
    });
    Test("backend_reuses_numeric_killed_id_unique_insert_keeps_old_record", [] {
        Fixture f;
        f.backend->ids = {81,81};
        f.Run("assert(SetTimer('Old','Old()',1)==81); KillTimer(81); assert(SetTimer('New','New()',2)==81)");
        f.Dispatch(81);
        Require(f.backend->intervals==std::vector<std::uint32_t>{1,2}, "duplicate ID skipped backend start");
        Require(f.backend->evaluated==std::vector<std::pair<std::string,std::string>>{{"Old","Old()"}}, "duplicate ID overwrote stale record");
    });
    Test("callback_can_erase_itself_with_record_strings_still_alive", [] {
        Fixture f;
        f.Run("SetTimer('Owner','Expression()',1)");
        f.backend->evaluate = [&](const std::string& owner,const std::string& expression) {
            f.manager->KillExpression(expression);
            Require(owner=="Owner" && expression=="Expression()", "dispatch did not copy record before callback");
        };
        f.Dispatch(1); f.Dispatch(1);
        Require(f.backend->evaluated.size()==1 && f.backend->forgotten.size()==1, "self cancellation kept record");
    });
    Test("callback_can_clear_then_add_without_invalidating_dispatch", [] {
        Fixture f;
        f.backend->ids = {10,20,30};
        f.Run("SetTimer('Old','First',1); SetTimer('Other','Second',1)");
        f.backend->evaluate = [&](const std::string& owner,const std::string& expression) {
            if (expression=="First")
            {
                f.manager->Clear();
                Require(f.manager->Set("New","Third",1)==30,"reentrant start ID");
                Require(owner=="Old" && expression=="First","clear invalidated dispatch strings");
            }
        };
        f.Dispatch(10); f.Dispatch(20); f.Dispatch(30);
        Require(f.backend->evaluated.size()==2 && f.backend->evaluated.back().second=="Third", "clear/add callback record state");
        Require(f.backend->killed==std::vector<TimerId>{10,20}, "clear skipped a pre-existing timer");
    });
    Test("direct_dispatch_reports_evaluation_exception_to_its_caller", [] {
        Fixture f;
        f.Run("SetTimer('O','E',1)");
        f.backend->evaluate=[](const std::string&,const std::string&) { throw std::runtime_error("evaluation failure"); };
        bool caught=false;
        try { f.Dispatch(1); }
        catch (const std::runtime_error& error) { caught=std::string(error.what())=="evaluation failure"; }
        Require(caught && f.backend->evaluated.size()==1, "direct Dispatch hid callback exception");
    });
    Test("clear_returns_no_values_kills_stale_and_live_then_forgets_all", [] {
        Fixture f;
        f.Run("SetTimer('O','A',1); SetTimer('O','B',1); KillTimer(1); function Count(...) return arg.n end; "
              "assert(Count(ClearAllTimer('ignored'))==0); assert(Count(ClearAllTimer())==0)");
        Require(f.backend->killed==std::vector<TimerId>{1,1,2} && f.backend->forgotten==std::vector<TimerId>{1,2}, "Clear did not cancel stale and live records exactly once");
        f.Dispatch(1); f.Dispatch(2);
        Require(f.backend->evaluated.empty(), "stale callback survived clear");
    });
    Test("clear_continues_cleanup_after_backend_cancellation_error", [] {
        Fixture f;
        f.Run("SetTimer('O','A',1); SetTimer('O','B',1)");
        f.backend->kill=[](TimerId id) { if(id==1) throw std::runtime_error("cancel failure"); };
        f.Run("local ok,msg=pcall(ClearAllTimer); assert(ok==false and msg=='timer service failed: C++ exception')");
        Require(f.backend->killed==std::vector<TimerId>{1,2} && f.backend->forgotten==std::vector<TimerId>{1,2}, "cleanup stopped at first failed kill");
        Require(!f.backend->errors.empty(), "cancellation failure was not reported");
        f.Dispatch(1); f.Dispatch(2);
        Require(f.backend->evaluated.empty(), "failed Clear retained stale records");
    });
    Test("shutdown_cancels_before_lua_release_and_weak_closures_fail", [] {
        Fixture f;
        f.Run("SetTimer('O','E',1)");
        f.manager.reset();
        Require(f.backend->bound.expired() && f.backend->killed==std::vector<TimerId>{1}, "closure retained manager past shutdown");
        f.Run("local ok,msg=pcall(SetTimer,'O','E',1); assert(not ok and string.find(msg,'unavailable',1,true)); "
              "assert(pcall(KillTimer,1)==false and pcall(ClearAllTimer)==false); collectgarbage()");
    });
    Test("shutdown_is_noexcept_and_logs_backend_cleanup_failure", [] {
        Fixture f;
        f.Run("SetTimer('O','E',1)");
        f.backend->kill=[](TimerId) { throw std::runtime_error("shutdown fixture failure"); };
        f.manager.reset();
        Require(f.backend->forgotten==std::vector<TimerId>{1} && f.backend->errors.size()>=2, "noexcept destructor dropped error or route cleanup");
    });
    Test("registration_only_nil_preserves_existing_function_and_value", [] {
        Fixture f(false);
        f.Run("SetTimer=function() return 123 end; KillTimer=false");
        auto globals=f.state.p->GetGlobals();
        Require(CysHostTimers::Register(globals,f.manager)==1, "non-nil slots were overwritten");
        f.Run("assert(SetTimer()==123 and KillTimer==false); saved=ClearAllTimer");
        Require(CysHostTimers::Register(globals,f.manager)==0, "second registration changed closures");
        f.Run("assert(saved==ClearAllTimer)");
        Require(f.backend->intervals.empty(), "existing function was not preserved");
    });
    Test("two_lua_states_and_managers_keep_same_id_callbacks_isolated", [] {
        Fixture first;
        Fixture second;
        first.backend->ids={91}; second.backend->ids={91};
        first.backend->evaluate=[&](const std::string&,const std::string& code) { first.Run(code.c_str()); };
        second.backend->evaluate=[&](const std::string&,const std::string& code) { second.Run(code.c_str()); };
        first.Run("count=0; SetTimer('A','count=count+1',1)");
        second.Run("count=0; SetTimer('B','count=count+10',1)");
        first.Dispatch(91); second.Dispatch(91);
        first.Run("assert(count==1); ClearAllTimer()");
        second.Dispatch(91); second.Run("assert(count==20)");
        Require(second.backend->killed.empty(), "one state cleared another manager");
    });
    Test("start_backend_exception_becomes_visible_lua_error", [] {
        Fixture f;
        f.backend->failStart=true;
        f.Run("local ok,msg=pcall(SetTimer,'O','E',1); assert(not ok and msg=='timer service failed: C++ exception')");
        Require(f.backend->intervals.size()==1 && f.backend->killed.empty(), "failed start created cleanup record");
    });

    Test("weak_handle_collector_rejects_foreign_userdata_without_memory_cast", [] {
        Fixture f;
        lua_State* raw=f.state.p->GetCState();
        const int top=lua_gettop(raw);
        luaL_getmetatable(raw,"CysHostTimers.WeakManager");
        lua_pushstring(raw,"__gc"); lua_rawget(raw,-2); lua_remove(raw,-2);
        lua_newuserdata(raw,1);
        const int rc=lua_pcall(raw,1,0,0);
        Require(rc!=0,"foreign userdata accepted by weak-handle collector");
        lua_settop(raw,top);
        f.Run("assert(SetTimer('O','E',1)==1)");
    });
    Test("checked_helper_selects_owner_environment_and_restores_prior_name", [] {
        Fixture f;
        f.Run("Old_Env={marker=9}; Owner_Env={marker=17}; setmetatable(_G,{__index=Old_Env})");
        std::string active="Old_Env";
        f.backend->evaluate=[&](const std::string& owner,const std::string& expression) {
            const auto result=CysHostTimerLua::Execute(f.state.p,active,owner,expression);
            Require(result.ok() && result.stateUsable,"production Lua timer evaluation failed");
        };
        f.Run("SetTimer('Owner','observed=marker; return 1,2,3',1)");
        lua_pushstring(f.state.p->GetCState(),"stack sentinel");
        const int top=lua_gettop(f.state.p->GetCState());
        f.Dispatch(1);
        Require(active=="Old_Env" && lua_gettop(f.state.p->GetCState())==top,"helper failed to restore name/stack");
        Require(std::string(lua_tostring(f.state.p->GetCState(),-1))=="stack sentinel","helper changed existing stack value");
        lua_pop(f.state.p->GetCState(),1);
        f.Run("assert(observed==17 and marker==9 and getmetatable(_G).__index==Old_Env)");
    });
    Test("checked_helper_empty_old_name_keeps_selected_environment", [] {
        State state;
        Lua(state.p,"Owner_Env={marker=31}");
        std::string active;
        const auto result=CysHostTimerLua::Execute(state.p,active,"Owner","observed=marker");
        Require(result.ok() && active=="Owner_Env","empty old environment was restored instead of kept");
        Lua(state.p,"assert(observed==31 and getmetatable(_G).__index==Owner_Env)");
    });
    Test("checked_helper_unknown_owner_uses_globals_without_window_validation", [] {
        State state;
        Lua(state.p,"Old_Env={}; globalMarker=77; setmetatable(_G,{__index=Old_Env})");
        std::string active="Old_Env";
        const auto result=CysHostTimerLua::Execute(state.p,active,"MissingOwner","observed=globalMarker");
        Require(result.ok() && active=="Old_Env","unknown owner incorrectly rejected");
        Lua(state.p,"assert(observed==77 and getmetatable(_G).__index==Old_Env)");
    });
    Test("checked_helper_same_environment_keeps_name_without_extra_restore", [] {
        State state;
        Lua(state.p,"Owner_Env={}; originalSet=setmetatable; selections=0; setmetatable=function(t,m) selections=selections+1; return originalSet(t,m) end");
        std::string active="Owner_Env";
        Require(CysHostTimerLua::Execute(state.p,active,"Owner","observed=1").ok(),"same owner evaluation failed");
        Lua(state.p,"assert(selections==1 and observed==1 and getmetatable(_G).__index==Owner_Env)");
    });
    Test("checked_helper_syntax_and_runtime_errors_restore_stack_and_environment", [] {
        State state;
        Lua(state.p,"Old_Env={}; Owner_Env={}; setmetatable(_G,{__index=Old_Env})");
        std::string active="Old_Env";
        const std::vector<std::pair<std::string,CysHostTimerLua::Phase>> cases={
            {"local =",CysHostTimerLua::Phase::ExpressionLoad},
            {"error('fixture runtime error')",CysHostTimerLua::Phase::ExpressionCall}};
        lua_pushnumber(state.p->GetCState(),123);
        const int top=lua_gettop(state.p->GetCState());
        for(const auto& entry:cases)
        {
            const auto result=CysHostTimerLua::Execute(state.p,active,"Owner",entry.first);
            Require(!result.ok() && result.stateUsable && result.phase==entry.second && result.status>0,
                    "checked helper lost Lua failure phase/status");
            Require(result.restoreStatus==0 && active=="Old_Env" && lua_gettop(state.p->GetCState())==top,
                    "Lua error failed stack/environment restoration");
            Require(lua_tonumber(state.p->GetCState(),-1)==123,"Lua error changed original stack value");
        }
        lua_pop(state.p->GetCState(),1);
        Lua(state.p,"assert(getmetatable(_G).__index==Old_Env); stillUsable=1");
    });
    Test("checked_helper_empty_old_name_and_expression_error_keeps_selection", [] {
        State state;
        Lua(state.p,"Owner_Env={}");
        std::string active;
        const auto result=CysHostTimerLua::Execute(state.p,active,"Owner","error('fixture')");
        Require(!result.ok() && result.stateUsable && active=="Owner_Env" && result.restoreStatus==0,
                "empty previous name policy changed on expression failure");
        Lua(state.p,"assert(getmetatable(_G).__index==Owner_Env)");
    });
    Test("checked_helper_select_syntax_failure_restores_prior_environment", [] {
        State state;
        Lua(state.p,"Old_Env={}; setmetatable(_G,{__index=Old_Env})");
        std::string active="Old_Env";
        const auto result=CysHostTimerLua::Execute(state.p,active,"Not Valid","observed=1");
        Require(!result.ok() && result.stateUsable && result.phase==CysHostTimerLua::Phase::SelectLoad &&
                result.status>0 && result.restoreStatus==0 && active=="Old_Env","select syntax failure contract");
        Lua(state.p,"assert(observed==nil and getmetatable(_G).__index==Old_Env)");
    });
    Test("checked_helper_partial_select_runtime_error_restores_real_metatable", [] {
        State state;
        Lua(state.p,"Old_Env={}; Owner_Env={}; originalSet=setmetatable; originalSet(_G,{__index=Old_Env}); "
              "setmetatable=function(t,m) originalSet(t,m); if m.__index==Owner_Env then error('after mutation') end; return t end");
        std::string active="Old_Env";
        const auto result=CysHostTimerLua::Execute(state.p,active,"Owner","observed=1");
        Require(!result.ok() && result.stateUsable && result.phase==CysHostTimerLua::Phase::SelectCall &&
                result.status>0 && result.restoreStatus==0 && active=="Old_Env","partial select failure not reported/restored");
        Lua(state.p,"assert(observed==nil and getmetatable(_G).__index==Old_Env)");
    });
    Test("checked_helper_reports_primary_and_restore_failures_independently", [] {
        State state;
        Lua(state.p,"Old_Env={}; Owner_Env={}; originalSet=setmetatable; originalSet(_G,{__index=Old_Env}); "
              "setmetatable=function(t,m) if m.__index==Old_Env then error('restore error') end; return originalSet(t,m) end");
        std::string active="Old_Env";
        const auto result=CysHostTimerLua::Execute(state.p,active,"Owner","error('expression error')");
        Require(!result.ok() && result.stateUsable && result.phase==CysHostTimerLua::Phase::ExpressionCall &&
                result.status>0 && result.restorePhase==CysHostTimerLua::Phase::RestoreCall && result.restoreStatus>0,
                "helper overwrote primary error or concealed restore failure");
        Require(active=="Owner_Env","failed restore falsely published old environment name");
        Lua(state.p,"assert(getmetatable(_G).__index==Owner_Env)");
    });
    Test("checked_helper_restore_syntax_failure_retains_successful_expression", [] {
        State state;
        Lua(state.p,"Owner_Env={}");
        std::string active="Not Valid";
        const auto result=CysHostTimerLua::Execute(state.p,active,"Owner","observed=99");
        Require(!result.ok() && result.stateUsable && result.status==0 &&
                result.restorePhase==CysHostTimerLua::Phase::RestoreLoad && result.restoreStatus>0 && active=="Owner_Env",
                "restore load failure incorrectly reported successful overall result");
        Lua(state.p,"assert(observed==99 and getmetatable(_G).__index==Owner_Env)");
    });
    Test("checked_helper_missing_state_returns_fixed_unavailable_status", [] {
        std::string active="Old_Env";
        const auto result=CysHostTimerLua::Execute(nullptr,active,"Owner","unused");
        Require(!result.ok() && !result.stateUsable && result.phase==CysHostTimerLua::Phase::Unavailable &&
                result.status==CysHostTimerLua::MissingState && active=="Old_Env","null state result differs");
    });

    Test("win32_repeats_on_creating_thread_only_during_bounded_message_pump", [] {
        const ULONGLONG began=GetTickCount64();
        State state;
        Lua(state.p,"ticks0=0; ticks1=0");
        const DWORD thread=GetCurrentThreadId();
        std::vector<DWORD> callbackThreads;
        std::vector<ULONGLONG> callbackTimes;
        std::vector<std::string> errors;
        CysHostTimers::WindowsCallbacks callbacks;
        callbacks.evaluate=[&](const std::string& owner,const std::string& expression) {
            Require(owner=="Owner","Windows backend lost owner");
            callbackThreads.push_back(GetCurrentThreadId());
            callbackTimes.push_back(GetTickCount64());
            Lua(state.p,expression.c_str());
        };
        callbacks.reportError=[&](const std::string& text) { errors.push_back(text); };
        auto backend=CysHostTimers::MakeWindowsBackend(callbacks);
        auto manager=Manager::Create(backend);
        const ULONGLONG started=GetTickCount64();
        const auto zero=manager->Set("Owner","ticks0=ticks0+1",0);
        const auto one=manager->Set("Owner","ticks1=ticks1+1",1);
        Require(zero>0 && one>0 && zero!=one,"Windows timer start returned invalid IDs");
        Require(callbackTimes.empty(),"SetTimer invoked synchronously");
        PumpFor(120);
        Require(callbackTimes.size()>=4,"Windows timers did not repeat during pump");
        Lua(state.p,"assert(ticks0>=2 and ticks1>=2)");
        // GetTickCount64 has coarse clock resolution; allow 5 ms tolerance around USER_TIMER_MINIMUM=10.
        Require(callbackTimes.front()-started>=5,"callback arrived before Windows minimum interval");
        for(DWORD id:callbackThreads) Require(id==thread,"Lua callback moved to another thread");
        manager->Clear();
        const std::size_t before=callbackTimes.size();
        PumpFor(35);
        Require(callbackTimes.size()==before,"cleared Windows route still evaluated Lua");
        manager.reset(); backend.reset();
        PumpFor(20);
        Require(callbackTimes.size()==before && errors.empty(),"shutdown callback or timer error");
        Require(GetTickCount64()-began<2000,"offline Win32 smoke exceeded two-second bound");
        std::printf("WIN32 callbacks=%zu first_delay_ms=%llu pump_total_ms=%llu thread=%lu errors=%zu\n",
                    before,callbackTimes.front()-started,GetTickCount64()-began,thread,errors.size());
    });
    Test("win32_callback_exceptions_are_logged_and_never_cross_timerproc", [] {
        const ULONGLONG began=GetTickCount64();
        State state;
        Lua(state.p,"Old_Env={}; Owner_Env={}; setmetatable(_G,{__index=Old_Env})");
        std::string active="Old_Env";
        unsigned callbacksRun=0;
        unsigned checkedLuaErrors=0;
        std::vector<std::string> errors;
        CysHostTimers::WindowsCallbacks callbacks;
        callbacks.evaluate=[&](const std::string& owner,const std::string& expression) {
            ++callbacksRun;
            const auto result=CysHostTimerLua::Execute(state.p,active,owner,expression);
            if(!result.ok() && result.stateUsable && result.phase==CysHostTimerLua::Phase::ExpressionCall &&
               result.status>0 && result.restoreStatus==0 && active=="Old_Env") ++checkedLuaErrors;
            throw std::runtime_error("controlled callback failure");
        };
        callbacks.reportError=[&](const std::string& text) { errors.push_back(text); };
        auto backend=CysHostTimers::MakeWindowsBackend(callbacks);
        auto manager=Manager::Create(backend);
        Require(manager->Set("Owner","error('controlled Lua callback error')",10)>0,"Windows error timer could not start");
        PumpFor(55);
        manager->Clear(); manager.reset(); backend.reset();
        Require(callbacksRun>=1 && errors.size()==callbacksRun,"TimerProc lost repeated callback error reports");
        Require(checkedLuaErrors==callbacksRun,"Windows callback failed checked Lua error/restore contract");
        Lua(state.p,"assert(getmetatable(_G).__index==Old_Env)");
        for(const auto& text:errors) Require(text=="timer callback failed: C++ exception","TimerProc report missing phase or exposed exception payload");
        Require(GetTickCount64()-began<2000,"error smoke exceeded two-second bound");
        std::printf("WIN32_ERRORS callbacks=%u checked_lua_errors=%u reports=%zu elapsed_ms=%llu\n",
                    callbacksRun,checkedLuaErrors,errors.size(),GetTickCount64()-began);
    });

    std::printf("RESULT passed=%u failed=%u total=%u\n",passed,failed,passed+failed);
    return failed ? 1 : 0;
}
