// CYS: real parser + LuaPlus host tests with synthetic regions, no sockets.
#include "CysHostQueries.h"
#include "CysLoginList.h"
#include "LuaApiGen.h"

#include <cstdio>
#include <algorithm>
#include <fstream>
#include <iterator>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

namespace
{
    unsigned passed = 0, failed = 0;
    std::vector<std::string> missingLines;
    void Require(bool value, const char* why) { if (!value) throw std::runtime_error(why); }
    void Capture(const char* message) { missingLines.emplace_back(message); }
    template<class F> void Test(const char* name, F run)
    {
        try { run(); ++passed; std::printf("PASS %s\n", name); }
        catch (const LuaPlus::LuaException& error) { ++failed; std::printf("FAIL %s: %s\n", name, error.GetMessage()); }
        catch (const std::exception& error) { ++failed; std::printf("FAIL %s: %s\n", name, error.what()); }
    }
    std::string Row(const char* area = "North", const char* description = "Northern region", const char* server = "One")
    {
        return std::string(area) + "," + server + ",1,10,3,0,0," + description +
               ",127.0.0.1:14400,127.0.0.1:14401,,,0,0";
    }
    std::string Document(const std::string& rows)
    { return "VERSION 1\r\nSERVER_BEGIN\r\n" + rows + "\r\nSERVER_END\r\n"; }
    std::string Column(std::string row, unsigned column, const std::string& value)
    {
        std::size_t start = 0;
        for (unsigned i = 0; i < column; ++i) start = row.find(',', start) + 1;
        const auto end = row.find(',', start);
        row.replace(start, end == std::string::npos ? end : end - start, value);
        return row;
    }
    void Reject(const std::string& input)
    {
        bool rejected = false;
        try { CysLoginList::Parse(input); }
        catch (const std::runtime_error& e) { rejected = std::string(e.what()).find("CYS login list line ") == 0; }
        Require(rejected, "malformed list accepted or diagnostic missing");
    }
    struct State
    {
        LuaPlus::LuaState* p = LuaPlus::LuaState::Create(true);
        State()
        {
            Require(p != nullptr, "Lua state missing");
            LuaApiGen::SetLogSink(Capture); LuaApiGen::ResetMissingCallCounts(); missingLines.clear();
        }
        ~State() { LuaPlus::LuaState::Destroy(p); }
        void Run(const char* code)
        {
            auto* raw = p->GetCState(); const int top = lua_gettop(raw);
            const int rc = luaL_loadbuffer(raw, code, std::char_traits<char>::length(code), "login-area-test");
            const int result = rc ? rc : lua_pcall(raw, 0, 0, 0);
            if (result)
            {
                const char* text = lua_tostring(raw, -1);
                const std::string error = text ? text : "Lua error";
                lua_settop(raw, top); throw std::runtime_error(error);
            }
            Require(lua_gettop(raw) == top, "Lua stack leaked");
        }
        void Number(const char* name, double value)
        { lua_pushnumber(p->GetCState(), value); lua_setglobal(p->GetCState(), name); }
        void String(const char* name, const std::string& value)
        { lua_pushlstring(p->GetCState(), value.data(), value.size()); lua_setglobal(p->GetCState(), name); }
    };
    struct Regions
    {
        std::vector<CysLoginList::Area> values = CysLoginList::Parse(Document(Row() + "\n" + Row("South", "Southern region", "Two")));
        std::vector<std::int32_t> calls;
        int throwKind = 0, active = 0;
        bool returnNull = false;
        static const char* Lookup(void* context, std::int32_t index)
        {
            auto& data = *static_cast<Regions*>(context); data.calls.push_back(index);
            struct Scope { int& n; Scope(int& v) : n(v) { ++n; } ~Scope() { --n; } } scope(data.active);
            if (data.throwKind == 1) throw std::runtime_error("PRIVATE_TEST_TEXT");
            if (data.throwKind == 2) throw LuaPlus::LuaException("PRIVATE_TEST_TEXT");
            if (data.returnNull) return nullptr;
            return index >= 0 && static_cast<std::size_t>(index) < data.values.size() ? data.values[index].description.c_str() : "";
        }
        CysHostQueries::Services Services()
        { CysHostQueries::Services s; s.context = this; s.areaDescription = Lookup; return s; }
    };
    struct Fixture
    {
        Regions data;
        State state;
        Fixture(bool install = true)
        {
            auto globals = state.p->GetGlobals(); auto meta = globals.CreateTable("RegionMeta");
            meta.SetObject("__index", meta);
            LuaPlus::LuaObject receiver = state.p->BoxPointer(&data); receiver.SetMetaTable(meta); globals.SetObject("GameProduceLogin", receiver);
            state.Run("saved=GameProduceLogin; savedMeta=getmetatable(saved); savedMeta.Existing=function() return 917 end");
            if (install) Install(data.Services());
        }
        unsigned Install(const CysHostQueries::Services& services)
        {
            auto globals = state.p->GetGlobals(); const int top = lua_gettop(state.p->GetCState());
            const auto n = CysHostQueries::RegisterLogin(globals, services);
            Require(lua_gettop(state.p->GetCState()) == top, "registration stack leaked"); return n;
        }
        void Generated() { auto meta = state.p->GetGlobals().GetByName("RegionMeta"); LuaApiGen::Register_GameProduceLogin(meta); }
    };
    struct GlFixture : Fixture
    {
        std::vector<CysLoginList::Match> matches;
        int page = 0, submits = 0, reads = 0, copyResult = 0;
        bool accepting = true, throwSubmit = false;
        std::string user = "alpha", secret = "synthetic", receivedUser, receivedSecret;
        CysHostQueries::AccountServices account;
        GlFixture()
        {
            auto services = data.Services(); services.context = this;
            services.areaRecommendLevel = [](void* p, std::int32_t index) -> std::int32_t {
                auto& f = *static_cast<GlFixture*>(p);
                return index >= 0 && index < f.data.values.size() ? f.data.values[index].recommendLevel : 0;
            };
            services.setCurrentServerPage = [](void* p, std::int32_t page) { static_cast<GlFixture*>(p)->page = page; };
            services.setLoginServerKeyword = [](void* p, const std::string& text) -> std::int32_t {
                auto& f = *static_cast<GlFixture*>(p); f.matches = CysLoginList::Search(f.data.values, text);
                return static_cast<std::int32_t>(f.matches.size());
            };
            services.keywordLoginServerInfo = [](void* p, std::int32_t index, CysHostQueries::LoginServerInfo& result) {
                auto& f = *static_cast<GlFixture*>(p);
                if (index < 0 || index >= f.matches.size()) return false;
                const auto& m = f.matches[index]; result = f.Info(m.areaIndex, m.serverIndex); return true;
            };
            auto globals = state.p->GetGlobals();
            Require(CysHostQueries::RegisterGlLogin(globals, services) == 6, "GL hosts not installed");
            account.context = this;
            account.acceptingInput = [](void* p) { return static_cast<GlFixture*>(p)->accepting; };
            account.copyEditText = [](void* p, const char* name, char* out, unsigned capacity) {
                auto& f = *static_cast<GlFixture*>(p); ++f.reads;
                const auto& value = std::string(name) == "LogOn_ID" ? f.user : f.secret;
                if (f.copyResult) return f.copyResult;
                if (value.size() >= capacity) return -2;
                std::copy(value.begin(), value.end(), out); out[value.size()] = 0;
                return static_cast<int>(value.size());
            };
            account.submit = [](void* p, const std::string& user, const std::string& secret) {
                auto& f = *static_cast<GlFixture*>(p);
                if (f.throwSubmit) throw std::runtime_error("PRIVATE_TEST_SECRET");
                ++f.submits; f.receivedUser = user; f.receivedSecret = secret;
            };
            auto* raw = state.p->GetCState();
            lua_pushlightuserdata(raw, this); lua_pushcclosure(raw, Ordinary, 1); lua_setglobal(raw, "Ordinary");
            lua_pushlightuserdata(raw, this); lua_pushcclosure(raw, Account, 1); lua_setglobal(raw, "Account");
            state.Run("savedMeta.GetAreaLoginServerInfo=Ordinary; savedMeta.CheckAccount=Account");
        }
        CysHostQueries::LoginServerInfo Info(int a, int index)
        {
            CysHostQueries::LoginServerInfo info;
            if (a < 0 || a >= data.values.size() || index < 0 || index >= data.values[a].servers.size()) return info;
            const auto& server = data.values[a].servers[index];
            info.name = server.name; info.status = server.status; info.recommendLevel = server.recommendLevel;
            info.isNew = server.isNew; info.provider = server.provider; info.serverId = server.serverId;
            info.rowOrdinal = server.rowOrdinal; info.areaIndex = a; info.serverIndex = index;
            return info;
        }
        static int Ordinary(lua_State* raw)
        {
            auto& f = *static_cast<GlFixture*>(lua_touserdata(raw, lua_upvalueindex(1)));
            const auto info = f.Info(static_cast<int>(lua_tonumber(raw, 2)), static_cast<int>(lua_tonumber(raw, 3)));
            return CysHostQueries::PushLoginServerInfo(f.state.p, &info);
        }
        static int Account(lua_State* raw)
        {
            auto& f = *static_cast<GlFixture*>(lua_touserdata(raw, lua_upvalueindex(1)));
            return CysHostQueries::CheckAccount(f.state.p, f.account);
        }
    };

}

int main(int argc, char** argv)
{
    Test("reader_distinct_description_and_four_endpoints", [] {
        auto areas = CysLoginList::Parse(Document(Row()));
        Require(areas.size() == 1 && areas[0].name == "North" && areas[0].description == "Northern region", "wrong area fields");
        const auto& s = areas[0].servers[0];
        Require(s.name == "One" && s.provider == 1 && s.status == 3, "wrong server fields");
        Require(s.endpoints[0].port == 14400 && s.endpoints[1].port == 14401 && s.endpoints[2].host.empty(), "endpoint slots shifted");
    });
    Test("reader_first_seen_region_order_and_first_description", [] {
        auto a = CysLoginList::Parse(Document(Row("B", "First", "1") + "\n" + Row("A", "Other", "2") + "\n" + Row("B", "Later", "3")));
        Require(a.size() == 2 && a[0].name == "B" && a[1].name == "A" && a[0].description == "First", "grouping or description replaced");
        Require(a[0].servers.size() == 2 && a[0].servers[1].name == "3", "server order lost");
    });
    Test("reader_first_empty_description_stays_empty", [] {
        auto a = CysLoginList::Parse(Document(Row("A", "") + "\n" + Row("A", "Later")));
        Require(a[0].description.empty(), "empty description replaced");
    });
    Test("reader_chinese_vietnamese_bytes_and_bom", [] {
        const std::string text = "\xe4\xb8\xad\xe6\x96\x87 \xe1\xba\xbf";
        auto a = CysLoginList::Parse("\xef\xbb\xbf" + Document(Row(text.c_str(), text.c_str())));
        Require(a[0].name == text && a[0].description == text, "UTF-8 bytes changed");
    });
    Test("reader_crlf_lf_comments_and_final_line_without_newline", [] {
        auto a = CysLoginList::Parse("\t #comment\r\nVERSION \nSERVER_BEGIN\n  " + Row() + "\nSERVER_END");
        Require(a.size() == 1, "line handling failed");
    });
    Test("reader_normal_shared_and_special_groups", [] {
        auto a = CysLoginList::Parse(Document(Column(Row("Normal"), 12, "0") + "\n" + Column(Row("Shared"), 12, "1") + "\n" + Column(Row("Special"), 12, "2")));
        Require(a.size() == 2 && a[0].name == "Normal" && a[1].name == "Shared", "normal group filtering failed");
    });
    Test("reader_15_columns_and_recommendation_tail", [] {
        auto a = CysLoginList::Parse(Document(Row() + ",2") + "RECOMMENDAREA_BEGIN\nNorth,2\nRECOMMENDAREA_END\n");
        Require(a.size() == 1, "optional column or tail failed");
    });
    Test("reader_empty_normal_view", [] { Require(CysLoginList::Parse(Document("")).empty(), "empty list failed"); });
    Test("reader_rejects_invalid_utf8_and_nul", [] {
        Reject(Document(Row("\xc0\xaf"))); Reject(Document(Row()) + std::string(1, '\0')); Reject(Document(Row("\xed\xa0\x80")));
    });
    Test("reader_rejects_bad_structure", [] {
        Reject(Row()); Reject("SERVER_BEGIN\n" + Row()); Reject("SERVER_END\n");
        Reject("SERVER_BEGIN\nSERVER_BEGIN\nSERVER_END\n"); Reject(Document(Row()) + "SERVER_END\n");
    });
    Test("reader_rejects_column_shift_and_empty_names", [] {
        Reject(Document("short,row")); Reject(Document(Row() + ",0,0")); Reject(Document(Row(""))); Reject(Document(Row("A", "B", "")));
    });
    Test("reader_rejects_invalid_numeric_fields", [] {
        for (const char* n : {"", "-", "x", "1x", "2147483648", "99999999999999999999999999"}) Reject(Document(Column(Row(), 2, n)));
        Reject(Document(Column(Row(), 2, "3"))); Reject(Document(Column(Row(), 4, "5"))); Reject(Document(Column(Row(), 12, "-1")));
    });
    Test("reader_rejects_endpoint_errors", [] {
        for (const char* s : {"", "127.0.0.1", ":14400", "127.0.0.1:0", "127.0.0.1:65536", "host :14400", "[::1]:14400", "host:12:34"})
            Reject(Document(Column(Row(), 8, s)));
        Reject(Document(Column(Row(), 9, "backup:bad")));
    });
    Test("reader_accepts_endpoint_port_boundaries", [] {
        auto a = CysLoginList::Parse(Document(Column(Column(Row(), 8, "localhost:1"), 9, "host-name:65535")));
        Require(a[0].servers[0].endpoints[1].port == 65535, "port boundary failed");
    });
    Test("reader_rejects_oversize_input_and_missing_file", [] {
        Reject(std::string(2 * 1024 * 1024 + 1, 'x')); Reject(Document(Row("A", std::string(16385, 'a').c_str())));
        bool caught = false; try { CysLoginList::LoadFile("missing-login-area-fixture.txt"); } catch (const std::runtime_error&) { caught = true; }
        Require(caught, "missing file silently accepted");
    });
    Test("same_lua_snippet_missing_two_to_zero", [] {
        const char* code = "first=GameProduceLogin:GetServerAreaDis(0); second=GameProduceLogin:GetServerAreaDis(1)";
        { Fixture b(false); b.Generated(); b.state.Run(code); Require(LuaApiGen::GetMissingCallCount() == 2 && missingLines.size() == 1, "baseline counters failed"); }
        Fixture a; a.Generated(); a.state.Run(code);
        a.state.Run("assert(first=='Northern region' and second=='Southern region')");
        Require(LuaApiGen::GetMissingCallCount() == 0 && missingLines.empty(), "real method still missing");
        std::printf("BEFORE_AFTER missing_calls=2->0 missing_lines=1->0 descriptions=2\n");
    });
    Test("host_preserves_receiver_metatable_and_existing_methods", [] {
        Fixture f; f.state.Run("assert(saved==GameProduceLogin and savedMeta==getmetatable(saved)); assert(saved:Existing()==917)");
    });
    Test("host_range_and_fractional_indices", [] {
        Fixture f; f.state.Run("assert(saved:GetServerAreaDis(-1)==''); assert(saved:GetServerAreaDis(2)==''); assert(saved:GetServerAreaDis(1.9)=='Southern region'); assert(saved:GetServerAreaDis(-0.9)=='Northern region')");
    });
    Test("host_one_return_and_ignored_extras", [] {
        Fixture f; f.state.Run("local function count(...) return arg.n end; assert(count(saved:GetServerAreaDis(0))==1); assert(saved:GetServerAreaDis(1,true,{})=='Southern region')");
    });
    Test("host_nan_infinity_and_int32_overflow", [] {
        Fixture f; f.state.Number("nan", (std::numeric_limits<double>::quiet_NaN)()); f.state.Number("inf", (std::numeric_limits<double>::infinity)());
        f.state.Run("assert(saved:GetServerAreaDis(nan)==''); assert(saved:GetServerAreaDis(inf)==''); assert(saved:GetServerAreaDis(-inf)==''); assert(saved:GetServerAreaDis(2147483648)==''); assert(saved:GetServerAreaDis(-2147483649)=='')");
        Require(f.data.calls == std::vector<std::int32_t>(5, (std::numeric_limits<std::int32_t>::min)()), "int32 invalid conversion differs");
    });
    Test("host_invalid_types_error_before_service", [] {
        Fixture f;
        for (const char* value : {"", "nil", "'0'", "true", "{}", "function() end"})
            f.state.Run((std::string("local ok=pcall(function() return saved:GetServerAreaDis(") + value + ") end); assert(not ok)").c_str());
        Require(f.data.calls.empty(), "wrong type reached service");
    });
    Test("host_utf8_empty_and_c_string_boundary", [] {
        Fixture f; const std::string text = "\xe4\xb8\xad\xe1\xba\xbf";
        f.data.values[0].description = text; f.data.values[1].description.clear(); f.state.String("expected", text);
        f.state.Run("assert(saved:GetServerAreaDis(0)==expected and saved:GetServerAreaDis(1)=='')");
        f.data.values[0].description = std::string("A\0B", 3); f.state.Run("assert(saved:GetServerAreaDis(0)=='A')");
    });
    Test("host_reads_updated_list_and_copies_service_descriptor", [] {
        Fixture f(false); auto s = f.data.Services(); Require(f.Install(s) == 1, "method not added"); s.context = nullptr; s.areaDescription = nullptr;
        Require(f.Install(s) == 0, "repeat install changed method"); f.data.values[0].description = "Updated";
        f.state.Run("collectgarbage(); assert(saved:GetServerAreaDis(0)=='Updated')");
    });
    Test("host_preserves_function_false_zero_and_string", [] {
        Fixture f(false);
        for (const char* value : {"function() return 99 end", "false", "0", "'existing'"})
        {
            f.state.Run((std::string("savedMeta.GetServerAreaDis=") + value + "; old=savedMeta.GetServerAreaDis").c_str());
            Require(f.Install(f.data.Services()) == 0, "non-nil overwritten"); f.Generated();
            f.state.Run("assert(savedMeta.GetServerAreaDis==old)");
        }
    });
    Test("host_unavailable_or_null_service_is_error", [] {
        Fixture f(false); f.Install(CysHostQueries::Services{});
        f.state.Run("local ok,e=pcall(function() saved:GetServerAreaDis(0) end); assert(not ok and string.find(e,'unavailable',1,true))");
        Fixture n; n.data.returnNull = true;
        n.state.Run("local ok,e=pcall(function() saved:GetServerAreaDis(0) end); assert(not ok and string.find(e,'returned null',1,true))");
    });
    Test("host_callback_exceptions_unwind_and_do_not_leak_text", [] {
        Fixture f;
        for (int kind : {1, 2})
        {
            f.data.throwKind = kind;
            f.state.Run("local ok,e=pcall(function() saved:GetServerAreaDis(0) end); assert(not ok and not string.find(e,'PRIVATE_TEST_TEXT',1,true))");
            Require(f.data.active == 0, "callback did not unwind");
        }
        f.data.throwKind = 0; f.state.Run("assert(saved:GetServerAreaDis(0)=='Northern region')");
    });
    Test("host_independent_states_and_unrelated_stub", [] {
        Fixture a, b; b.data.values[0].description = "Different";
        a.state.Run("assert(saved:GetServerAreaDis(0)=='Northern region')"); b.state.Run("assert(saved:GetServerAreaDis(0)=='Different')");
        b.Generated(); b.state.Run("saved:GetServerAreaDis(0); saved:GetServerAreaRecommendLevel(0)");
        Require(LuaApiGen::GetMissingCallCountFor("GameProduceLogin", "GetServerAreaDis") == 0 && LuaApiGen::GetMissingCallCount() == 1, "unrelated counter disabled");
    });
    Test("host_missing_or_default_receiver_rejected", [] {
        State s;
        for (int kind : {0, 1, 2})
        {
            if (kind == 1) s.Run("GameProduceLogin={}");
            if (kind == 2) { lua_newuserdata(s.p->GetCState(), 1); lua_setglobal(s.p->GetCState(), "GameProduceLogin"); }
            auto globals = s.p->GetGlobals(); const int top = lua_gettop(s.p->GetCState()); bool rejected = false;
            try { CysHostQueries::RegisterLogin(globals, CysHostQueries::Services{}); } catch (const std::runtime_error&) { rejected = true; }
            Require(rejected && lua_gettop(s.p->GetCState()) == top, "bad receiver accepted or stack leaked");
        }
    });

    Test("gl_reader_preserves_metadata_and_area_recommendation", [] {
        auto row = Column(Column(Column(Column(Row(),3,"741"),5,"7"),6,"1"),2,"2");
        auto values = CysLoginList::Parse(Document(row)+"RECOMMENDAREA_BEGIN\nNorth,9\nAbsent,2\nNorth,4\nRECOMMENDAREA_END\n");
        const auto& server = values[0].servers[0];
        Require(server.provider == 2 && server.serverId == 741 && server.recommendLevel == 7 && server.isNew &&
                server.rowOrdinal == 0 && values[0].recommendLevel == 4, "metadata shifted");
    });
    Test("gl_negative_recommendations_clamp_to_zero", [] {
        auto values = CysLoginList::Parse(Document(Column(Row(),5,"-3"))+"RECOMMENDAREA_BEGIN\nNorth,-9\nRECOMMENDAREA_END\n");
        Require(values[0].recommendLevel == 0 && values[0].servers[0].recommendLevel == 0, "negative recommendation retained");
    });
    Test("gl_recommendation_malformed_and_unclosed_rejected", [] {
        for (const char* text : {"North,x\nRECOMMENDAREA_END\n", "North,2,3\nRECOMMENDAREA_END\n", "North,2\n"})
            Reject(Document(Row())+"RECOMMENDAREA_BEGIN\n"+text);
    });
    Test("gl_ordinary_tuple_has_five_values_in_B_order", [] {
        GlFixture f; auto& server = f.data.values[0].servers[0];
        server.recommendLevel = 8; server.isNew = true; server.provider = 2; server.serverId = 912;
        f.state.Run("local function count(...) return arg.n end; local n,s,r,new,p=saved:GetAreaLoginServerInfo(0,0); assert(n=='One' and s==3 and r==8 and new==1 and p==2); assert(count(saved:GetAreaLoginServerInfo(0,0))==8)");
    });
    Test("gl_ordinary_invalid_tuple_defaults", [] {
        GlFixture f; f.state.Run("local n,s,r,new,p=saved:GetAreaLoginServerInfo(-1,-1); assert(n=='' and s==0 and r==0 and new==0 and p==-1)");
    });
    Test("gl_search_eight_tuple_carries_actual_indices_and_ids", [] {
        GlFixture f; f.data.values[1].servers[0].serverId = 808; f.data.values[1].servers[0].rowOrdinal = 19;
        f.state.Run("assert(saved:SetLoginServerKeyword('wo')==1); local function count(...) return arg.n end; local n,s,r,new,row,area,id,index=saved:GetKeywordLoginServerInfo(0); assert(n=='Two' and s==3 and r==0 and new==0 and row==19 and area==1 and id==808 and index==0); assert(count(saved:GetKeywordLoginServerInfo(0))==8)");
    });
    Test("gl_search_clears_old_results_for_empty_or_no_match", [] {
        GlFixture f; f.state.Run("assert(saved:SetLoginServerKeyword('One')==1); assert(saved:SetLoginServerKeyword('')==0); local n,s,r,new,row,area,id,index=saved:GetKeywordLoginServerInfo(0); assert(n=='' and s==0 and r==0 and new==0 and row==0 and area==0 and id==0 and index==0); assert(saved:SetLoginServerKeyword('absent')==0)");
    });
    Test("gl_search_skips_hidden_and_deduplicates_name_within_area", [] {
        auto hidden = Column(Row("North","","OneHidden"),4,"10");
        auto special = Column(Row("Special","","OneSpecial"),12,"2");
        auto values = CysLoginList::Parse(Document(special+"\n"+Row()+"\n"+Row()+"\n"+hidden+"\n"+Row("South","","One")));
        auto results = CysLoginList::Search(values,"One");
        Require(results.size()==2 && results[0].areaIndex==0 && results[0].serverIndex==0 && results[1].areaIndex==1, "wrong duplicates/hidden handling");
        Require(values[0].servers[0].rowOrdinal==1 && values[1].servers[0].rowOrdinal==4, "global row order lost");
    });
    Test("gl_search_is_case_sensitive_utf8", [] {
        GlFixture f; const std::string text = "\xe4\xb8\xad\xe1\xba\xbf";
        f.data.values[0].servers[0].name=text; f.state.String("keyword",text.substr(3));
        f.state.Run("assert(saved:SetLoginServerKeyword(keyword)==1); assert(saved:SetLoginServerKeyword('two')==0)");
    });
    Test("gl_search_indices_nan_and_invalid_types", [] {
        GlFixture f; f.state.Number("nan", (std::numeric_limits<double>::quiet_NaN)());
        f.state.Run("saved:SetLoginServerKeyword('One'); assert(saved:GetKeywordLoginServerInfo(nan)==''); assert(saved:GetKeywordLoginServerInfo(-1)==''); assert(saved:GetKeywordLoginServerInfo(0.9)=='One'); assert(not pcall(function() saved:GetKeywordLoginServerInfo('0') end)); assert(not pcall(function() saved:SetLoginServerKeyword({}) end))");
    });
    Test("gl_recommendation_and_page_are_live_catalog_state", [] {
        GlFixture f; f.data.values[1].recommendLevel=6;
        f.state.Run("assert(saved:GetServerAreaRecommendLevel(1)==6); assert(saved:GetServerAreaRecommendLevel(-1)==0); local function count(...) return arg.n end; assert(count(saved:SetCurrentServerPage(2))==0)");
        Require(f.page==2,"page not persisted");
        f.state.Run("saved:SetCurrentServerPage(-4.9)"); Require(f.page==-4,"page does not follow B numeric conversion");
    });
    Test("gl_local_capabilities_have_B_types", [] {
        GlFixture f; f.state.Run("assert(type(saved:IsYunGameMobileClient())=='boolean' and saved:IsYunGameMobileClient()==false); assert(type(saved:IsWeGameClient())=='number' and saved:IsWeGameClient()==0)");
    });
    Test("gl_hosts_preserved_by_generated_registration_and_repeat", [] {
        GlFixture f; auto globals=f.state.p->GetGlobals(); Require(CysHostQueries::RegisterGlLogin(globals,{})==0,"repeat replaced hosts");
        f.Generated(); f.state.Run("saved:GetServerAreaRecommendLevel(0); saved:SetCurrentServerPage(1); saved:SetLoginServerKeyword('One'); saved:GetKeywordLoginServerInfo(0); saved:IsYunGameMobileClient(); saved:IsWeGameClient()");
        Require(LuaApiGen::GetMissingCallCount()==0,"generated stub replaced host");
    });
    Test("gl_check_account_suffix_reads_actual_named_editboxes", [] {
        GlFixture f; f.state.Run("local function count(...) return arg.n end; assert(count(saved:CheckAccount('-suffix'))==0)");
        Require(f.submits==1 && f.reads==2 && f.receivedUser=="alpha-suffix" && f.receivedSecret=="synthetic", "suffix or raw password lost");
    });
    Test("gl_check_account_legacy_two_args_do_not_read_ui", [] {
        GlFixture f; f.state.Run("saved:CheckAccount('beta','legacy-fixture')");
        Require(f.submits==1 && f.reads==0 && f.receivedUser=="beta" && f.receivedSecret=="legacy-fixture", "legacy contract changed");
    });
    Test("gl_check_account_state_gate_precedes_argument_validation", [] {
        GlFixture f; f.accepting=false; f.state.Run("saved:CheckAccount({}); saved:CheckAccount()");
        Require(f.submits==0 && f.reads==0,"inactive input reached service");
    });
    Test("gl_check_account_empty_suffix_and_nil_password_use_ui", [] {
        GlFixture f; f.state.Run("saved:CheckAccount('',nil)");
        Require(f.receivedUser=="alpha" && f.reads==2,"empty suffix mishandled");
    });
    Test("gl_check_account_wrong_types_never_submit", [] {
        GlFixture f; f.state.Run("assert(not pcall(function() saved:CheckAccount({}) end)); assert(not pcall(function() saved:CheckAccount('a',{}) end))");
        Require(f.submits==0 && f.reads==0,"invalid types reached input");
    });
    Test("gl_check_account_missing_or_oversize_editbox_is_error", [] {
        GlFixture f;
        for (int code : {-1,-2}) { f.copyResult=code; f.state.Run("assert(not pcall(function() saved:CheckAccount('') end))"); }
        Require(f.submits==0,"unavailable edit text submitted");
    });
    Test("gl_check_account_raw_utf8_and_mask_characters_not_substituted", [] {
        GlFixture f; f.user="\xe4\xb8\xad"; f.secret="a*b\xe1\xba\xbf"; f.state.Run("saved:CheckAccount('')");
        Require(f.receivedUser==f.user && f.receivedSecret==f.secret,"raw editbox bytes transformed");
    });
    Test("gl_check_account_exception_redacts_secret_and_recovers", [] {
        GlFixture f; f.throwSubmit=true;
        f.state.Run("local ok,e=pcall(function() saved:CheckAccount('') end); assert(not ok and not string.find(e,'PRIVATE_TEST_SECRET',1,true))");
        f.throwSubmit=false; f.state.Run("saved:CheckAccount('')"); Require(f.submits==1,"exception left stale state");
    });
    if (argc >= 2 && argv[1][0]) Test("reference_plaintext_read_only_profile", [&] {
        auto areas = CysLoginList::LoadFile(argv[1]);
        Require(areas.size() == 1 && areas[0].servers.size() == 1 && !areas[0].description.empty(), "reference shape mismatch");
        std::printf("REFERENCE regions=%zu servers=%zu description_bytes=%zu network_calls=0\n", areas.size(), areas[0].servers.size(), areas[0].description.size());
    });

    if (argc >= 3) Test("gl_canonical_logon_lua_submits_native_one_argument_path", [&] {
        GlFixture f;
        std::ifstream file(argv[2], std::ios::binary);
        Require(static_cast<bool>(file), "Canonical LogOn script unavailable");
        const std::string script((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
        f.state.Run(script.c_str());
        f.state.Run("LogOn_ID={GetText=function() return 'display account' end,SetProperty=function() end}; LogOn_PassWord={GetText=function() return '*********' end,SetProperty=function() end}; LogOn_Region={GetCurrentSelect=function() return '@legacy',8 end,GetText=function() return '@legacy' end}; Variable={GetVariable=function() return '65001' end,SetVariable=function() end}; PushEvent=function() error('unexpected validation failure') end; LogOn_CheckAccount()");
        Require(f.submits==1 && f.reads==2 && f.receivedUser==f.user && f.receivedSecret==f.secret,"Canonical GL used displayed mask, account text or suffix");
    });
    std::printf("LOGIN_AREA_TESTS passed=%u failed=%u total=%u network_calls=0\n", passed, failed, passed + failed);
    return failed ? 1 : 0;
}
