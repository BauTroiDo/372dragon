#pragma once
// CYS-UIEDIT 19/09: luot do live cho bo sua bo cuc UI (`CYS_UIEDIT_LIVE=1`).
//
// No chay DUNG loi ma ma cu keo chuot chay — `CysUiEditSelect` / `CysUiEditSizeBy` / `CysUiEditSave`
// la nhung ham ma `CysUiEdit::OnMouseMove` goi — nen mot luot xanh chung minh vong
// "mo -> doi hinh hoc -> luu -> nap lai van giu" that su chay. No KHONG chung minh cu keo chuot:
// duong chuot VAT LY bi `g_cysGlLoginSmoke` chan trong moi rig live (DIEU-PHOI 19/09 muc 11), nen
// cu keo phai do nguoi dung kiem.
//
// Bang chung "da ap that" nam o hai con so IN RA NGAY DAU luot, TRUOC khi sua gi:
//   rows    = so dong bang de doc duoc tu file
//   applied = so luot ghi de da ap tu luc khoi dong
// Luot 1 (file rong): rows=0 applied=0. Luot 2 (sau khi luu): rows>=1 va applied>=1 ⇒ file da duoc
// doc VA ap that. Luot 3 voi `CYS_UIEDIT_APPLY=0`: rows>=1 nhung applied=0 va o ve kich thuoc goc
// ⇒ phep do biet truot.
#include "CysUiInputBridge.h"
#include "TDUtil.h"
// CYS-UIEDIT 20/09: buoc do moc `@UIEDIT:` cua menu NPC (`CYS_UIEDIT_NPC=1`) — xem cuoi tep.
#include "..\DataPool\GMUIDataPool.h"
#include "..\DataPool\DataPoolCommandDef.h"
#include "..\GameCommand.h"
#include "ScriptCommandStruct.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>

namespace CysUiEditProbe
{
    namespace
    {
        typedef int (__cdecl *FnInt)(void);
        typedef int (__cdecl *FnSetMode)(int);
        typedef int (__cdecl *FnName)(const char*);
        typedef int (__cdecl *FnRect)(const char*, float[4]);
        typedef int (__cdecl *FnDelta)(float, float);
        typedef int (__cdecl *FnSave)(char*, unsigned);

        struct State
        {
            bool evaluated;
            bool on;
            bool drag;      // CYS_UIEDIT_LIVE=1 : vong chon -> doi hinh hoc -> luu
            bool npc;       // CYS_UIEDIT_NPC=1  : moc `@UIEDIT:` cua menu NPC
            bool done;
            unsigned step;
            float before[4];
            // Chep MOT lan luc khoi tao: `EnvOr` chi co 4 o dem xoay vong, dung no trong vong lap
            // la mot cach im lang de hai chuoi de len nhau.
            char npcWindow[64];
            char npcWidget[96];
            FnSetMode setMode;
            FnInt     mode;
            FnName    select;
            FnRect    rect;
            FnDelta   moveBy;
            FnDelta   sizeBy;
            FnSave    save;
            FnName    open;
            FnInt     applied;
            FnInt     rows;
            State() : evaluated(false), on(false), drag(false), npc(false), done(false), step(0),
                      setMode(0), mode(0), select(0),
                      rect(0), moveBy(0), sizeBy(0), save(0), open(0), applied(0), rows(0)
            { before[0] = before[1] = before[2] = before[3] = 0.0f; npcWindow[0] = 0; npcWidget[0] = 0; }
        };

        inline State& S() { static State s; return s; }

        inline const char* EnvOr(const char* name, const char* fallback)
        {
            static char buffer[4][256];
            static unsigned slot = 0;
            char* out = buffer[slot++ & 3];
            const DWORD n = ::GetEnvironmentVariableA(name, out, 255);
            return (n > 0 && n < 255) ? out : fallback;
        }

        inline float EnvFloat(const char* name, float fallback)
        {
            char value[32] = {0};
            const DWORD n = ::GetEnvironmentVariableA(name, value, sizeof(value));
            if (n == 0 || n >= sizeof(value)) return fallback;
            return (float)atof(value);
        }
    }

    // Cung hop dong voi CysHostHost2::Tick: true = tat hoac da xong.
    inline bool Tick()
    {
        State& s = S();
        if (s.done) return true;
        if (!s.evaluated)
        {
            s.evaluated = true;
            char flag[4] = {0};
            s.drag = (::GetEnvironmentVariableA("CYS_UIEDIT_LIVE", flag, sizeof(flag)) == 1 && flag[0] == '1');
            char flagNpc[4] = {0};
            s.npc = (::GetEnvironmentVariableA("CYS_UIEDIT_NPC", flagNpc, sizeof(flagNpc)) == 1 && flagNpc[0] == '1');
            s.on = s.drag || s.npc;
            if (!s.on) { s.done = true; return true; }
            HMODULE ui = ::GetModuleHandleA("UI_CEGUI.dll");
            if (!ui)
            {
                TDU_Log("CYS-UIEDIT live: HONG - khong tim thay UI_CEGUI.dll dang nap");
                s.done = true; return true;
            }
            s.setMode = (FnSetMode)::GetProcAddress(ui, "CysUiEditSetMode");
            s.mode    = (FnInt)    ::GetProcAddress(ui, "CysUiEditMode");
            s.select  = (FnName)   ::GetProcAddress(ui, "CysUiEditSelect");
            s.rect    = (FnRect)   ::GetProcAddress(ui, "CysUiEditGetRect");
            s.moveBy  = (FnDelta)  ::GetProcAddress(ui, "CysUiEditMoveBy");
            s.sizeBy  = (FnDelta)  ::GetProcAddress(ui, "CysUiEditSizeBy");
            s.save    = (FnSave)   ::GetProcAddress(ui, "CysUiEditSave");
            s.open    = (FnName)   ::GetProcAddress(ui, "CysUiEditOpen");
            s.applied = (FnInt)    ::GetProcAddress(ui, "CysUiEditApplied");
            s.rows    = (FnInt)    ::GetProcAddress(ui, "CysUiEditRows");
            if (!s.setMode || !s.select || !s.rect || !s.sizeBy || !s.save || !s.open || !s.applied || !s.rows)
            {
                TDU_Log("CYS-UIEDIT live: HONG - UI_CEGUI.dll thieu export cua bo sua "
                        "(setMode=%d select=%d rect=%d sizeBy=%d save=%d open=%d applied=%d rows=%d)",
                        s.setMode != 0, s.select != 0, s.rect != 0, s.sizeBy != 0,
                        s.save != 0, s.open != 0, s.applied != 0, s.rows != 0);
                s.done = true; return true;
            }
            // Khung dich cua buoc NPC phai KHAC khung cua vong keo, neu khong "da mo" cua buoc truoc
            // se lam buoc NPC trong nhu da dat ma khong chung minh gi.
            strncpy(s.npcWindow, EnvOr("CYS_UIEDIT_NPC_WINDOW", "Synthesize"), sizeof(s.npcWindow) - 1);
            strncpy(s.npcWidget, EnvOr("CYS_UIEDIT_NPC_WIDGET", "Synthesize_PageHeader_Name"), sizeof(s.npcWidget) - 1);
            s.npcWindow[sizeof(s.npcWindow) - 1] = 0;
            s.npcWidget[sizeof(s.npcWidget) - 1] = 0;
            // HAI CON SO NAY DUOC IN TRUOC KHI SUA BAT KY THU GI.
            TDU_Log("CYS-UIEDIT live: bat dau; rows=%d applied=%d (truoc khi sua)", s.rows(), s.applied());
        }

        const char* window = EnvOr("CYS_UIEDIT_LIVE_WINDOW", "LifeSkill");
        const char* widget = EnvOr("CYS_UIEDIT_LIVE_WIDGET", "LifeSkill_Target_Skill_Name");
        const float dw = EnvFloat("CYS_UIEDIT_LIVE_DW", 120.0f);

        // Hai cua truot: chi bat `CYS_UIEDIT_NPC` thi bo qua vong keo; chi bat `CYS_UIEDIT_LIVE`
        // thi bo qua buoc NPC. Hai phep do doc lap nhau, khong cai nao lam nen cho cai kia.
        if (!s.drag && s.step < 6) s.step = 6;
        if (!s.npc && s.step >= 6 && s.step < 90) s.step = 90;

        switch (s.step)
        {
        case 0:
            TDU_Log("CYS-UIEDIT live: SetMode(1) rc=%d mode=%d", s.setMode(1), s.mode ? s.mode() : -1);
            ++s.step; return false;
        case 1:
        {
            // Mo mot khung KHONG qua script cua no: day la cai nguoi dung goi la "NPC mo khung con loi".
            const int rc = s.open(window);
            TDU_Log("CYS-UIEDIT live: Open(\"%s\") rc=%d", window, rc);
            ++s.step; return false;
        }
        case 2:
        {
            if (!s.rect(widget, s.before))
            {
                TDU_Log("CYS-UIEDIT live: HONG - khong doc duoc o cua \"%s\" (khung chua nap?)", widget);
                s.done = true; return true;
            }
            TDU_Log("CYS-UIEDIT live: o goc cua \"%s\": x=%.1f y=%.1f w=%.1f h=%.1f",
                    widget, s.before[0], s.before[1], s.before[2], s.before[3]);
            ++s.step; return false;
        }
        case 3:
            TDU_Log("CYS-UIEDIT live: Select(\"%s\") rc=%d", widget, s.select(widget));
            ++s.step; return false;
        case 4:
        {
            const int rc = s.sizeBy(dw, 0.0f);
            float after[4] = {0.0f, 0.0f, 0.0f, 0.0f};
            s.rect(widget, after);
            const float grew = after[2] - s.before[2];
            TDU_Log("CYS-UIEDIT live: SizeBy(%.1f,0) rc=%d -> w %.1f -> %.1f (rong them %.1f px, mong doi %.1f)",
                    dw, rc, s.before[2], after[2], grew, dw);
            if (fabs(grew - dw) > 1.0f)
                TDU_Log("CYS-UIEDIT live: HONG - be rong khong doi dung muc mong doi");
            ++s.step; return false;
        }
        case 5:
        {
            char err[256] = {0};
            const int rows = s.save(err, sizeof(err));
            if (rows < 0) TDU_Log("CYS-UIEDIT live: HONG - luu that bai: %s", err);
            else          TDU_Log("CYS-UIEDIT live: Save -> %d dong", rows);
            ++s.step; return false;
        }
        // ---------------------------------------------------------------- moc `@UIEDIT:` cua menu NPC
        // Hai buoc nay chay tren DUNG duong ma cu bam cua nguoi choi di, va KHONG can server:
        // goi tin da giai ma (`ScriptParam_EventList`) duoc day vao `CUIDataPool` bang DUNG lenh ma
        // `GCScriptCommandHandler` dung, roi `SendSelectEvent` duoc goi y het luc bam muc menu.
        // Chi cai ONG SOCKET bi thay; moi doan ma sau do la that.
        //
        // Buoc 6 la DOI CHUNG AM va no nam TRONG CUNG MOT LUOT: cung danh sach, cung chi so, chi khac
        // MOT thu la chuoi co dau hieu hay khong. Neu moc luon mo khung bat ke dau hieu thi buoc 6
        // se mo `Synthesize` va phep do TRUOT — do la cach no biet truot.
        case 6:
        case 7:
        {
            CUIDataPool* pool = CUIDataPool::GetMe();
            if (!pool) { TDU_Log("CYS-UIEDIT npc: HONG - khong co CUIDataPool"); s.done = true; return true; }
            const bool withMark = (s.step == 7);
            const int  kScript = 999701;   // so rieng cho phep do, khong trung script that nao
            const int  kIndex  = 1;

            // TRANG THAI TRUOC, in ra truoc khi bam: khung da hien chua?
            float before[4] = {0.0f, 0.0f, 0.0f, 0.0f};
            const int presentBefore = s.rect(s.npcWidget, before) ? 1 : 0;

            char label[192];
            if (withMark) _snprintf(label, sizeof(label) - 1, "Sua khung @UIEDIT:%s", s.npcWindow);
            else          _snprintf(label, sizeof(label) - 1, "Sua khung %s", s.npcWindow);
            label[sizeof(label) - 1] = 0;

            static ScriptParam_EventList list;   // 16 muc — qua lon cho ngan xep cua Tick()
            list.Reset();
            list.m_idNPC = 1;
            ScriptString text; text.Reset(); text = label;
            list.m_seiItem[0].SetScriptID(kIndex, 0, kScript, &text);
            list.m_yItemCount = 1;

            SCommand_DPC cmd;
            cmd.m_wID        = DPC_SCRIPT_COMMAND;
            cmd.m_anParam[0] = SCRIPT_COMMAND_EVENT_LIST_RESPONSE;
            cmd.m_apParam[1] = &list;
            pool->OnCommand_(&cmd);

            TDU_Log("CYS-UIEDIT npc: %s; muc = \"%s\"; \"%s\" hien TRUOC khi bam = %d",
                    withMark ? "luot CO dau hieu" : "DOI CHUNG AM (khong dau hieu)",
                    label, s.npcWidget, presentBefore);

            pool->SendSelectEvent(0, kScript, kIndex);

            float after[4] = {0.0f, 0.0f, 0.0f, 0.0f};
            const int presentAfter = s.rect(s.npcWidget, after) ? 1 : 0;
            TDU_Log("CYS-UIEDIT npc: sau khi bam, \"%s\" hien = %d (w=%.1f)", s.npcWidget, presentAfter, after[2]);

            if (withMark && !presentAfter)
                TDU_Log("CYS-UIEDIT npc: HONG - co dau hieu ma khung khong mo");
            if (!withMark && presentAfter && !presentBefore)
                TDU_Log("CYS-UIEDIT npc: HONG - KHONG co dau hieu ma khung van mo (moc bat qua rong)");

            ++s.step; return false;
        }

        default:
            s.setMode(0);
            TDU_Log("CYS-UIEDIT live: XONG; mode=%d (da tat), rows=%d applied=%d",
                    s.mode ? s.mode() : -1, s.rows(), s.applied());
            s.done = true;
            return true;
        }
    }
}
