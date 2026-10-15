// CYS-HOST2: second batch of Lua host functions + the live probe. See CysHost_Host2.h.
//
// Disassembly (client_GL\Bin64\Game.exe, image base 0x140000000; listings in Build/Logs/2026-09-17-host-2/re/):
//
//   DataPool:Lua_GetItemNameByIndex  B 0x140244070 (578 bytes)
//       lua_type(2) != NUMBER -> tThrowStringException("Lua_GetItemNameByIndex parameter2 error!")
//       kind = ItemTableMgr->vf[18](index)      // 1 equip, 2 common item, 3 gem; anything else -> nothing pushed
//       kind 1: row = DBC 0x74 (EquipBase).Search_Index_EQU(index)      -> lua_pushstring(row + 0x28 = szName)
//       kind 2: index in [39920000, 39999999] -> DBC 0x113 (CampaignItemTable) row + 0x10
//               else                          -> DBC 0x75 (CommonItem)        row + 0x20 = szName
//       kind 3: row = DBC 0x76 (GemInfo)                                  -> row + 0x28 = szName
//       no row -> returns 0 values (nil in Lua).
//       The 0x28 / 0x20 / 0x28 offsets are the szName columns of _DBC_ITEM_EQUIP_BASE (10 ints before it),
//       _DBC_ITEM_MEDIC (5 ints + szIcon) and _DBC_ITEM_GEM (5 ints + szIcon + nRule) with 8-byte string cells -
//       the same column layout this tree declares in TDDBC_Struct.h. The kind follows the index ranges that
//       Obj_Item.cpp CObject_Item::NewItem uses (1xxxxxxx equip, 2-4xxxxxxx common item, 5xxxxxxx gem).
//       DELIBERATE GAP: this tree loads no CampaignItem table; the 39.92M-39.99M window falls back to CommonItem,
//       which has no id there (CanonicalCY CommonItem.txt: 0 rows in that range) -> nil, as B answers for an
//       unknown index.
//
//   _G:ToggleWuhunPage  B 0x14021b700 (52 bytes)
//       if (!Guard()) g_EventSystem->PushEvent(0x27c, -1);  return 0 values
//       Guard (0x140218430) = the active procedure exists and its class id is 0x4d, i.e. NOT the main game
//       procedure; here: skip unless CGameProcedure::GetActiveProcedure() == s_pProcMain (the test that
//       Player:IsVaild / CysHost_Plumbing already uses for "in the main procedure").
//       0x27c = 636 = "TOGGLE_WUHUN_PAGE" (Wuhun.lua:54 RegisterEvent) - a NEW event of this tree
//       (TDEventDefine.h / GMEventSystem.cpp, tagged CYS-HOST2), otherwise RegisterEventHandle drops the handler.
//
//   _G:SetDefaultMouse  B 0x140222ce0 (61 bytes)
//       type = g_Game->vf[45]();  g_CursorMng->vf[18](type)   - the cursor manager's SetCursor with the default type
//       of the current state. [SL] the default type is CURSOR_NORMAL here; GamePro_Main re-evaluates the hover
//       cursor every tick anyway, so the one-shot reset is what the 51 CY frames want (shop windows closing).
#include "CysHost_Host2.h"
#include "LuaApiGen.h"
#include "Network/CysModernGame.h"
#include "Network/CysWorldReplay.h"
#include "Event/GMEventSystem.h"
#include "Script/GMScriptSystem.h"
#include "Procedure/GameProcedure.h"
#include "Procedure/GamePro_Main.h"
#include "Object/ObjectManager.h"
#include "Object/Character/Obj_PlayerMySelf.h"
#include "Object/Character/AI/GMAI_Base.h"
#include <set>
#include "World/WorldManager.h"
#include "World/Scene.h"
#include "Cursor/CursorMng.h"
#include <map>
#include <set>
#include <vector>
#include <cmath>
#include "DataPool/GMDataPool.h"
#include "Object/Item/Obj_Item.h"
#include "DBC/GMDataBase.h"
#include "TDDBC_Struct.h"
#include "TDEventDefine.h"
#include "TDException.h"
#include "TDUISystem.h"
#include "TDUtil.h"
#include "CysUiInputBridge.h"
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

namespace CysHostHost2
{
    namespace
    {
        LuaPlus::LuaObject Receiver(LuaPlus::LuaObject& globals, const char* name)
        {
            LuaPlus::LuaObject o = globals.GetByName(name);
            if (o.IsTable()) return o;
            if (o.IsUserData())
            {
                LuaPlus::LuaObject meta = o.GetMetaTable();
                if (!meta.IsTable()) return LuaPlus::LuaObject();
                LuaPlus::LuaObject index = meta.GetByName("__index");
                return index.IsTable() ? index : meta;
            }
            return LuaPlus::LuaObject();
        }

        bool EnvFlag(const char* name)
        {
            char text[8] = {};
            const DWORD n = ::GetEnvironmentVariableA(name, text, sizeof(text));
            return n == 1 && text[0] == '1';
        }

        bool InMainProcedure()
        {
            return CGameProcedure::s_pProcMain
                && CGameProcedure::GetActiveProcedure() == static_cast<CGameProcedure*>(CGameProcedure::s_pProcMain);
        }

        // ---- Lua entries -----------------------------------------------------------------------------------
        int DataPoolGetItemNameByIndex(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            if (!args[2].IsNumber()) TDThrow("Lua_GetItemNameByIndex parameter2 error!");   // B: lua_type(2) == NUMBER
            const int index = static_cast<int>(args[2].GetNumber());
            const char* name = ItemNameByIndex(index);
            {   // CYS_HOST2_PROBE=1: which indices the CY frames ask for, and what they got (evidence runs only)
                static int probe = -1, logged = 0;
                if (probe < 0) probe = EnvFlag("CYS_HOST2_PROBE") ? 1 : 0;
                if (probe == 1 && logged++ < 40) TDU_Log("CYS host2: Lua_GetItemNameByIndex(%d) -> %s", index, name ? name : "(nil)");
            }
            if (!name) return 0;
            s->PushString(name);
            return 1;
        }

        int GlobalToggleWuhunPage(LuaPlus::LuaState*)
        {
            ToggleWuhunPage();
            return 0;   // B pushes nothing (Infant.lua:1082 "local bRet = ToggleWuhunPage()" sees nil, as in CY)
        }

        int GlobalSetDefaultMouse(LuaPlus::LuaState*)
        {
            CCursorMng* cursors = CCursorMng::GetMe();
            if (!cursors) return 0;
            // CYS_HOST2_PROBE=1: the state BEFORE the reset is the only way to check the premise of this function -
            // if a CY frame calls it while the cursor is already NORMAL, the call corrects nothing and the entry is
            // not worth keeping; a non-NORMAL state proves it is (a shop closing with its "buy" cursor still set).
            static int probe = -1, logged = 0;
            if (probe < 0) probe = EnvFlag("CYS_HOST2_PROBE") ? 1 : 0;
            const INT before = cursors->GetCursor_State();
            cursors->SetCursor(CURSOR_NORMAL);
            if (probe == 1 && logged++ < 20)
                TDU_Log("CYS host2: SetDefaultMouse cursor %d -> %d (CURSOR_NORMAL=%d)", (int)before, (int)cursors->GetCursor_State(), (int)CURSOR_NORMAL);
            return 0;
        }

        // ---- DataPool:GetKfs* - the wuhun (武魂, "KFS") readers of Wuhun.lua ----------------------------------
        // B (listing Build/Logs/2026-09-17-host-2/re/Kfs_DataPool_140270cd0-1a00.txt), all four start alike:
        //     item = ItemContainerMgr->vf[0x19](0x12)          // the equipment at point 18 (= server HEQUIP_WUHUN)
        //     if (!item || item->vf[3]() != 1 || !IsKfs(item)) return 0 values      // IsKfs: define->nEquipPoint == 0x12
        // so WITHOUT a wuhun every one of them answers NOTHING (nil). The generated stubs answered "" / 0 / ("", 0)
        // instead, and Wuhun.lua:354 "data < 5" on that "" raised a Lua error that aborted Wuhun_Update before
        // this:Show() - the hub window could never open. With a wuhun equipped B reads the item's wuhun block
        // (level, exp, life, grow rate, extra attributes ...) which this client does not carry yet
        // (PgStructs.h has wh_level & co, CysModernHandlers::ItemInfoToLegacy drops them): those keys answer nil
        // and log once, so the gap stays visible instead of showing a wrong number.
        //   GetKfsData(key)      B 0x140270cd0: "NAME" -> item name, "NEEDLEVEL" -> level requirement (both from the
        //                        item table, answered here), the other keys from the wuhun block (nil here).
        //   GetKfsFixAttrEx(i)   B 0x140271540: (text, value) of fixed attribute i          -> nil here
        //   GetKfsBase(i)        B 0x1402716c0: base value i (KfsBase table by wh_level)     -> nil here
        //   GetFixKfsBase(i)     B 0x140271770: base value i * grow rate / 1000             -> nil here
        //   GetKfsSkill(i) / KFS_UpdateKFSModel() stay stubs: B answers 0 / nothing without a wuhun, exactly what
        //   the stubs answer, so installing them would only silence the "missing host function" line.
        CObject_Item* EquippedWuhun()
        {
            CDataPool* pool = CDataPool::GetMe();
            if (!pool) return nullptr;
            tObject_Item* item = pool->UserEquip_GetItem((HUMAN_EQUIP)18);
            if (!item) return nullptr;
            CObject_Item* obj = (CObject_Item*)item;
            return obj->GetItemClass() == ICLASS_EQUIP ? obj : nullptr;   // B: item class 1 (equipment) at point 18 (GameDefine_Item.h)
        }
        void KfsGapLog(const char* what)
        {
            static int logged = 0;
            if (logged++ < 8) TDU_Log("CYS host2: wuhun equipped but %s is not carried by this client (nil)", what);
        }
        int DataPoolGetKfsData(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            if (!args[2].IsString()) return 0;               // B: lua_isstring(2)
            CObject_Item* wuhun = EquippedWuhun();
            if (!wuhun) return 0;
            const std::string key = args[2].GetString();
            if (key == "NAME") { s->PushString(wuhun->GetName() ? wuhun->GetName() : ""); return 1; }
            if (key == "NEEDLEVEL") { s->PushNumber(wuhun->GetNeedLevel()); return 1; }
            KfsGapLog(("GetKfsData(" + key + ")").c_str());
            return 0;
        }
        int DataPoolGetKfsFixAttrEx(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            if (!args[2].IsNumber() || !EquippedWuhun()) return 0;
            KfsGapLog("GetKfsFixAttrEx");
            return 0;
        }
        int DataPoolGetKfsBase(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            if (!args[2].IsNumber() || !EquippedWuhun()) return 0;
            KfsGapLog("GetKfsBase");
            return 0;
        }
        int DataPoolGetFixKfsBase(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            if (!args[2].IsNumber() || !EquippedWuhun()) return 0;
            KfsGapLog("GetFixKfsBase");
            return 0;
        }

        int GlobalAutoRunToTarget(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            auto self = CObjectManager::GetMe()->GetMySelf();
            auto scene = (CScene*)CWorldManager::GetMe()->GetActiveScene();
            if(!CysModernGame::IsInWorld() || !self || !scene || self->CysIsLeaping() ||
               !args[1].IsNumber() || !args[2].IsNumber()) { s->PushInteger(0); return 1; }
            const float x = (float)args[1].GetNumber(), z = (float)args[2].GetNumber();
            if(!std::isfinite(x) || !std::isfinite(z) || !scene->IsValidPosition(fVector2(x,z)))
            { s->PushInteger(0); return 1; }
            // SceneMap.lua supplies scene coordinates, the same contract as
            // the native map hyperlinks. The AI builds a navmesh waypoint path.
            auto ai = self->CharacterLogic_GetAI();
            const bool accepted = ai && ai->PushCommand_MoveTo(x,z);
            TDU_Log("CYS-MAPMOVE: target=(%.3f,%.3f) accepted=%d",x,z,accepted?1:0);
            s->PushInteger(accepted?1:0); return 1;
        }

        struct Entry { const char* receiver; const char* name; int (*fn)(LuaPlus::LuaState*); };
        const Entry kEntries[] = {
            {"DataPool", "Lua_GetItemNameByIndex", DataPoolGetItemNameByIndex},
            {nullptr,    "ToggleWuhunPage",        GlobalToggleWuhunPage},
            {nullptr,    "SetDefaultMouse",        GlobalSetDefaultMouse},
            {nullptr,    "AutoRunToTarget",        GlobalAutoRunToTarget},
            {"DataPool", "GetKfsData",             DataPoolGetKfsData},
            {"DataPool", "GetKfsFixAttrEx",        DataPoolGetKfsFixAttrEx},
            {"DataPool", "GetKfsBase",             DataPoolGetKfsBase},
            {"DataPool", "GetFixKfsBase",          DataPoolGetFixKfsBase},
        };
    }

    bool Disabled()
    {
        static int cached = -1;
        if (cached < 0) cached = EnvFlag("CYS_HOST2_OFF") ? 1 : 0;
        return cached == 1;
    }

    const char* ItemNameByIndex(int index)
    {
        if (!CGameProcedure::s_pDataBaseSystem) return nullptr;
        if (index >= 10000000 && index <= 19999999)
        {
            DBC_DEFINEHANDLE(s_pEquipBase, DBC_ITEM_EQUIP_BASE);
            const _DBC_ITEM_EQUIP_BASE* row = (const _DBC_ITEM_EQUIP_BASE*)s_pEquipBase->Search_Index_EQU((UINT)index);
            return row ? row->szName : nullptr;
        }
        if (index >= 20000000 && index <= 49999999)
        {
            DBC_DEFINEHANDLE(s_pMedic, DBC_ITEM_MEDIC);
            const _DBC_ITEM_MEDIC* row = (const _DBC_ITEM_MEDIC*)s_pMedic->Search_Index_EQU((UINT)index);
            return row ? row->szName : nullptr;
        }
        if (index >= 50000000 && index <= 59999999)
        {
            DBC_DEFINEHANDLE(s_pGem, DBC_ITEM_GEM);
            const _DBC_ITEM_GEM* row = (const _DBC_ITEM_GEM*)s_pGem->Search_Index_EQU((UINT)index);
            return row ? row->szName : nullptr;
        }
        return nullptr;   // B: kind outside 1..3 -> nothing pushed
    }

    bool ToggleWuhunPage()
    {
        if (!InMainProcedure()) return false;
        CEventSystem* events = CEventSystem::GetMe();
        if (!events) return false;
        events->PushEvent(GE_TOGGLE_WUHUN_PAGE, -1);
        return true;
    }

    int Register(LuaPlus::LuaState* state)
    {
        if (!state || Disabled()) return 0;
        LuaPlus::LuaObject globals = state->GetGlobals();
        int registered = 0;
        for (const Entry& e : kEntries)
        {
            LuaPlus::LuaObject table = e.receiver ? Receiver(globals, e.receiver) : globals;
            if (!table.IsTable()) continue;
            table.Register(e.name, e.fn);   // forced: the generated stub already owns the slot
            ++registered;
        }
        return registered;
    }

    void RegisterHost()
    {
        CScriptSystem* scripts = CScriptSystem::GetMe();
        if (!scripts || !scripts->GetLuaState()) return;
        const int n = Register(scripts->GetLuaState());
        TDU_Log("CYS host2: host functions registered=%d off=%d", n, Disabled() ? 1 : 0);
    }

    // ---- CYS_HOST2_LIVE=1: open the windows this batch touches, one after another, and shoot them -------------
    namespace
    {
        enum Step { Off, Wait, Book, BookShot, Study, StudyPick, StudyShot, Forum, ForumShot,
                    Wuhun, WuhunShot, Accel, AccelShot, Quest, QuestShot, Summary, Done };
        struct State
        {
            bool evaluated = false;
            Step step = Off;
            DWORD at = 0;
            bool wuhunPushed = false;
            CysUiInputBridge::SmokePointer pointer = nullptr;
            CysUiInputBridge::GetWindowRectUtf8 rect = nullptr;
            CysUiInputBridge::CopyWindowTextUtf8 text = nullptr;
            CysUiInputBridge::CopyWindowTextUtf8 simpleText = nullptr;
        };
        State& S() { static State s; return s; }

        void Log(const char* fmt, ...)
        {
            char text[1024] = {};
            va_list args; va_start(args, fmt);
            _vsnprintf(text, sizeof(text) - 1, fmt, args);
            va_end(args);
            TDU_Log("CYS host2-live: %s", text);
        }
        void Go(Step next, const char* why) { S().step = next; S().at = GetTickCount(); Log("step %d: %s", (int)next, why); }
        DWORD Age() { return GetTickCount() - S().at; }
        bool Shown(const char* window) { return CGameProcedure::s_pUISystem && CGameProcedure::s_pUISystem->IsWindowShow(window); }
        void Shot(const char* label) { CysWorldReplay::LiveShot(label); }

        bool Center(const char* window, float xy[2])
        {
            float r[4] = {};
            if (!S().rect || S().rect(window, r) != 1) return false;
            xy[0] = r[0] + r[2] * 0.5f; xy[1] = r[1] + r[3] * 0.5f;
            return true;
        }
        bool Click(const char* window)
        {
            float xy[2] = {};
            if (!S().pointer || !Center(window, xy)) { Log("cannot click %s (pointer=%d)", window, S().pointer ? 1 : 0); return false; }
            S().pointer(1, xy[0], xy[1]); S().pointer(2, xy[0], xy[1]);
            Log("clicked %s", window);
            return true;
        }
        // Text of a label, LF/CR flattened; TLBB_SimpleMulitiTextFrame keeps its text in its own layer (simpleText).
        void LogText(const char* window)
        {
            char buffer[1024] = {};
            int n = S().text ? S().text(window, buffer, (unsigned)sizeof(buffer)) : -1;
            if (n <= 0 && S().simpleText) n = S().simpleText(window, buffer, (unsigned)sizeof(buffer));
            for (char* p = buffer; *p; ++p) { if (*p == '\r' || *p == '\n') *p = ' '; }
            Log("text %s rc=%d [%s]", window, n, buffer);
        }
        void Push(GAME_EVENT_ID id) { if (CEventSystem::GetMe()) CEventSystem::GetMe()->PushEvent(id); }
        void PushNamed(const char* name, const char* arg0)
        {
            if (!CEventSystem::GetMe()) return;
            std::vector<STRING> params;
            if (arg0) params.push_back(arg0);
            const BOOL ok = CEventSystem::GetMe()->PushEventByName(name, params);
            Log("PushEventByName(%s) accepted=%d", name, ok ? 1 : 0);
        }
        // CYS_HOST2_LIVE: "UI_COMMAND 20141203" reaches EVERY frame that listens to UI_COMMAND, and one of them opens a
        // confirmation box ("Chức năng lưu thông tin sạp hàng…", StrDictionary INTERFACE_XML_681). A modal box left open
        // swallows the quit click of the runner, so live-5-on had to be killed at 240 s (quit_complete / finished_in_time
        // red, while the quit item HAD been clicked). The probe closes them itself; it must never leave the session in a
        // state the runner cannot leave.
        void CloseModals(const char* why)
        {
            static const char* const kBoxes[] = { "MessageBox_Self", "MessageBoxCommon", "MessageBox_Time1", "MessageBox_Time2" };
            if (!CGameProcedure::s_pUISystem) return;
            for (const char* name : kBoxes)
            {
                if (!Shown(name)) continue;
                CGameProcedure::s_pUISystem->CloseWindowByName(name);
                Log("closed %s (%s)", name, why);
            }
        }

        void Stubs(const char* receiver, const char* name)
        {
            Log("stub calls %s:%s = %llu", receiver, name, LuaApiGen::GetMissingCallCountFor(receiver, name));
        }
    }

    bool Tick()
    {
        State& s = S();
        if (!s.evaluated)
        {
            s.evaluated = true;
            if (EnvFlag("CYS_HOST2_LIVE")) { s.step = Wait; s.at = GetTickCount(); }
            HMODULE ui = GetModuleHandleA("UI_CEGUI.dll");
            if (ui)
            {
                s.rect = reinterpret_cast<CysUiInputBridge::GetWindowRectUtf8>(GetProcAddress(ui, "CysUiGetWindowRectUtf8"));
                s.pointer = reinterpret_cast<CysUiInputBridge::SmokePointer>(GetProcAddress(ui, "CysUiSmokePointer"));
                s.text = reinterpret_cast<CysUiInputBridge::CopyWindowTextUtf8>(GetProcAddress(ui, "CysUiCopyWindowTextUtf8"));
                s.simpleText = reinterpret_cast<CysUiInputBridge::CopyWindowTextUtf8>(GetProcAddress(ui, "CysUiCopySimpleTextUtf8"));
            }
            Log("driver %s off=%d pointer=%d", s.step == Wait ? "enabled" : "disabled", Disabled() ? 1 : 0, s.pointer ? 1 : 0);
        }
        if (s.step == Off || s.step == Done) return true;
        if (!CysModernGame::IsInWorld()) { Log("left the world at step %d", (int)s.step); s.step = Done; return true; }
        switch (s.step)
        {
        case Wait:
            if (Age() < 1500) break;
            Shot("h2-hud");
            Push(GE_TOGLE_SKILL_BOOK);          // MainMenuBar skill button: ActionSkill (xinfa page)
            Go(Book, "TOGLE_SKILL_BOOK");
            break;
        case Book:
            if (Age() < 1500) break;
            Log("ActionSkill shown=%d", Shown("ActionSkill") ? 1 : 0);
            LogText("ActionSkill_Explain");    // Player:GetXinfaInfo(id, "explain") of the selected xinfa
            Shot("h2-skillbook");
            Go(BookShot, "shot");
            break;
        case BookShot:
            if (Age() < 300) break;
            Push(GE_TOGLE_SKILL_BOOK);          // close it again
            Go(Study, "closing the skill book");
            break;
        case Study:
            if (Age() < 800) break;
            if (CEventSystem::GetMe()) CEventSystem::GetMe()->PushEvent(GE_TOGLE_SKILLSTUDY, -1);   // as CysSkillDriver XWait
            Go(StudyPick, "TOGLE_SKILLSTUDY");
            break;
        case StudyPick:
            if (Age() < 1500) break;
            Log("ActionSkillsStudy shown=%d", Shown("ActionSkillsStudy") ? 1 : 0);
            Click("ActionSkillsStudy_XinfaSkill_1");
            Go(StudyShot, "xinfa 1 selected");
            break;
        case StudyShot:
            if (Age() < 1200) break;
            LogText("ActionSkillsStudy_SkillInfo");   // the label that printed "最高等级%d" raw before this batch
            Shot("h2-study");
            if (CGameProcedure::s_pUISystem) CGameProcedure::s_pUISystem->CloseWindowByName("ActionSkillsStudy");
            // No QuestLog step: TOGLE_MISSION from a fresh session dies with an access violation in CEGUIBase.dll
            // (live-1-control, host-2 functions OFF - a pre-existing fault, reported to the quest branch). The
            // Listbox pair is exercised by the HUD MissionTrack on entering the world anyway.
            Go(Forum, "study window shot");
            break;
        case Forum:
            if (Age() < 800) break;
            PushNamed("UI_COMMAND", "20141203");   // MiniMap.lua:232 -> MiniMap_OpenForumTips -> this:GetChildOffset("MiniMap_Forum")
            Go(ForumShot, "UI_COMMAND 20141203 (MiniMap forum tip -> GetChildOffset)");
            break;
        case ForumShot:
            if (Age() < 1200) break;
            Shot("h2-forumtip");
            CloseModals("after the forum tip");
            Go(Wuhun, "forum tip shot");
            break;
        case Wuhun:
            if (Age() < 800) break;
            s.wuhunPushed = ToggleWuhunPage();   // the host function itself (B: PushEvent 0x27c, -1)
            if (!s.wuhunPushed) PushNamed("TOGGLE_WUHUN_PAGE", "-1");   // control binary: the name is unknown -> rejected
            Go(WuhunShot, "ToggleWuhunPage");
            break;
        case WuhunShot:
            if (Age() < 1800) break;
            Log("Wuhun shown=%d (pushed by host function=%d)", Shown("Wuhun") ? 1 : 0, s.wuhunPushed ? 1 : 0);
            Shot("h2-wuhun");
            if (Shown("Wuhun")) ToggleWuhunPage();
            Go(Accel, "wuhun shot");
            break;
        case Accel:
            if (Age() < 800) break;
            // AcceSetup: the CY key-remap window (SystemSetup:GetInputSetup). AcceSetup.lua:253-254 only opens on
            // arg0 == "show", so the event MUST carry that string - pushing it bare left the window closed
            // (live-9-on: "AcceSetup shown=0").
            if (CEventSystem::GetMe()) CEventSystem::GetMe()->PushEvent(GE_TOGLE_INPUTSETUP, "show");
            Go(AccelShot, "TOGLE_INPUTSETUP show");
            break;
        case AccelShot:
            if (Age() < 1800) break;
            // CYS-HOST2 18/09: evidence for the modifier-bit fix - rows 31..33 must read "Ctrl+1/2/3", not "Shift+...".
            Log("AcceSetup shown=%d", Shown("AcceSetup") ? 1 : 0);
            LogText("AcceSetup_Key_11");
            LogText("AcceSetup_Key_12");
            Shot("h2-accel");
            if (CGameProcedure::s_pUISystem) CGameProcedure::s_pUISystem->CloseWindowByName("AcceSetup");
            Go(Quest, "accel window shot");
            break;
        case Quest:
            if (Age() < 600) break;
            // CYS-HOST2 18/09: CYS_HOST2_QUEST=1 only. Opening the CY quest log ends the process (move-2: key Q;
            // review-red: Access Violation in CEGUIBase.dll). This step exists to catch the last AddTextElement
            // breadcrumb before the death, so it must never run in a normal evidence session.
            if (!EnvFlag("CYS_HOST2_QUEST")) { Go(Summary, "quest step off"); break; }
            Log("opening QuestLog (CYS_HOST2_QUEST=1) - the process is expected to die here");
            Push(GE_TOGLE_MISSION);
            Go(QuestShot, "TOGLE_MISSION");
            break;
        case QuestShot:
            if (Age() < 2500) break;
            Log("QuestLog shown=%d - SURVIVED", Shown("QuestLog") ? 1 : 0);
            Shot("h2-questlog");
            Push(GE_TOGLE_MISSION);
            Go(Summary, "quest log shot");
            break;
        case Summary:
            if (Age() < 600) break;
            CloseModals("before the summary");
            Stubs("MetaTable_Control_Listbox", "GetCurrentFirstItem");
            Stubs("MetaTable_Control_Listbox", "SetCurrentFirstItem");
            Stubs("DataPool", "Lua_GetItemNameByIndex");
            Stubs("_G", "ToggleWuhunPage");
            Stubs("_G", "SetDefaultMouse");
            Stubs("this", "GetChildOffset");
            Log("PASS host2 live script (distinct stubs so far=%u calls=%u)", LuaApiGen::GetMissingDistinctCount(), LuaApiGen::GetMissingCallCount());
            s.step = Done;
            return true;
        default:
            s.step = Done;
            return true;
        }
        return false;
    }
}
