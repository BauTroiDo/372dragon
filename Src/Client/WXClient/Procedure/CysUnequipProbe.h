#pragma once
// CYS-UNEQUIP 20/09/2026: live turn for "take a worn item off" (CYS_UNEQUIP_LIVE=1).
//
// WHY: the user reported "khong thao vu khi duoc" after a real play session. The differential against the pair that
// works (client_GL + the original server; CY 3.71 agrees) found ONE differing link: which mouse button sends
// CGUnEquip (Build\Logs\2026-09-20-unequip\02-bang-vi-sai.md rows M4a/M4b/M4c).
//
// THIS PROBE TAKES THE PLAYER'S OWN DOOR. It never calls DoAction / DoSubAction and never builds a packet:
//   1. opens the character frame with the event the accelerator key pushes (ACCELERATE_KEYSEND "acc_selfequip"),
//   2. reads the on-screen rectangle of the equipment slot (SelfEquip_11 = weapon),
//   3. injects a mouse press + release of the chosen button at the centre of that rectangle through
//      CysUiSmokePointer -> CEGUI::System::injectMouseButtonDown/Up, the two calls CUISystem::InjectInput makes for
//      a physical click. From there on everything is the shipping path: CEGUI hit test (through the hollow
//      SelfEquip_11_Mask / _Animate children) -> FalagardActionButton -> MouseRClick / Clicked -> the layout's
//      SelfEquip_Equip_Click(11, n) -> g_WEAPON:DoSubAction() / :DoAction() -> CActionItem_Item -> CGUnEquip ->
//      server -> GCUnEquipResult.
//   Two earlier branches "proved" a frame by pushing its C++ from a probe and never went through the real door;
//   this one is built so that it cannot do that.
//
// ENVIRONMENT
//   CYS_UNEQUIP_LIVE=1          enable
//   CYS_UNEQUIP_GESTURE=right   right (default) | left | both  ("both": left first, then right if still worn)
//   CYS_UNEQUIP_WINDOW=SelfEquip_11   slot window (default: the weapon slot)
//   CYS_UNEQUIP_POINT=0               equipment point behind that window (default HEQUIP_WEAPON)
//   CYS_UNEQUIP_LEGACY=1        (read by GMActionSystem_Item.cpp) arm A of the A/B: the 0.85 behaviour
//
// VERDICT LINE (one per gesture, grep-able):
//   "CYS-UNEQUIP-LIVE: RESULT gesture=<g> held_ms=<n> answered=<0|1> worn_item=<id|-1> model_item=<id|-1>
//    item_<id>_bag_slot=<n|-1> taken_off=<0|1>"
// Whether a CGUnEquip LEFT the client is not decided here: it is the "CYS-UNEQUIP: ... -> CGUnEquip" line of
// GMActionSystem_Item.cpp plus the "CYS inv: CGUnEquip point=" line of the translation layer, both written by the
// shipping path the click travels, not by this probe.
// A turn whose precondition fails (no weapon worn, frame not open, slot not on screen) says PRECONDITION and
// claims nothing.
#include "CysUiInputBridge.h"
#include "TDUtil.h"
#include "TDEventDefine.h"
#include "TDUISystem.h"
#include "GameProcedure.h"
#include "..\Global.h"
#include "..\Event\GMEventSystem.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\Object\Item\Obj_Item.h"
#include "..\DataPool\GMDataPool.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\Action\GMActionSystem.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>

#if defined(CYS_HAVE_NETCORE)
#include "..\Network\CysModernGame.h"
#include "..\Network\CysInventoryNet.h"
#include "..\Network\CysWorldReplay.h"
#include "..\Script\GMScriptSystem.h"
#include "..\Script\CysCheckedScriptLua.h"
#include "LuaPlus.h"
#include "CysSelfEquipGeometryProbe.h"

namespace CysUnequipProbe
{
    namespace
    {
        enum Step { Off, Begin, OpenFrame, FrameWait, Press, Release, AnswerWait, Report, NextGesture,
                    Restore, RestoreWait, CloseFrame, WorldShot, Done, Hover, PostMove, PostMoveWait };

        struct State
        {
            bool evaluated;
            Step step;
            DWORD at;
            char gesture[8];        // right | left | both
            char window[64];
            int  point;
            int  pass;              // 0 = first gesture, 1 = second gesture of "both"
            bool right;             // button of the current pass
            float x, y;
            unsigned baseUnEquip, baseUseEquip;
            int  itemBefore;        // table id worn at the point before the gesture
            unsigned __int64 guidBefore; // distinguish two copies of the same item table row
            bool tookOff;           // some pass took the item off (restore needed)
            DWORD pressedAt, heldMs; // CEGUI only raises MouseRClick when release follows press within 0.2 s
            int  retries;
            unsigned postClicks;
            float postFromX, postFromZ, postPath;
            CysUiInputBridge::SmokePointer pointer;
            CysUiInputBridge::GetWindowRectUtf8 rect;
            CysUiInputBridge::GetDisplaySize display;
            State() : evaluated(false), step(Off), at(0), point(0), pass(0), right(true), x(0), y(0),
                      baseUnEquip(0), baseUseEquip(0), itemBefore(-1), guidBefore(0), tookOff(false),
                      pressedAt(0), heldMs(0), retries(0), postClicks(0), postFromX(0), postFromZ(0), postPath(0),
                      pointer(NULL), rect(NULL), display(NULL)
            { gesture[0] = 0; window[0] = 0; }
        };
        inline State& S() { static State s; return s; }

        inline void Go(Step next, const char* why)
        {
            S().step = next; S().at = GetTickCount();
            TDU_Log("CYS-UNEQUIP-LIVE: step %d: %s", (int)next, why);
        }
        inline DWORD Age() { return GetTickCount() - S().at; }

        inline bool Shown(const char* name)
        { return CGameProcedure::s_pUISystem && CGameProcedure::s_pUISystem->IsWindowShow(name); }

        // what the CLIENT believes: the item object at the point, the visible-equipment id of the own character
        // (the one the model is dressed from), and the bag slot holding `item` (-1 = not in the bag).
        inline int WornItem(int point)
        {
            tObject_Item* item = CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)point);
            return item ? (int)item->GetIdTable() : -1;
        }
        inline int ModelItem(int point)
        {
            CObject_PlayerMySelf* self = CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : NULL;
            return (self && point < HEQUIP_NUMBER) ? self->GetCharacterData()->Get_Equip((HUMAN_EQUIP)point) : -2;
        }
        inline int BagSlotOf(int itemId)
        {
            if (itemId <= 0) return -1;
            for (int i = 0; i < CYS_CLIENT_BAG_SLOTS; ++i)
            {
                tObject_Item* item = CDataPool::GetMe()->UserBag_GetItem(i);
                if (item && (int)item->GetIdTable() == itemId && item->GetGUID() == S().guidBefore) return i;
            }
            return -1;
        }
        inline int BagCount()
        {
            int n = 0;
            for (int i = 0; i < CYS_CLIENT_BAG_SLOTS; ++i) if (CDataPool::GetMe()->UserBag_GetItem(i)) ++n;
            return n;
        }
        // Opt-in read-only stats evidence. All four widgets are Falagard/SimpleText; the two
        // resource widgets each contain two numeric components, exactly as the real Lua renders.
        inline void DumpStats()
        {
            static const bool on = []() { char v[4] = {}; return GetEnvironmentVariableA("CYS_SELFEQUIP_STATS_LIVE", v, sizeof(v)) == 1 && v[0] == '1'; }();
            if (!on) return;
            CScriptSystem* script = CScriptSystem::GetMe();
            HMODULE ui = GetModuleHandleA("UI_CEGUI.dll");
            const auto text = ui ? reinterpret_cast<CysUiInputBridge::CopyWindowTextUtf8>(GetProcAddress(ui, "CysUiCopySimpleTextUtf8")) : nullptr;
            if (!script || !text) { TDU_Log("CYS-SELFEQUIP-STATS: INVALID missing script/text export"); return; }
            static const char* keys[] = { "CRITICALATTACK", "CRITICALDEFENCE", "VIGOR", "MAXVIGOR", "ENERGY", "MAXENERGY" };
            for (unsigned i = 0; i < 6; ++i)
            {
                char code[160] = {};
                _snprintf(code, sizeof(code), "__cys_selfequip_stat = nil; __cys_selfequip_stat = Player:GetData('%s')", keys[i]);
                const CysCheckedScriptLua::Result result = script->EvaluateScript("CysSelfEquipStats", code);
                if (!result.ok())
                {
                    TDU_Log("CYS-SELFEQUIP-STATS: INVALID Lua key=%s status=%d usable=%d", keys[i], result.status, result.stateUsable ? 1 : 0);
                    return;
                }
                LuaPlus::LuaObject value = script->GetLuaState()->GetGlobals().GetByName("__cys_selfequip_stat");
                TDU_Log("CYS-SELFEQUIP-STATS: key=%s ok=%d number=%d value=%.0f", keys[i], result.ok() ? 1 : 0,
                    value.IsNumber() ? 1 : 0, value.IsNumber() ? value.GetNumber() : -999.0);
            }
            script->EvaluateScript("CysSelfEquipStatsCleanup", "__cys_selfequip_stat = nil");
            static const char* widgets[] = { "SelfEquip_Perporty8", "SelfEquip_Perporty9", "SelfEquip_Vigor", "SelfEquip_Energy" };
            for (unsigned i = 0; i < 4; ++i)
            {
                char actual[256] = {};
                const int bytes = text(widgets[i], actual, sizeof(actual));
                TDU_Log("CYS-SELFEQUIP-STATS: widget=%s bytes=%d text=[%s]", widgets[i], bytes, actual);
            }
        }
        inline void Snapshot(const char* when)
        {
            const State& s = S();
            TDU_Log("CYS-UNEQUIP-LIVE: state %s: point=%d worn_item=%d model_item=%d bag_slot_of_item=%d bag_items=%d frame_shown=%d",
                    when, s.point, WornItem(s.point), ModelItem(s.point), BagSlotOf(s.itemBefore), BagCount(),
                    Shown("SelfEquip") ? 1 : 0);
        }
    }

    // true = finished (or disabled): the smoke moves on to the next driver.
    inline bool Tick()
    {
        State& s = S();
        if (!s.evaluated)
        {
            s.evaluated = true;
            char text[64] = {};
            const DWORD n = GetEnvironmentVariableA("CYS_UNEQUIP_LIVE", text, sizeof(text));
            const bool on = (n == 1 && text[0] == '1');
            if (GetEnvironmentVariableA("CYS_UNEQUIP_GESTURE", s.gesture, sizeof(s.gesture)) == 0) strcpy(s.gesture, "right");
            if (GetEnvironmentVariableA("CYS_UNEQUIP_WINDOW", s.window, sizeof(s.window)) == 0) strcpy(s.window, "SelfEquip_11");
            if (GetEnvironmentVariableA("CYS_UNEQUIP_POINT", text, sizeof(text)) > 0) s.point = atoi(text);
            if (on)
            {
                if (s.point < 0 || s.point >= HEQUIP_NUMBER ||
                    (strcmp(s.gesture, "right") && strcmp(s.gesture, "left") && strcmp(s.gesture, "both")))
                {
                    TDU_Log("CYS-UNEQUIP-LIVE: PRECONDITION failed: invalid point or gesture");
                    s.step = Done;
                    return true;
                }
                HMODULE ui = GetModuleHandleA("UI_CEGUI.dll");
                if (ui)
                {
                    s.pointer = reinterpret_cast<CysUiInputBridge::SmokePointer>(GetProcAddress(ui, "CysUiSmokePointer"));
                    s.rect = reinterpret_cast<CysUiInputBridge::GetWindowRectUtf8>(GetProcAddress(ui, "CysUiGetWindowRectUtf8"));
                    s.display = reinterpret_cast<CysUiInputBridge::GetDisplaySize>(GetProcAddress(ui, "CysUiGetDisplaySize"));
                }
                char legacy[8] = {};
                GetEnvironmentVariableA("CYS_UNEQUIP_LEGACY", legacy, sizeof(legacy));
                TDU_Log("CYS-UNEQUIP-LIVE: probe enabled gesture=%s window=%s point=%d legacy=%s exports=%d%d%d",
                        s.gesture, s.window, s.point, legacy[0] ? legacy : "0",
                        s.pointer ? 1 : 0, s.rect ? 1 : 0, s.display ? 1 : 0);
                if (!s.pointer || !s.rect || !s.display)
                {
                    TDU_Log("CYS-UNEQUIP-LIVE: PRECONDITION failed: UI_CEGUI.dll input exports missing - nothing measured");
                    s.step = Done;
                }
                else { s.step = Begin; s.at = GetTickCount(); }
            }
        }
        if (s.step == Off || s.step == Done) return true;
        if (!CysModernGame::IsInWorld()) { TDU_Log("CYS-UNEQUIP-LIVE: left the world at step %d", (int)s.step); s.step = Done; return true; }

        const CysInventoryNet::Counters c = CysInventoryNet::Get();
        switch (s.step)
        {
        case Begin:
            if (Age() < 3000) break;                  // let GCDetailEquipList / GCMyBagList settle
            s.itemBefore = WornItem(s.point);
            {
                tObject_Item* initial = CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)s.point);
                s.guidBefore = initial ? initial->GetGUID() : 0;
                TDU_Log("CYS-UNEQUIP-LIVE: initial item GUID=%I64u", s.guidBefore);
            }
            Snapshot("at start");
            CysWorldReplay::LiveShot("unequip-0-world-before");
            if (s.itemBefore <= 0 || !s.guidBefore)
            {
                TDU_Log("CYS-UNEQUIP-LIVE: PRECONDITION failed: nothing is worn at point %d - nothing measured", s.point);
                Go(Done, "no worn item");
                return true;
            }
            s.right = (strcmp(s.gesture, "left") != 0 && strcmp(s.gesture, "both") != 0) ? true : false; // both: left first
            Go(OpenFrame, "push ACCELERATE_KEYSEND acc_selfequip (the event the C key pushes)");
            break;

        case OpenFrame:
            CEventSystem::GetMe()->PushEvent(GE_ACCELERATE_KEYSEND, "acc_selfequip");
            Go(FrameWait, "wait for the character frame");
            break;

        case FrameWait:
            if (Age() < 2500) break;
            if (!Shown("SelfEquip"))
            {
                TDU_Log("CYS-UNEQUIP-LIVE: PRECONDITION failed: the character frame did not open - nothing measured");
                Go(Done, "frame not open");
                return true;
            }
            {
                float r[4] = {}, d[2] = {};
                const int haveRect = s.rect(s.window, r);
                const int haveDisplay = s.display(d);
                s.x = r[0] + r[2] * 0.5f; s.y = r[1] + r[3] * 0.5f;
                TDU_Log("CYS-UNEQUIP-LIVE: slot %s rect=%.1f,%.1f %.1fx%.1f (ok=%d) centre=%.1f,%.1f display=%.0fx%.0f (ok=%d)",
                        s.window, r[0], r[1], r[2], r[3], haveRect, s.x, s.y, d[0], d[1], haveDisplay);
                if (haveRect != 1 || haveDisplay != 1 || s.x < 0 || s.y < 0 || s.x >= d[0] || s.y >= d[1])
                {
                    TDU_Log("CYS-UNEQUIP-LIVE: PRECONDITION failed: slot %s is not on screen - nothing measured", s.window);
                    Go(Done, "slot not on screen");
                    return true;
                }
            }
            Snapshot("frame open");
            DumpStats();
            CysWorldReplay::LiveShot(s.pass == 0 ? "unequip-1-frame-before" : "unequip-4-frame-before-second");
            // A hover queues SHOW_SUPERTOOLTIP; its real Lua this:Show activates the tooltip. Let that event
            // finish before DOWN so the rig does not have activation steal capture halfway through its click.
            s.pointer(0, s.x, s.y);
            Go(Hover, "hover for 250 ms before mouse down");
            break;

        case Hover:
            if (Age() >= 250) Go(Press, "hover settled; press");
            break;

        case Press:
            s.baseUnEquip = c.unEquip;
            s.pointer(0, s.x, s.y);
            {
                const int ok = s.pointer(s.right ? 3u : 1u, s.x, s.y);
                TDU_Log("CYS-UNEQUIP-LIVE: %s button DOWN at %.1f,%.1f accepted=%d", s.right ? "RIGHT" : "LEFT", s.x, s.y, ok);
            }
            s.pressedAt = GetTickCount();
            Go(Release, "release on the next tick");
            break;

        case Release:
            // A human click: press and release are separate frames. No minimum hold: CEGUI raises MouseRClick /
            // MouseLClick only when the release follows the press within System::DefaultSingleClickTimeout (0.2 s,
            // CEGUISystem.cpp:125), and the smoke ticks every ~100 ms. A longer hold is NOT a click for CEGUI, so a
            // turn that held too long measured nothing: it is reported as such and the click is repeated.
            {
                const int ok = s.pointer(s.right ? 4u : 2u, s.x, s.y);
                s.heldMs = GetTickCount() - s.pressedAt;
                TDU_Log("CYS-UNEQUIP-LIVE: %s button UP at %.1f,%.1f accepted=%d held_ms=%lu", s.right ? "RIGHT" : "LEFT",
                        s.x, s.y, ok, (unsigned long)s.heldMs);
            }
            Go(AnswerWait, "wait for GCUnEquipResult");
            break;

        case AnswerWait:
            if (c.unEquip > s.baseUnEquip && Age() >= 1500) { Go(Report, "answered"); break; }
            if (Age() > 6000) Go(Report, "no GCUnEquipResult within 6 s");
            break;

        case Report:
        {
            const bool answered = c.unEquip > s.baseUnEquip;
            if (!answered && s.heldMs > 190 && s.retries < 3)
            {
                ++s.retries;
                TDU_Log("CYS-UNEQUIP-LIVE: INVALID CLICK: held %lu ms > 190 ms, CEGUI did not see a click; retry %d/3",
                        (unsigned long)s.heldMs, s.retries);
                Go(Press, "repeat the click");
                break;
            }
            const int worn = WornItem(s.point), model = ModelItem(s.point), bagSlot = BagSlotOf(s.itemBefore);
            Snapshot("after gesture");
            TDU_Log("CYS-UNEQUIP-LIVE: RESULT gesture=%s held_ms=%lu answered=%d worn_item=%d model_item=%d item_%d_bag_slot=%d taken_off=%d",
                    s.right ? "right" : "left", (unsigned long)s.heldMs, answered ? 1 : 0, worn, model, s.itemBefore, bagSlot,
                    (answered && worn <= 0 && bagSlot >= 0) ? 1 : 0);
            CysWorldReplay::LiveShot(s.pass == 0 ? (s.right ? "unequip-2-frame-after-right" : "unequip-2-frame-after-left")
                                                 : "unequip-5-frame-after-second");
            if (answered && worn <= 0) s.tookOff = true;
            Go(NextGesture, "next");
            break;
        }

        case NextGesture:
            if (strcmp(s.gesture, "left") == 0 && !CysSelfEquipGeometryProbe::Tick()) break;
            if (strcmp(s.gesture, "both") == 0 && s.pass == 0 && !s.tookOff)
            {
                s.pass = 1; s.right = true; s.retries = 0; // the left click left it on: now the right click
                Go(FrameWait, "second gesture of 'both': right click");
                break;
            }
            Go(CloseFrame, "close the frame to show the model");
            break;

        case CloseFrame:
            if (Shown("SelfEquip")) CEventSystem::GetMe()->PushEvent(GE_ACCELERATE_KEYSEND, "acc_selfequip");
            Go(WorldShot, "frame toggled off");
            break;

        case WorldShot:
            if (Age() < 2000) break;
            Snapshot("frame closed");
            CysWorldReplay::LiveShot("unequip-3-world-after");
            if (s.tookOff) Go(Restore, "put the item back on so the account ends as it started");
            else Go(PostMove, "nothing to restore; measure movement after frame close");
            break;

        case Restore:
        {
            // Putting it back is NOT under test (the user's own session proved the bag door: CGUseEquip left
            // through RBClicked). Use the action directly; it only tidies the test account.
            const int slot = BagSlotOf(s.itemBefore);
            tActionItem* action = slot >= 0 ? CActionSystem::GetMe()->EnumAction(slot, NAMETYPE_PACKAGEITEM) : NULL;
            if (!action) { TDU_Log("CYS-UNEQUIP-LIVE: restore: item %d is not in the bag; account left without it", s.itemBefore); Go(Done, "no restore"); break; }
            s.baseUseEquip = c.useEquip;
            action->DoAction();
            Go(RestoreWait, "CGUseEquip (restore, not under test)");
            break;
        }

        case RestoreWait:
            if (c.useEquip > s.baseUseEquip && Age() >= 1500)
            {
                tObject_Item* restored = CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)s.point);
                if (!restored || restored->GetGUID() != s.guidBefore)
                {
                    TDU_Log("CYS-UNEQUIP-LIVE: PRECONDITION restore failed: original GUID not at original point");
                    Snapshot("restore failed"); Go(Done, "restore failed");
                }
                else { Snapshot("restored"); CysWorldReplay::LiveShot("unequip-6-world-restored"); Go(PostMove, "restored; measure movement after frame close"); }
            }
            else if (Age() > 6000) { TDU_Log("CYS-UNEQUIP-LIVE: restore: no GCUseEquipResult within 6 s"); Snapshot("restore timeout"); Go(Done, "restore timeout"); }
            break;

        case PostMove:
        {
            CObject_PlayerMySelf* self = CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : NULL;
            if (!self || Shown("SelfEquip") || self->GetCharacterData()->IsLimitMove())
            {
                TDU_Log("CYS-UNEQUIP-LIVE: PRECONDITION post-close movement: self missing, frame open or movement limited");
                Go(Done, "post-close movement invalid"); break;
            }
            if (!s.postClicks)
            {
                TDU_Log("CYS-SELFEQUIP-POSTMOVE: BEGIN frame_shown=0 path=LiveGroundClick_Player_MoveTo first_index=4");
                CysWorldReplay::LiveShot("selfequip-postclose-move-before");
            }
            s.postFromX = self->GetPosition().x; s.postFromZ = self->GetPosition().z;
            TDU_Log("CYS-SELFEQUIP-POSTMOVE: REQUEST index=%u frame_shown=0 from=%.3f,%.3f",
                    s.postClicks + 4, s.postFromX, s.postFromZ);
            // Index4..6 are distinct from the initial replay's three clicks. The return
            // value alone is not success: the checker requires sent packets and displacement.
            if (!CysWorldReplay::LiveGroundClick(s.postClicks + 4))
            {
                TDU_Log("CYS-UNEQUIP-LIVE: PRECONDITION post-close movement: request failed");
                Go(Done, "post-close movement request failed"); break;
            }
            Go(PostMoveWait, "observe actual movement after frame close");
            break;
        }

        case PostMoveWait:
        {
            if (Age() < 2500) break;
            CObject_PlayerMySelf* self = CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : NULL;
            if (!self) { TDU_Log("CYS-UNEQUIP-LIVE: PRECONDITION post-close movement: self disappeared"); Go(Done, "no self"); break; }
            const float x = self->GetPosition().x, z = self->GetPosition().z;
            const float dx = x - s.postFromX, dz = z - s.postFromZ, distance = std::sqrt(dx * dx + dz * dz);
            TDU_Log("CYS-SELFEQUIP-POSTMOVE: OBSERVED index=%u frame_shown=%d from=%.3f,%.3f to=%.3f,%.3f distance_m=%.3f elapsed_ms=%lu",
                    s.postClicks + 4, Shown("SelfEquip") ? 1 : 0, s.postFromX, s.postFromZ, x, z, distance, (unsigned long)Age());
            if (Shown("SelfEquip") || !std::isfinite(distance) || distance < .5f)
            {
                TDU_Log("CYS-UNEQUIP-LIVE: PRECONDITION post-close movement: frame reopened or displacement below 0.5m");
                Go(Done, "post-close movement failed"); break;
            }
            s.postPath += distance;
            if (++s.postClicks < 3) { Go(PostMove, "next post-close destination"); break; }
            if (s.postPath < 2.0f)
            { TDU_Log("CYS-UNEQUIP-LIVE: PRECONDITION post-close movement: total below 2m"); Go(Done, "short path"); break; }
            TDU_Log("CYS-SELFEQUIP-POSTMOVE: DONE clicks=3 path_m=%.3f frame_shown=0", s.postPath);
            CysWorldReplay::LiveShot("selfequip-postclose-move-after");
            Go(Done, "post-close movement measured");
            break;
        }

        default:
            break;
        }
        if (s.step == Done) return true;
        return false;
    }
}
#else
namespace CysUnequipProbe { inline bool Tick() { return true; } }
#endif
