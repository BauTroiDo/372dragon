#pragma once
// Explicit live smoke only. Input targets this process's GUI, never the desktop.
// CYS_CHATENTER_OFF=1 keeps the original stub paths for a same-binary control.
#include "CysUiInputBridge.h"
#include "CysAccelTable.h"
#include "../Input/GMInputSystem.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Network/CysWorldReplay.h"
#include "../Script/GMScriptSystem.h"
#include "../Script/CysCheckedScriptLua.h"
#include "../Network/CysModernHandlers.h"
#include "TDUtil.h"
#include <cstring>
#include <cmath>
#include <stdexcept>

namespace CysChatEnterProbe
{
    struct State
    {
        bool evaluated = false, enabled = false, off = false, done = false;
        unsigned phase = 0, index = 0;
        DWORD next = 0;
        float fromX = 0, fromZ = 0;
        const char* shot = nullptr;
        CysUiInputBridge::SmokePointer pointer = nullptr;
        CysUiInputBridge::GetWindowRectUtf8 rect = nullptr;
        CysUiInputBridge::GetActiveInputName active = nullptr;
        CysUiInputBridge::CopyWindowTextUtf8 text = nullptr;
    };
    inline State& S() { static State state; return state; }
    inline bool Env(const char* name)
    {
        char value[4] = {};
        return GetEnvironmentVariableA(name, value, sizeof(value)) == 1 && value[0] == '1';
    }
    inline void Require(bool ok, const char* message)
    {
        if (ok) return;
        TDU_Log("CYS-CHATENTER-PROBE: FAIL %s", message);
        throw std::runtime_error(message);
    }
    inline void Lua(const char* code)
    {
        CScriptSystem* script = CScriptSystem::GetMe();
        Require(script != nullptr, "script system unavailable");
        const CysCheckedScriptLua::Result result = script->EvaluateScript("CysChatEnterProbe", code);
        if (!result.ok()) TDU_Log("CYS-CHATENTER-PROBE: Lua error [%s]", result.error);
        Require(result.ok(), "checked Lua failed");
    }
    inline void Enter()
    {
        const LPARAM scan = static_cast<LPARAM>(MapVirtualKeyW(VK_RETURN, MAPVK_VK_TO_VSC)) << 16;
        SendMessageW(g_hMainWnd, WM_KEYDOWN, VK_RETURN, scan | 1);
        SendMessageW(g_hMainWnd, WM_CHAR, VK_RETURN, scan | 1);
        SendMessageW(g_hMainWnd, WM_KEYUP, VK_RETURN, scan | 0xc0000001);
    }
    inline void ClearInput()
    {
        Require(S().active() && std::strcmp(S().active(), "Chat_EditBox") == 0, "chat reset target is not focused");
        // WM_CHAR Ctrl+A / Backspace use the same selection/delete path as native editing.
        // SetTextOriginal only stores translation metadata and does not clear displayed text.
        SendMessageW(g_hMainWnd, WM_CHAR, 1, 1);
        SendMessageW(g_hMainWnd, WM_CHAR, VK_BACK, 1);
        char text[512] = {};
        Require(S().text("Chat_EditBox", text, sizeof(text)) >= 0 && !text[0], "preparation did not clear chat input");
        TDU_Log("CYS-CHATENTER-PROBE: reset empty=1");
    }
    inline const wchar_t* Phrase(unsigned index)
    {
        static const wchar_t* phrases[] = {
            L"alo CYSCE01", L"Ch\u00E0o Vi\u1EC7t Nam CYSCE02", L"chat tiep CYSCE03"
        };
        return phrases[index];
    }
    inline const char* Expected(unsigned index)
    {
        static const char* phrases[] = {
            "alo CYSCE01", "Ch\xC3\xA0o Vi\xE1\xBB\x87t Nam CYSCE02", "chat tiep CYSCE03"
        };
        return phrases[index];
    }
    inline bool Tick()
    {
        State& s = S();
        if (s.done) return true;
        if (!s.evaluated)
        {
            s.evaluated = true;
            s.enabled = Env("CYS_CHATENTER_LIVE");
            if (!s.enabled) { s.done = true; return true; }
            Require(Env("CYS_CHATENTER_PROBE"), "diagnostic logging must be enabled for a measured run");
            Require(Env("CYS_GL_LOGIN_SMOKE"), "chat probe requires explicit smoke mode");
            s.off = Env("CYS_CHATENTER_OFF");
            HMODULE ui = GetModuleHandleA("UI_CEGUI.dll");
            s.pointer = reinterpret_cast<CysUiInputBridge::SmokePointer>(GetProcAddress(ui, "CysUiSmokePointer"));
            s.rect = reinterpret_cast<CysUiInputBridge::GetWindowRectUtf8>(GetProcAddress(ui, "CysUiGetWindowRectUtf8"));
            s.active = reinterpret_cast<CysUiInputBridge::GetActiveInputName>(GetProcAddress(ui, "CysUiGetActiveInputName"));
            s.text = reinterpret_cast<CysUiInputBridge::CopyWindowTextUtf8>(GetProcAddress(ui, "CysUiCopyWindowTextUtf8"));
            Require(s.pointer && s.rect && s.active && s.text, "UI input bridge unavailable");
            TDU_Log("CYS-CHATENTER-PROBE: BEGIN off=%d", s.off ? 1 : 0);
            Require(CInputSystem::GetMe() != nullptr, "input queue unavailable before chat");
            CInputSystem::GetMe()->CysInjectKey(KC_RETURN, TRUE);
            CInputSystem::GetMe()->CysInjectKey(KC_RETURN, FALSE);
            s.phase = 9; s.next = GetTickCount() + 500; return false;
        }
        if (static_cast<LONG>(GetTickCount() - s.next) < 0) return false;
        if (s.phase == 9)
        {
            Require(CysAccel::ChatEditActive(), "Enter did not open chat input mode");
            TDU_Log("CYS-CHATENTER-PROBE: input-mode opened=1");
            s.phase = 0;
        }
        if (s.phase == 0)
        {
            // Clearing under test remains exclusively ChatFrame_TextAccepted's setter.
            Lua("assert(ChatFrame_Env and ChatFrame_Env.Chat_EditBox) "
                "ChatFrame_Env.g_theCurrentChannel='near'");
            float r[4] = {};
            Require(s.rect("Chat_EditBox", r) == 1, "chat editbox not visible");
            const float x = r[0] + r[2] / 2, y = r[1] + r[3] / 2;
            Require(s.pointer(1, x, y) == 1 && s.pointer(2, x, y) == 1, "chat click rejected");
            Require(s.active() && std::strcmp(s.active(), "Chat_EditBox") == 0, "chat editbox focus mismatch");
            ClearInput();
            for (const wchar_t* p = Phrase(s.index); *p; ++p) SendMessageW(g_hMainWnd, WM_CHAR, *p, 1);
            char text[512] = {};
            Require(s.text("Chat_EditBox", text, sizeof(text)) >= 0, "cannot read typed text");
            TDU_Log("CYS-CHATENTER-PROBE: typed case=%u text=[%s]", s.index + 1, text);
            Require(std::strcmp(text, Expected(s.index)) == 0, "typed text differs from Unicode input");
            if (s.index == 0) s.shot = "chatenter-before";
            s.phase = 1; s.next = GetTickCount() + 500; return false;
        }
        if (s.phase == 1)
        {
            Enter();
            s.phase = 2; s.next = GetTickCount() + 1000; return false;
        }
        if (s.phase == 2)
        {
            char text[512] = {};
            Require(s.text("Chat_EditBox", text, sizeof(text)) >= 0, "cannot read text after Enter");
            TDU_Log("CYS-CHATENTER-PROBE: after case=%u cleared=%d text=[%s]", s.index + 1, !text[0] ? 1 : 0, text);
            Require(s.off ? std::strcmp(text, Expected(s.index)) == 0 : !text[0], "clear behavior differs from A/B arm");
            s.shot = s.index == 0 ? "chatenter-after-1" : (s.index == 1 ? "chatenter-after-2" : "chatenter-after-3");
            s.phase = 3; s.next = GetTickCount() + 3000; return false;
        }
        if (s.phase == 3)
        {
            if (++s.index < 3) { s.phase = 0; return false; }
            // Empty Enter is a negative control for packet generation.
            ClearInput();
            TDU_Log("CYS-CHATENTER-PROBE: empty-enter BEGIN");
            Enter();
            s.phase = 4; s.next = GetTickCount() + 1500; return false;
        }
        if (s.phase == 4)
        {
            Require(CInputSystem::GetMe() != nullptr, "input queue unavailable after chat");
            CInputSystem::GetMe()->CysInjectKey(KC_ESCAPE, TRUE);
            CInputSystem::GetMe()->CysInjectKey(KC_ESCAPE, FALSE);
            s.phase = 5; s.next = GetTickCount() + 500; return false;
        }
        if (s.phase == 5)
        {
            Require(!CysAccel::ChatEditActive(), "Escape did not leave chat input mode");
            CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
            Require(self != nullptr, "self unavailable before post-chat movement");
            s.fromX = self->GetPosition().x; s.fromZ = self->GetPosition().z;
            Require(CysWorldReplay::LiveGroundClick(8), "post-chat ground click rejected");
            s.phase = 6; s.next = GetTickCount() + 3500; return false;
        }
        CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
        Require(self != nullptr, "self unavailable after post-chat movement");
        const float dx = self->GetPosition().x - s.fromX, dz = self->GetPosition().z - s.fromZ;
        const float moved = std::sqrt(dx * dx + dz * dz);
        TDU_Log("CYS-CHATENTER-PROBE: END off=%d input_cases=3 empty_cases=1 moved=%.2f chatting=%d", s.off ? 1 : 0, moved, CysAccel::ChatEditActive() ? 1 : 0);
        Require(moved >= 2, "post-chat movement below two units");
        s.done = true;
        return true;
    }
    inline const char* ShotName()
    {
        const char* result = S().shot;
        S().shot = nullptr;
        return result;
    }
}
