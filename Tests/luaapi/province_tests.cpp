// CYS: typed city table plus the real LuaPlus queries, no sockets or Game process.
#include "CysHostProvinces.h"
#include "LuaApiGen.h"
#include <cstdio>
#include <fstream>
#include <iterator>
#include <limits>
#include <stdexcept>

namespace {
unsigned passed=0,failed=0;
void Require(bool yes,const char* why) { if(!yes) throw std::runtime_error(why); }
template<class F> void Test(const char* name,F run) {
    try { run(); ++passed; std::printf("PASS %s\n",name); }
    catch(const LuaPlus::LuaException& e) { ++failed; std::printf("FAIL %s: %s\n",name,e.GetMessage()); }
    catch(const std::exception& e) { ++failed; std::printf("FAIL %s: %s\n",name,e.what()); }
}
void Put(std::string& bytes,std::uint32_t n) { for(unsigned i=0;i<4;++i) bytes+=char((n>>(8*i))&255); }
void Set(std::string& bytes,std::size_t offset,std::uint32_t n) { std::string v;Put(v,n);bytes.replace(offset,4,v); }
struct Row { std::int32_t id; std::string city,province; };
std::string Document(const std::vector<Row>& rows) {
    std::string cells,strings(1,0),out;
    for(std::size_t i=0;i<rows.size();++i) {
        Put(cells,std::uint32_t(i+1));Put(cells,std::uint32_t(rows[i].id));
        Put(cells,std::uint32_t(strings.size()));strings+=rows[i].city;strings+=char(0);
        Put(cells,std::uint32_t(strings.size()));strings+=rows[i].province;strings+=char(0);Put(cells,0);
    }
    Put(out,0xddbbcc00);Put(out,5);Put(out,std::uint32_t(rows.size()));Put(out,std::uint32_t(strings.size()));
    for(unsigned type:{0,0,2,2,0}) Put(out,type);return out+cells+strings;
}
CysHostProvinces::Catalog Parse(const std::string& bytes) { return CysHostProvinces::Parse(bytes.data(),bytes.size()); }
void Reject(const std::string& bytes) { bool threw=false;try{Parse(bytes);}catch(const std::runtime_error&){threw=true;}Require(threw,"bad table accepted"); }
std::string Sample() { return Document({{20,"Town A","North"},{30,"Town B","South"},{21,"Town C","North"}}); }
struct State {
    LuaPlus::LuaState* p=LuaPlus::LuaState::Create(true);
    State(){ Require(p!=nullptr,"Lua state");LuaApiGen::ResetMissingCallCounts(); }
    ~State(){LuaPlus::LuaState::Destroy(p);}
    void Run(const char* code) {
        auto* raw=p->GetCState();const int top=lua_gettop(raw);
        int rc=luaL_loadbuffer(raw,code,std::char_traits<char>::length(code),"province-test");if(!rc)rc=lua_pcall(raw,0,0,0);
        if(rc){std::string message=lua_tostring(raw,-1);lua_settop(raw,top);throw std::runtime_error(message);}
        Require(lua_gettop(raw)==top,"Lua stack leak");
    }
    void Number(const char* name,double value){lua_pushnumber(p->GetCState(),value);lua_setglobal(p->GetCState(),name);}
};
struct Fixture {
    CysHostProvinces::Catalog catalog=Parse(Sample());State state;
    Fixture(bool install=true) {
        auto globals=state.p->GetGlobals();auto meta=globals.CreateTable("ProvinceMeta");meta.SetObject("__index",meta);
        LuaPlus::LuaObject receiver=state.p->BoxPointer(&catalog);receiver.SetMetaTable(meta);globals.SetObject("DataPool",receiver);
        if(install)Install(&catalog);
    }
    void Generated() {auto meta=state.p->GetGlobals().GetByName("ProvinceMeta");LuaApiGen::Register_DataPool(meta);}
    unsigned Install(const CysHostProvinces::Catalog* value) {auto globals=state.p->GetGlobals();return CysHostProvinces::Register(globals,value);}
};
}
int main(int argc,char** argv) {
    Test("binary_groups_province_column3_first_seen_not_city_column2",[]{auto c=Parse(Sample());Require(c.provinces.size()==2 && c.provinces[0].id==0 && c.provinces[1].id==1 && c.provinces[0].name=="North" && c.provinces[0].cities.size()==2 && c.provinces[0].cities[1].id==21,"schema/order");});
    Test("binary_preserves_duplicate_city_ids_and_empty_province",[]{auto c=Parse(Document({{3,"A",""},{3,"B",""}}));Require(c.provinces.size()==1 && c.provinces[0].cities.size()==2,"rows removed");});
    Test("binary_empty_table_has_real_zero_count",[]{Require(Parse(Document({})).provinces.empty(),"empty catalog");});
    Test("binary_utf8_vietnamese_and_chinese",[]{std::string vn="B\xe1\xba\xaf" "c Kinh",zh="\xe4\xb8\xad\xe6\x96\x87";auto c=Parse(Document({{7,zh,vn}}));Require(c.provinces[0].name==vn && c.provinces[0].cities[0].name==zh,"UTF-8 bytes");});
    Test("binary_cp936_converts_chinese_to_utf8",[]{auto c=Parse(Document({{7,"\xd6\xd0\xce\xc4","\xb1\xb1\xbe\xa9"}}));Require(c.provinces[0].name=="\xe5\x8c\x97\xe4\xba\xac" && c.provinces[0].cities[0].name=="\xe4\xb8\xad\xe6\x96\x87","CP936 conversion");});
    Test("binary_bad_identity_columns_types",[]{auto b=Sample();Set(b,0,0);Reject(b);b=Sample();Set(b,4,4);Reject(b);for(unsigned col=0;col<5;++col){b=Sample();Set(b,16+col*4,7);Reject(b);}});
    Test("binary_truncation_trailing_bytes_and_size_overflow",[]{auto b=Sample();for(std::size_t n:{std::size_t(0),std::size_t(15),std::size_t(35),b.size()-1})Reject(b.substr(0,n));Reject(b+"x");Set(b,8,0xffffffff);Reject(b);});
    Test("binary_invalid_offsets_and_missing_terminator",[]{auto b=Sample();Set(b,44,0xffffffff);Reject(b);b=Sample();Set(b,48,0xffffffff);Reject(b);b=Sample();b.back()='x';Reject(b);});
    Test("binary_invalid_encoding_and_bounded_size",[]{Reject(Document({{1,std::string(1,char(0xff)),"X"}}));Reject(std::string(2*1024*1024+1,'x'));});
    Test("binary_catalog_owns_text_after_source_destroyed",[]{auto b=Sample();auto c=Parse(b);b.assign(b.size(),'x');Require(c.provinces[0].name=="North" && c.provinces[0].cities[0].name=="Town A","borrowed source");});
    Test("text_legacy_four_columns_schema_order_and_cp936",[]{auto c=Parse("INT\tSTRING\tSTRING\tINT\r\nID\tCity\tProvince\tFlag\r\n10\t\xb1\xb1\xbe\xa9\t\xb1\xb1\xbe\xa9\t0\r\n20\tOther\tSouth\t1\r\n11\tSecond\t\xb1\xb1\xbe\xa9\t0\r\n");Require(c.provinces.size()==2 && c.provinces[0].name=="\xe5\x8c\x97\xe4\xba\xac" && c.provinces[0].cities.size()==2 && c.provinces[0].cities[1].id==11,"legacy schema");});
    Test("text_modern_five_columns_utf8_bom_and_lf",[]{auto c=Parse("\xef\xbb\xbf" "INT\tINT\tSTRING\tSTRING\tINT\n# comment\nIndex\tID\tCity\tProvince\tFlag\n1\t10\t\xe4\xb8\xad\xe6\x96\x87\tNorth\t0");Require(c.provinces[0].cities[0].id==10 && c.provinces[0].cities[0].name=="\xe4\xb8\xad\xe6\x96\x87","modern text");});
    Test("text_empty_table_is_valid_but_missing_header_rejected",[]{Require(Parse("INT\tSTRING\tSTRING\tINT\nA\tB\tC\tD\n").provinces.empty(),"empty text");Reject("INT\tSTRING\tSTRING\tINT\n");});
    Test("text_bad_types_columns_nul_and_integer_rejected",[]{Reject("INT\tFLOAT\tSTRING\tINT\nA\tB\tC\tD\n");Reject("INT\tSTRING\tSTRING\tINT\nA\tB\tC\tD\n1\tA\tB\n");Reject(std::string("INT\0STRING",10));for(const char* value:{"x","2147483648","-2147483649","1.5","-"})Reject(std::string("INT\tSTRING\tSTRING\tINT\nA\tB\tC\tD\n")+value+"\tA\tB\t0\n");});
    Test("text_empty_names_duplicate_city_and_signed_id_preserved",[]{auto c=Parse("INT\tSTRING\tSTRING\tINT\nA\tB\tC\tD\n-1\t\t\t0\n-1\tTwo\t\t0\n");Require(c.provinces.size()==1 && c.provinces[0].name.empty() && c.provinces[0].cities.size()==2 && c.provinces[0].cities[0].id==-1,"text preservation");});
    Test("text_matches_binary_catalog",[]{auto c=Parse("INT\tSTRING\tSTRING\tINT\nA\tB\tC\tD\n20\tTown A\tNorth\t0\n30\tTown B\tSouth\t0\n21\tTown C\tNorth\t0\n");auto b=Parse(Sample());Require(c.provinces.size()==b.provinces.size() && c.provinces[0].cities[1].id==b.provinces[0].cities[1].id && c.provinces[1].name==b.provinces[1].name,"binary/text differ");});
    Test("lua_register_four_methods_and_same_loop_missing_to_real",[]{
        const char* code="local n=DataPool:GetProvincesNum(); local got={};for i=0,n-1 do local id,name=DataPool:EnumProvinces(i);got[id]=name end; count=n; north=got[0]";
        {Fixture f(false);f.Generated();f.state.Run(code);Require(LuaApiGen::GetMissingCallCount()==1,"baseline count");}
        Fixture f(false);Require(f.Install(&f.catalog)==4 && f.Install(&f.catalog)==0,"registration count");f.Generated();f.state.Run(code);f.state.Run("assert(count==2 and north=='North')");Require(LuaApiGen::GetMissingCallCount()==0,"real loop still missing");
    });
    Test("lua_count_enum_and_city_queries_exact_results",[]{Fixture f;f.state.Run("function count(...) return arg.n end; assert(count(DataPool:GetProvincesNum())==1); assert(DataPool:GetProvincesNum()==2); assert(count(DataPool:EnumProvinces(0))==2); local id,n=DataPool:EnumProvinces(1);assert(id==1 and n=='South');assert(DataPool:GetCityNumFromOneProvinceId(0)==2);assert(count(DataPool:GetCityNumFromOneProvinceId(0))==1);assert(count(DataPool:NumCityFromOneProvince(0,1))==2);local city,name=DataPool:NumCityFromOneProvince(0,1);assert(city==21 and name=='Town C')");});
    Test("lua_fractional_indices_truncate_and_extra_args_ignored",[]{Fixture f;f.state.Run("local id,n=DataPool:EnumProvinces(1.9,'extra');assert(id==1 and n=='South');assert(DataPool:GetCityNumFromOneProvinceId(0.9,false)==2);local id,n=DataPool:NumCityFromOneProvince(0.9,1.9,'extra');assert(id==21 and n=='Town C');assert(DataPool:GetProvincesNum(false)==2)");});
    Test("lua_enum_range_errors_and_city_range_sentinels",[]{Fixture f;f.state.Run("assert(not pcall(DataPool.EnumProvinces,DataPool,-1));assert(not pcall(DataPool.EnumProvinces,DataPool,2));assert(DataPool:GetCityNumFromOneProvinceId(-1)==-1 and DataPool:GetCityNumFromOneProvinceId(2)==-1);local id,n=DataPool:NumCityFromOneProvince(0,-1);assert(id==-1 and n=='');local id,n=DataPool:NumCityFromOneProvince(-1,0);assert(id==-1 and n=='');local id,n=DataPool:NumCityFromOneProvince(0,2);assert(id==-1 and n=='')");});
    Test("lua_non_numeric_indices_reject_numeric_strings_and_nil",[]{Fixture f;f.state.Run("for _,value in ipairs({'1',false,{},function() end}) do assert(not pcall(DataPool.EnumProvinces,DataPool,value));assert(not pcall(DataPool.GetCityNumFromOneProvinceId,DataPool,value));assert(not pcall(DataPool.NumCityFromOneProvince,DataPool,0,value)) end;assert(not pcall(DataPool.EnumProvinces,DataPool));assert(not pcall(DataPool.NumCityFromOneProvince,DataPool,0))");});
    Test("lua_nan_infinity_and_int32_overflow_safe",[]{Fixture f;for(double n:{(std::numeric_limits<double>::quiet_NaN)(),(std::numeric_limits<double>::infinity)(),2147483648.0,-2147483649.0}){f.state.Number("n",n);f.state.Run("assert(not pcall(DataPool.EnumProvinces,DataPool,n));assert(DataPool:GetCityNumFromOneProvinceId(n)==-1);local id,name=DataPool:NumCityFromOneProvince(0,n);assert(id==-1 and name=='')");}});
    Test("lua_empty_catalog_count_and_lookup_behavior",[]{Fixture f;f.catalog.provinces.clear();f.state.Run("assert(DataPool:GetProvincesNum()==0);assert(not pcall(DataPool.EnumProvinces,DataPool,0));assert(DataPool:GetCityNumFromOneProvinceId(0)==-1)");});
    Test("lua_utf8_names_and_cstring_boundary",[]{Fixture f;f.catalog.provinces[0].name="\xe4\xb8\xad\xe6\x96\x87";f.catalog.provinces[0].cities[0].name=std::string("A\0suffix",8);f.state.Run("local id,n=DataPool:EnumProvinces(0);assert(string.len(n)==6);local id,n=DataPool:NumCityFromOneProvince(0,0);assert(n=='A')");});
    Test("lua_missing_catalog_visible_for_each_query",[]{Fixture f(false);f.Install(nullptr);f.state.Run("assert(not pcall(DataPool.GetProvincesNum,DataPool));assert(not pcall(DataPool.EnumProvinces,DataPool,0));assert(not pcall(DataPool.GetCityNumFromOneProvinceId,DataPool,0));assert(not pcall(DataPool.NumCityFromOneProvince,DataPool,0,0))");});
    Test("lua_nil_only_registration_preserves_slots_receiver_and_meta",[]{Fixture f(false);f.state.Run("saved=DataPool;savedmeta=getmetatable(DataPool);ProvinceMeta.GetProvincesNum=false;ProvinceMeta.EnumProvinces=function()return 99 end;ProvinceMeta.GetCityNumFromOneProvinceId=42;ProvinceMeta.NumCityFromOneProvince='kept'");Require(f.Install(&f.catalog)==0,"overwrites");f.state.Run("assert(DataPool==saved and getmetatable(DataPool)==savedmeta and DataPool.GetProvincesNum==false and DataPool:EnumProvinces()==99)");});
    Test("lua_catalog_pointer_is_per_state",[]{Fixture a,b;b.catalog.provinces.clear();a.state.Run("assert(DataPool:GetProvincesNum()==2)");b.state.Run("assert(DataPool:GetProvincesNum()==0)");});
    Test("lua_registration_requires_dedicated_receiver_meta",[]{State s;auto globals=s.p->GetGlobals();bool threw=false;try{CysHostProvinces::Register(globals,nullptr);}catch(const std::runtime_error&){threw=true;}Require(threw,"missing receiver accepted");LuaPlus::LuaObject receiver=s.p->BoxPointer(&threw);globals.SetObject("DataPool",receiver);const int top=lua_gettop(s.p->GetCState());threw=false;try{CysHostProvinces::Register(globals,nullptr);}catch(const std::runtime_error&){threw=true;}Require(threw && lua_gettop(s.p->GetCState())==top,"default meta or stack leak");});
    if(argc>1)Test("real_city_table_has_nonzero_provinces_and_all_rows",[&]{std::ifstream file(argv[1],std::ios::binary);Require(bool(file),"reference input");std::string bytes((std::istreambuf_iterator<char>(file)),{});auto c=Parse(bytes);std::size_t cities=0;for(const auto& p:c.provinces)cities+=p.cities.size();Require(!c.provinces.empty() && cities>0,"no real records");std::printf("REFERENCE provinces=%zu cities=%zu network_calls=0\n",c.provinces.size(),cities);});
    std::printf("RESULT passed=%u failed=%u total=%u\n",passed,failed,passed+failed);return failed?1:0;
}
