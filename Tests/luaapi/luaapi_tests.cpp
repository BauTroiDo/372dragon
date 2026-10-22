// Offline Lua 5.0.1/LuaPlus regression tests for generated host registrations.
#include "LuaApiGen.h"
#include "CysHostGlobals.h"
#include "../../Src/Client/CEGUISystem/CysUiDictionary.h"
#ifdef GetMessage
#undef GetMessage // Windows dictionary conversion headers must not rename LuaException::GetMessage.
#endif

#include <cstdio>
#include <cstring>
#include <exception>
#include <fstream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <vector>

namespace
{
    std::vector<std::string> lines;
    unsigned int passed = 0;
    unsigned int failed = 0;

    void Capture(const char* line) { lines.push_back(line ? line : ""); }
    void Require(bool condition, const char* message)
    {
        if (!condition) throw std::runtime_error(message);
    }
    void Lua(LuaPlus::LuaState* state, const char* code)
    {
        const int top = lua_gettop(state->GetCState());
        int rc = state->DoString(code);
        if (rc != 0)
        {
            const char* message = lua_tostring(state->GetCState(), -1);
            throw std::runtime_error(message ? message : "Lua returned nonzero");
        }
        Require(lua_gettop(state->GetCState()) == top, "Lua snippet leaked stack entries");
    }
    struct State
    {
        LuaPlus::LuaState* p;
        State() : p(LuaPlus::LuaState::Create(true))
        {
            Require(p != 0, "LuaState::Create failed");
            LuaApiGen::ResetMissingCallCounts();
            lines.clear();
            LuaApiGen::SetLogSink(Capture);
        }
        ~State() { LuaPlus::LuaState::Destroy(p); }
    };

    template<class F> void Test(const char* name, F run)
    {
        std::printf("RUN %s\n", name);
        try { run(); ++passed; std::printf("PASS %s\n", name); }
        catch (const LuaPlus::LuaException& e)
        { ++failed; std::printf("FAIL %s: %s\n", name, e.GetMessage()); }
        catch (const std::exception& e)
        { ++failed; std::printf("FAIL %s: %s\n", name, e.what()); }
        catch (...)
        { ++failed; std::printf("FAIL %s: unknown exception\n", name); }
    }

    int Neutral(LuaPlus::LuaState* state)
    { return LuaApiGen::Stub(state, "Harness", "Neutral", "nsbzto"); }
    int Empty(LuaPlus::LuaState* state)
    { return LuaApiGen::Stub(state, "Harness", "Empty", ""); }
    int Dynamic(LuaPlus::LuaState* state)
    {
        return LuaApiGen::Stub(state, "Harness", lua_tostring(state->GetCState(), 1), "");
    }
    int EchoA(LuaPlus::LuaState* state)
    { return LuaApiGen::Stub(state, "ReceiverA", "Echo", ""); }
    int EchoB(LuaPlus::LuaState* state)
    { return LuaApiGen::Stub(state, "ReceiverB", "Echo", ""); }
    void RegisterDynamic(LuaPlus::LuaState* state)
    {
        LuaPlus::LuaObject globals = state->GetGlobals();
        globals.Register("HarnessDynamic", Dynamic);
    }
    void Populate25(LuaPlus::LuaState* state)
    {
        RegisterDynamic(state);
        Lua(state, "for i=1,25 do for j=1,27-i do HarnessDynamic(string.format('fn%02d',i)) end end");
        Require(LuaApiGen::GetMissingCallCount() == 350, "25-function total must be 350");
        Require(LuaApiGen::GetMissingDistinctCount() == 25, "25-function distinct count");
        lines.clear();
    }
    void CheckDump(unsigned int limit, unsigned int shown)
    {
        LuaApiGen::DumpMissingCallCounts(limit);
        Require(lines.size() == shown + 2, "dump line count");
        const std::string header = "LuaApiGen missing calls begin total=350 distinct=25 shown=" + std::to_string(shown);
        Require(lines.front() == header, "dump header");
        Require(lines.back() == "LuaApiGen missing calls end", "dump footer");
        for (unsigned int i = 0; i < shown; ++i)
        {
            char wanted[128];
            std::sprintf(wanted, "LuaApiGen missing calls item count=%u function=Harness:fn%02u", 26-i, i+1);
            Require(lines[i+1] == wanted, "dump ordering/count mismatch");
        }
        Require(LuaApiGen::GetMissingCallCount() == 350, "dump changed total");
        Require(LuaApiGen::GetMissingDistinctCount() == 25, "dump changed distinct");
    }

    struct Event
    {
        std::string name;
        std::vector<std::string> arguments;
    };
    struct ClosedWindow { std::string name; bool immediate; };
    struct ServiceTrace
    {
        std::vector<Event> events;
        std::vector<ClosedWindow> closed;
        bool windowBlocked = false;
        unsigned gateCalls = 0;
        std::map<std::string, std::string> dictionary;
        std::vector<std::string> dictionaryKeys, stripInputs;
        bool replaceStripped = false;
        std::string strippedResult;
    };
    void Emit(void* context, const std::string& name, const std::vector<std::string>& arguments)
    { static_cast<ServiceTrace*>(context)->events.push_back({name, arguments}); }
    void Close(void* context, const std::string& name, bool immediate)
    { static_cast<ServiceTrace*>(context)->closed.push_back({name, immediate}); }
    void ThrowEmit(void*, const std::string&, const std::vector<std::string>&)
    { throw std::runtime_error("event test failure"); }
    void ThrowClose(void*, const std::string&, bool)
    { throw LuaPlus::LuaException("window test failure"); }
    bool WindowBlocked(void* context)
    { auto& trace = *static_cast<ServiceTrace*>(context); ++trace.gateCalls; return trace.windowBlocked; }
    bool ThrowGate(void*) { throw std::runtime_error("gate test failure"); }
    std::string DictionaryText(void* context, const std::string& key)
    {
        auto& trace = *static_cast<ServiceTrace*>(context);
        trace.dictionaryKeys.push_back(key);
        const auto entry = trace.dictionary.find(key);
        return entry == trace.dictionary.end() ? std::string() : entry->second;
    }
    std::string StripTextColour(void* context, const std::string& text)
    {
        auto& trace = *static_cast<ServiceTrace*>(context);
        trace.stripInputs.push_back(text);
        return trace.replaceStripped ? trace.strippedResult : text;
    }
    std::string ThrowDictionary(void*, const std::string&) { throw std::runtime_error("dictionary test failure"); }
    std::string ThrowColour(void*, const std::string&) { throw LuaPlus::LuaException("colour test failure"); }
    void CreateTalk(LuaPlus::LuaState* state, void* context)
    {
        auto globals = state->GetGlobals();
        auto meta = globals.CreateTable("TestTalkMeta"); meta.SetObject("__index", meta);
        LuaPlus::LuaObject receiver = state->BoxPointer(context);
        receiver.SetMetaTable(meta); globals.SetObject("Talk", receiver);
    }
    CysHostGlobals::Services Services(ServiceTrace& trace)
    {
        CysHostGlobals::Services result;
        result.context = &trace;
        result.pushEvent = Emit;
        result.closeWindow = Close;
        result.openWindowBlocked = WindowBlocked;
        result.dictionaryText = DictionaryText;
        result.stripTextColour = StripTextColour;
        return result;
    }
    unsigned RegisterReal(LuaPlus::LuaState* state, ServiceTrace& trace)
    {
        LuaPlus::LuaObject globals = state->GetGlobals();
        return CysHostGlobals::Register(globals, Services(trace));
    }
}

int main(int argc, char** argv)
{
    setvbuf(stdout, nullptr, _IONBF, 0);
    Test("registration_does_not_count_calls", [] {
        State s;
        LuaApiGen::RegisterAll(s.p);
        Require(LuaApiGen::GetMissingCallCount() == 0, "registration counted calls");
        Require(LuaApiGen::GetMissingDistinctCount() == 0, "registration counted distinct");
        Require(lines.empty(), "registration logged missing calls");
    });
    Test("registered_stubs_count_every_call_log_first_once", [] {
        State s;
        LuaApiGen::RegisterAll(s.p);
        Lua(s.p, "for i=1,3 do assert(ScriptGlobal_Format('%s','x')=='') end "
                 "for i=1,2 do PushEvent('test'); CloseWindow('test') end");
        Require(LuaApiGen::GetMissingCallCount() == 7, "total expected 7");
        Require(LuaApiGen::GetMissingDistinctCount() == 3, "distinct expected 3");
        Require(LuaApiGen::GetMissingCallCountFor("_G", "ScriptGlobal_Format") == 3, "format count expected 3");
        Require(LuaApiGen::GetMissingCallCountFor("_G", "PushEvent") == 2, "event count expected 2");
        Require(LuaApiGen::GetMissingCallCountFor("_G", "CloseWindow") == 2, "close count expected 2");
        Require(lines.size() == 3, "first-call log expected exactly 3 lines");
        Require(lines[0] == "missing host function _G:ScriptGlobal_Format", "first-call format line");
        Require(lines[1] == "missing host function _G:PushEvent", "first-call event line");
        Require(lines[2] == "missing host function _G:CloseWindow", "first-call close line");
    });
    Test("rank_by_count_then_function_name", [] {
        State s;
        LuaApiGen::RegisterAll(s.p);
        Lua(s.p, "for i=1,2 do PushEvent('test'); CloseWindow('test') end "
                 "for i=1,3 do ScriptGlobal_Format('%s','x') end");
        lines.clear();
        LuaApiGen::DumpMissingCallCounts();
        Require(lines.size() == 5, "rank log size");
        Require(lines[0] == "LuaApiGen missing calls begin total=7 distinct=3 shown=3", "rank header");
        Require(lines[1] == "LuaApiGen missing calls item count=3 function=_G:ScriptGlobal_Format", "rank top");
        Require(lines[2] == "LuaApiGen missing calls item count=2 function=_G:CloseWindow", "tie lexical first");
        Require(lines[3] == "LuaApiGen missing calls item count=2 function=_G:PushEvent", "tie lexical second");
    });
    Test("receiver_names_are_independent", [] {
        State s;
        LuaPlus::LuaObject globals = s.p->GetGlobals();
        globals.Register("EchoA", EchoA);
        globals.Register("EchoB", EchoB);
        Lua(s.p, "EchoA(); EchoB(); EchoB()");
        Require(LuaApiGen::GetMissingCallCountFor("ReceiverA", "Echo") == 1, "receiver A count");
        Require(LuaApiGen::GetMissingCallCountFor("ReceiverB", "Echo") == 2, "receiver B count");
        Require(LuaApiGen::GetMissingDistinctCount() == 2, "receiver distinct");
    });
    Test("queries_missing_or_null_do_not_mutate", [] {
        State s;
        Require(LuaApiGen::GetMissingCallCountFor("absent", "absent") == 0, "missing query");
        Require(LuaApiGen::GetMissingCallCountFor(0, "absent") == 0, "null receiver query");
        Require(LuaApiGen::GetMissingCallCountFor("absent", 0) == 0, "null name query");
        Require(LuaApiGen::GetMissingDistinctCount() == 0, "query inserted entry");
        Require(LuaApiGen::GetMissingCallCount() == 0 && lines.empty(), "query side effects");
    });
    Test("all_neutral_return_kinds_and_null_object", [] {
        State s;
        LuaApiGen::RegisterAll(s.p);
        LuaPlus::LuaObject globals = s.p->GetGlobals();
        globals.Register("HarnessNeutral", Neutral);
        Lua(s.p, "local n,s,b,z,t,o=HarnessNeutral(); assert(n==0 and s=='' and b==false and z==nil); "
                 "assert(type(t)=='table' and next(t)==nil); assert(type(o)=='table'); "
                 "assert(o:UnknownMethod()==nil)");
        Require(LuaApiGen::GetMissingCallCount() == 1, "neutral/null-object count");
    });
    Test("empty_return_has_zero_values", [] {
        State s;
        LuaPlus::LuaObject globals = s.p->GetGlobals();
        globals.Register("HarnessEmpty", Empty);
        Lua(s.p, "function CountReturns(...) return arg.n end; assert(CountReturns(HarnessEmpty())==0)");
        Require(LuaApiGen::GetMissingCallCount() == 1, "empty count");
    });
    Test("dump_default_top20", [] {
        State s; Populate25(s.p);
        LuaApiGen::DumpMissingCallCounts();
        Require(lines.size() == 22, "default limit must be 20");
        Require(lines[0] == "LuaApiGen missing calls begin total=350 distinct=25 shown=20", "default header");
        lines.clear(); CheckDump(20, 20);
    });
    Test("dump_explicit_top3", [] { State s; Populate25(s.p); CheckDump(3, 3); });
    // CYS-TESTRED 19/09: limit 0 means "rank EVERY stub", not "rank none". The production contract lives in
    // LuaApiGen_Common.cpp:88 (CYS-HOST2) and the shutdown snapshot GameProcedure.cpp:866 calls
    // DumpMissingCallCounts(0) precisely to get the full list (20 truncated 77 of 114 functions in a real
    // session). The old expectation here was CheckDump(0, 0) - the pre-CYS-HOST2 contract - so this case went
    // red the day the meaning changed and stayed red because the suite had no caller. Both halves below matter:
    // "0 lists all 25" AND "0 is not a synonym for the default 20", so a regression in either direction is caught.
    Test("dump_zero_limit_lists_every_stub", [] {
        State s; Populate25(s.p);
        CheckDump(0, 25);
        lines.clear();
        LuaApiGen::DumpMissingCallCounts(20);
        Require(lines.size() == 22, "limit 0 must not behave like the default limit 20");
        Require(lines.front() == "LuaApiGen missing calls begin total=350 distinct=25 shown=20", "default limit header");
    });
    Test("dump_limit_exceeds_distinct", [] { State s; Populate25(s.p); CheckDump(100, 25); });
    Test("dump_empty_session", [] {
        State s; LuaApiGen::DumpMissingCallCounts();
        Require(lines.size() == 2, "empty dump lines");
        Require(lines[0] == "LuaApiGen missing calls begin total=0 distinct=0 shown=0", "empty dump header");
        Require(lines[1] == "LuaApiGen missing calls end", "empty dump footer");
    });
    Test("reset_counters_and_first_call_logging", [] {
        State s; LuaApiGen::RegisterAll(s.p);
        Lua(s.p, "PushEvent('test'); PushEvent('test')");
        LuaApiGen::ResetMissingCallCounts(); lines.clear();
        Require(LuaApiGen::GetMissingCallCount() == 0, "reset total");
        Require(LuaApiGen::GetMissingDistinctCount() == 0, "reset distinct");
        Require(LuaApiGen::GetMissingCallCountFor("_G", "PushEvent") == 0, "reset per-function");
        Lua(s.p, "PushEvent('test'); PushEvent('test')");
        Require(LuaApiGen::GetMissingCallCount() == 2, "post-reset total");
        Require(lines.size() == 1 && lines[0] == "missing host function _G:PushEvent", "post-reset log once");
    });
    Test("register_all_keeps_existing_function_and_non_function", [] {
        State s;
        Lua(s.p, "function CloseWindow(name) return 'real:'..name end; existingClose=CloseWindow; PushEvent=17");
        LuaApiGen::RegisterAll(s.p);
        LuaApiGen::RegisterAll(s.p);
        Lua(s.p, "assert(CloseWindow==existingClose); assert(CloseWindow('sample')=='real:sample'); assert(PushEvent==17)");
        Require(LuaApiGen::GetMissingCallCount() == 0 && lines.empty(), "existing functions became stubs");
    });
    Test("register_all_keeps_existing_receiver_metatable_function", [] {
        State s;
        Lua(s.p, "RealMeta={}; RealMeta.__index=RealMeta; "
                 "function RealMeta:GetItemTableIndex(slot) return slot+1000 end; "
                 "PlayerPackage={}; setmetatable(PlayerPackage,RealMeta)");
        LuaApiGen::RegisterAll(s.p);
        Lua(s.p, "assert(PlayerPackage:GetItemTableIndex(8)==1008)");
        Require(LuaApiGen::GetMissingCallCount() == 0, "existing receiver function became stub");
    });


    Test("host_format_exact_b_byte_vector_and_numeric_conversion", [] {
        State s; ServiceTrace trace; RegisterReal(s.p, trace);
        Lua(s.p, "assert(ScriptGlobal_Format('#{K}','Q')==string.char(35,123,75,42,1,6,42,1,81,125)); "
                 "assert(ScriptGlobal_Format('#{K}',123)=='#{K'..string.char(42,1,8,42,3)..'123}'); "
                 "assert(ScriptGlobal_Format('AB',7)=='A'..string.char(42,1,6,42,1)..'7}')");
        Require(trace.events.empty() && trace.closed.empty(), "format unexpected side effect");
        std::printf("FORMAT_VECTOR input=synthetic expected=237B4B2A01062A01517D actual_match=true\n");
    });
    Test("host_format_keeps_utf8_and_placeholders_as_opaque_bytes", [] {
        State s; ServiceTrace trace; RegisterReal(s.p, trace);
        Lua(s.p, "local text=string.char(225,187,135); "
                 "assert(ScriptGlobal_Format('#{K}',text)=='#{K'..string.char(42,1,8,42,3)..text..'}'); "
                 "assert(ScriptGlobal_Format('#{%s0}','%s9')=='#{%s0'..string.char(42,1,8,42,3)..'%s9}')");
    });
    Test("host_format_c_string_inputs_stop_at_embedded_null", [] {
        State s; ServiceTrace trace; RegisterReal(s.p, trace);
        Lua(s.p, "assert(ScriptGlobal_Format('#{K}'..string.char(0)..'ignored','Q'..string.char(0)..'ignored')=="
                 "string.char(35,123,75,42,1,6,42,1,81,125))");
    });
    Test("host_format_c_string_result_stops_at_zero_metadata", [] {
        State s; ServiceTrace trace; RegisterReal(s.p, trace);
        Lua(s.p, "local empty=string.char(35,123,75,42,1,5,42); "
                 "assert(ScriptGlobal_Format('#{K}','')==empty); "
                 "assert(ScriptGlobal_Format('#{K}',string.rep('Q',256))==empty); "
                 "assert(ScriptGlobal_Format('#{K}',string.rep('Q',251))==string.char(35,123,75,42,1))");
    });
    Test("host_format_padding_only_when_argument_block_is_56_bytes", [] {
        State s; ServiceTrace trace; RegisterReal(s.p, trace);
        Lua(s.p, "assert(ScriptGlobal_Format('#{K}',string.rep('Q',53))=='#{K'..string.char(42,1,58,42,53)..string.rep('Q',53)..'}'); "
                 "assert(ScriptGlobal_Format('#{K}',string.rep('Q',54))=='#{K'..string.char(42,1,60,42,54)..string.rep('Q',54)..' }'); "
                 "assert(ScriptGlobal_Format('#{K}',string.rep('Q',55))=='#{K'..string.char(42,1,60,42,55)..string.rep('Q',55)..'}')");
    });
    Test("host_format_1024_byte_capacity_rejects_overflow_and_empty_template", [] {
        State s; ServiceTrace trace; RegisterReal(s.p, trace);
        Lua(s.p, "local packed=ScriptGlobal_Format('#{K}',string.rep('Q',1014)); "
                 "assert(packed=='#{K'..string.char(42,1,251,42,246)..string.rep('Q',1014)..'}'); "
                 "assert(string.len(packed)==1023); "
                 "local ok,err=pcall(ScriptGlobal_Format,'#{K}',string.rep('Q',1015)); assert(not ok and type(err)=='string'); "
                 "ok,err=pcall(ScriptGlobal_Format,'','Q'); assert(not ok and type(err)=='string'); "
                 "ok,err=pcall(ScriptGlobal_Format,string.char(0)..'ignored','Q'); assert(not ok and type(err)=='string')");
    });
    Test("host_format_without_arguments_emits_debug_event_zero_returns", [] {
        State s; ServiceTrace trace; RegisterReal(s.p, trace);
        Lua(s.p, "function CountReturns(...) return arg.n end; assert(CountReturns(ScriptGlobal_Format('literal'))==0); "
                 "assert(CountReturns(ScriptGlobal_Format(''))==0)");
        Require(trace.events.size() == 2 && trace.events[0].name == "NEW_DEBUGMESSAGE", "debug event name");
        Require(trace.events[0].arguments.size() == 1 && trace.events[0].arguments[0] == "literal", "debug event content");
        Require(trace.events[1].name == "NEW_DEBUGMESSAGE" && trace.events[1].arguments.size() == 1 && trace.events[1].arguments[0].empty(), "empty debug event content");
    });
    Test("host_format_accepts_15_arguments_rejects_invalid_inputs", [] {
        State s; ServiceTrace trace; RegisterReal(s.p, trace);
        Lua(s.p, "assert(ScriptGlobal_Format('#{K}','Q','Q','Q','Q','Q','Q','Q','Q','Q','Q','Q','Q','Q','Q','Q')=="
                 "'#{K'..string.char(42,15,48)..string.rep(string.char(42,1)..'Q',15)..'}'); "
                 "local ok,err=pcall(ScriptGlobal_Format,'#{K}',0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15); "
                 "assert(not ok and string.find(err,'at most 15',1,true)); "
                 "ok,err=pcall(ScriptGlobal_Format,'#{K}',{}); assert(not ok and string.find(err,'string or number',1,true)); "
                 "ok,err=pcall(ScriptGlobal_Format); assert(not ok and string.find(err,'expected a string template',1,true))");
    });
    Test("host_event_argument_conversion_stops_at_nil_or_unsupported", [] {
        State s; ServiceTrace trace; RegisterReal(s.p, trace);
        Lua(s.p, "function CountReturns(...) return arg.n end; "
                 "assert(CountReturns(PushEvent('FIRST','text',12,nil,'ignored'))==0); "
                 "PushEvent('SECOND',3,true,'ignored'); PushEvent('EMPTY'); "
                 "local ok,err=pcall(PushEvent,{}); assert(not ok and string.find(err,'expected an event name',1,true))");
        Require(trace.events.size() == 3, "event callback count");
        Require(trace.events[0].name == "FIRST" && trace.events[0].arguments.size() == 2, "nil stop");
        Require(trace.events[0].arguments[0] == "text" && trace.events[0].arguments[1] == "12", "numeric conversion");
        Require(trace.events[1].name == "SECOND" && trace.events[1].arguments.size() == 1 && trace.events[1].arguments[0] == "3", "unsupported stop");
        Require(trace.events[2].name == "EMPTY" && trace.events[2].arguments.empty(), "empty event");
    });
    Test("host_close_boolean_is_strict_and_returns_nothing", [] {
        State s; ServiceTrace trace; RegisterReal(s.p, trace);
        Lua(s.p, "function CountReturns(...) return arg.n end; assert(CountReturns(CloseWindow('one',true))==0); "
                 "CloseWindow('two',false); CloseWindow('three'); CloseWindow('four',1); CloseWindow('five','true'); "
                 "local ok,err=pcall(CloseWindow,{}); assert(not ok and string.find(err,'expected a window name',1,true))");
        Require(trace.closed.size() == 5 && trace.closed[0].name == "one" && trace.closed[0].immediate, "close true");
        for (size_t i=1; i<trace.closed.size(); ++i) Require(!trace.closed[i].immediate, "non-boolean true accepted");
    });
    Test("host_event_and_window_service_strings_stop_at_null", [] {
        State s; ServiceTrace trace; RegisterReal(s.p, trace);
        Lua(s.p, "local z=string.char(0); PushEvent('known'..z..'ignored','prefix'..z..'ignored'); "
                 "CloseWindow('window'..z..'ignored',true); ScriptGlobal_Format('debug'..z..'ignored')");
        Require(trace.events.size() == 2 && trace.events[0].name == "known", "event name C-string boundary");
        Require(trace.events[0].arguments.size() == 1 && trace.events[0].arguments[0] == "prefix", "event argument C-string boundary");
        Require(trace.events[1].name == "NEW_DEBUGMESSAGE" && trace.events[1].arguments[0] == "debug", "debug C-string boundary");
        Require(trace.closed.size() == 1 && trace.closed[0].name == "window" && trace.closed[0].immediate, "window name C-string boundary");
    });
    Test("host_registration_keeps_existing_and_generated_keeps_real", [] {
        State s; ServiceTrace trace;
        Lua(s.p, "function CloseWindow(name) return 'kept:'..name end; oldClose=CloseWindow; PushEvent=42");
        Require(RegisterReal(s.p, trace) == 5, "real registration must add only the five nil slots");
        Require(RegisterReal(s.p, trace) == 0, "second real registration must be empty");
        LuaApiGen::RegisterAll(s.p);
        Lua(s.p, "assert(CloseWindow==oldClose and CloseWindow('x')=='kept:x'); assert(PushEvent==42); "
                 "assert(ScriptGlobal_Format('#{K}','Q')==string.char(35,123,75,42,1,6,42,1,81,125))");
        Require(LuaApiGen::GetMissingCallCount() == 0, "generated stubs replaced real host");
        Require(trace.closed.empty() && trace.events.empty(), "existing host calls reached adapter");
    });
    Test("host_closures_keep_services_separate_between_states", [] {
        State a; State b; ServiceTrace first; ServiceTrace second;
        RegisterReal(a.p, first); RegisterReal(b.p, second);
        Lua(a.p, "PushEvent('A'); CloseWindow('A',true)");
        Lua(b.p, "PushEvent('B'); CloseWindow('B')");
        Require(first.events.size() == 1 && first.events[0].name == "A", "state A event service replaced");
        Require(second.events.size() == 1 && second.events[0].name == "B", "state B event service replaced");
        Require(first.closed.size() == 1 && first.closed[0].immediate, "state A close service replaced");
        Require(second.closed.size() == 1 && !second.closed[0].immediate, "state B close service replaced");
    });
    Test("host_unavailable_services_report_lua_errors", [] {
        State s;
        LuaPlus::LuaObject globals = s.p->GetGlobals();
        CysHostGlobals::Register(globals, CysHostGlobals::Services());
        Lua(s.p, "assert(ScriptGlobal_Format('#{K}','Q')==string.char(35,123,75,42,1,6,42,1,81,125)); "
                 "local ok,err=pcall(ScriptGlobal_Format,'debug'); assert(not ok and string.find(err,'event service is unavailable',1,true)); "
                 "ok,err=pcall(PushEvent,'event'); assert(not ok and string.find(err,'event service is unavailable',1,true)); "
                 "ok,err=pcall(CloseWindow,'window'); assert(not ok and string.find(err,'window service is unavailable',1,true))");
        Require(LuaApiGen::GetMissingCallCount() == 0, "real host errors counted as stub calls");
    });
    Test("host_callback_exceptions_become_catchable_lua_errors", [] {
        State s;
        LuaPlus::LuaObject globals = s.p->GetGlobals();
        CysHostGlobals::Services services;
        services.pushEvent = ThrowEmit;
        services.closeWindow = ThrowClose;
        CysHostGlobals::Register(globals, services);
        Lua(s.p, "assert(ScriptGlobal_Format('#{K}','Q')==string.char(35,123,75,42,1,6,42,1,81,125)); "
                 "local ok,err=pcall(ScriptGlobal_Format,'debug'); assert(not ok and string.find(err,'event test failure',1,true)); "
                 "ok,err=pcall(PushEvent,'event'); assert(not ok and string.find(err,'event test failure',1,true)); "
                 "ok,err=pcall(CloseWindow,'window'); assert(not ok and string.find(err,'window test failure',1,true)); "
                 "assert(1+1==2)");
        Require(LuaApiGen::GetMissingCallCount() == 0, "service exceptions counted as stub calls");
    });
    Test("same_lua_snippet_missing_calls_before_after_real_hosts", [] {
        const char* snippet = "formatted={}; for i=1,5 do formatted[i]=ScriptGlobal_Format('#{K}','hero',7); "
                              "PushEvent('UNIT_EVENT','hello',7); CloseWindow('Panel',true) end";
        unsigned int beforeCalls = 0, beforeLines = 0;
        {
            State before;
            LuaApiGen::RegisterAll(before.p);
            Lua(before.p, snippet);
            Lua(before.p, "for i=1,5 do assert(formatted[i]=='') end");
            beforeCalls = LuaApiGen::GetMissingCallCount();
            beforeLines = static_cast<unsigned int>(lines.size());
            Require(beforeCalls == 15 && beforeLines == 3, "baseline must call 3 generated stubs 5 times each");
            lines.clear(); LuaApiGen::DumpMissingCallCounts();
            for (const auto& line : lines) std::printf("BASELINE %s\n", line.c_str());
        }
        {
            State after; ServiceTrace trace;
            Require(RegisterReal(after.p, trace) == 7, "all seven real globals must register");
            LuaApiGen::RegisterAll(after.p);
            Lua(after.p, snippet);
            Lua(after.p, "for i=1,5 do assert(formatted[i]=='#{K'..string.char(42,2,12,42,4)..'hero'..string.char(42,1)..'7}') end");
            Require(LuaApiGen::GetMissingCallCount() == 0 && lines.empty(), "real hosts still hit generated stubs");
            Require(trace.events.size() == 5 && trace.closed.size() == 5, "real host side effects missing");
            std::printf("BEFORE_AFTER mode=offline_same_lua calls=%u->0 missing_log_lines=%u->0 lua_errors=0 functions=3 iterations=5 event_close_effects=10 format_outputs_checked=5\n", beforeCalls, beforeLines);
        }
    });
    Test("softkey_same_login_snippet_missing_two_to_zero_and_real_events", [] {
        const char* snippet = "SetSoftKeyAim('LogOn_ID'); SetSoftKeyAim('LogOn_PassWord')";
        {
            State before; LuaApiGen::RegisterAll(before.p); Lua(before.p, snippet);
            Require(LuaApiGen::GetMissingCallCountFor("_G", "SetSoftKeyAim")==2 && lines.size()==1, "baseline stub evidence");
        }
        State after; ServiceTrace trace; RegisterReal(after.p,trace); LuaApiGen::RegisterAll(after.p);
        Lua(after.p,snippet);
        Require(LuaApiGen::GetMissingCallCount()==0 && lines.empty(), "real softkey still counted missing");
        Require(trace.events.size()==2 && trace.events[0].name=="SET_SOFTKEY_AIM" && trace.events[1].name=="SET_SOFTKEY_AIM", "wrong event route");
        Require(trace.events[0].arguments==std::vector<std::string>{"LogOn_ID"} && trace.events[1].arguments==std::vector<std::string>{"LogOn_PassWord"}, "target order/content lost");
        std::printf("SOFTKEY_BEFORE_AFTER calls=2->0 missing_lines=1->0 target_events=0->2\n");
    });
    Test("softkey_returns_zero_values_and_ignores_extra_arguments", [] {
        State s; ServiceTrace trace; RegisterReal(s.p,trace);
        Lua(s.p,"function count(...) return arg.n end; assert(count(SetSoftKeyAim('box','unused'))==0)");
        Require(trace.events.size()==1 && trace.events[0].arguments==std::vector<std::string>{"box"}, "extra argument reached listener");
    });
    Test("softkey_keeps_utf8_target_bytes_without_normalizing", [] {
        State s; ServiceTrace trace; RegisterReal(s.p,trace);
        const char* target="\xe4\xb8\xad\xe1\xba\xbf";
        s.p->GetGlobals().SetString("target",target); Lua(s.p,"SetSoftKeyAim(target)");
        Require(trace.events.size()==1 && trace.events[0].arguments[0]==target,"UTF8 target changed");
    });
    Test("softkey_uses_existing_lua_cstring_boundary", [] {
        State s; ServiceTrace trace; RegisterReal(s.p,trace);
        Lua(s.p,"SetSoftKeyAim('box'..string.char(0)..'suffix'); SetSoftKeyAim(''); SetSoftKeyAim(123)");
        Require(trace.events.size()==3 && trace.events[0].arguments[0]=="box" && trace.events[1].arguments[0].empty() && trace.events[2].arguments[0]=="123","string conversion changed");
    });
    Test("softkey_invalid_types_raise_before_dispatch", [] {
        State s; ServiceTrace trace; RegisterReal(s.p,trace);
        Lua(s.p,"assert(not pcall(SetSoftKeyAim)); assert(not pcall(SetSoftKeyAim,nil)); assert(not pcall(SetSoftKeyAim,false)); assert(not pcall(SetSoftKeyAim,{})); assert(not pcall(SetSoftKeyAim,function() end))");
        Require(trace.events.empty(),"invalid target dispatched");
    });
    Test("softkey_missing_service_is_visible_lua_error", [] {
        State s; auto globals=s.p->GetGlobals(); CysHostGlobals::Register(globals,{});
        Lua(s.p,"local ok,err=pcall(SetSoftKeyAim,'box'); assert(not ok and string.find(err,'event service is unavailable',1,true))");
    });
    Test("softkey_service_exception_unwinds_and_vm_remains_usable", [] {
        State s; auto globals=s.p->GetGlobals(); CysHostGlobals::Services services; services.pushEvent=ThrowEmit; CysHostGlobals::Register(globals,services);
        Lua(s.p,"local ok,err=pcall(SetSoftKeyAim,'box'); assert(not ok and string.find(err,'event test failure',1,true)); assert(2+2==4)");
    });
    Test("softkey_keeps_existing_function_and_false_slots", [] {
        State s; ServiceTrace trace; Lua(s.p,"function SetSoftKeyAim(x) return 'kept:'..x end; saved=SetSoftKeyAim"); RegisterReal(s.p,trace); LuaApiGen::RegisterAll(s.p);
        Lua(s.p,"assert(SetSoftKeyAim==saved and SetSoftKeyAim('x')=='kept:x'); SetSoftKeyAim=false");
        RegisterReal(s.p,trace); LuaApiGen::RegisterAll(s.p); Lua(s.p,"assert(SetSoftKeyAim==false)"); Require(trace.events.empty(),"existing slot overwritten");
    });
    Test("softkey_context_is_per_lua_state", [] {
        State a; State b; ServiceTrace first; ServiceTrace second; RegisterReal(a.p,first); RegisterReal(b.p,second);
        Lua(a.p,"SetSoftKeyAim('A')"); Lua(b.p,"SetSoftKeyAim('B')");
        Require(first.events.size()==1 && first.events[0].arguments[0]=="A" && second.events.size()==1 && second.events[0].arguments[0]=="B", "context crossed states");
    });
    Test("toggle_real_event_missing_to_zero", [] {
        { State before; LuaApiGen::RegisterAll(before.p); Lua(before.p,"ToggleWindow('SoftKeyBoard')");
          Require(LuaApiGen::GetMissingCallCountFor("_G","ToggleWindow")==1,"missing baseline"); }
        ServiceTrace trace; State after; RegisterReal(after.p,trace); LuaApiGen::RegisterAll(after.p);
        Lua(after.p,"function count(...) return arg.n end; assert(count(ToggleWindow('SoftKeyBoard',42))==0)");
        Require(trace.events.size()==1 && trace.events[0].name=="TOGGLE_WINDOW" && trace.events[0].arguments==std::vector<std::string>{"SoftKeyBoard"},"wrong toggle event");
        Require(LuaApiGen::GetMissingCallCount()==0,"real toggle is missing");
    });
    Test("toggle_scene_gate_precedes_argument_validation", [] {
        ServiceTrace trace;trace.windowBlocked=true;State s;RegisterReal(s.p,trace);
        Lua(s.p,"ToggleWindow();ToggleWindow(false);ToggleWindow({})");
        Require(trace.gateCalls==3 && trace.events.empty(),"toggle gate bypassed");
        trace.windowBlocked=false;Lua(s.p,"assert(not pcall(ToggleWindow,false))");Require(trace.events.empty(),"invalid toggle dispatched");
    });
    Test("toggle_cstring_utf8_number_empty", [] {
        ServiceTrace trace;State s;RegisterReal(s.p,trace);const char* text="\xe4\xb8\xad\xe6\x96\x87";s.p->GetGlobals().SetString("label",text);
        Lua(s.p,"ToggleWindow('box'..string.char(0)..'suffix');ToggleWindow(123);ToggleWindow('');ToggleWindow(label)");
        Require(trace.events.size()==4 && trace.events[0].arguments[0]=="box" && trace.events[1].arguments[0]=="123" && trace.events[2].arguments[0].empty() && trace.events[3].arguments[0]==text,"toggle string boundary");
    });
    Test("toggle_missing_services_and_callback_failure", [] {
        // Every LuaObject must leave scope before its owning LuaState closes.
        {
            State s; auto globals=s.p->GetGlobals(); CysHostGlobals::Register(globals,{});
            Lua(s.p,"assert(not pcall(ToggleWindow,'box'))");
        }
        ServiceTrace trace;
        {
            State s; auto globals=s.p->GetGlobals(); auto api=Services(trace); api.pushEvent=nullptr;
            CysHostGlobals::Register(globals,api); Lua(s.p,"assert(not pcall(ToggleWindow,'box'))");
        }
        {
            State s; auto globals=s.p->GetGlobals(); auto api=Services(trace); api.pushEvent=ThrowEmit;
            CysHostGlobals::Register(globals,api); Lua(s.p,"assert(not pcall(ToggleWindow,'box'));assert(2+2==4)");
        }
    });
    Test("toggle_preserves_non_nil_registration", [] {
        for(const char* value:{"false","42","'kept'","function()return 9 end"}) {
            ServiceTrace trace;State s;Lua(s.p,(std::string("ToggleWindow=")+value+";saved=ToggleWindow").c_str());RegisterReal(s.p,trace);LuaApiGen::RegisterAll(s.p);Lua(s.p,"assert(ToggleWindow==saved)");
        }
    });
    Test("toggle_canonical_keyboard_script_shows_then_hides", [&] {
        Require(argc==2,"dictionary path needed for Canonical root");
        const std::string path=argv[1];const auto slash=path.find_last_of("/\\");Require(slash!=std::string::npos,"dictionary path has no parent");
        std::ifstream input(path.substr(0,slash+1)+"../InterfaceFolder/SoftKeyBoard/SoftKeyBoard.lua",std::ios::binary);Require(input.good(),"Canonical keyboard missing");
        const std::string code((std::istreambuf_iterator<char>(input)),std::istreambuf_iterator<char>());
        ServiceTrace trace;State s;RegisterReal(s.p,trace);
        Lua(s.p,"registered={};visible=false;shown=0;hidden=0;this={RegisterEvent=function(self,e)table.insert(registered,e)end,Show=function()visible=true;shown=shown+1 end,Hide=function()visible=false;hidden=hidden+1 end,IsVisible=function()return visible end};AxTrace=function()end");
        Lua(s.p,code.c_str());Lua(s.p,"SoftKeyBoard_PreLoad();assert(registered[3]=='TOGGLE_WINDOW');ToggleWindow('SoftKeyBoard');assert(not visible)");
        Require(trace.events.size()==1,"toggle did not enqueue");s.p->GetGlobals().SetString("arg0",trace.events[0].arguments[0].c_str());Lua(s.p,"SoftKeyBoard_OnEvent('TOGGLE_WINDOW');assert(visible and shown==1 and hidden==0);ToggleWindow('SoftKeyBoard');assert(visible)");
        Require(trace.events.size()==2,"second toggle did not enqueue");Lua(s.p,"SoftKeyBoard_OnEvent('TOGGLE_WINDOW');assert(not visible and shown==1 and hidden==1);arg0='Unrelated';SoftKeyBoard_OnEvent('TOGGLE_WINDOW');assert(not visible and hidden==1)");
    });
    Test("open_scene_gate_precedes_validation", [] {
        ServiceTrace trace; trace.windowBlocked=true; State s; RegisterReal(s.p,trace);
        Lua(s.p,"function count(...) return arg.n end; assert(count(OpenWindow())==0); OpenWindow(false); OpenWindow({})");
        Require(trace.gateCalls==3 && trace.events.empty(), "gate bypassed");
        trace.windowBlocked=false; Lua(s.p,"assert(not pcall(OpenWindow,false))"); Require(trace.events.empty(), "invalid dispatched");
    });
    Test("open_real_event_returns_zero_and_ignores_extras", [] {
        ServiceTrace trace; State s; RegisterReal(s.p,trace); LuaApiGen::RegisterAll(s.p);
        Lua(s.p,"function count(...) return arg.n end; assert(count(OpenWindow('Notice',9))==0)");
        Require(trace.events.size()==1 && trace.events[0].name=="OPEN_WINDOW" && trace.events[0].arguments==std::vector<std::string>{"Notice"}, "wrong event");
        Require(LuaApiGen::GetMissingCallCount()==0,"missing count");
    });
    Test("open_cstring_number_utf8_empty", [] {
        ServiceTrace trace; State s; RegisterReal(s.p,trace); const char* text="\xe4\xb8\xad\xe6\x96\x87";
        s.p->GetGlobals().SetString("label",text);
        Lua(s.p,"OpenWindow('box'..string.char(0)..'suffix'); OpenWindow(123); OpenWindow(''); OpenWindow(label)");
        Require(trace.events.size()==4 && trace.events[0].arguments[0]=="box" && trace.events[1].arguments[0]=="123" && trace.events[2].arguments[0].empty() && trace.events[3].arguments[0]==text,"boundary");
    });
    Test("open_missing_scene_and_event_service_errors", [] {
        State s; auto globals=s.p->GetGlobals(); CysHostGlobals::Services service; CysHostGlobals::Register(globals,service);
        Lua(s.p,"local ok,e=pcall(OpenWindow,'box'); assert(not ok and string.find(e,'scene service is unavailable',1,true))");
        ServiceTrace trace; State t; service.context=&trace; service.openWindowBlocked=WindowBlocked; globals=t.p->GetGlobals(); CysHostGlobals::Register(globals,service);
        Lua(t.p,"local ok,e=pcall(OpenWindow,'box'); assert(not ok and string.find(e,'event service is unavailable',1,true))");
    });
    Test("open_gate_and_event_exceptions_unwind", [] {
        ServiceTrace trace; State s; auto globals=s.p->GetGlobals(); auto service=Services(trace); service.openWindowBlocked=ThrowGate; CysHostGlobals::Register(globals,service);
        Lua(s.p,"local ok,e=pcall(OpenWindow,'box'); assert(not ok and string.find(e,'gate test failure',1,true)); assert(2+2==4)");
        State t; globals=t.p->GetGlobals(); service=Services(trace); service.pushEvent=ThrowEmit; CysHostGlobals::Register(globals,service);
        Lua(t.p,"local ok,e=pcall(OpenWindow,'box'); assert(not ok and string.find(e,'event test failure',1,true)); assert(2+2==4)");
    });
    Test("open_keeps_non_nil_slots", [] {
        for (const char* value : {"false", "42", "'kept'", "function() return 9 end"}) {
            ServiceTrace trace; State s; Lua(s.p,(std::string("OpenWindow=")+value+"; saved=OpenWindow").c_str());
            RegisterReal(s.p,trace); LuaApiGen::RegisterAll(s.p); Lua(s.p,"assert(OpenWindow==saved)");
        }
    });
    Test("open_state_context_and_descriptor_copy", [] {
        ServiceTrace a,b; a.windowBlocked=true; State sa,sb; auto globals=sa.p->GetGlobals(); auto service=Services(a); CysHostGlobals::Register(globals,service);
        service=Services(b); globals=sb.p->GetGlobals(); CysHostGlobals::Register(globals,service);
        Lua(sa.p,"OpenWindow('A')"); Lua(sb.p,"OpenWindow('B')");
        Require(a.events.empty() && a.gateCalls==1 && b.events.size()==1 && b.events[0].arguments[0]=="B","context leak");
    });
    Test("talk_hide_missing_one_to_zero_and_real_event", [] {
        { State before; LuaApiGen::RegisterAll(before.p); Lua(before.p,"Talk:HideContexMenu4Speaker()"); Require(LuaApiGen::GetMissingCallCount()==1,"baseline"); }
        ServiceTrace trace; State s; CreateTalk(s.p,&trace); auto globals=s.p->GetGlobals();
        Require(CysHostGlobals::RegisterTalk(globals,Services(trace))==1,"registration"); LuaApiGen::RegisterAll(s.p);
        Lua(s.p,"Talk:HideContexMenu4Speaker()");
        Require(LuaApiGen::GetMissingCallCount()==0 && trace.events.size()==1 && trace.events[0].name=="HIDE_CONTEXMENU_SPEAKER" && trace.events[0].arguments.empty(),"wrong hide event");
    });
    Test("talk_hide_ignores_arguments_and_returns_zero", [] {
        ServiceTrace trace; State s; CreateTalk(s.p,&trace); auto globals=s.p->GetGlobals(); CysHostGlobals::RegisterTalk(globals,Services(trace));
        Lua(s.p,"function count(...) return arg.n end; assert(count(Talk:HideContexMenu4Speaker('unused',false))==0); Talk.HideContexMenu4Speaker(); Talk.HideContexMenu4Speaker(nil,{})");
        Require(trace.events.size()==3 && trace.events[0].arguments.empty(),"arguments");
    });
    Test("talk_hide_receiver_metatable_identity", [] {
        ServiceTrace trace; State s; CreateTalk(s.p,&trace); Lua(s.p,"saved=Talk; savedmeta=getmetatable(Talk)"); auto globals=s.p->GetGlobals();
        CysHostGlobals::RegisterTalk(globals,Services(trace)); LuaApiGen::RegisterAll(s.p); Lua(s.p,"assert(saved==Talk and getmetatable(Talk)==savedmeta)");
    });
    Test("talk_hide_keeps_existing_slots_and_stub", [] {
        for (const char* value : {"false", "42", "'kept'", "function() return 9 end"}) {
            ServiceTrace trace; State s; CreateTalk(s.p,&trace); Lua(s.p,(std::string("TestTalkMeta.HideContexMenu4Speaker=")+value+"; saved=Talk.HideContexMenu4Speaker").c_str()); auto globals=s.p->GetGlobals();
            Require(CysHostGlobals::RegisterTalk(globals,Services(trace))==0,"overwrite"); LuaApiGen::RegisterAll(s.p); Lua(s.p,"assert(Talk.HideContexMenu4Speaker==saved)");
        }
        ServiceTrace trace; State s; CreateTalk(s.p,&trace); LuaApiGen::RegisterAll(s.p); auto globals=s.p->GetGlobals(); Require(CysHostGlobals::RegisterTalk(globals,Services(trace))==0,"stub overwrite");
    });
    Test("talk_hide_service_error_and_exception_unwind", [] {
        ServiceTrace trace; State s; CreateTalk(s.p,&trace); auto globals=s.p->GetGlobals(); CysHostGlobals::Services service; CysHostGlobals::RegisterTalk(globals,service);
        Lua(s.p,"local ok,e=pcall(Talk.HideContexMenu4Speaker,Talk); assert(not ok and string.find(e,'event service is unavailable',1,true))");
        State t; CreateTalk(t.p,&trace); globals=t.p->GetGlobals(); service=Services(trace); service.pushEvent=ThrowEmit; CysHostGlobals::RegisterTalk(globals,service);
        Lua(t.p,"local ok,e=pcall(Talk.HideContexMenu4Speaker,Talk); assert(not ok and string.find(e,'event test failure',1,true)); assert(2+2==4)");
    });
    Test("talk_hide_requires_dedicated_receiver_metatable", [] {
        State s; auto globals=s.p->GetGlobals(); bool threw=false; try {CysHostGlobals::RegisterTalk(globals,{});} catch(const std::runtime_error&) {threw=true;} Require(threw,"missing receiver");
        LuaPlus::LuaObject receiver=s.p->BoxPointer(&threw); globals.SetObject("Talk",receiver); threw=false; const int top=lua_gettop(s.p->GetCState());
        try {CysHostGlobals::RegisterTalk(globals,{});} catch(const std::runtime_error&) {threw=true;} Require(threw,"default metatable");
        Require(lua_gettop(s.p->GetCState())==top,"stack leak");
    });
    Test("talk_hide_descriptor_copy_per_state", [] {
        ServiceTrace a,b; State sa,sb; CreateTalk(sa.p,&a); CreateTalk(sb.p,&b); auto globals=sa.p->GetGlobals(); auto service=Services(a); CysHostGlobals::RegisterTalk(globals,service);
        service=Services(b); globals=sb.p->GetGlobals(); CysHostGlobals::RegisterTalk(globals,service); Lua(sa.p,"Talk:HideContexMenu4Speaker()"); Lua(sb.p,"Talk:HideContexMenu4Speaker()");
        Require(a.events.size()==1 && b.events.size()==1,"context leak");
    });
    Test("dictionary_nonstring_returns_zero_without_services", [] {
        State s; auto globals=s.p->GetGlobals(); CysHostGlobals::Register(globals,{});
        Lua(s.p,"function count(...) return arg.n end; assert(count(GetDictionaryString())==0); "
                "for _,v in ipairs({false,true,{},function() end}) do assert(count(GetDictionaryString(v))==0) end");
    });
    Test("dictionary_exact_lookup_missing_empty_and_numeric_keys", [] {
        State s; ServiceTrace trace; trace.dictionary={{"K","found"},{"","empty key"},{"123","number"}}; RegisterReal(s.p,trace);
        Lua(s.p,"function count(...) return arg.n end; assert(GetDictionaryString('K')=='found'); assert(GetDictionaryString('k')==''); "
                "assert(count(GetDictionaryString('missing'))==1); assert(GetDictionaryString('')=='empty key'); assert(GetDictionaryString(123)=='number')");
        Require(trace.dictionaryKeys==std::vector<std::string>({"K","k","missing","","123"}),"lookup keys");
    });
    Test("dictionary_key_template_and_output_c_string_boundaries", [] {
        State s; ServiceTrace trace; trace.dictionary["K"]=std::string("value\0%s",8); RegisterReal(s.p,trace);
        Lua(s.p,"assert(GetDictionaryString('K'..string.char(0)..'ignored')=='value')");
        Require(trace.dictionaryKeys[0]=="K" && trace.stripInputs[0]=="value","C-string key or template");
        trace.replaceStripped=true; trace.strippedResult=std::string("done\0tail",9);
        Lua(s.p,"assert(GetDictionaryString('K')=='done')");
    });
    Test("dictionary_utf8_vietnamese_chinese_bytes_preserved", [] {
        State s; ServiceTrace trace;
        const std::string text=u8"Tiếng Việt 中文"; trace.dictionary[u8"键"]=text; RegisterReal(s.p,trace);
        auto globals=s.p->GetGlobals(); globals.SetString("key",u8"键"); globals.SetString("wanted",text.c_str());
        Lua(s.p,"assert(GetDictionaryString(key)==wanted)"); Require(trace.stripInputs[0]==text,"UTF8 value changed");
    });
    Test("dictionary_ignores_all_extra_lua_arguments", [] {
        State s; ServiceTrace trace; trace.dictionary["K"]="literal"; RegisterReal(s.p,trace);
        Lua(s.p,"assert(GetDictionaryString('K',7,false,{},function() end)=='literal')");
        Require(trace.dictionaryKeys.size()==1,"extra argument read");
    });
    Test("dictionary_percent_escape_and_2048_byte_format_bound", [] {
        State s; ServiceTrace trace; trace.dictionary={{"escaped","100%% %%%%"},{"long",std::string(2047,'x')+"%%tail"}}; RegisterReal(s.p,trace);
        Lua(s.p,"assert(GetDictionaryString('escaped')=='100% %%'); assert(GetDictionaryString('long')==string.rep('x',2047)..'%')");
        Require(trace.stripInputs[1].size()==2048,"format limit");
    });
    Test("dictionary_absent_varargs_and_invalid_formats_report_errors", [] {
        State s; ServiceTrace trace; RegisterReal(s.p,trace);
        for (const char* format : {"%s","%d","%n","%*s","%.2f","%1$s","%","%q"}) {
            trace.dictionary["K"]=format;
            Lua(s.p,"local ok,e=pcall(GetDictionaryString,'K','not a C vararg'); assert(not ok and string.find(e,'unsupported format arguments',1,true)); assert(2+2==4)");
        }
        Require(trace.stripInputs.empty(),"invalid format reached colour service");
    });
    Test("dictionary_no_colour_service_runs_after_literal_formatting", [] {
        State s; ServiceTrace trace; trace.dictionary["K"]="#gFF000F100%%#l#n"; trace.replaceStripped=true; trace.strippedResult="100%#n"; RegisterReal(s.p,trace);
        Lua(s.p,"assert(GetDictionaryString('K')=='100%#n')");
        Require(trace.stripInputs==std::vector<std::string>({"#gFF000F100%#l#n"}),"NoColor service input");
    });
    Test("dictionary_each_required_service_checked", [] {
        for (int missing=0; missing<2; ++missing) {
            State s; ServiceTrace trace; auto service=Services(trace);
            if(missing==0) service.dictionaryText=nullptr; else service.stripTextColour=nullptr;
            auto globals=s.p->GetGlobals(); CysHostGlobals::Register(globals,service);
            Lua(s.p,"local ok,e=pcall(GetDictionaryString,'K'); assert(not ok and string.find(e,'dictionary service is unavailable',1,true))");
            Require(trace.dictionaryKeys.empty(),"partial service called");
        }
    });
    Test("dictionary_service_exceptions_unwind_before_lua_error", [] {
        for (int which=0; which<2; ++which) {
            State s; ServiceTrace trace; auto service=Services(trace);
            if(which==0) service.dictionaryText=ThrowDictionary; else service.stripTextColour=ThrowColour;
            auto globals=s.p->GetGlobals(); CysHostGlobals::Register(globals,service);
            Lua(s.p,"local ok,e=pcall(GetDictionaryString,'K'); assert(not ok and string.find(e,'test failure',1,true)); assert(1+1==2)");
        }
    });
    Test("dictionary_registration_preserves_non_nil_slots", [] {
        for (const char* value : {"false","42","{}","function() return 'existing' end"}) {
            State s; ServiceTrace trace; Lua(s.p,(std::string("GetDictionaryString=")+value+"; saved=GetDictionaryString").c_str());
            RegisterReal(s.p,trace); LuaApiGen::RegisterAll(s.p); Lua(s.p,"assert(GetDictionaryString==saved)");
        }
    });
    Test("dictionary_service_descriptor_keeps_state_context", [] {
        State a,b; ServiceTrace first,second; first.dictionary["K"]="one"; second.dictionary["K"]="two";
        auto service=Services(first); auto globals=a.p->GetGlobals(); CysHostGlobals::Register(globals,service);
        service=Services(second); globals=b.p->GetGlobals(); CysHostGlobals::Register(globals,service);
        Lua(a.p,"assert(GetDictionaryString('K')=='one')"); Lua(b.p,"assert(GetDictionaryString('K')=='two')");
    });
    Test("dictionary_six_login_calls_from_canonical_corpus_missing_to_zero", [&] {
        Require(argc==2,"canonical dictionary argument required");
        std::ifstream input(argv[1],std::ios::binary); Require(input.good(),"canonical dictionary unavailable");
        const std::string bytes((std::istreambuf_iterator<char>(input)),std::istreambuf_iterator<char>());
        ServiceTrace trace; trace.dictionary=CysUiDictionary::Parse(bytes,CP_UTF8).entries;
        const char* names[]={"Tip_PVP_Peace","Tip_PVP_Moral","Tip_PVP_FreeForAll","Tip_PVP_FreeForTeam","TM_20080311_16","Tip_PVP_Peace"};
        const char* snippet="result={}; for i=1,6 do result[i]=GetDictionaryString(keys[i]) end";
        {
            State before; auto table=before.p->GetGlobals().CreateTable("keys");
            for(int i=0;i<6;++i) table.SetString(i+1,names[i]);
            LuaApiGen::RegisterAll(before.p); Lua(before.p,snippet);
            Require(LuaApiGen::GetMissingCallCountFor("_G","GetDictionaryString")==6,"missing-call baseline");
        }
        {
            State after; RegisterReal(after.p,trace); LuaApiGen::RegisterAll(after.p);
            auto globals=after.p->GetGlobals(); auto table=globals.CreateTable("keys"); auto wanted=globals.CreateTable("wanted");
            for(int i=0;i<6;++i) {
                table.SetString(i+1,names[i]); const auto& value=trace.dictionary.at(names[i]);
                Require(!value.empty() && value.find('%')==std::string::npos && value.find('#')==std::string::npos,"login literal profile changed");
                wanted.SetString(i+1,value.c_str());
            }
            Lua(after.p,snippet); Lua(after.p,"for i=1,6 do assert(result[i]==wanted[i]) end");
            Require(LuaApiGen::GetMissingCallCount()==0 && trace.stripInputs.size()==6,"real host missing or no colour service");
            std::printf("BEFORE_AFTER mode=offline_canonical_dictionary calls=6->0 keys=5 outputs_checked=6\n");
        }
    });
    std::printf("RESULT passed=%u failed=%u total=%u\n", passed, failed, passed+failed);
    return failed == 0 ? 0 : 1;
}
