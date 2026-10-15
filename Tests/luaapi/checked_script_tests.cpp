// CYS: real LuaPlus checks for UI DoString restoration and sanitized diagnostics.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include "CysCheckedScriptLua.h"
#include "CysHostGlobals.h"
#include <cstdio>
#include <cstring>
#include <memory>
#include <stdexcept>
#include <type_traits>

namespace
{
    unsigned passed = 0, failed = 0;
    const char* const Canary = "DIAGNOSTIC_CANARY_7X";
    void Check(bool yes) { if (!yes) throw std::runtime_error("check failed"); }
    template<class F> void Test(const char* name, F fn)
    {
        try { fn(); ++passed; std::printf("PASS %s\n", name); }
        catch (...) { ++failed; std::printf("FAIL %s\n", name); }
    }
    struct State
    {
        LuaPlus::LuaState* lua = LuaPlus::LuaState::Create(true);
        std::string active = "Old_Env";
        State() { Check(lua != nullptr); }
        ~State() { LuaPlus::LuaState::Destroy(lua); }
        lua_State* raw() { return lua->GetCState(); }
        void Run(const char* code)
        {
            const int top = lua_gettop(raw());
            const int rc = lua->DoString(code);
            lua_settop(raw(), top);
            Check(rc == 0);
        }
        void Setup()
        { Run("Old_Env={marker=11}; Owner_Env={marker=22}; Inner_Env={marker=33}; oldmeta={__index=Old_Env,token=91}; setmetatable(_G,oldmeta)"); }
        bool Boolean(const char* name)
        { lua_getglobal(raw(),name); const bool b=lua_toboolean(raw(),-1)!=0; lua_pop(raw(),1); return b; }
        double Number(const char* name)
        { lua_getglobal(raw(),name); const double n=lua_tonumber(raw(),-1); lua_pop(raw(),1); return n; }
        bool OldMetatable()
        {
            const bool found=lua_getmetatable(raw(),LUA_GLOBALSINDEX)!=0;
            if (!found) return false;
            lua_getglobal(raw(),"oldmeta"); const bool same=lua_rawequal(raw(),-1,-2)!=0; lua_pop(raw(),2); return same;
        }
        void Sentinel() { lua_pushnumber(raw(),817); }
        void Restored()
        { Check(active=="Old_Env" && lua_gettop(raw())==1 && lua_tonumber(raw(),1)==817 && OldMetatable()); }
    };
    struct NestedContext
    {
        State* state;
        bool innerFails = false;
        bool observed = false;
        CysCheckedScriptLua::Census census;
    };
    NestedContext* nested = nullptr;
    int Nested(lua_State*)
    {
        NestedContext& n=*nested;
        const auto result=CysCheckedScriptLua::Execute(n.state->lua,n.state->active,"Inner_Env",
            n.innerFails ? "innerObserved=marker; error('DIAGNOSTIC_CANARY_7X')" : "innerObserved=marker");
        char text[384] = {};
        n.census.Record(result,"Inner_Env",text,sizeof(text));
        n.observed=result.restored && result.stateUsable && result.ok()!=n.innerFails &&
            n.state->active=="Owner_Env" && n.state->Number("marker")==22 && std::strstr(text,Canary)==nullptr;
        return 0;
    }
    std::unique_ptr<std::string> owner;
    int DestroyOwner(lua_State*) { owner.reset(); return 0; }
    int ThrowNative(lua_State*) { throw std::runtime_error(Canary); }
    static_assert(!std::is_base_of<std::exception,CysCheckedScriptLua::StateUnavailable>::value,
        "VM failure must bypass generic host-service exception translation");
    struct NativeNestedContext
    {
        State* state;
        unsigned calls = 0;
        bool innerUnusable = false;
        bool serviceContinued = false;
        unsigned luaContinued = 0;
        CysCheckedScriptLua::Census census;
    };
    NativeNestedContext* nativeNested = nullptr;
    int AfterPoison(lua_State*) { ++nativeNested->luaContinued; return 0; }
    void CloseWithNestedFailure(void* opaque,const std::string& name,bool immediate)
    {
        auto& context=*static_cast<NativeNestedContext*>(opaque);
        Check(name=="Owner" && immediate);++context.calls;
        const auto result=CysCheckedScriptLua::Execute(context.state->lua,context.state->active,
            "Inner_Env","ThrowNative()");
        context.innerUnusable=!result.stateUsable && !result.restored;
        char diagnostic[384]={};context.census.Record(result,"Inner_Env",diagnostic,sizeof(diagnostic));
        Check(!std::strstr(diagnostic,Canary));
        CysCheckedScriptLua::ThrowIfUnusable(result);
        context.serviceContinued=true;
    }
    void Register(State& state,const char* name,lua_CFunction fn)
    { lua_pushcfunction(state.raw(),fn); lua_setglobal(state.raw(),name); }
    int NativeChild()
    {
        State state;state.Setup();Register(state,"ThrowNative",ThrowNative);
        const auto result=CysCheckedScriptLua::Execute(state.lua,state.active,"Owner_Env","ThrowNative()");
        CysCheckedScriptLua::Census census;char text[384] = {};
        const bool observable=census.Record(result,"Owner_Env",text,sizeof(text));
        const bool okay=observable && !result.stateUsable && !result.restored &&
            result.status==CysCheckedScriptLua::CppException && result.phase==CysCheckedScriptLua::Phase::ExpressionCall &&
            state.active=="Owner_Env" && census.unusable==1 && std::strstr(text,Canary)==nullptr;
        std::printf("%s\nNATIVE no_vm_reentry=1 passed=%d\n",text,okay?1:0);std::fflush(stdout);
        // Native unwind poisoned this legacy VM: do not even run its destructor.
        ExitProcess(okay?0:1);
    }
    int NativeNestedChild()
    {
        State state;state.Setup();Register(state,"ThrowNative",ThrowNative);Register(state,"AfterPoison",AfterPoison);
        NativeNestedContext context{&state};nativeNested=&context;
        {
            CysHostGlobals::Services services;services.context=&context;services.closeWindow=CloseWithNestedFailure;
            auto globals=state.lua->GetGlobals();CysHostGlobals::Register(globals,services);
        }
        bool outerUnusable=false,mainLoopRethrew=false,topCaught=false;
        try
        {
            try
            {
                const auto result=CysCheckedScriptLua::Execute(state.lua,state.active,"Owner_Env",
                    "CloseWindow('Owner',true); AfterPoison()");
                outerUnusable=!result.stateUsable && !result.restored && result.status==CysCheckedScriptLua::CppException;
                char diagnostic[384]={};context.census.Record(result,"Owner_Env",diagnostic,sizeof(diagnostic));
                Check(!std::strstr(diagnostic,Canary));
                CysCheckedScriptLua::ThrowIfUnusable(result);
            }
            catch (...)
            {
                // The production MainLoop boundary logs metadata then rethrows.
                mainLoopRethrew=true;throw;
            }
        }
        catch (const CysCheckedScriptLua::StateUnavailable&)
        { topCaught=true; }
        catch (...) {}
        const bool okay=context.calls==1 && context.innerUnusable && !context.serviceContinued &&
            context.luaContinued==0 && outerUnusable && mainLoopRethrew && topCaught &&
            context.census.failures==2 && context.census.unusable==2 && state.active=="Inner_Env";
        std::printf("NESTED actual_CloseWindow=1 inner_unusable=%d outer_unusable=%d service_continued=%d lua_continued=%u mainloop_rethrow=%d top_signal=%d no_vm_reentry=1 passed=%d\n",
            context.innerUnusable?1:0,outerUnusable?1:0,context.serviceContinued?1:0,context.luaContinued,mainLoopRethrew?1:0,topCaught?1:0,okay?1:0);
        std::fflush(stdout);ExitProcess(okay?0:1);
    }
}

int main(int argc,char** argv)
{
    if(argc==2 && std::strcmp(argv[1],"--native-child")==0) return NativeChild();
    if(argc==2 && std::strcmp(argv[1],"--native-nested-child")==0) return NativeNestedChild();
    Test("success_discards_returns_restores_stack_and_metatable",[] {
        State s;s.Setup();s.Sentinel();
        auto r=CysCheckedScriptLua::Execute(s.lua,s.active,"Owner_Env","observed=marker; return 1,2,3");
        Check(r.ok() && r.restored && s.Number("observed")==22);s.Restored();
        CysCheckedScriptLua::Census census;char text[384]={};
        Check(!census.Record(r,"Owner_Env",text,sizeof(text)) && census.calls==1 && census.failures==0 && text[0]==0);
    });
    Test("syntax_error_is_observable_without_expression_or_error_text",[] {
        State s;s.Setup();s.Sentinel();
        auto r=CysCheckedScriptLua::Execute(s.lua,s.active,"Owner_Env","local = DIAGNOSTIC_CANARY_7X");
        Check(!r.ok() && r.status>0 && r.phase==CysCheckedScriptLua::Phase::ExpressionLoad && r.restored);s.Restored();
        CysCheckedScriptLua::Census census;char text[384]={};
        Check(census.Record(r,"Owner_Env",text,sizeof(text)) && census.calls==1 && census.failures==1 &&
            std::strstr(text,"CYS Lua failure") && !std::strstr(text,Canary) && !std::strstr(text,"local ="));
    });
    Test("missing_native_method_stops_hide_and_reports_lua_failure",[] {
        State s;s.Setup();s.Sentinel();
        s.Run("window={Hide=function() hidden=true end}; hidden=false");
        auto r=CysCheckedScriptLua::Execute(s.lua,s.active,"Owner_Env","window:FlashMe(); window:Hide()");
        Check(!r.ok() && r.status>0 && r.phase==CysCheckedScriptLua::Phase::ExpressionCall && !s.Boolean("hidden"));s.Restored();
        CysCheckedScriptLua::Census census;char text[384]={};
        Check(census.Record(r,"Owner_Env",text,sizeof(text)) && !std::strstr(text,"FlashMe") && !std::strstr(text,"Hide"));
    });
    Test("runtime_error_restores_and_next_dispatch_succeeds",[] {
        State s;s.Setup();s.Sentinel();
        auto r=CysCheckedScriptLua::Execute(s.lua,s.active,"Owner_Env","error('DIAGNOSTIC_CANARY_7X')");
        Check(!r.ok() && r.restored);s.Restored();
        r=CysCheckedScriptLua::Execute(s.lua,s.active,"Owner_Env","observed=marker");
        Check(r.ok() && s.Number("observed")==22);s.Restored();
    });
    Test("empty_previous_name_restores_luaplus_default_metatable",[] {
        // This LuaPlus fork maps nil to defaultmeta and getmetatable always returns it.
        State s;s.active.clear();s.Run("Owner_Env={}; setmetatable(_G,nil); oldmeta=getmetatable(_G)");s.Sentinel();
        auto r=CysCheckedScriptLua::Execute(s.lua,s.active,"Owner_Env","error('fixture')");
        Check(!r.ok() && r.restored && s.active.empty() && lua_gettop(s.raw())==1 && s.OldMetatable());
    });
    Test("empty_previous_name_restores_existing_metatable",[] {
        State s;s.Setup();s.active.clear();s.Sentinel();
        auto r=CysCheckedScriptLua::Execute(s.lua,s.active,"Owner_Env","observed=marker");
        Check(r.ok() && r.restored && s.active.empty() && s.OldMetatable() && lua_gettop(s.raw())==1);
    });
    Test("same_environment_preserves_original_metatable_identity",[] {
        State s;s.Setup();s.active="Owner_Env";s.Run("oldmeta.__index=Owner_Env");s.Sentinel();
        auto r=CysCheckedScriptLua::Execute(s.lua,s.active,"Owner_Env","observed=marker");
        Check(r.ok() && r.restored && s.active=="Owner_Env" && s.OldMetatable() && lua_gettop(s.raw())==1);
    });
    Test("failed_select_after_mutation_restores_without_lua_restore_call",[] {
        State s;s.Setup();s.Sentinel();
        s.Run("originalSet=setmetatable; setmetatable=function(t,m) originalSet(t,m); error('DIAGNOSTIC_CANARY_7X') end");
        auto r=CysCheckedScriptLua::Execute(s.lua,s.active,"Owner_Env","executed=true");
        Check(!r.ok() && r.restored && r.phase==CysCheckedScriptLua::Phase::SelectCall && !s.Boolean("executed"));s.Restored();
    });
    Test("expression_replaces_setmetatable_but_restore_uses_c_api",[] {
        State s;s.Setup();s.Sentinel();
        auto r=CysCheckedScriptLua::Execute(s.lua,s.active,"Owner_Env","setmetatable=function() error('blocked') end; error('fixture')");
        Check(!r.ok() && r.restored);s.Restored();
    });
    for(unsigned mode=0;mode!=3;++mode)
        Test(mode==0?"nested_success_restores_both_frames":mode==1?"nested_error_observable_outer_continues":"nested_error_then_outer_error_restores_both",[mode] {
            State s;s.Setup();s.Sentinel();NestedContext context{&s};context.innerFails=mode!=0;nested=&context;Register(s,"Nested",Nested);
            auto r=CysCheckedScriptLua::Execute(s.lua,s.active,"Owner_Env",mode==2?"Nested(); error('outer')":"Nested(); outerObserved=marker");
            nested=nullptr;Check(context.observed && r.restored && r.ok()==(mode!=2) && context.census.failures==(mode!=0?1U:0U) && s.Number("innerObserved")==33);s.Restored();
            if(mode!=2) Check(s.Number("outerObserved")==22);
        });
    Test("owner_destroyed_during_callback_no_borrowed_name_after_dispatch",[] {
        State s;s.Setup();s.Sentinel();owner.reset(new std::string("Owner_Env"));Register(s,"DestroyOwner",DestroyOwner);
        auto r=CysCheckedScriptLua::Execute(s.lua,s.active,*owner,"DestroyOwner(); observed=marker");
        Check(r.ok() && !owner && s.Number("observed")==22);s.Restored();
    });
    Test("previous_metatable_rooted_across_collection",[] {
        State s;s.Run("Old_Env={marker=11}; Owner_Env={}; weak=setmetatable({},{__mode='v'}); do local m={__index=Old_Env}; weak[1]=m; setmetatable(_G,m) end");s.Sentinel();
        auto r=CysCheckedScriptLua::Execute(s.lua,s.active,"Owner_Env","collectgarbage(); oldAlive=weak[1]~=nil");
        Check(r.ok() && s.Boolean("oldAlive") && s.active=="Old_Env" && s.Number("marker")==11 && lua_gettop(s.raw())==1);
    });
    Test("invalid_owner_filtered_and_null_expression_never_runs",[] {
        State s;s.Setup();s.Sentinel();
        auto r=CysCheckedScriptLua::Execute(s.lua,s.active,"bad\nDIAGNOSTIC_CANARY_7X",nullptr);
        Check(!r.ok() && r.stateUsable && r.status==CysCheckedScriptLua::InvalidInput);s.Restored();
        CysCheckedScriptLua::Census census;char text[384]={};
        Check(census.Record(r,"bad\nDIAGNOSTIC_CANARY_7X",text,sizeof(text)) && std::strstr(text,"env=invalid") && !std::strstr(text,Canary));
    });
    Test("missing_state_and_bounded_census_sink",[] {
        std::string active="Old_Env";
        auto r=CysCheckedScriptLua::Execute(nullptr,active,"Owner_Env","unused");
        Check(!r.ok() && !r.stateUsable && r.status==CysCheckedScriptLua::MissingState && active=="Old_Env");
        CysCheckedScriptLua::Census census;char tiny[1]={'x'};
        Check(census.Record(r,"Owner_Env",tiny,sizeof(tiny)) && tiny[0]==0 && census.unusable==1);
        Check(census.Record(r,"Owner_Env",nullptr,0) && census.failures==2);
    });
    std::printf("SUMMARY passed=%u failed=%u\n",passed,failed);
    return failed?1:0;
}
