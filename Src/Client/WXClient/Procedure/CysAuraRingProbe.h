#pragma once
// CYS-AURARING 20/09: luot do live cho VONG BAO TAM CHIEU (技能作用范围环) - `CYS_AURARING_LIVE=1`.
//
// VI SAO CAN MOT BO DO RIENG: vong nay la chi bao hien ra TRUOC KHI thi trien, tren duong CON TRO.
// Rig `--cast` cua `atk-range` gui thang goi thi trien nen KHONG BAO GIO di qua `MCT_SKILL_AREA`
// va vi vay khong the nghiem thu duoc chuoi loi nay. Duong that chi co hai nhanh:
//   (a) nguoi choi bam icon chieu dien rong => `CActionSystem::SetDefaultAction`
//   (b) con tro di qua mat dat        => `CCursorMng::MouseCommand_Set(..., pDefaultAction)`
//        -> `CursorMng.cpp:752-766` case SELECT_TYPE_POS: MCT_SKILL_AREA + m_afParam[5] = DamageRange*100
//   (c) `CGamePro_Main::ProcessInput_Mouse` (GamePro_Main.cpp:544-557) dung `m_afParam[5]` de dung vong.
// Bo do nay chay dung (b) + (c), bang chinh cac ham ao that; no KHONG tu ve gi ca.
//
// CHUOI LOI DANG NGHIEM THU (ba khau, deu ke thua tu 0.85, CY da sua ca ba):
//   1 `WXObj_ProjTex.cpp:25`  xin `createEffect("aura_rune_projector")` - du lieu chi co `...0..15`
//   2 `Obj_ProjTex.h:78`      ctor khong khoi tao `m_fRingRange` (ctor dung bi chu thich)
//   3 `GamePro_Main.cpp:554`  khong bao gio doc `cmd.m_afParam[5]`; `SetRingRange()` 0 noi goi
//
// DOI CHUNG AM (CUNG binary, khac dung MOT bien): `CYS_AURARING=0` giu NGUYEN VAN ten template tran.
//   canh =0 PHAI co  dong auraring cua Render.dll ket thuc bang `effect=aura_rune_projector` VA dong
//            `can't find the required effect template 'aura_rune_projector` => 0 diem anh vong.
//   canh =1 PHAI co  `... effect=aura_rune_projector0`, KHONG co dong "can't find", va ANH CO VONG.
// Neu tay do am ma van ra vong thi phep do KHONG biet truot => bo di.
//
// BAY DA BIET, ghi ra de nguoi sau khong mat mot luot:
//   - Chieu `SELECT_TYPE_POS` co `m_fDamageRange == 0` (ca 30 chieu khinh cong, ke ca 34) cho
//     `m_afParam[5] = 0`. Bo do vi the UU TIEN chieu co DamageRange > 0 va in ro da chon cai nao.
//   - `EffectManager` cua CYS TU TAO template `Effect_Error` trong ctor (WXEffectManager.cpp:148-149),
//     nen canh =0 KHONG nem ngoai le: no ve mot effect RONG. Dung de canh doi chung khong bi
//     nham voi mot cu van.
#include "TDUtil.h"
#include "TDActionSystem.h"
#include "..\Global.h"
#include "..\Cursor\CursorMng.h"
#include "..\GameCommand.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\Object\ProjTex\Obj_ProjTex.h"
#include "..\Action\GMActionSystem.h"
#include "..\DataPool\GMDP_Struct_Skill.h"
#include "GameStruct_Skill.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace CysAuraRingProbe
{
    namespace
    {
        struct State
        {
            bool evaluated;
            bool on;
            bool done;
            int  step;
            int  wait;
            int  skillsSeen;
            int  posSeen;
            int  chosenId;
            float chosenRange;      // m_fDamageRange cua chieu da chon
            float paramRingRange;   // m_afParam[5] doc lai tu lenh chuot
            int  leftType;          // m_typeMouse thu duoc
            bool ringMade;
            // CYS-PROJSIZE (projsize 20/09): quet NHIEU ban kinh trong CUNG MOT luot, CUNG camera.
            // `CYS_AURARING_SWEEP=300,800,1000` => ba anh projsize-0/-1/-2. Khong dat => y nguyen
            // hanh vi cu cua auraring (mot vong, ba anh auraring-before/-1/-2).
            int   sweepN;
            int   sweepAt;
            float sweep[4];
            CObject_ProjTex_AuraDure* ring;
            tActionItem* skill;
            fVector3 at;
            State() : evaluated(false), on(false), done(false), step(0), wait(0),
                      skillsSeen(0), posSeen(0), chosenId(-1), chosenRange(-1.0f),
                      paramRingRange(-1.0f), leftType(-1), ringMade(false),
                      sweepN(0), sweepAt(0), ring(NULL),
                      skill(NULL), at(0.0f, 0.0f, 0.0f)
            { sweep[0] = sweep[1] = sweep[2] = sweep[3] = 0.0f; }
        };
        inline State& S() { static State s; return s; }

        inline const char* MctName(int t)
        {
            switch (t)
            {
            case SCommand_Mouse::MCT_NULL:          return "MCT_NULL";
            case SCommand_Mouse::MCT_PLAYER_MOVETO: return "MCT_PLAYER_MOVETO";
            case SCommand_Mouse::MCT_SKILL_OBJ:     return "MCT_SKILL_OBJ";
            case SCommand_Mouse::MCT_SKILL_AREA:    return "MCT_SKILL_AREA";
            case SCommand_Mouse::MCT_SKILL_DIR:     return "MCT_SKILL_DIR";
            default:                                return "khac";
            }
        }

        // Duyet moi chieu nhan vat DANG CO, in bang, tra ve action tot nhat cho SELECT_TYPE_POS.
        // "Tot nhat" = SELECT_TYPE_POS va m_fDamageRange LON NHAT; DamageRange 0 thi vong co ban kinh 0.
        inline tActionItem* PickAreaSkill()
        {
            State& s = S();
            CActionSystem* actions = CActionSystem::GetMe();
            if (!actions) { TDU_Log("CYS-AURARING: khong co CActionSystem; bo luot"); return NULL; }
            tActionItem* best = NULL;
            float bestRange = -1.0f;
            for (int i = 0; i < 256; ++i)
            {
                tActionItem* item = actions->EnumAction(i, NAMETYPE_SKILL);
                if (!item) break;
                ++s.skillsSeen;
                const SCLIENT_SKILL* impl = (const SCLIENT_SKILL*)item->GetImpl();
                if (!impl || !impl->m_pDefine) continue;
                const _DBC_SKILL_DATA* def = impl->m_pDefine;
                const int sel = def->m_nSelectType;
                if (sel != SELECT_TYPE_POS) continue;
                ++s.posSeen;
                TDU_Log("CYS-AURARING: chieu SELECT_TYPE_POS id=%d ten=%s cap=%d hoc=%d "
                        "DamageRange=%.2f MaxAttackRange=%.2f => RingRange=%.1f",
                        def->m_nID, def->m_lpszName ? def->m_lpszName : "?",
                        (int)impl->m_nLevel, (int)(impl->m_bLeaned ? 1 : 0),
                        def->m_fDamageRange, def->m_fMaxAttackRange, def->m_fDamageRange * 100.0f);
                if (def->m_fDamageRange > bestRange)
                {
                    bestRange = def->m_fDamageRange;
                    best = item;
                    s.chosenId = def->m_nID;
                    s.chosenRange = def->m_fDamageRange;
                }
            }
            TDU_Log("CYS-AURARING: duyet %d chieu, %d chieu SELECT_TYPE_POS", s.skillsSeen, s.posSeen);
            return best;
        }
    }

    // true = xong (hoac tat); false = con dang chay, goi lai o khung sau.
    inline bool Tick()
    {
        State& s = S();
        if (!s.evaluated)
        {
            s.evaluated = true;
            char text[8] = {0};
            s.on = (::GetEnvironmentVariableA("CYS_AURARING_LIVE", text, sizeof(text)) > 0 && text[0] == '1');
            char fix[8] = {0};
            const bool fixOff = (::GetEnvironmentVariableA("CYS_AURARING", fix, sizeof(fix)) > 0 && fix[0] == '0');
            TDU_Log("CYS-AURARING: bo do %s, CYS_AURARING=%s (0 = canh DOI CHUNG AM, ten template tran)",
                    s.on ? "BAT" : "TAT", fixOff ? "0" : "1");
            // CYS-PROJSIZE: danh sach ban kinh can quet (don vi cua m_afParam[5], tuc met*100).
            char sweepText[64] = {0};
            if (::GetEnvironmentVariableA("CYS_AURARING_SWEEP", sweepText, sizeof(sweepText)) > 0)
            {
                const char* p = sweepText;
                while (*p && s.sweepN < 4)
                {
                    char* end = NULL;
                    const float v = (float)strtod(p, &end);
                    if (end == p) break;
                    s.sweep[s.sweepN++] = v;
                    p = end;
                    while (*p == ',' || *p == ' ') ++p;
                }
            }
            TDU_Log("CYS-AURARING: sweep=%d gia tri [%.1f %.1f %.1f %.1f]", s.sweepN,
                    s.sweep[0], s.sweep[1], s.sweep[2], s.sweep[3]);
            s.step = 0; s.wait = 0;
        }
        if (!s.on || s.done) return true;

        switch (s.step)
        {
        case 0: // cho the gioi on dinh + danh sach chieu ve du
            if (++s.wait < 40) return false;   // ~4 s o nhip 100 ms
            s.step = 1; s.wait = 0;
            return false;

        case 1:
            {
                tActionItem* skill = PickAreaSkill();
                if (!skill)
                {
                    TDU_Log("CYS-AURARING: KET QUA lop 1 HONG - nhan vat khong co mot chieu "
                            "SELECT_TYPE_POS nao (duyet %d chieu). Khong co gi de bat vong.", s.skillsSeen);
                    s.done = true; return true;
                }
                CObjectManager* objects = CObjectManager::GetMe();
                CObject_PlayerMySelf* self = objects ? objects->GetMySelf() : NULL;
                if (!self) { TDU_Log("CYS-AURARING: khong co nhan vat cua minh; bo luot"); s.done = true; return true; }
                const fVector3 me = self->GetPosition();

                // (b) DUNG duong con tro that. Vi tri = ngay duoi chan nhan vat, de vong nam
                // giua khung hinh va so sanh duoc voi anh CY.
                CCursorMng* cursor = CCursorMng::GetMe();
                if (!cursor) { TDU_Log("CYS-AURARING: khong co CCursorMng; bo luot"); s.done = true; return true; }
                cursor->MouseCommand_Set(FALSE, NULL, me, skill);
                const SCommand_Mouse left = cursor->MouseCommand_GetLeft();
                s.leftType = (int)left.m_typeMouse;
                s.paramRingRange = left.m_afParam[5];
                TDU_Log("CYS-AURARING: chieu da chon id=%d DamageRange=%.2f => lenh trai=%d(%s) "
                        "m_afParam[5]=%.1f (CursorMng.cpp:757-761 dien so nay)",
                        s.chosenId, s.chosenRange, s.leftType, MctName(s.leftType), s.paramRingRange);
                if (s.leftType != SCommand_Mouse::MCT_SKILL_AREA)
                {
                    TDU_Log("CYS-AURARING: KET QUA lop 2 HONG - lenh trai khong phai MCT_SKILL_AREA, "
                            "nen duong vong khong bao gio duoc goi. Dung o day.");
                    s.done = true; return true;
                }

                s.skill = skill;
                s.at = me;
                s.step = 2; s.wait = 0;
                return false;
            }

        case 2: // GIU YEN vai giay de chup anh NEN (chua co vong) - doi chung am NAM TRONG CHINH LUOT NAY
            if (++s.wait < 14) return false;   // ~1,4 s
            s.step = 3; s.wait = 0;
            return false;

        case 3:
            {
                CObjectManager* objects = CObjectManager::GetMe();
                const fVector3 me = s.at;
                // (c) DUNG y GamePro_Main.cpp:544-557 (ke ca dong CYS-FXCY2 moi them).
                s.ring = (CObject_ProjTex_AuraDure*)objects->NewObject("CObject_ProjTex_AuraDure");
                if (!s.ring) { TDU_Log("CYS-AURARING: NewObject tra NULL; bo luot"); s.done = true; return true; }
                s.ring->Initial(NULL);
                // CYS-PROJSIZE: khi quet, gia tri dau tien cua danh sach thay cho m_afParam[5].
                // Duong ma di qua van la duong THAT: SetRingRange -> Attach_ProjTexture(AURA_RUNE,...).
                const float r0 = (s.sweepN > 0) ? s.sweep[0] : s.paramRingRange;
                s.ring->SetRingRange(r0);   // chinh la cmd.m_afParam[5] cua GamePro_Main.cpp
                s.ring->SetShowEnable(TRUE);
                s.ring->SetPosition(me);
                s.ringMade = true;
                TDU_Log("CYS-AURARING: da bat vong tai (%.1f, %.1f, %.1f); RingRange doc lai = %.1f, ShowEnable=%d",
                        me.x, me.y, me.z, s.ring->GetRingRange(), (int)s.ring->GetShowEnable());
                s.step = 4; s.wait = 0;
                return false;
            }

        case 4: // giu vong tren man hinh vai giay de anh chup bat duoc
            if (++s.wait < 30) return false;   // ~3 s
            TDU_Log("CYS-AURARING: KET QUA - chieu=%d DamageRange=%.2f RingRange=%.1f lenh=%s ring_made=%d "
                    "sweep_at=%d sweep_value=%.1f doc_lai=%.1f. "
                    "Nghiem thu con lai doc tren ANH va tren dong auraring cua WXRender.log.",
                    s.chosenId, s.chosenRange, s.paramRingRange, MctName(s.leftType), (int)(s.ringMade ? 1 : 0),
                    s.sweepAt, (s.sweepN > 0) ? s.sweep[s.sweepAt] : s.paramRingRange,
                    s.ring ? s.ring->GetRingRange() : -1.0f);
            // CYS-PROJSIZE: con gia tri nua thi DOI ban kinh tren CHINH doi tuong nay (nhanh
            // "da ton tai" cua Attach_ProjTexture - dung nhanh ma CY va GL cung va) roi giu tiep.
            if (s.sweepN > 0 && s.sweepAt + 1 < s.sweepN && s.ring)
            {
                ++s.sweepAt;
                s.ring->SetRingRange(s.sweep[s.sweepAt]);
                TDU_Log("CYS-AURARING: sweep buoc %d -> RingRange=%.1f (doc lai %.1f)",
                        s.sweepAt, s.sweep[s.sweepAt], s.ring->GetRingRange());
                s.wait = 0;
                return false;   // o lai case 4
            }
            s.step = 5; s.wait = 0;
            return false;

        case 5: // tat vong lai, tra trang thai ve nhu cu
            if (s.ring) s.ring->SetShowEnable(FALSE);
            TDU_Log("CYS-AURARING: probe XONG");
            s.done = true;
            return true;
        }
        s.done = true;
        return true;
    }

    // Nhan anh chup cho pha hien tai, hoac NULL khi pha nay khong can anh.
    inline const char* ShotName()
    {
        State& s = S();
        if (!s.on || s.done) return NULL;
        // Ba anh CUNG mot luot, CUNG camera, khac dung mot thu: vong bat hay chua.
        if (s.step == 2 && s.wait == 6)  return "auraring-before";
        // CYS-PROJSIZE: khi quet, MOI buoc mot anh rieng, CUNG camera - so kich thuoc giua chung
        // khong con thua huong sai lech giua hai luot.
        if (s.sweepN > 0)
        {
            if (s.step == 4 && s.wait == 20)
            {
                switch (s.sweepAt)
                {
                case 0: return "projsize-0";
                case 1: return "projsize-1";
                case 2: return "projsize-2";
                default: return "projsize-3";
                }
            }
            return NULL;
        }
        if (s.step == 4 && s.wait == 5)  return "auraring-1";
        if (s.step == 4 && s.wait == 20) return "auraring-2";
        return NULL;
    }
}
