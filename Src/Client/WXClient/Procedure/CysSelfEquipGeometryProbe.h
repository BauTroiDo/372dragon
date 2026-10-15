#pragma once
// Explicit probe only. The real MouseButtonUp callback still owns every tab action.
#include "TDVariable.h"
#include "CysUiInputBridge.h"
#include "../Script/GMScriptSystem.h"
#include "../Script/CysCheckedScriptLua.h"
#include "../Network/CysWorldReplay.h"

namespace CysSelfEquipGeometryProbe
{
    struct State
    {
        int step = 0, index = 0, semantic[17] = {}, disabled[17] = {}, baseHits = 0;
        int routed = 0, blocked = 0, bad = 0, kind = 0;
        bool done = false, wrapped = false, luaUsable = true;
        DWORD at = 0, started = 0, pressed = 0;
        float x = 0, y = 0;
        const char* closeRoot = nullptr;
        CysUiInputBridge::SmokePointer pointer = nullptr;
        CysUiInputBridge::GetWindowRectUtf8 rect = nullptr;
        CysUiInputBridge::CopyCaptionUtf8 text = nullptr;
        CysUiInputBridge::GetDisplaySize display = nullptr;
    };
    inline State& S() { static State s; return s; }
    inline bool Shown(const char* name) { return CGameProcedure::s_pUISystem->IsWindowShow(name); }
    inline void Go(int next) { S().step = next; S().at = GetTickCount(); }
    inline int ReadInt(const char* name)
    {
        LuaPlus::LuaObject value = CScriptSystem::GetMe()->GetLuaState()->GetGlobals().GetByName(name);
        return value.IsNumber() ? (int)value.GetNumber() : -999;
    }
    inline bool Lua(const char* code)
    {
        if (!S().luaUsable) return false;
        const auto result = CScriptSystem::GetMe()->EvaluateScript("SelfEquip_Env", code);
        S().luaUsable = result.stateUsable;
        if (!result.ok()) TDU_Log("CYS-SELFEQUIP-GEOM: INVALID Lua status=%d usable=%d", result.status, result.stateUsable ? 1 : 0);
        return result.ok();
    }
    inline void RestoreObserver()
    {
        State& s = S();
        if (!s.wrapped) return;
        const bool ok = Lua("rawset(_G,'SelfEquip_OnPageClicked',__cys_geom_saved_raw); __cys_geom_saved_raw=nil; __cys_geom_original=nil; __cys_geom_hits=nil; __cys_geom_last=nil; __cys_geom_semantic=nil; __cys_geom_disabled=nil");
        TDU_Log("CYS-SELFEQUIP-GEOM: observer_restored=%d", ok ? 1 : 0);
        s.wrapped = false;
    }
    inline const char* Window(int index)
    {
        static const char* names[] = { "SelfEquip_SelfEquip", "SelfEquip_SelfData", "SelfEquip_Pet", "SelfEquip_Infant",
            "SelfEquip_Wuhun", "SelfEquip_Xiulian", "SelfEquip_Miji", "SelfEquip_ZhenYuan", "SelfEquip_JingMai",
            "SelfEquip_ShenDing", "SelfEquip_JunXian", "SelfEquip_BaoJian", "SelfEquip_WuYi", "SelfEquip_ShenQi",
            "SelfEquip_Armor", "SelfEquip_CangPin", "SelfEquip_OtherInfo" };
        return names[index];
    }
    inline const char* Target(int semantic)
    {
        switch (semantic)
        {
        case 1: return "SelfEquip"; case 2: return "SelfData"; case 3: return "Pet";
        case 5: return "Wuhun"; case 10: return "ShenDing"; case 17: return "OtherInfo";
        default: return "not-enabled-for-test13";
        }
    }
    inline bool PrepareClick(const char* name, int kind)
    {
        State& s = S(); float r[4] = {}, d[2] = {};
        if (s.rect(name, r) != 1 || s.display(d) != 1) return false;
        s.x = r[0] + r[2] / 2; s.y = r[1] + r[3] / 2;
        if (r[2] <= 0 || r[3] <= 0 || s.x < 0 || s.y < 0 || s.x >= d[0] || s.y >= d[1]) return false;
        s.kind = kind; s.pointer(0, s.x, s.y); Go(3); return true;
    }
    inline bool Tick()
    {
        static const bool on = []() { char v[4] = {}; return GetEnvironmentVariableA("CYS_SELFEQUIP_GEOMETRY_LIVE", v, sizeof(v)) == 1 && v[0] == '1'; }();
        State& s = S(); if (!on || s.done) return true;
        const DWORD now = GetTickCount();
        if (s.started && now - s.started > 65000)
        {
            if (s.step == 4 && s.pointer) s.pointer(2,s.x,s.y); // release a pending DOWN before abort
            TDU_Log("CYS-SELFEQUIP-GEOM: INVALID timeout"); RestoreObserver(); s.done = true; return true;
        }
        switch (s.step)
        {
        case 0:
        {
            s.started = now;
            HMODULE ui = GetModuleHandleA("UI_CEGUI.dll");
            s.pointer = (CysUiInputBridge::SmokePointer)GetProcAddress(ui, "CysUiSmokePointer");
            s.rect = (CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(ui, "CysUiGetWindowRectUtf8");
            s.text = (CysUiInputBridge::CopyCaptionUtf8)GetProcAddress(ui, "CysUiCopyCaptionUtf8");
            s.display = (CysUiInputBridge::GetDisplaySize)GetProcAddress(ui, "CysUiGetDisplaySize");
            if (!s.pointer || !s.rect || !s.text || !s.display || !CScriptSystem::GetMe() || !Shown("SelfEquip"))
            { TDU_Log("CYS-SELFEQUIP-GEOM: INVALID precondition"); s.done = true; return true; }
            if (!Lua("assert(__cys_geom_original == nil); assert(type(SelfEquip_OnPageClicked)=='function'); __cys_geom_saved_raw=rawget(_G,'SelfEquip_OnPageClicked'); __cys_geom_original=SelfEquip_OnPageClicked; __cys_geom_hits=0; __cys_geom_last=-1; SelfEquip_OnPageClicked=function(idx) __cys_geom_hits=__cys_geom_hits+1; __cys_geom_last=idx; return __cys_geom_original(idx) end"))
            { s.done = true; return true; }
            s.wrapped = true;
            float parent[4] = {}; s.rect("SelfEquip_Checkbox_Frame", parent);
            TDU_Log("CYS-SELFEQUIP-GEOM: BEGIN tabs=17 parent=%.1f,%.1f,%.1f,%.1f", parent[0],parent[1],parent[2],parent[3]);
            for (int i = 0; i < 17; ++i)
            {
                char code[512] = {}, caption[256] = {}, mask[96] = {}; float r[4] = {}, maskRect[4] = {};
                _snprintf(code, sizeof(code), "__cys_geom_semantic=-1; local n=0; for i=1,17 do if SelfEquip_CheckPage(i)==1 then n=n+1; if n==%d then __cys_geom_semantic=i end end end; __cys_geom_disabled=(%s:GetProperty('Disabled')=='True') and 1 or 0", i+1, Window(i));
                if (!Lua(code)) { RestoreObserver(); s.done = true; return true; }
                s.semantic[i] = ReadInt("__cys_geom_semantic"); s.disabled[i] = ReadInt("__cys_geom_disabled");
                _snprintf(mask, sizeof(mask), "%s_tips", Window(i));
                const int ok = s.rect(Window(i),r), bytes = s.text(Window(i),caption,sizeof(caption));
                TDU_Log("CYS-SELFEQUIP-GEOM: ROW slot=%d semantic=%d shown=%d disabled=%d mask=%d rect_ok=%d rect=%.1f,%.1f,%.1f,%.1f bytes=%d text=[%s]",
                    i+1,s.semantic[i],ok==1?1:0,s.disabled[i],s.rect(mask,maskRect)==1?1:0,ok,r[0],r[1],r[2],r[3],bytes,caption);
            }
            CysWorldReplay::LiveShot("selfequip-geometry-tabs"); Go(1); break;
        }
        case 1:
            if (s.index == 17)
            {
                RestoreObserver();
                TDU_Log("CYS-SELFEQUIP-GEOM: DONE measured=17 routed=%d blocked=%d bad=%d targets_are_separate=1",s.routed,s.blocked,s.bad);
                s.done=true; return true;
            }
            if (!Shown("SelfEquip")) CEventSystem::GetMe()->PushEvent(GE_ACCELERATE_KEYSEND,"acc_selfequip");
            Go(2); break;
        case 2:
            if (now-s.at < 750) break;
            s.baseHits=ReadInt("__cys_geom_hits");
            if (!PrepareClick(Window(s.index),0))
            { TDU_Log("CYS-SELFEQUIP-GEOM: OUTCOME slot=%d INVALID target-not-visible",s.index+1); ++s.bad; ++s.index; Go(1); }
            break;
        case 3:
            if (now-s.at < 250) break;
            TDU_Log("CYS-SELFEQUIP-GEOM: DOWN slot=%d kind=%d accepted=%d",s.index+1,s.kind,s.pointer(1,s.x,s.y));
            s.pressed=now; Go(4); break;
        case 4:
            if (now-s.pressed < 70) break;
            TDU_Log("CYS-SELFEQUIP-GEOM: UP slot=%d kind=%d accepted=%d held_ms=%lu",s.index+1,s.kind,s.pointer(2,s.x,s.y),(unsigned long)(now-s.pressed));
            if (now-s.pressed > 190) ++s.bad;
            Go(s.kind==0 ? 5 : 7); break;
        case 5:
        {
            if (now-s.at < 400) break;
            const int delta=ReadInt("__cys_geom_hits")-s.baseHits, last=ReadInt("__cys_geom_last");
            const bool pass=s.disabled[s.index] ? delta==0 : delta==1 && last==s.index+1;
            if (!pass) ++s.bad; else if(s.disabled[s.index]) ++s.blocked; else ++s.routed;
            const char* target=Target(s.semantic[s.index]);
            TDU_Log("CYS-SELFEQUIP-GEOM: OUTCOME slot=%d semantic=%d disabled=%d dispatch_delta=%d last=%d route=%s target=%s target_state=%s",
                s.index+1,s.semantic[s.index],s.disabled[s.index],delta,last,pass?"PASS":"FAIL",target,
                s.disabled[s.index]?"LOCKED":Shown(target)?"OPEN":"NOT_OPEN");
            char shot[64]={}; _snprintf(shot,sizeof(shot),"selfequip-geometry-tab-%02d",s.index+1); CysWorldReplay::LiveShot(shot);
            Go(6); break;
        }
        case 6:
        {
            static const char* roots[]={"SelfData","Pet","Wuhun","ShenDing","OtherInfo"};
            bool close=false;
            for (const char* root:roots) if(Shown(root))
            {
                char name[64]={}; _snprintf(name,sizeof(name),"%s_Close",root); s.closeRoot=root;
                if (!PrepareClick(name,1)) { TDU_Log("CYS-SELFEQUIP-GEOM: INVALID close target=%s",root); ++s.bad; RestoreObserver(); s.done=true; return true; }
                close=true; break;
            }
            if (!close) { ++s.index; Go(1); }
            break;
        }
        case 7:
            if(now-s.at < 400) break;
            if (s.closeRoot && Shown(s.closeRoot))
            { TDU_Log("CYS-SELFEQUIP-GEOM: INVALID close remained=%s",s.closeRoot); ++s.bad; RestoreObserver(); s.done=true; return true; }
            Go(6); break;
        }
        return false;
    }
}
