#include "StdAfx.h"
#include "CysAccelTable.h"
#include "../Network/CysForge.h"
#include "CysAccelCore.h"
#include "CysTooltipContract.h"
// CYS-MOVE2: see CysAccelTable.h / CysAccelCore.h. Every rule below names the CY function it copies.
#include "GameProcedure.h"
#include "GamePro_Login.h"
#include "..\Global.h"
#include "..\Input\GMInputSystem.h"
#include "..\Event\GMEventSystem.h"
#include "..\Action\GMActionSystem.h"
#include "../Action/CysQuickbarContract.h"
#include "..\Object\ObjectManager.h"
#include "..\World\WorldManager.h"
#include "..\World\Scene.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\Object\Character\AI\GMAI_MySelf.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\Interface\GMGameInterface.h"
#include "..\Interface\GMGameInterface_Script.h"	// brings GMInterface_Script_Talk.h (no include guard there)
#include "..\Helper\GMHelperSystem.h"
#include "..\WxRender\RenderSystem.h"
#include "CysUiInputBridge.h"
#include "TDEventDefine.h"
#include "TDUISystem.h"
#include "TDUtil.h"
#if defined(CYS_HAVE_NETCORE)
#include "..\Network\CysModernGame.h"
#include "PgPackets_misc.h"
#include <memory>
#endif
#include <string>
#include <vector>

namespace
{
    using namespace CysAccelCore;

    struct Capture
    {
        bool on;
        bool chatSlot;
        int id;
    };

    struct State
    {
        bool ready;
        Table table;
        Capture capture;
        int menuBarPage;
        std::string account;
        std::string customFile;
        bool customLoaded;
        bool notPortedLogged[kRows];
        bool slotMissingLogged[kRows];
        CysAccel::Counters counters;
        CysUiInputBridge::GetActiveInputName activeName;
        CysUiInputBridge::CopyWindowTextUtf8 copyText;
        int (__cdecl *dumpWindows)(char* out, unsigned capacity);   // CysUiDumpVisibleWindowsUtf8 (window census)
        CysUiInputBridge::GetWindowRectUtf8 rect;                   // CysUiGetWindowRectUtf8: 0 when not visible
        int gateLogged;                                             // which chat gate answered (logged once)
        bool chatStateKnown;                                        // NonChatActive has been published at least once
        INT nonChatActive;                                          // last value written (1 = keyboard is the game's)
        int useVariableGate;                                        // -1 unread, 0 conservative, 1 CY's NonChatActive
        bool bridgeResolved;
    };

    State& S()
    {
        static State s = State();
        static bool first = true;
        if (first) { first = false; s.useVariableGate = -1; }
        return s;
    }

    void ResolveBridge()
    {
        State& s = S();
        if (s.bridgeResolved) return;
        s.bridgeResolved = true;
        HMODULE module = GetModuleHandleA("UI_CEGUI.dll");
        if (!module) { s.bridgeResolved = false; return; }   // the DLL is not loaded yet (login screens): retry later
        s.activeName = reinterpret_cast<CysUiInputBridge::GetActiveInputName>(GetProcAddress(module, "CysUiGetActiveInputName"));
        s.copyText = reinterpret_cast<CysUiInputBridge::CopyWindowTextUtf8>(GetProcAddress(module, "CysUiCopyWindowTextUtf8"));
        s.dumpWindows = reinterpret_cast<int (__cdecl *)(char*, unsigned)>(GetProcAddress(module, "CysUiDumpVisibleWindowsUtf8"));
        s.rect = reinterpret_cast<CysUiInputBridge::GetWindowRectUtf8>(GetProcAddress(module, "CysUiGetWindowRectUtf8"));
        TDU_Log("CYS-ACCEL: UI bridge active_name=%s copy_text=%s census=%s rect=%s", s.activeName ? "ok" : "MISSING",
                s.copyText ? "ok" : "MISSING", s.dumpWindows ? "ok" : "MISSING", s.rect ? "ok" : "MISSING");
    }

    // Evidence line "which frames are open now": the depth-0 and depth-1 visible windows of the GUI sheet, names
    // only, after a key fired. UI_CEGUI's census format is "depth|name|type|l,t,w,h|text;".
    void LogFrames(const char* when)
    {
        State& s = S();
        if (!s.dumpWindows) return;
        static char dump[32768];
        const int count = s.dumpWindows(dump, sizeof(dump));
        if (count < 0) return;
        char line[900];
        unsigned used = 0;
        for (const char* p = dump; *p && used < sizeof(line) - 80; )
        {
            const char* end = strchr(p, ';');
            if (!end) break;
            char entry[320];
            unsigned len = (unsigned)(end - p);
            if (len >= sizeof(entry)) len = sizeof(entry) - 1;
            memcpy(entry, p, len); entry[len] = '\0';
            // depth|name|...
            char* bar = strchr(entry, '|');
            if (bar && (entry[0] == '0' || entry[0] == '1'))
            {
                char* nameEnd = strchr(bar + 1, '|');
                if (nameEnd) *nameEnd = '\0';
                const int n = _snprintf(line + used, sizeof(line) - used - 1, "%s%s", used ? " " : "", bar + 1);
                if (n > 0) used += (unsigned)n;
            }
            p = end + 1;
        }
        line[used] = '\0';
        TDU_Log("CYS-ACCEL: %s frames(%d)=%s", when, count, line);
    }

    void LoadCustom()
    {
        State& s = S();
        if (s.customLoaded || s.customFile.empty()) return;
        s.customLoaded = true;
        FILE* f = fopen(s.customFile.c_str(), "rb");
        if (!f)
        {
            TDU_Log("CYS-ACCEL: no custom key file %s (CY defaults stay)", s.customFile.c_str());
            return;
        }
        std::string text;
        char buf[4096];
        size_t n;
        while ((n = fread(buf, 1, sizeof(buf), f)) > 0) text.append(buf, n);
        fclose(f);
        const int rows = s.table.Parse(text.c_str());
        s.table.Snapshot();
        s.table.changed = false;
        TDU_Log("CYS-ACCEL: custom key file %s loaded rows=%d", s.customFile.c_str(), rows);
    }

    STRING DictText(const char* key)
    {
        // "#{KEY}" -> the StrDictionary text, the way CY resolves ZDYKJJ_20071227_02/03 before pushing them.
        if (!CGameProcedure::s_pUISystem) return STRING(key);
        char id[64];
        _snprintf(id, sizeof(id) - 1, "#{%s}", key);
        id[sizeof(id) - 1] = '\0';
        return CGameProcedure::s_pUISystem->ParserString_NoColor_NoVarParam(id);
    }

    void DebugMessage(const char* dictKey)
    {
        const STRING text = DictText(dictKey);
        CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE, text.c_str());
    }

    void TellWindow(int row)
    {


        char k1[48], k2[48];
        KeyText(S().table.key1[row], k1, sizeof(k1));
        KeyText(S().table.key2[row], k2, sizeof(k2));
        CEventSystem::GetMe()->PushEvent(GE_TOGLE_INPUTSETUP, k1, k2, (INT)kRowMeta[row].id);
    }

    unsigned Modifiers()
    {
        tInputSystem* in = CGameProcedure::s_pInputSystem;
        if (!in) return 0;
        unsigned mod = 0;
        if (in->IsKeyDown(KC_LCONTROL) || in->IsKeyDown(KC_RCONTROL)) mod |= kModCtrl;
        if (in->IsKeyDown(KC_LMENU) || in->IsKeyDown(KC_RMENU)) mod |= kModAlt;
        if (in->IsKeyDown(KC_LSHIFT) || in->IsKeyDown(KC_RSHIFT)) mod |= kModShift;
        return mod;
    }

    CObject_PlayerMySelf* Self()
    {
        return CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : NULL;
    }

    void PushNamed(const char* name, const char* arg0)
    {
        std::vector<STRING> args;
        if (arg0) args.push_back(STRING(arg0));
        if (!CEventSystem::GetMe()->PushEventByName(STRING(name), args))
            TDU_Log("CYS-ACCEL: event %s is not in this build's event table (CY pushes it)", name);
    }

    void HandleCapture(unsigned packed)
    {
        State& s = S();
        const int row = s.table.RowOfId(s.capture.id);
        if (row < kFixedRows)
        {
            TDU_Log("CYS-ACCEL: capture for unknown id %d cancelled", s.capture.id);
            s.capture.on = false;
            return;
        }
        char text[48];
        KeyText(packed, text, sizeof(text), false);
        if (Vk(packed) == 0x1B)
        {

            TDU_Log("CYS-ACCEL: capture id=%d cancelled with Esc", s.capture.id);
            TellWindow(row);
            s.capture.on = false;
            return;
        }
        int slot;
        if (IsValidChatBinding(packed)) slot = 2;
        else if (IsValidPlainBinding(packed)) slot = 1;
        else
        {

            TDU_Log("CYS-ACCEL: capture id=%d refused key %s (%06X) - not a bindable key", s.capture.id, text, packed);
            DebugMessage("ZDYKJJ_20071227_02");
            return;
        }
        const int replaced = s.table.Apply(row, slot, packed);
        ++s.counters.captured;
        TDU_Log("CYS-ACCEL: capture id=%d row=%d slot=%d <- %s (%06X) replaced=%d", s.capture.id, row, slot, text, packed, replaced);
        if (replaced > 0) DebugMessage("ZDYKJJ_20071227_03");
        TellWindow(row);
        s.capture.on = false;
    }

    void LogChatText(const char* when)
    {
        char text[128] = {0};
        if (CysAccel::CopyEditText("Chat_EditBox", text, sizeof(text)))
            TDU_Log("CYS-ACCEL: %s Chat_EditBox=\"%s\" active=\"%s\"", when, text, CysAccel::ActiveEditName());
    }

    void Dispatch(int row, int slot, bool down, unsigned packed, bool editActive)
    {
        State& s = S();
        const RowMeta& meta = kRowMeta[row];
        CObject_PlayerMySelf* self = Self();
        char text[48];
        KeyText(packed, text, sizeof(text), false);
        ++s.counters.dispatched;
        TDU_Log("CYS-ACCEL: %s %s row=%d id=%d slot=%d action=%d%s%s edit=%s", down ? "down" : "up", text, row,
                meta.id, slot, (int)meta.action, meta.arg[0] ? " " : "", meta.arg, editActive ? CysAccel::ActiveEditName() : "-");

        switch (meta.action)
        {
        case ACT_ESCAPE:
            if (!down) break;
            if (CysAccel::ChatEditActive())
            {



                CysAccel::SetChatting(false);
                CEventSystem::GetMe()->PushEvent(GE_CHAT_CLOSED);
            }
            else
            {
                CGameProcedure::s_pUISystem->OnPushEcsape();
                CGameInterface::GetMe()->Skill_CancelAction();
            }
            break;
        case ACT_CHAT_OPEN:



            if (down) CysAccel::SetChatting(true);
            break;
        case ACT_CHAT_GM_PREV:
            if (down && CysAccel::ChatEditActive()) SCRIPT_SANDBOX::Talk::s_Talk.HandleKey_Shift_ArrowUp(1);
            break;
        case ACT_CHAT_GM_NEXT:
            if (down && CysAccel::ChatEditActive()) SCRIPT_SANDBOX::Talk::s_Talk.HandleKey_Shift_ArrowDown(1);
            break;
        case ACT_UP:
            if (!down) break;
            if (CysAccel::ChatEditActive()) SCRIPT_SANDBOX::Talk::s_Talk.HandleKey_Shift_ArrowUp(0);
            else CGameProcedure::s_pGfxSystem->Camera_SetZoom(TRUE, 2);
            break;
        case ACT_DOWN:
            if (!down) break;
            if (CysAccel::ChatEditActive()) SCRIPT_SANDBOX::Talk::s_Talk.HandleKey_Shift_ArrowDown(0);
            else CGameProcedure::s_pGfxSystem->Camera_SetZoom(FALSE, 2);
            break;
        case ACT_ZOOM_IN:
            if (down) CGameProcedure::s_pGfxSystem->Camera_SetZoom(TRUE, 2);
            break;
        case ACT_ZOOM_OUT:
            if (down) CGameProcedure::s_pGfxSystem->Camera_SetZoom(FALSE, 2);
            break;
        case ACT_MENUBAR:
        {

            const int index = 10 * s.menuBarPage + (meta.id - 1);
            CActionSystem::GetMe()->MainMenuBar_DoAction(index, down ? true : FALSE);
            break;
        }
        case ACT_MENUBAR_SLOT:
        {
            const int index = atoi(meta.arg);
            const int kThisBuildMainBarSlots = CysQuickbarContract::SlotCount;
            if (index >= kThisBuildMainBarSlots)
            {
                if (!s.slotMissingLogged[row])
                {
                    s.slotMissingLogged[row] = true;
                    TDU_Log("CYS-ACCEL: row %d (%s) is CY main-bar slot %d; this build's bar has %d slots - nothing to do",
                            row, text, index, kThisBuildMainBarSlots);
                }
                break;
            }
            CActionSystem::GetMe()->MainMenuBar_DoAction(index, down ? true : FALSE);
            break;
        }
        case ACT_EVENT_ACC:
            if (down) CEventSystem::GetMe()->PushEvent(GE_ACCELERATE_KEYSEND, meta.arg);
            break;
        case ACT_HELP:
            if (down)
            {
                CHelperSystem* help = (CHelperSystem*)CGameProcedure::s_pHelperSystem;
                if (help) help->GotoAnchorHelp(STRING(""));
            }
            break;
        case ACT_JUMP:
            if (down && self && self->GetCharacterData() && !self->GetCharacterData()->Get_IsInStall())
            {
                CAI_Base* ai = self->CharacterLogic_GetAI();
                if (ai) ((CAI_MySelf*)ai)->PushCommand_Jump();
            }
            break;
        case ACT_SCENE_MAP:




            if (down && CWorldManager::GetMe() && CWorldManager::GetMe()->GetActiveScene())
            {
                std::vector<STRING> params;
                params.push_back(CWorldManager::GetMe()->GetActiveScene()->GetSceneDefine()->szSceneMap);
                params.push_back(STRING("2"));
                CEventSystem::GetMe()->PushEvent(GE_TOGLE_SCENEMAP, params);
                CGameProcedure::m_bNeedFreshMinimap = true;
                CGameProcedure::m_bWaitNeedFreshMinimap = true;
            }
            break;
        case ACT_EVENT_NAMED:
            if (down) PushNamed(meta.arg, NULL);
            break;
        case ACT_EVENT_NAMED_INT:
            if (down) PushNamed(meta.arg, "-1");
            break;
        case ACT_XIULIAN_PAGE:

            if (down && self && self->GetCharacterData() && self->GetCharacterData()->Get_Level() >= 70) PushNamed(meta.arg, "-1");
            break;
        case ACT_STOP_TEAM_FOLLOW:
#if defined(CYS_HAVE_NETCORE)
            if (down)
            {

                if (!CysModernGame::SendModern(std::unique_ptr<pg::Packet>(new pg::CGStopTeamFollow)))
                    TDU_Log("CYS-ACCEL: CGStopTeamFollow not sent (no modern session)");
            }
#endif
            break;
        case ACT_ALT_TOOLTIP:
            if (CysTooltipContract::Probe()) TDU_Log("CYS-FT-TOOLTIP: alt down=%d old=%d", down ? 1 : 0, CysTooltipContract::Old() ? 1 : 0);
            // D5: CY Lua expects "1" for both edges; GL's altkeydown/altkeyup
            // belong to a different Lua contract (frames-truth live evidence).
            if (CysTooltipContract::Old())
            {
                PushNamed("UPDATE_SUPERTOOLTIP", down ? "altkeydown" : "altkeyup");
                if (down) PushNamed("SHOW_SUPERTOOLTIP2", "");
            }
            else
            {
                PushNamed("UPDATE_SUPERTOOLTIP", "1");
                PushNamed("SHOW_SUPERTOOLTIP2", down ? "2" : "3");
            }
            break;
        case ACT_DEBUG:
#ifndef _FINAL
            // Ctrl+G (row 3) is CY's gfx debug toggle; the 0.85 tree toggled its debug panel on plain G. Same role.
            if (down && row == 3 && CGameProcedure::s_pGfxSystem) CGameProcedure::s_pGfxSystem->Debug_ToggleShowDebugPanel();
#endif
            break;
        case ACT_SCREENSHOT:
        case ACT_SYSTEM_LOCKKEY:
            break;   // handled elsewhere (screenshot: CInputSystem::MessageProc WM_KEYUP) or CY lock-key bookkeeping
        case ACT_CY_NOT_PORTED:
            if (down)
            {
                ++s.counters.notPorted;
                if (!s.notPortedLogged[row])
                {
                    s.notPortedLogged[row] = true;
                    TDU_Log("CYS-ACCEL: row %d (%s) - CY: %s; not ported, nothing done", row, text, meta.arg);
                }
            }
            break;
        default:
            break;
        }
    }
}

void CysAccel::Init()
{
    State& s = S();
    if (!s.ready)
    {
        s.ready = true;
        s.table.Reset();
        s.capture.on = false;
        s.menuBarPage = 0;
        TDU_Log("CYS-ACCEL: table ready rows=%d (CY .data 0x140998980, mod bits Ctrl=1 Alt=2 Shift=4)", (int)kRows);
    }
    if (s.account.empty() && CGameProcedure::s_pProcLogIn && !CGameProcedure::s_pProcLogIn->m_strUserName.empty())
        SetAccount(CGameProcedure::s_pProcLogIn->m_strUserName.c_str());
    LoadCustom();
    ResolveBridge();
}

void CysAccel::SetAccount(const char* account)
{
    State& s = S();
    if (!account || !account[0]) return;
    std::string clean;
    for (const char* p = account; *p; ++p)
        clean.push_back((*p == '\\' || *p == '/' || *p == ':' || *p == '.' || *p == '"') ? '_' : *p);
    if (clean == s.account) return;
    s.account = clean;
    s.customFile = "..\\Accounts\\" + clean + "\\Acce_Custom.ini";
    s.customLoaded = false;
}

bool CysAccel::ProcessKey(int kc, bool down)
{
    if(CysForge::Key(kc,down))return true;
    Init();
    State& s = S();
    ++s.counters.keysSeen;
    const unsigned vk = DikToVk(kc);
    if (!vk) return false;
    const unsigned mod = Modifiers();
    const unsigned packed = Pack(vk, mod);

    if (s.capture.on)
    {
        if (down) HandleCapture(packed);
        return true;
    }

    ResolveBridge();
    const bool editActive = AnyEditActive();
    if (editActive && !(mod & (kModCtrl | kModAlt)) && IsTextKey(vk))
    {

        ++s.counters.swallowedByEdit;
        if (down)
        {
            char text[48];
            KeyText(packed, text, sizeof(text), false);
            TDU_Log("CYS-ACCEL: %s left to edit box \"%s\"", text, ActiveEditName());
            LogChatText("after text key");
        }
        return false;
    }

    int slot = 0;
    const int row = s.table.Find(packed, &slot);
    if (row < 0)
    {
        ++s.counters.unbound;
        return false;
    }
    CObject_PlayerMySelf* self = Self();
    if (down && self && self->IsDie() && !(kRowMeta[row].flags & kFlagUsableWhileDead))
    {
        ++s.counters.refusedDead;
        return true;
    }
    if (!down && !kRowMeta[row].hasUp) return true;   // the row has no fn_up in CY
    Dispatch(row, slot, down, packed, editActive);
    if (down && editActive) LogChatText("after chord");
    if (down) LogFrames("after key");
    if (down && (s.counters.dispatched % 20) == 0)
        TDU_Log("CYS-ACCEL: counters seen=%u dispatched=%u edit=%u unbound=%u dead=%u captured=%u notported=%u",
                s.counters.keysSeen, s.counters.dispatched, s.counters.swallowedByEdit, s.counters.unbound,
                s.counters.refusedDead, s.counters.captured, s.counters.notPorted);
    return true;
}

























void CysAccel::SetChatting(bool chatting)
{
    Init();
    if (!CGameProcedure::s_pVariableSystem) return;
    State& s = S();
    const INT value = chatting ? 0 : 1;
    if (s.chatStateKnown && s.nonChatActive == value) return;
    s.chatStateKnown = true;
    s.nonChatActive = value;
    CGameProcedure::s_pVariableSystem->SetAs_Int("NonChatActive", value);
    TDU_Log("CYS-ACCEL: NonChatActive=%d (%s)", (int)value, chatting ? "typing in the chat box" : "keyboard belongs to the game");
}

bool CysAccel::ChatEditActive()
{
    State& s = S();
    ResolveBridge();

    // The world starts with the keyboard belonging to the game; publish that once so the CY frames that read
    // NonChatActive (ChatFrame, LargeMap, MainMenuBar, MiniMap, SceneMap, TeamFrame) see a defined value.
    if (!s.chatStateKnown) SetChatting(false);

    // THE GATE IS CY'S VARIABLE, and both halves of the fix now use it. The other half lives in
    // CUISystem::MessageProc (CYS-MOVE2): characters reach a CEGUI edit box through WM_CHAR -> Ime::ImeMsgProc,
    // NOT through the DirectInput queue this table reads (CUISystem::InjectInput has no keyboard case at all),
    // so without that half a plain letter would be typed into the always-focused chat box AND fire its shortcut.
    // The two halves must agree, so they read the same variable. CYS_ACCEL_CHATGATE=uifocus falls back to the old
    // conservative answer (swallow whenever the UI says an edit box has focus) without a rebuild.
    if (s.useVariableGate < 0)
    {
        char mode[16] = {0};
        s.useVariableGate = (GetEnvironmentVariableA("CYS_ACCEL_CHATGATE", mode, sizeof(mode)) > 0 &&
                             _stricmp(mode, "uifocus") == 0) ? 0 : 1;
        TDU_Log("CYS-ACCEL: chat swallow gate = %s", s.useVariableGate ? "NonChatActive (CY rule; UI half in CUISystem::MessageProc)"
                                                                      : "UI focus (conservative fallback, CYS_ACCEL_CHATGATE=uifocus)");
    }
    BOOL have = FALSE;
    if (s.useVariableGate == 1 && CGameProcedure::s_pVariableSystem)
    {
        const INT nonChat = CGameProcedure::s_pVariableSystem->GetAs_Int("NonChatActive", &have);
        if (have)
        {
            if (!s.gateLogged) { s.gateLogged = 1; TDU_Log("CYS-ACCEL: chat gate = variable NonChatActive (CY's own rule)"); }
            return nonChat != 1;
        }
    }
    // MEASURED 18/09 (live-1 and live-2): neither of the two fallbacks can ever say "not chatting" in the CY GUI -
    // Chat_EditBox is BOTH permanently focused (DefaultEditBox=True) and permanently visible. They stay only so the
    // gate still answers something on a GUI that does not behave like CY's.
    if (s.rect)
    {
        float box[4] = {0, 0, 0, 0};
        const int visible = s.rect("Chat_EditBox", box);
        if (!s.gateLogged) { s.gateLogged = 2; TDU_Log("CYS-ACCEL: chat gate = Chat_EditBox visibility (NonChatActive missing) - always true in the CY GUI"); }
        return visible != 0;
    }
    if (!s.gateLogged) { s.gateLogged = 3; TDU_Log("CYS-ACCEL: chat gate = CEGUI focus list - always true in the CY GUI"); }
    const char* name = ActiveEditName();
    return name && strcmp(name, "Chat_EditBox") == 0;
}

// "Some edit box is taking characters." Every other edit box of the CY GUI (344 of them) behaves normally - it is
// only Chat_EditBox that is permanently default - so the focus list is right for them; the chat is asked separately.
bool CysAccel::AnyEditActive()
{
    const char* name = ActiveEditName();
    if (!name || !name[0]) return false;
    if (strcmp(name, "Chat_EditBox") == 0) return ChatEditActive();
    return true;
}

const char* CysAccel::ActiveEditName()
{
    ResolveBridge();
    State& s = S();
    if (s.activeName)
    {
        const char* name = s.activeName();
        return name ? name : "";
    }
    // Bridge missing: the tUISystem interface only knows the 0.85 question. Fall back to the CY chat box name so
    // at least the chat is right, which is where the 17/09 measurement failed.
    if (CGameProcedure::s_pUISystem && CGameProcedure::s_pUISystem->IsIMEEditboxActive("Chat_EditBox")) return "Chat_EditBox";
    return "";
}

bool CysAccel::CopyEditText(const char* window, char* out, unsigned capacity)
{
    ResolveBridge();
    State& s = S();
    if (!s.copyText || !out || !capacity) return false;
    return s.copyText(window, out, capacity) >= 0;
}

bool CysAccel::RowText(int rowIndex, char* key1, unsigned cap1, char* key2, unsigned cap2)
{
    Init();
    if (key1 && cap1) key1[0] = '\0';
    if (key2 && cap2) key2[0] = '\0';
    if (rowIndex < 0 || rowIndex >= kRows) return false;
    const Table& t = S().table;
    if (key1) KeyText(t.key1[rowIndex], key1, cap1);
    if (key2) KeyText(t.key2[rowIndex], key2, cap2);
    return true;
}

void CysAccel::BeginCapture(int id, bool chatSlot)
{
    Init();
    State& s = S();
    s.capture.on = true;
    s.capture.chatSlot = chatSlot;
    s.capture.id = id;
    TDU_Log("CYS-ACCEL: capture armed id=%d slot=%s", id, chatSlot ? "chat" : "plain");
}

void CysAccel::EndCapture() { S().capture.on = false; }
bool CysAccel::IsCapturing() { return S().capture.on; }

void CysAccel::RestoreDefaults()
{
    Init();
    Table& t = S().table;
    for (int i = 0; i < kRows; ++i) { t.key1[i] = DefaultKey1(i); t.key2[i] = DefaultKey2(i); }
    t.changed = true;
    TDU_Log("CYS-ACCEL: defaults restored (ComeBackAcce)");
}

void CysAccel::Snapshot() { Init(); S().table.Snapshot(); }

void CysAccel::Revert()
{
    Init();
    S().table.Revert();
    S().table.changed = false;
    TDU_Log("CYS-ACCEL: bindings reverted to the snapshot (RevertAcceCustom)");
}

bool CysAccel::Commit()
{
    Init();
    State& s = S();
    if (s.customFile.empty())
    {
        TDU_Log("CYS-ACCEL: UseAcceCustomKey with no account: bindings kept in memory only");
        s.table.Snapshot();
        s.table.changed = false;
        return false;
    }
    char body[16384];
    const int n = s.table.Serialize(body, sizeof(body));
    if (n < 0) return false;
    // ..\Accounts\<account>\ may not exist for an account that never saved a cfg here.
    std::string dir = s.customFile.substr(0, s.customFile.find_last_of('\\'));
    CreateDirectoryA("..\\Accounts", NULL);
    CreateDirectoryA(dir.c_str(), NULL);
    FILE* f = fopen(s.customFile.c_str(), "wb");
    if (!f)
    {
        TDU_Log("CYS-ACCEL: cannot write %s", s.customFile.c_str());
        return false;
    }
    fwrite(body, 1, (size_t)n, f);
    fclose(f);
    s.table.Snapshot();
    s.table.changed = false;
    TDU_Log("CYS-ACCEL: %s written (%d bytes)", s.customFile.c_str(), n);
    return true;
}

bool CysAccel::IsChanged() { Init(); return S().table.changed; }
void CysAccel::SetChanged(bool changed) { Init(); S().table.changed = changed; }

void CysAccel::SetMenuBarPage(int page)
{
    Init();
    if (page < 0) page = 0;
    if (page > 2) page = 2;
    S().menuBarPage = page;
}

int CysAccel::MenuBarPage() { Init(); return S().menuBarPage; }

CysAccel::Counters CysAccel::Get() { return S().counters; }
