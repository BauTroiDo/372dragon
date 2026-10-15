#pragma once
// CYS-SCENEMAP 20/09: luot do live cho BAN DO LON (Alt+M) va MINIMAP (`CYS_SCENEMAP_LIVE=1`).
//
// VI SAO CAN: nguoi dung bao "Ban do (alt + M) phai su dung cac hinh anh dds trong thu muc scene
// de la anh chu?, minimap cung chua dung". Nguyen nhan goc: hai ham host `GetSceneMapByID` va
// `GetSceneSizeByID` la STUB sinh tu dong (LuaApiGen_Globals.cpp:225/233) nen tra ve "" va 0,0.
// Ban va nam o GMGameInterface_Script.cpp (Lua_GetSceneMapByID / Lua_GetSceneSizeByID).
//
// BO DO NAY CHAY DUNG DUONG MA NGUOI CHOI CHAY, khong phai mot duong rieng:
//   - canh DANG DUNG : dung chinh `MiniMap_Update(GetSceneMapByID(GetSceneID()))` cua MiniMap.lua:246
//   - canh KHAC      : dung chinh `PushEvent("TOGLE_SCENE_MAP", mapname, "3", id)` cua
//                      LargeMap.lua:285 (nhanh `LargeMap_Click_NormalScene`) - day la duong DUY NHAT
//                      dung hai ham nay cho mot canh khac, va la duong `minimap-holes` chua bao gio phu.
//
// IN RA (TDU_Log, tien to `CYS-SCENEMAP:`):
//   - TRUOC khi lam gi: gia tri hai ham tra ve cho canh dang dung va cho canh khac
//     (in ca "truoc" lan "sau" de mot luot im lang phan biet duoc "chua chay" voi "chay ma rong").
//   - SAU khi mo: `FalagardSceneMap::CreateSceneMap` tu in mot dong `grid` moi lan duoc goi.
// DOI CHUNG AM: `CYS_SCENEMAP_BADID=1` bat them mot canh KHONG co dong DBC (mac dinh 42, mot trong
// bon canh active khong co dong SceneDefineEx). Neu tay do am ma van ra base khac rong thi phep do
// KHONG biet truot => bo di.
#include "TDUtil.h"
#include "TDScriptSystem.h"
#include "..\Global.h"
#include "..\Script\GMScriptSystem.h"
#include "..\Script\CysCheckedScriptLua.h"
#include "LuaPlus.h"
#include "..\World\WorldManager.h"
#include "..\World\Scene.h"           // CYS-SCENEMAP 20/09: duong Alt+M that
#include "..\Event\GMEventSystem.h"   // CYS-SCENEMAP 20/09: GE_TOGLE_SCENEMAP
#include "TDEventDefine.h"             // CYS-SCENEMAP 20/09
#include "TDUISystem.h"
#include "GameProcedure.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\Interface\GMGameInterface.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace CysSceneMapProbe
{
    namespace
    {
        struct State
        {
            bool evaluated;
            bool on;
            bool badid;
            int  otherScene;
            int  badScene;
            int  phase;
            int  wait;
            bool done;
            float startX, startZ;
            DWORD moveAt;
        };

        inline State& S()
        {
            static State s = { false, false, false, -1, 42, 0, 0, false };
            return s;
        }

        inline int EnvInt(const char* name, int fallback)
        {
            const char* p = ::getenv(name);
            if (!p || !p[0]) return fallback;
            return ::atoi(p);
        }

        // Chay mot doan Lua qua duong CO KIEM cua du an (CScriptSystem::EvaluateScript ->
        // CysCheckedScriptLua::Execute). KHONG dung DoString tran: EvaluateScript tra ve ca loi
        // cua chunk, nen mot doan Lua bi TU CHOI IM LANG se lo ra thay vi chay tiep binh thuong
        // (dung bay so 2 ma bullet-fx da sap: "kich ban bi client tu choi im lang roi chay tiep").
        inline bool Lua(const char* code)
        {
            CScriptSystem* pScript = CScriptSystem::GetMe();
            if (!pScript) { TDU_Log("CYS-SCENEMAP: KHONG CO SCRIPT SYSTEM"); return false; }
            CysCheckedScriptLua::Result r = pScript->EvaluateScript("CysSceneMapProbe", code);
            if (!r.ok())
                TDU_Log("CYS-SCENEMAP: Lua TRUOT status=%d usable=%d loi='%s'",
                        r.status, r.stateUsable ? 1 : 0, r.error);
            return r.ok();
        }

        // Chon mot canh KHAC canh dang dung, co dong DBC va co bo o. Duyet bang DBC chu khong
        // cam cung mot so: bang du lieu la MUC TIEU DANG DI CHUYEN (DIEU-PHOI 23.2 khoan 2).
        inline int PickOtherScene(int nCurrent)
        {
            const tDataBase* pDBC = CGameProcedure::s_pDataBaseSystem
                ? CGameProcedure::s_pDataBaseSystem->GetDataBase(DBC_SCENE_DEFINE) : NULL;
            if (!pDBC) return -1;
            const _DBC_SCENE_DEFINE* pCur =
                (const _DBC_SCENE_DEFINE*)pDBC->Search_Index_EQU(nCurrent);
            const char* szCurMap = pCur ? pCur->szSceneMap : "";
            const int nRows = (int)pDBC->GetRecordsNum();
            for (int i = 0; i < nRows; ++i)
            {
                const _DBC_SCENE_DEFINE* pRow =
                    (const _DBC_SCENE_DEFINE*)pDBC->Search_LineNum_EQU(i);
                if (!pRow || !pRow->szSceneMap || !pRow->szSceneMap[0]) continue;
                if (pRow->nServerID == nCurrent) continue;
                // Phai la BO O KHAC, neu khong thi "canh khac" ve ra cung mot anh va khong
                // chung minh duoc gi (dung lop loi "chon doi tuong do sai" cua atk-range).
                if (szCurMap && std::strcmp(pRow->szSceneMap, szCurMap) == 0) continue;
                if (pRow->nXSize <= 0 || pRow->nZSize <= 0) continue;
                return pRow->nServerID;
            }
            return -1;
        }

        // In nguyen van thu hai ham host tra ve cho mot ID - GOI QUA LUA (dung duong that), roi
        // doc nguoc gia tri ve C++ de TDU_Log. KHONG dung AxTrace: AxTrace.cpp:33 chi gui
        // WM_COPYDATA cho mot cua so theo doi ben ngoai, khong ghi tep log nao, nen moi dong
        // "bang chung" qua no se bien mat khong dau vet.
        inline void DumpApi(const char* szTag, int nSceneID)
        {
            char szCode[384];
            _snprintf(szCode, sizeof(szCode),
                "__cys_map = GetSceneMapByID(%d) "
                "__cys_x, __cys_z = GetSceneSizeByID(%d)",
                nSceneID, nSceneID);
            szCode[sizeof(szCode) - 1] = 0;
            // Xoa truoc khi goi: neu ham khong chay thi ta thay <nil>, chu khong thay gia tri
            // cua luot truoc (bay so 2 cua DIEU-PHOI muc 24: doc lai ket qua cu).
            Lua("__cys_map = nil __cys_x = nil __cys_z = nil");
            Lua(szCode);
            CScriptSystem* pScript = CScriptSystem::GetMe();
            if (!pScript) { TDU_Log("CYS-SCENEMAP: %s id=%d KHONG CO SCRIPT SYSTEM", szTag, nSceneID); return; }
            LuaPlus::LuaObject g = pScript->GetLuaState()->GetGlobals();
            LuaPlus::LuaObject oMap = g.GetByName("__cys_map");
            LuaPlus::LuaObject oX = g.GetByName("__cys_x");
            LuaPlus::LuaObject oZ = g.GetByName("__cys_z");
            TDU_Log("CYS-SCENEMAP: %s id=%d map=[%s] size=%dx%d",
                szTag, nSceneID,
                oMap.IsString() ? oMap.GetString() : "<nil>",
                oX.IsNumber() ? (int)oX.GetNumber() : -1,
                oZ.IsNumber() ? (int)oZ.GetNumber() : -1);
        }
    }

    // Tra ve true khi da xong (hoac khong bat), false khi con dang chay.
    inline bool Tick()
    {
        State& s = S();
        if (s.done) return true;
        if (!s.evaluated)
        {
            s.evaluated = true;
            const char* p = ::getenv("CYS_SCENEMAP_LIVE");
            s.on = (p && p[0] == '1');
            s.badid = (::getenv("CYS_SCENEMAP_BADID") != NULL);
            s.badScene = EnvInt("CYS_SCENEMAP_BADID", 42);
            if (!s.on) { s.done = true; return true; }
            TDU_Log("CYS-SCENEMAP: probe BAT (CYS_SCENEMAP_LIVE=1)");
        }
        if (!s.on) { s.done = true; return true; }

        const int nCur = CWorldManager::GetMe() ? CWorldManager::GetMe()->GetActiveSceneID() : -1;

        switch (s.phase)
        {
        case 0:
            if (CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf())
            {
                s.startX = self->GetPosition().x; s.startZ = self->GetPosition().z;
            }
            // TRUOC: hai ham tra ve gi cho canh DANG DUNG.
            TDU_Log("CYS-SCENEMAP: canh dang dung id=%d", nCur);
            DumpApi("CUR", nCur);
            s.otherScene = EnvInt("CYS_SCENEMAP_OTHER", PickOtherScene(nCur));
            // LUU Y: canh id=0 la Lac Duong - MOT ID HOP LE. Luot dau 20/09 dung
            // `> 0` nen da BO QUA no va ca pha ban do lon khong bao gio chay, trong khi
            // log van day du va trong nhu mot luot thanh cong. Moc "khong co" la -1.
            TDU_Log("CYS-SCENEMAP: canh KHAC duoc chon id=%d", s.otherScene);
            if (s.otherScene >= 0) DumpApi("OTHER", s.otherScene);
            if (s.badid)
            {
                TDU_Log("CYS-SCENEMAP: doi chung am, canh khong co dong DBC id=%d", s.badScene);
                DumpApi("BADID", s.badScene);
            }
            ++s.phase; s.wait = 0; return false;

        case 1:
            // Ep MiniMap chay lai dung duong cua no (MiniMap.lua:245-247).
            // Ep MiniMap ve lai bang chinh SU KIEN cua no (MiniMap.lua:242-247 `ON_SCENE_UPDATED`),
            // KHONG goi thang MiniMap_Update. Luot dau 20/09 goi thang va TRUOT:
            //   "MiniMap.lua:902: attempt to call method `SetSceneFileName' (a nil value)".
            // Ly do: `SetActiveEnvironment` dat `setmetatable(_G, {__index = <Env>})` nen TEN HAM
            // van tra cuu duoc tu _G, nhung WIDGET (`MiniMap_MapArea`) thi KHONG - no chi song
            // trong `MiniMap_Env`. Di bang su kien thi khung tu chay trong moi truong cua no.
            TDU_Log("CYS-SCENEMAP: MINIMAP - day su kien ON_SCENE_UPDATED (MiniMap.lua:242-247)");
            Lua("PushEvent('ON_SCENE_UPDATED')");
            ++s.phase; s.wait = 0; return false;

        case 2:
            // Cho vai khung hinh cho minimap ve xong roi moi mo ban do lon.
            if (++s.wait < 8) return false;
            ++s.phase; s.wait = 0; return false;

        case 3:
            // BAN DO LON cua CHINH canh dang dung - DUNG DUONG PHIM TAT THAT, khong phai
            // mot duong rieng: CysAccelTable.cpp:339-352 (ACT_SCENE_MAP) day y het hai tham so
            // { szSceneMap, "2" } vao GE_TOGLE_SCENEMAP. Day la cai nguoi dung bam Alt+M va la
            // cho trieu chung "moi o mot vong tron" xuat hien.
            if( CWorldManager::GetMe() && CWorldManager::GetMe()->GetActiveScene()
                && CWorldManager::GetMe()->GetActiveScene()->GetSceneDefine() )
            {
                std::vector<STRING> params;
                params.push_back(CWorldManager::GetMe()->GetActiveScene()->GetSceneDefine()->szSceneMap);
                params.push_back(STRING("2"));
                TDU_Log("CYS-SCENEMAP: LARGEMAP CANH DANG DUNG - day GE_TOGLE_SCENEMAP {%s,\"2\"} (duong Alt+M that)",
                        params[0].c_str());
                CEventSystem::GetMe()->PushEvent(GE_TOGLE_SCENEMAP, params);
            }
            else
            {
                TDU_Log("CYS-SCENEMAP: LARGEMAP CANH DANG DUNG - KHONG CO SCENE/SCENEDEFINE => KHONG DO DUOC");
            }
            ++s.phase; s.wait = 0; return false;

        case 4:
            // Keep both early images, plus a sample after several UPDATE_MAP intervals.
            // r5's wait1/wait8 images preceded the first position update; do not hide them.
            if (++s.wait < 45) return false;
            ++s.phase; s.wait = 0; return false;

        case 5:
            // Dong lai bang chinh phim tat do (su kien nay la TOGGLE) truoc khi mo canh KHAC,
            // neu khong thi nhanh `arg1 == "2"` se dong ban do thay vi mo.
            if( CWorldManager::GetMe() && CWorldManager::GetMe()->GetActiveScene()
                && CWorldManager::GetMe()->GetActiveScene()->GetSceneDefine() )
            {
                std::vector<STRING> params;
                params.push_back(CWorldManager::GetMe()->GetActiveScene()->GetSceneDefine()->szSceneMap);
                params.push_back(STRING("2"));
                TDU_Log("CYS-SCENEMAP: LARGEMAP CANH DANG DUNG - dong lai (toggle)");
                CEventSystem::GetMe()->PushEvent(GE_TOGLE_SCENEMAP, params);
            }
            ++s.phase; s.wait = 0; return false;

        case 6:
            if (++s.wait < 4) return false;
            ++s.phase; s.wait = 0; return false;

        case 7:
            // BAN DO LON cua canh KHAC - dung y nguyen dong LargeMap.lua:283-285.
            if (s.otherScene >= 0)
            {
                TDU_Log("CYS-SCENEMAP: LARGEMAP - mo ban do lon cua canh KHAC id=%d qua dung dong LargeMap.lua:283-285", s.otherScene);
                char szCode[384];
                _snprintf(szCode, sizeof(szCode),
                    "local id = %d "
                    "local mapname = GetSceneMapByID(id) "
                    "PushEvent('TOGLE_SCENE_MAP', tostring(mapname), '3', id)",
                    s.otherScene);
                szCode[sizeof(szCode) - 1] = 0;
                Lua(szCode);
            }
            ++s.phase; s.wait = 0; return false;

        case 8:
            if (++s.wait < 12) return false;
            // CY SceneMap.lua: default TOGLE_SCENE_MAP branch closes either current/other map.
            // Leave through the real close event before the outer driver opens the system menu.
            Lua("PushEvent('TOGLE_SCENE_MAP', '', '0')");
            ++s.phase; s.wait = 0; return false;
        case 9:
            if (++s.wait < 8) return false;
            if (CGameProcedure::s_pUISystem->IsWindowShow("SceneMap"))
            {
                TDU_Log("CYS-SCENEMAP: FAIL cleanup map remains visible");
                s.done = true; return true;
            }
            TDU_Log("CYS-SCENEMAP: cleanup closed=1; movement BEGIN from=%.3f,%.3f", s.startX, s.startZ);
            CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(s.startX + 2.0f, s.startZ));
            s.moveAt = GetTickCount(); ++s.phase; return false;
        case 10:
        {
            if (GetTickCount() - s.moveAt < 4500) return false;
            CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
            if (!self) { TDU_Log("CYS-SCENEMAP: FAIL missing self after close"); s.done = true; return true; }
            const fVector3 p = self->GetPosition();
            const float dx = p.x - s.startX, dz = p.z - s.startZ;
            TDU_Log("CYS-SCENEMAP: movement END delta2=%.3f pos=%.3f,%.3f", dx*dx+dz*dz, p.x, p.z);
            CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(s.startX, s.startZ));
            s.moveAt = GetTickCount(); ++s.phase; return false;
        }
        case 11:
        {
            if (GetTickCount() - s.moveAt < 4500) return false;
            CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
            if (self) TDU_Log("CYS-SCENEMAP: restored start=%.3f,%.3f actual=%.3f,%.3f",
                s.startX, s.startZ, self->GetPosition().x, self->GetPosition().z);
            TDU_Log("CYS-SCENEMAP: probe XONG");
            s.done = true;
            return true;
        }
        }
        s.done = true;
        return true;
    }

    // Nhan anh chup cho pha hien tai, hoac NULL khi pha nay khong can anh.
    inline const char* ShotName()
    {
        State& s = S();
        if (!s.on || s.done) return NULL;
        if (s.phase == 2 && s.wait == 1) return "scenemap-minimap";
        if (s.phase == 4 && s.wait == 1) return "scenemap-largemap-curscene";
        if (s.phase == 4 && s.wait == 8) return "scenemap-largemap-curscene-2";
        if (s.phase == 4 && s.wait == 32) return "scenemap-largemap-curscene-stable";
        if (s.phase == 8 && s.wait == 1) return "scenemap-largemap-otherscene";
        if (s.phase == 8 && s.wait == 8) return "scenemap-largemap-otherscene-2";
        return NULL;
    }
}
