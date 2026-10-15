// CYS: actual dispatcher/action/input method bodies with isolated service doubles.
//
// CYS-TESTRED 19/09 - THIS SUITE DOES NOT BUILD, AND MAKING IT BUILD WOULD MAKE IT LIE. Read before touching it.
// Measured today, HEAD e80fcfab: build_rc=2, 15 errors, all inside the extracted bodies:
//   input.inl    C2065 'm_cysInjectedKeys' (x8), C3861 'AddEvent' (x2)   <- CInputSystem::Tick, CYS-SKILL
//   keyboard.inl C3861 'TDU_Log', C2653 'CysAccel', C3861 'ProcessKey'   <- ProcessInput_Keybord, CYS-MOVE2
// This is NOT another branch's uncommitted work: extracting from `git show HEAD:` copies of the four sources
// produces .inl files byte-identical to the ones from the working tree (evidence
// Build/Logs/2026-09-19-tests-red5/head-control). The suite is broken at HEAD and has been since 18/09.
//
// Adding the four missing doubles would compile, and would be worthless. CGamePro_Main::ProcessInput_Keybord was
// 435 lines when this suite was written (733c29cd, 12/09) and 476 on 17/09; since 31a4f118 (18/09, CYS-MOVE2) it
// is 36 lines that do exactly two things - ask CInputSystem::AllowGameHotKey, then delegate to
// CysAccel::ProcessKey. Every key decision the cases below assert (Escape, F1..F10 -> MainMenuBar_DoAction, camera
// keys, Tab/scene map, chat history, the dead/edit-box gates) now lives in CysAccelTable.cpp, which pulls 25 real
// client headers and cannot be linked into this harness. Stubbing CysAccel::ProcessKey to satisfy them would mean
// the cases verify the stub - green with no meaning, the one outcome worse than red.
//
// The fix is a decision, not an edit; the proposal is in Timeline/handoff/tests-red5.md dot 4:
//   (a) 10 of the 24 cases never call Key(KC_...) at all: registration, the int32/NaN policy, protected service
//       exceptions, gate latching. They need only the real CysHostHotKeys.cpp and CysHotKeys::Gate, no
//       extraction whatsoever, and compile today;
//   (b) the dispatcher cases belong on CysAccelCore.h - header-only, engine-free (<cstdio>/<cstdlib>/<cstring>),
//       holding Pack/DikToVk/IsTextKey/IsValidChatBinding/KeyText and the 79-row Table::Find - which has no test
//       at all right now and needs no copied code;
//   (c) what is genuinely left in ProcessInput_Keybord is the gate seam, worth 2-3 cases.
// General rule this suite paid for: a test that copies a body out of a living file rots with that file, and the
// rot is invisible to every measurement except running the test.
#include "CysHostHotKeys.h"
#include "CysHotKeyGate.h"
#include "LuaApiGen.h"
#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdio>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

using INT = int;
using BOOL = int;
using VOID = void;
using HWND = int;
using STRING = std::string;
const BOOL TRUE = 1, FALSE = 0;
#include "keys.inl"
using InputEventQueue = std::vector<InputEvent>;
HWND GetActiveWindow() { return 1; }
bool gbTestMinimap = true;

enum EventId { GE_ACCELERATE_KEYSEND, GE_SEND_MAIL, GE_TOGLE_SCENEMAP,
               GE_CHAT_CLOSED, GE_CHAT_OPEN, GE_NEW_DEBUGMESSAGE };
struct CEventSystem
{
    static CEventSystem instance;
    std::vector<std::string> events;
    static CEventSystem* GetMe() { return &instance; }
    void PushEvent(int event, const char* value = "") { events.push_back(std::to_string(event) + ":" + value); }
    void PushEvent(int event, const std::vector<STRING>&) { PushEvent(event, "scene"); }
};
CEventSystem CEventSystem::instance;
struct Ui
{
    std::string edit;
    bool consumeKeys = false, capture = false;
    unsigned injections = 0, escapes = 0;
    BOOL IsIMEEditboxEmpty() { return edit.empty(); }
    BOOL IsIMEEditboxActive(const char* name) { return edit == name; }
    BOOL IsWindowShow(const char*) { return false; }
    void OnPushEcsape() { ++escapes; }
    void InjectInput();
};
struct Gfx
{
    unsigned calls = 0;
    void Camera_AddDirection(float) { ++calls; }
    void Camera_SetZoom(bool, int) { ++calls; }
    void Debug_ToggleShowDebugPanel() { ++calls; }
};
struct CHelperSystem { unsigned calls = 0; void GotoAnchorHelp(const STRING&) { ++calls; } };
struct CAI_Base {};
struct CAI_MySelf : CAI_Base { unsigned jumps = 0; void PushCommand_Jump() { ++jumps; } };
struct CharacterData { BOOL Get_IsInStall() { return FALSE; } };
struct CObject_PlayerMySelf
{
    bool dead = false, rendered = true;
    CharacterData data;
    CAI_MySelf ai;
    void* GetRenderInterface() { return rendered ? this : nullptr; }
    bool IsDie() { return dead; }
    CharacterData* GetCharacterData() { return &data; }
    CAI_Base* CharacterLogic_GetAI() { return &ai; }
};
struct CObjectManager
{
    static CObjectManager instance;
    CObject_PlayerMySelf player;
    static CObjectManager* GetMe() { return &instance; }
    CObject_PlayerMySelf* GetMySelf() { return &player; }
};
CObjectManager CObjectManager::instance;
struct CGameInterface
{
    static CGameInterface instance;
    unsigned cancels = 0;
    static CGameInterface* GetMe() { return &instance; }
    void Skill_CancelAction() { ++cancels; }
};
CGameInterface CGameInterface::instance;
struct SceneDefine { const char* szSceneMap = "test"; };
struct Scene { SceneDefine define; SceneDefine* GetSceneDefine() { return &define; } };
struct CWorldManager
{
    static CWorldManager instance;
    Scene scene;
    static CWorldManager* GetMe() { return &instance; }
    Scene* GetActiveScene() { return &scene; }
};
CWorldManager CWorldManager::instance;
namespace SCRIPT_SANDBOX { namespace Talk {
    struct Talk { unsigned history = 0; void HandleKey_Shift_ArrowUp(int) { ++history; }
        void HandleKey_Shift_ArrowDown(int) { ++history; } } s_Talk;
} }
struct CInputSystem
{
    static CInputSystem instance;
    CysHotKeys::Gate m_cysHotKeys;
    InputEventQueue m_vEventQueue, pending;
    HWND m_hWnd = 1;
    bool m_bFirstActive = false;
    InputCapture capture = ICS_NONE;
    std::array<bool, 256> rawKeys{};
    static CInputSystem* GetMe() { return &instance; }
    void SetCanUseHotKey(INT value);
    BOOL AllowGameHotKey(const InputEvent& event);
    void Tick();
    void KeybordTick() { m_vEventQueue = pending; pending.clear(); }
    void MouseTick() {}
    InputCapture GetCapture() { return capture; }
    InputEventQueue& GetInputQueue() { return m_vEventQueue; }
    BOOL IsKeyDown(KeyCode key) { return rawKeys[key]; }
};
CInputSystem CInputSystem::instance;
struct CGameProcedure
{
    static CInputSystem* s_pInputSystem;
    static Ui* s_pUISystem;
    static Gfx* s_pGfxSystem;
    static CHelperSystem* s_pHelperSystem;
    static bool m_bNeedFreshMinimap, m_bWaitNeedFreshMinimap;
    static void ProcessActiveInput();
};
CInputSystem* CGameProcedure::s_pInputSystem = &CInputSystem::instance;
Ui ui;
Gfx gfx;
CHelperSystem helper;
Ui* CGameProcedure::s_pUISystem = &ui;
Gfx* CGameProcedure::s_pGfxSystem = &gfx;
CHelperSystem* CGameProcedure::s_pHelperSystem = &helper;
bool CGameProcedure::m_bNeedFreshMinimap = false, CGameProcedure::m_bWaitNeedFreshMinimap = false;
struct CGamePro_Main : CGameProcedure { void ProcessInput_Keybord(); } mainProcedure;
unsigned mouseDispatches = 0;
void CGameProcedure::ProcessActiveInput() { mainProcedure.ProcessInput_Keybord(); ++mouseDispatches; }
void Ui::InjectInput()
{
    ++injections;
    auto& input = CInputSystem::instance;
    if (capture) input.capture = ICS_UI;
    if (consumeKeys) for (auto& event : input.m_vEventQueue) event.bProcessed = TRUE;
}
struct CActionItem
{
    unsigned executes = 0, prepareCalls = 0;
    bool prepared = false;
    void DoActionPrepare(bool value) { prepared = value; ++prepareCalls; }
    void DoAction() { ++executes; }
};
struct CActionSystem
{
    struct ACTIONBAR_ITEM { INT idActionItem = 0; };
    static CActionSystem instance;
    static const INT s_MainMenuBarNum = 10;
    std::array<ACTIONBAR_ITEM, 10> m_barMain;
    std::array<CActionItem, 10> actions;
    CActionSystem() { for (INT i = 0; i < 10; ++i) m_barMain[i].idActionItem = i; }
    static CActionSystem* GetMe() { return &instance; }
    CActionItem* GetAction(INT id) { return id >= 0 && id < 10 ? &actions[id] : nullptr; }
    void MainMenuBar_DoAction(INT index, BOOL prepare);
    void MainMenuBar_CancelPrepare(INT index);
};
CActionSystem CActionSystem::instance;
// These are verbatim method bodies extracted by the runner, not test reimplementations.
#include "input.inl"
#include "action.inl"
#include "keyboard.inl"

namespace
{
    unsigned passed = 0, failed = 0;
    std::vector<std::string> missing;
    void Require(bool value, const char* reason) { if (!value) throw std::runtime_error(reason); }
    void Log(const char* line) { missing.emplace_back(line); }
    template<class F> void Test(const char* name, F run)
    {
        try { run(); ++passed; std::printf("PASS %s\n", name); }
        catch (const LuaPlus::LuaException& e) { ++failed; std::printf("FAIL %s: %s\n", name, e.GetMessage()); }
        catch (const std::exception& e) { ++failed; std::printf("FAIL %s: %s\n", name, e.what()); }
    }
    void ResetGame()
    {
        CInputSystem::instance = CInputSystem{};
        CActionSystem::instance = CActionSystem{};
        CObjectManager::instance = CObjectManager{};
        CGameInterface::instance = CGameInterface{};
        CEventSystem::instance.events.clear();
        ui = Ui{}; gfx = Gfx{}; helper = CHelperSystem{};
        SCRIPT_SANDBOX::Talk::s_Talk.history = 0;
        mouseDispatches = 0;
    }
    void Key(KeyCode key, bool down, bool processed = false)
    {
        auto& input = CInputSystem::instance;
        input.pending.push_back({down ? EVENT_KEY_DOWN : EVENT_KEY_UP, key, processed});
        input.Tick();
    }
    struct Fixture
    {
        LuaPlus::LuaState* state = LuaPlus::LuaState::Create(true);
        unsigned callbackCalls = 0;
        int throwKind = 0;
        Fixture(bool real = true)
        {
            ResetGame(); missing.clear();
            LuaApiGen::SetLogSink(Log); LuaApiGen::ResetMissingCallCounts();
            auto globals = state->GetGlobals();
            auto meta = globals.CreateTable("TestDataPoolMeta");
            meta.SetObject("__index", meta);
            LuaPlus::LuaObject receiver = state->BoxPointer(this);
            receiver.SetMetaTable(meta);
            globals.SetObject("DataPool", receiver);
            if (real) Require(Register() == 1, "real registration failed");
            LuaApiGen::Register_DataPool(meta);
        }
        ~Fixture() { LuaPlus::LuaState::Destroy(state); }
        static void Set(void* ctx, std::int32_t value)
        {
            auto& f = *static_cast<Fixture*>(ctx); ++f.callbackCalls;
            if (f.throwKind == 1) throw std::runtime_error("PRIVATE_HOTKEY_DATA");
            if (f.throwKind == 2) throw LuaPlus::LuaException("PRIVATE_HOTKEY_DATA");
            CInputSystem::GetMe()->SetCanUseHotKey(value);
        }
        unsigned Register()
        {
            CysHostHotKeys::Services service; service.context = this; service.setCanUseHotKey = Set;
            auto globals = state->GetGlobals();
            return CysHostHotKeys::Register(globals, service);
        }
        void Run(const char* text)
        {
            const auto raw = state->GetCState(); const int top = lua_gettop(raw);
            if (state->DoString(text) != 0) throw std::runtime_error(lua_tostring(raw, -1));
            Require(lua_gettop(raw) == top, "Lua stack changed");
        }
        void Number(double value)
        { lua_pushnumber(state->GetCState(), value); lua_setglobal(state->GetCState(), "value"); }
    };
}

int main()
{
    Test("same Lua before: stub leaves action enabled", [] {
        Fixture f(false); f.Run("DataPool:SetCanUseHotKey(0)"); Key(KC_F1, true); Key(KC_F1, false);
        Require(LuaApiGen::GetMissingCallCount() == 1 && missing.size() == 1, "baseline missing census");
        Require(CActionSystem::instance.actions[0].executes == 1, "baseline shortcut must execute");
        std::puts("BEFORE missing=1 lines=1 action_executes=1");
    });
    Test("same Lua after: blocks actual dispatch and action", [] {
        Fixture f; f.Run("DataPool:SetCanUseHotKey(0)"); Key(KC_F1, true); Key(KC_F1, false);
        Require(LuaApiGen::GetMissingCallCount() == 0 && missing.empty(), "after missing census");
        Require(CActionSystem::instance.actions[0].executes == 0, "blocked shortcut executed");
        std::puts("AFTER missing=0 lines=0 action_executes=0");
    });
    Test("initial enabled / all ten toolbar keys", [] {
        Fixture f;
        for (int i = 0; i < 10; ++i) { Key(static_cast<KeyCode>(KC_F1+i), true); Key(static_cast<KeyCode>(KC_F1+i), false);
            Require(CActionSystem::instance.actions[i].executes == 1, "toolbar key failed"); }
    });
    Test("disable while pressed cancels preparation without action", [] {
        Fixture f; Key(KC_F2, true); Require(CActionSystem::instance.actions[1].prepared, "no prepare");
        f.Run("DataPool:SetCanUseHotKey(0)");
        Require(!CActionSystem::instance.actions[1].prepared, "visual still held");
        Key(KC_F2, false); Require(CActionSystem::instance.actions[1].executes == 0, "release executed");
    });
    Test("disable then re-enable before release suppresses stale action", [] {
        Fixture f; Key(KC_F3, true); f.Run("DataPool:SetCanUseHotKey(0); DataPool:SetCanUseHotKey(1)");
        Key(KC_F3, false); Require(CActionSystem::instance.actions[2].executes == 0, "stale release");
        Key(KC_F3, true); Key(KC_F3, false); Require(CActionSystem::instance.actions[2].executes == 1, "fresh press lost");
    });
    Test("blocked press then re-enable does not create an action", [] {
        Fixture f; f.Run("DataPool:SetCanUseHotKey(0)"); Key(KC_F4, true);
        f.Run("DataPool:SetCanUseHotKey(1)"); Key(KC_F4, false);
        Require(CActionSystem::instance.actions[3].executes == 0, "blocked press released as action");
    });
    Test("nonzero values retain raw int32 and enable", [] {
        Fixture f;
        for (double value : {2.9, -3.8, 2147483647.0, -2147483648.0}) {
            f.Number(value); f.Run("DataPool:SetCanUseHotKey(value)");
            Require(CInputSystem::instance.m_cysHotKeys.Value() == static_cast<std::int32_t>(value), "raw value changed");
            Key(KC_F5, true); Key(KC_F5, false);
        }
        Require(CActionSystem::instance.actions[4].executes == 4, "nonzero not enabled");
    });
    Test("fraction truncates to zero", [] { Fixture f; f.Run("DataPool:SetCanUseHotKey(-0.75)"); Key(KC_A, true);
        Require(CEventSystem::instance.events.empty(), "fraction did not disable"); });
    Test("invalid argument types and zero return values", [] {
        Fixture f; f.Run("function count(...) return arg.n end; "
            "assert(count(DataPool:SetCanUseHotKey(0))==0); "
            "assert(count(DataPool:SetCanUseHotKey())==0); "
            "assert(count(DataPool:SetCanUseHotKey(nil))==0); "
            "assert(count(DataPool:SetCanUseHotKey(true))==0); "
            "assert(count(DataPool:SetCanUseHotKey('1'))==0); "
            "assert(count(DataPool:SetCanUseHotKey({}))==0)");
        Require(f.callbackCalls == 1 && CInputSystem::instance.m_cysHotKeys.Value() == 0, "invalid type reached service");
    });
    Test("NaN infinity and overflow use int32 minimum policy", [] {
        Fixture f; for (double value : {std::numeric_limits<double>::quiet_NaN(), std::numeric_limits<double>::infinity(), -std::numeric_limits<double>::infinity(), 2147483648.0, -2147483649.0}) {
            f.Number(value); f.Run("DataPool:SetCanUseHotKey(value)");
            Require(CInputSystem::instance.m_cysHotKeys.Value() == (std::numeric_limits<std::int32_t>::min)(), "invalid conversion"); }
    });
    Test("Escape shortcut is blocked and restored", [] {
        Fixture f; f.Run("DataPool:SetCanUseHotKey(0)"); Key(KC_ESCAPE,true);
        Require(ui.escapes == 0 && CGameInterface::instance.cancels == 0, "disabled Escape");
        f.Run("DataPool:SetCanUseHotKey(1)"); Key(KC_ESCAPE,true);
        Require(ui.escapes == 1 && CGameInterface::instance.cancels == 1, "enabled Escape");
    });
    Test("camera repeat and shortcut event are blocked", [] {
        Fixture f; f.Run("DataPool:SetCanUseHotKey(0)");
        for (int i=0;i<4;++i) Key(KC_LEFT,true); Key(KC_B,true); Key(KC_TAB,true);
        Require(gfx.calls == 0 && CEventSystem::instance.events.empty(), "shortcut side effects");
    });
    Test("UI gets disabled keys before gameplay and mouse stays active", [] {
        Fixture f; f.Run("DataPool:SetCanUseHotKey(0)"); Key(KC_F1,true);
        Require(ui.injections == 1 && mouseDispatches == 1, "UI/mouse skipped");
        Require(CInputSystem::instance.m_vEventQueue[0].bProcessed, "blocked event not consumed");
    });
    Test("UI capture and consumed input retain routing", [] {
        Fixture f; ui.consumeKeys = true; Key(KC_F1,true); Key(KC_F1,false);
        Require(CActionSystem::instance.actions[0].prepareCalls == 0, "consumed key leaked");
        ui.capture = true; Key(KC_F1,true); Require(mouseDispatches == 2, "capture not honored");
        Key(KC_F1,false); Require(ui.injections == 4 && mouseDispatches == 2, "UI capture branch changed");
    });
    Test("GAME capture still applies shortcut gate", [] {
        Fixture f; CInputSystem::instance.capture=ICS_GAME; f.Run("DataPool:SetCanUseHotKey(0)"); Key(KC_F1,true);
        Require(ui.injections == 0 && mouseDispatches == 1 && !CActionSystem::instance.actions[0].prepared, "game capture gate");
    });
    Test("IME edit focus / modifiers preserve enabled behavior", [] {
        Fixture f; ui.edit="Chat_Frame_EditBox"; Key(KC_A,true); Key(KC_UP,true);
        Require(CEventSystem::instance.events.empty() && SCRIPT_SANDBOX::Talk::s_Talk.history == 1, "edit handling changed");
        CInputSystem::instance.rawKeys[KC_LMENU]=true; Key(KC_TAB,true);
        Require(CEventSystem::instance.events.empty(), "Alt Tab shortcut leaked");
        f.Run("DataPool:SetCanUseHotKey(0)");
        Require(CInputSystem::instance.IsKeyDown(KC_LMENU), "raw modifier state changed");
    });
    Test("death and first activation gates still apply", [] {
        Fixture f; CObjectManager::instance.player.dead=true; Key(KC_F1,true); Key(KC_F1,false);
        Require(CActionSystem::instance.actions[0].prepareCalls == 0, "dead toolbar key");
        CInputSystem::instance.m_bFirstActive=true; Key(KC_ESCAPE,true);
        Require(ui.escapes == 0, "first activation dispatched");
    });
    Test("registration is idempotent and preserves receiver", [] {
        Fixture f; f.Run("receiver=DataPool; meta=getmetatable(DataPool); fn=DataPool.SetCanUseHotKey");
        Require(f.Register() == 0, "registration replaced host");
        f.Run("assert(receiver==DataPool and meta==getmetatable(DataPool) and fn==DataPool.SetCanUseHotKey)");
    });
    Test("registration preserves non-nil existing method", [] {
        Fixture f(false); f.Run("getmetatable(DataPool).SetCanUseHotKey=false");
        Require(f.Register() == 0, "non-nil method replaced");
    });
    Test("service exceptions are protected and payload-free", [] {
        Fixture f; for (int kind : {1,2}) { f.throwKind=kind; f.Run("ok,err=pcall(function() DataPool:SetCanUseHotKey(0) end); assert(not ok); assert(not string.find(err,'PRIVATE_HOTKEY_DATA'))"); }
        f.throwKind=0; f.Run("DataPool:SetCanUseHotKey(0)"); Require(CInputSystem::instance.m_cysHotKeys.Value() == 0, "service did not recover");
    });
    Test("missing receiver rejects without stack leak", [] {
        auto* state=LuaPlus::LuaState::Create(true); bool rejected=false;
        const int top=lua_gettop(state->GetCState());
        { auto globals=state->GetGlobals();
          try { CysHostHotKeys::Register(globals, {}); } catch (const std::runtime_error&) { rejected=true; } }
        Require(rejected && lua_gettop(state->GetCState())==top, "missing receiver not rejected"); LuaPlus::LuaState::Destroy(state);
    });
    Test("cancellation exception still blocks all pending releases", [] {
        CysHotKeys::Gate gate;
        gate.Allow(KC_F1,true,false); gate.Allow(KC_F2,true,false);
        bool caught=false;
        try { gate.Set(0, [](unsigned) { throw std::runtime_error("cancel failed"); }); }
        catch (const std::runtime_error&) { caught=true; }
        gate.Set(1, [](unsigned) {});
        Require(caught && !gate.Allow(KC_F1,false,true) && !gate.Allow(KC_F2,false,true), "unlatched release after cancellation error");
    });
    Test("default userdata metatable is rejected", [] {
        auto* state=LuaPlus::LuaState::Create(true);
        bool rejected=false, stackUnchanged=false;
        { auto globals=state->GetGlobals();
          LuaPlus::LuaObject receiver=state->BoxPointer(nullptr); globals.SetObject("DataPool",receiver);
          const int top=lua_gettop(state->GetCState()); // BoxPointer itself leaves a stack value.
          try { CysHostHotKeys::Register(globals, {}); } catch (const std::runtime_error&) { rejected=true; }
          stackUnchanged=lua_gettop(state->GetCState())==top; }
        LuaPlus::LuaState::Destroy(state);
        Require(rejected && stackUnchanged, "default metatable changed");
    });
    Test("missing service raises a protected fixed error", [] {
        Fixture f(false); f.Run("getmetatable(DataPool).SetCanUseHotKey=nil");
        auto globals=f.state->GetGlobals(); Require(CysHostHotKeys::Register(globals,{})==1,"missing service registration");
        f.Run("ok,err=pcall(function() DataPool:SetCanUseHotKey(0) end); assert(not ok); assert(string.find(err,'service is unavailable'))");
    });
    std::printf("RESULT %u/%u passed; actual source methods with service doubles; no Game/OS input\n", passed, passed+failed);
    return failed ? 1 : 0;
}
