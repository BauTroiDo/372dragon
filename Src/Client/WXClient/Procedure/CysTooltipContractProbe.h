#pragma once
// Owned smoke only: real CEGUI hover, DirectInput event queue, server item refresh.
#include "CysUiInputBridge.h"
#include "CysTooltipContract.h"
#include "CysAccelTable.h"
#include "../Script/GMScriptSystem.h"
#include "../Script/CysCheckedScriptLua.h"
#include "../Input/GMInputSystem.h"
#include "../Event/GMEventSystem.h"
#include "../DataPool/GMDataPool.h"
#include "../Object/Item/Obj_Item.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Network/CysModernHandlers.h"
#include "../Network/CysWorldReplay.h"
#include "../Network/NetManager.h"
#include "CGAskItemInfo.h"
#include "TDEventDefine.h"
#include "TDUtil.h"
#include <cmath>
#include <stdexcept>

namespace CysTooltipContractProbe
{
    struct State
    {
        bool evaluated = false, enabled = false, done = false;
        unsigned phase = 0, infos = 0;
        DWORD next = 0, until = 0;
        int slot = -1;
        float button[4] = {}, display[2] = {}, fromX = 0, fromZ = 0;
        const char* shot = nullptr;
        CysUiInputBridge::SmokePointer pointer = nullptr;
        CysUiInputBridge::GetWindowRectUtf8 rect = nullptr;
        CysUiInputBridge::GetDisplaySize displaySize = nullptr;
        CysUiInputBridge::CopyCaptionUtf8 text = nullptr;
    };
    inline State& S() { static State state; return state; }
    inline bool Env(const char* name)
    {
        char value[4] = {};
        return GetEnvironmentVariableA(name, value, sizeof(value)) == 1 && value[0] == '1';
    }
    inline void Require(bool ok, const char* reason)
    {
        if (ok) return;
        TDU_Log("CYS-FT-TOOLTIP-PROBE: FAIL %s", reason);
        throw std::runtime_error(reason);
    }
    inline void Lua(const char* owner, const char* code)
    {
        const CysCheckedScriptLua::Result result = CScriptSystem::GetMe()->EvaluateScript(owner, code);
        if (!result.ok()) TDU_Log("CYS-FT-TOOLTIP-PROBE: Lua error [%s]", result.error);
        Require(result.ok(), "checked Lua failed");
    }
    inline void Position(const char* phase)
    {
        State& s = S();
        float tip[4] = {};
        Require(s.rect("_SuperTooltip_", tip) == 1, "tooltip is not visible after native hover");
        const float left = static_cast<float>(static_cast<int>(s.button[0]));
        const float top = static_cast<float>(static_cast<int>(s.button[1]));
        const float right = static_cast<float>(static_cast<int>(s.button[0] + s.button[2]));
        const float bottom = static_cast<float>(static_cast<int>(s.button[1] + s.button[3]));
        float x = tip[2] + right + 5 <= s.display[0] ? right + 0.5f : left - tip[2];
        float y = tip[3] + bottom + 5 <= s.display[1] ? bottom + 0.5f : top - tip[3];
        if (x < 0) x = 0;
        if (y < 0) y = 0;
        TDU_Log("CYS-FT-TOOLTIP-PROBE: position phase=%s actual=%.2f,%.2f size=%.2f,%.2f expected=%.2f,%.2f", phase, tip[0], tip[1], tip[2], tip[3], x, y);
        if (!CysTooltipContract::Old()) Require(std::fabs(tip[0] - x) <= 1.0f && std::fabs(tip[1] - y) <= 1.0f, "tooltip differs from recovered edge formula");
        const char* names[] = { "SuperTooltip_StaticPart_Title", "SuperTooltip_StaticPart_Item1", "SuperTooltip_StaticPart_Item2", "SuperTooltip_StaticPart_Item3",
            "SuperTooltip_StaticPart_Item4", "SuperTooltip_ShortDesc_Text", "SuperTooltip_Property", "SuperTooltip_Explain", "SuperTooltip_StaticPart_Money_Text" };
        for (const char* name : names)
        {
            char text[4096] = {};
            const int bytes = s.text(name, text, sizeof(text));
            TDU_Log("CYS-FT-TOOLTIP-PROBE: content phase=%s window=%s bytes=%d text=[%s]", phase, name, bytes, text);
            float child[4] = {};
            const int visible = s.rect(name, child);
            TDU_Log("CYS-FT-TOOLTIP-PROBE: child phase=%s window=%s visible=%d rect=%.1f,%.1f,%.1f,%.1f",
                phase, name, visible, child[0], child[1], child[2], child[3]);
        }
    }
    inline bool Tick()
    {
        State& s = S();
        if (s.done) return true;
        if (!s.evaluated)
        {
            s.evaluated = true;
            s.enabled = Env("CYS_FT_TOOLTIP_LIVE");
            if (!s.enabled) { s.done = true; return true; }
            Require(Env("CYS_GL_LOGIN_SMOKE") && CysTooltipContract::Probe(), "tooltip probe requires smoke and diagnostic flags");
            HMODULE ui = GetModuleHandleA("UI_CEGUI.dll");
            Require(ui != nullptr, "UI DLL unavailable");
            s.pointer = reinterpret_cast<CysUiInputBridge::SmokePointer>(GetProcAddress(ui, "CysUiSmokePointer"));
            s.rect = reinterpret_cast<CysUiInputBridge::GetWindowRectUtf8>(GetProcAddress(ui, "CysUiGetWindowRectUtf8"));
            s.displaySize = reinterpret_cast<CysUiInputBridge::GetDisplaySize>(GetProcAddress(ui, "CysUiGetDisplaySize"));
            s.text = reinterpret_cast<CysUiInputBridge::CopyCaptionUtf8>(GetProcAddress(ui, "CysUiCopyCaptionUtf8"));
            Require(s.pointer && s.rect && s.displaySize && s.text, "UI smoke bridge unavailable");
            Require(s.displaySize(s.display) == 1, "display size unavailable");
            TDU_Log("CYS-FT-TOOLTIP-PROBE: BEGIN old=%d display=%.0f,%.0f", CysTooltipContract::Old() ? 1 : 0, s.display[0], s.display[1]);
        }
        if (static_cast<LONG>(GetTickCount() - s.next) < 0) return false;
        if (s.phase == 0)
        {
            if (!CGameProcedure::s_pUISystem->IsWindowShow("Packet")) CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);
            s.phase = 1; s.next = GetTickCount() + 1500; return false;
        }
        if (s.phase == 1)
        {
            // DoFile defines functions in _G; the selected frame environment supplies widgets.
            // Match the real Packet tab event instead of indexing a function on Packet_Env.
            Lua("Packet_Env", "assert(type(Packet_ChangeTabIndex)=='function'); Packet_ChangeTabIndex(0)");
            // Live CY Packet.lua:88..107 and 676..682 enumerate base slots in rows of ten.
            // Prefer equipment but never create or move an item to manufacture a pass.
            for (int pass = 0; pass < 2 && s.slot < 0; ++pass)
                for (int slot = 0; slot < 100; ++slot)
                {
                    tObject_Item* item = CDataPool::GetMe()->UserBag_GetItem(slot);
                    if (!item || (pass == 0 && item->GetItemClass() != ICLASS_EQUIP)) continue;
                    char name[96];
                    _snprintf(name, sizeof(name), "Packet_Space_Line%d_Row%d_button", slot / 10 + 1, slot % 10 + 1);
                    if (s.rect(name, s.button) != 1 || s.button[2] <= 0 || s.button[3] <= 0) continue;
                    s.slot = slot;
                    TDU_Log("CYS-FT-TOOLTIP-PROBE: target slot=%d item=%u name=[%s] button=%s rect=%.2f,%.2f,%.2f,%.2f", slot, item->GetIdTable(), item->GetName(), name, s.button[0], s.button[1], s.button[0] + s.button[2], s.button[1] + s.button[3]);
                    break;
                }
            Require(s.slot >= 0, "no visible base-bag item to measure");
            Require(s.pointer(0, 1, 1) == 1, "pointer leave rejected");
            s.shot = "tooltip-packet-open";
            s.phase = 2; s.next = GetTickCount() + 300; return false;
        }
        if (s.phase == 2)
        {
            Require(s.pointer(0, s.button[0] + s.button[2] / 2, s.button[1] + s.button[3] / 2) == 1, "pointer hover rejected");
            s.phase = 3; s.next = GetTickCount() + 2000; return false;
        }
        if (s.phase == 3)
        {
            Position("hover");
            float first[4] = {}, last[4] = {};
            Require(s.rect("_SuperTooltip_", first) == 1, "tooltip missing before repeat resize");
            char resize[256];
            _snprintf(resize, sizeof(resize), "for i=1,6 do _SuperTooltip_:PositionSelf(%d,%d,%d,%d) end",
                static_cast<int>(s.button[0]), static_cast<int>(s.button[1]),
                static_cast<int>(s.button[0] + s.button[2]), static_cast<int>(s.button[1] + s.button[3]));
            Lua("SuperTooltip_Env", resize);
            Require(s.rect("_SuperTooltip_", last) == 1, "tooltip missing after repeat resize");
            TDU_Log("CYS-FT-TOOLTIP-PROBE: repeat-resize count=6 before=%.2f after=%.2f", first[3], last[3]);
            if (!CysTooltipContract::Old() && !Env("CYS_FT_RESIZETEXT_OLD"))
                Require(std::fabs(first[3] - last[3]) <= 1.0f, "repeated sizing changed tooltip height");
            s.shot = "tooltip-hover";
            Lua("SuperTooltip_Env", CysTooltipContract::Old()
                ? "local v=SuperTooltips:SendAskItemInfoMsg() assert(type(v)=='nil')"
                : "local v=SuperTooltips:SendAskItemInfoMsg() assert(type(v)=='number' and (v==0 or v==1))");
            s.phase = 4; s.next = GetTickCount() + 1000; return false;
        }
        if (s.phase == 4)
        {
            // Read-only refresh while the same native tooltip remains visible: force the async path even
            // when the login bag list already carried details and SendAskItemInfoMsg correctly returned 0.
            Position("before-refresh");
            s.infos = CysModernHandlers::Core().itemInfos;
            CGAskItemInfo ask; ask.setID(s.slot); CNetManager::GetMe()->SendPacket(&ask);
            TDU_Log("CYS-FT-TOOLTIP-PROBE: refresh slot=%d before=%u", s.slot, s.infos);
            s.phase = 5; s.until = GetTickCount() + 10000; s.next = GetTickCount() + 500; return false;
        }
        if (s.phase == 5)
        {
            if (CysModernHandlers::Core().itemInfos <= s.infos)
            {
                Require(static_cast<LONG>(GetTickCount() - s.until) < 0, "GCItemInfo refresh not received");
                s.next = GetTickCount() + 100; return false;
            }
            TDU_Log("CYS-FT-TOOLTIP-PROBE: refreshed delta=%u", CysModernHandlers::Core().itemInfos - s.infos);
            Position("refreshed"); s.shot = "tooltip-refreshed";
            Require(CInputSystem::GetMe() != nullptr, "input queue unavailable");
            CInputSystem::GetMe()->CysInjectKey(KC_LMENU, TRUE);
            s.phase = 6; s.next = GetTickCount() + 1000; return false;
        }
        if (s.phase == 6)
        {
            Position("alt-down"); s.shot = "tooltip-alt-down";
            CInputSystem::GetMe()->CysInjectKey(KC_LMENU, FALSE);
            s.phase = 7; s.next = GetTickCount() + 1000; return false;
        }
        if (s.phase == 7)
        {
            Position("alt-up"); s.shot = "tooltip-alt-up";
            Require(s.pointer(0, 1, 1) == 1, "pointer leave rejected");
            if (CGameProcedure::s_pUISystem->IsWindowShow("Packet")) CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);
            CysAccel::SetChatting(false);
            CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
            Require(self != nullptr, "self unavailable before movement");
            s.fromX = self->GetPosition().x; s.fromZ = self->GetPosition().z;
            Require(CysWorldReplay::LiveGroundClick(7), "ground click could not be sent");
            s.phase = 8; s.next = GetTickCount() + 3500; return false;
        }
        CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
        Require(self != nullptr, "self unavailable after movement");
        const float dx = self->GetPosition().x - s.fromX, dz = self->GetPosition().z - s.fromZ;
        const float moved = std::sqrt(dx * dx + dz * dz);
        TDU_Log("CYS-FT-TOOLTIP-PROBE: END old=%d moved=%.2f slot=%d", CysTooltipContract::Old() ? 1 : 0, moved, s.slot);
        Require(moved >= 2, "movement after tooltip below two units");
        s.done = true; return true;
    }
    inline const char* ShotName() { const char* shot = S().shot; S().shot = nullptr; return shot; }
}
