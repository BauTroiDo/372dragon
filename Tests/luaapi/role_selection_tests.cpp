// Real CharSel declaration/state methods and real Lua binding, with renderer doubles.
#include "LuaPlus.h"
#include <cstdio>
#include <stdexcept>
#include <string>
#include <fstream>
#include <iterator>

using namespace LuaPlus;
typedef void VOID;
typedef bool BOOL;
typedef unsigned UINT;
typedef int INT;
typedef char TCHAR;
typedef unsigned GUID_t;
enum HUMAN_EQUIP { HEQUIP_TEST };
struct DB_CHAR_BASE_INFO { int unused; };
class CGamePro_CharSel;
class CGameProcedure
{
public:
    static CGamePro_CharSel* s_pProcCharSel;
    virtual ~CGameProcedure() {}
};
#include "role_header.inl"
#include "role_state.inl"
CGamePro_CharSel* CGameProcedure::s_pProcCharSel = nullptr;
CModelShowInLoginUI::CModelShowInLoginUI() : m_pAvatar(nullptr) {}
CModelShowInLoginUI::~CModelShowInLoginUI() {}
CGamePro_CharSel::~CGamePro_CharSel() {}
VOID CGamePro_CharSel::Init() {}
VOID CGamePro_CharSel::Tick() {}
VOID CGamePro_CharSel::Render() {}
VOID CGamePro_CharSel::Release() {}
VOID CGamePro_CharSel::CloseRequest() {}
VOID CGamePro_CharSel::ProcessInput() {}

#define TDThrow(message) throw std::runtime_error(message)
namespace SCRIPT_SANDBOX
{
class CGameProduce_Login
{
public:
    static LuaObject* s_pMetaTable;
    INT GetCurSelectRole(LuaState* state);
    INT GetRoleCount(LuaState* state);
};
LuaObject* CGameProduce_Login::s_pMetaTable = nullptr;
}
#include "role_binding.inl"

namespace
{
unsigned passed = 0, failed = 0;
void Check(bool condition) { if (!condition) throw std::runtime_error("assertion"); }
template<class F> void Test(const char* name, F function)
{
    try { function(); ++passed; std::printf("PASS %s\n", name); }
    catch (...) { ++failed; std::printf("FAIL %s\n", name); }
}
void Run(LuaState* state, const std::string& code)
{
    lua_State* raw = state->GetCState(); const int top = lua_gettop(raw);
    int rc = luaL_loadbuffer(raw, code.data(), code.size(), "=role-selection-test");
    if (!rc) rc = lua_pcall(raw, 0, 0, 0);
    if (rc) { lua_settop(raw, top); throw std::runtime_error("Lua status"); }
    Check(lua_gettop(raw) == top);
}
}

int main(int argc, char** argv)
{
    CGamePro_CharSel selected;
    Test("B constructor empty count and selected slot are zero", [&] {
        Check(selected.GetCurRoleCount() == 0 && selected.GetCurSelectRole() == 0);
    });
    Test("selection is independently stored and not a constant", [&] {
        selected.RestoreRoleSelection(2); Check(selected.GetCurSelectRole() == 2);
        selected.m_iCurSelRoleDel = 1; Check(selected.GetCurSelectRole() == 2);
        selected.RestoreRoleSelection(1); Check(selected.m_iCurSelRoleDel == 1 && selected.GetCurSelectRole() == 1);
        selected.m_iCurSelRoleDel = -1; Check(selected.GetCurSelectRole() == 1);
    });
    Test("B restored negative clamps to zero", [&] {
        selected.RestoreRoleSelection(-1); Check(selected.GetCurSelectRole() == 0);
        selected.RestoreRoleSelection(-2147483647); Check(selected.GetCurSelectRole() == 0);
    });
    Test("restore does not invent a character count", [&] {
        selected.RestoreRoleSelection(2); Check(selected.GetCurRoleCount() == 0 && selected.GetCurSelectRole() == 2);
    });
    Test("invalid selection leaves stored state and deletion unchanged", [&] {
        Check(!selected.SelectRoleIndex(0)); Check(!selected.SelectRoleIndex(-1));
        Check(!selected.SelectRoleIndex(3)); Check(selected.GetCurSelectRole() == 2 && selected.m_iCurSelRoleDel == -1);
    });
    Test("native selection follows the admitted role range", [&] {
        selected.m_iCharacterCount = 3;
        Check(selected.SelectRoleIndex(1) && selected.GetCurSelectRole() == 1);
        Check(selected.SelectRoleIndex(2) && selected.GetCurSelectRole() == 2);
        Check(selected.SelectRoleIndex(0) && selected.GetCurSelectRole() == 0);
        Check(!selected.SelectRoleIndex(3) && selected.GetCurSelectRole() == 0);
    });
    Test("new account resets slot and null account is ignored", [&] {
        selected.RestoreRoleSelection(2); selected.SetUserName(nullptr); Check(selected.GetCurSelectRole() == 2);
        selected.SetUserName("synthetic"); Check(selected.GetCurSelectRole() == 0);
    });
    LuaStateOwner state;
    LuaState* lua = state.Get();
    CGameProcedure::s_pProcCharSel = &selected;
    SCRIPT_SANDBOX::CGameProduce_Login host;
    LuaObject meta = lua->GetGlobals().CreateTable("RoleHostMeta");
    meta.SetObject("__index", meta);
    SCRIPT_SANDBOX::CGameProduce_Login::s_pMetaTable = &meta;
    #include "role_registration.inl"
    LuaObject box = lua->BoxPointer(&host); box.SetMetaTable(meta);
    lua->GetGlobals().SetObject("GameProduceLogin", box);
    Test("actual host registration reads updated state with one result", [&] {
        selected.RestoreRoleSelection(2);
        Run(lua, "local a,b=GameProduceLogin:GetCurSelectRole(); assert(a==2 and b==nil); assert(GameProduceLogin:GetRoleCount()==3)");
        selected.RestoreRoleSelection(1);
        Run(lua, "assert(GameProduceLogin:GetCurSelectRole()==1)");
    });
    Test("missing procedure fails explicitly without fake zero", [&] {
        CGameProcedure::s_pProcCharSel = nullptr;
        bool threw = false; try { host.GetCurSelectRole(lua); } catch (const std::runtime_error&) { threw = true; }
        CGameProcedure::s_pProcCharSel = &selected; Check(threw);
    });
    Test("Canonical SelectRole empty OnEvent reaches Show without role access", [&] {
        Check(argc == 2); std::ifstream file(argv[1], std::ios::binary); Check(file.good());
        const std::string script((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
        selected.m_iCharacterCount = 0; selected.RestoreRoleSelection(0);
        Run(lua, R"LUA(
            shown=0; hidden=0
            local ui={}
            function ui:RegisterEvent(_) end
            function ui:SetText(_) end
            function ui:SetProperty(_,__) end
            function ui:GetProperty(_) return '1080' end
            function ui:Show() if self==this then shown=shown+1 end end
            function ui:Hide() if self==this then hidden=hidden+1 end end
            this=setmetatable({}, {__index=ui})
            function AxTrace(...) end
            setmetatable(_G,{__index=function(t,k)
                if string.sub(k,1,11)=='SelectRole_' then
                    local value=setmetatable({}, {__index=ui}); rawset(t,k,value); return value
                end
            end})
        )LUA");
        Run(lua, script);
        Run(lua, "LoginSelectRole_PreLoad(); LoginSelectRole_OnLoad(); LoginSelectRole_OnEvent('GAMELOGIN_OPEN_SELECT_CHARACTOR'); assert(shown==1); LoginSelectRole_OnEvent('GAMELOGIN_CLOSE_SELECT_CHARACTOR'); assert(hidden==1)");
    });
    SCRIPT_SANDBOX::CGameProduce_Login::s_pMetaTable = nullptr;
    CGameProcedure::s_pProcCharSel = nullptr;
    std::printf("RESULT passed=%u failed=%u renderer_doubles=1 real_state_and_binding=1 game_runtime=0\n", passed, failed);
    return failed ? 1 : 0;
}
