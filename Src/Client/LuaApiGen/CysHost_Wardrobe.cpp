// CYS-WARD2 19/09 (branch wardrobe-2): fashion depot + fitting set of the CY wardrobe. See CysHost_Wardrobe.h.
//
// Receiver methods are called as Table:Fn(a, b): stack 1 = self, 2.. = arguments.
#include "CysHost_Wardrobe.h"
#include "LuaApiGen.h"
#include "Network/CysModernGame.h"   // CYS-WARD2: ask the server for the real depot
#include "PgPackets_misc.h"          // CYS-WARD2: CGAskFashionDepotData (1316)
#include "Script/GMScriptSystem.h"
#include "Event/GMEventSystem.h"     // CYS-WARD3: cua duy nhat cua nguoi choi vao phong thay do
#include "Script/CysCheckedScriptLua.h"   // CYS-WARD3: chay dung cau lenh ma nut cua nguoi choi chay
#include "Network/CysWorldReplay.h"       // CYS-WARD3: LiveShot
#include "TDEventDefine.h"                // CYS-WARD3: GE_OPEN_EQUIP
#include "TDUISystem.h"                   // CYS-WARD3: IsWindowShow
#include "Procedure/GameProcedure.h"
#include "DataPool/GMDataPool.h"
#include "DataPool/GMDP_CharacterData.h"
#include "Action/GMActionSystem.h"
#include "Object/Item/Obj_Item.h"
#include "Object/Item/Obj_Item_Equip.h"
#include "Object/ObjectManager.h"
#include "Object/Character/Obj_PlayerMySelf.h"
#include "Object/Character/Obj_PlayerOther.h"
#include "GameDefine_Item.h"
#include "BaseType.h"   // INVALID_ID
#include "TDUtil.h"
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <map>
#include <memory>
#include <string>
#include <vector>
#include "CysWardrobeCatalog.inl"

namespace CysWardrobeHost
{
    namespace
    {
        unsigned g_logs = 0;
        int g_applied = 0;

        void Log(const char* fmt, ...)
        {
            if (g_logs++ >= 200) return;
            char text[512] = {};
            va_list args; va_start(args, fmt);
            _vsnprintf(text, sizeof(text) - 1, fmt, args);
            va_end(args);
            TDU_Log("CYS-WARD2: %s", text);
        }

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

        // ---- the fitting set --------------------------------------------------------------------------------
        // CY's frames write "ORNAMENTSHEAD" and read "OrnamentsHead" for the SAME slot (NewExterior_DressBox.lua
        // 991 vs 1471), so the key must be case-insensitive or half the wardrobe silently reads back nothing.
        std::string Key(const char* raw)
        {
            std::string k(raw ? raw : "");
            for (size_t i = 0; i < k.size(); ++i)
                if (k[i] >= 'a' && k[i] <= 'z') k[i] = (char)(k[i] - 'a' + 'A');
            return k;
        }

        struct Fit { int id; int a; int b; int c; };
        typedef std::map< std::string, Fit > FitMap;
        FitMap& Fitting() { static FitMap m; return m; }

        const Fit* FindFit(const char* key)
        {
            FitMap& m = Fitting();
            FitMap::const_iterator it = m.find(Key(key));
            return it == m.end() ? NULL : &it->second;
        }

        // ---- the fashion depot -------------------------------------------------------------------------------
        // Two sources, in this order:
        //   1. the SERVER's own array (GCAskFashionDepotData, 100 fixed slots) - the truth, and its index IS the
        //      nVecIndex the CY list works with;
        //   2. until that arrives, a stand-in built from what the client already holds: the fashion worn at equip
        //      point 16 (entry 0) then every equip-point-16 item in the bag.
        struct Slot { int bagIndex; int itemId; int visual; };   // bagIndex -1 = worn, -2 = a server slot
        std::vector< Slot >& Depot() { static std::vector< Slot > d; return d; }
        std::vector< Slot >& ServerDepot() { static std::vector< Slot > d; return d; }
        DWORD g_depotAt = 0;
        DWORD g_askedAt = 0;
        bool g_depotBuilt = false;
        bool g_haveServer = false;

        // CGAskFashionDepotData -> msgagent.lua:511 ask_fashion_depot_data -> scenecore.lua:1772
        // send_char_fashion_depot_data, which answers GCAskFashionDepotData (590) with the 100-slot array. The
        // request carries nothing the server reads, so the defaults are the message.
        void AskServerDepot(const char* why)
        {
            const DWORD now = GetTickCount();
            if (g_askedAt && now - g_askedAt < 3000) return;
            if (!CysModernGame::IsInWorld()) return;
            g_askedAt = now;
            const bool sent = CysModernGame::SendModern(std::unique_ptr< pg::Packet >(new pg::CGAskFashionDepotData));
            Log("asked the server for the fashion depot (%s) sent=%d", why, sent ? 1 : 0);
        }

        int DressVisualOf(tObject_Item* item)
        {
            if (!item || item->GetItemClass() != ICLASS_EQUIP) return INVALID_ID;
            CObject_Item_Equip* equip = (CObject_Item_Equip*)item;     // guarded by GetItemClass, house pattern
            if ((int)equip->GetItemType() != HEQUIP_DRESS) return INVALID_ID;
            return equip->GetVisualID();
        }

        void RebuildDepot(const char* why)
        {
            std::vector< Slot >& depot = Depot();
            depot.clear();
            g_depotAt = GetTickCount();
            g_depotBuilt = true;
            CDataPool* pool = CDataPool::GetMe();
            if (!pool) return;

            tObject_Item* worn = pool->UserEquip_GetItem((HUMAN_EQUIP)HEQUIP_DRESS);
            const int wornVisual = DressVisualOf(worn);
            if (worn && wornVisual != INVALID_ID)
            {
                Slot s; s.bagIndex = -1; s.itemId = worn->GetIdTable(); s.visual = wornVisual;
                depot.push_back(s);
            }
            for (int i = 0; i < CYS_CLIENT_BAG_SLOTS; ++i)
            {
                tObject_Item* item = pool->UserBag_GetItem(i);
                const int visual = DressVisualOf(item);
                if (visual == INVALID_ID) continue;
                Slot s; s.bagIndex = i; s.itemId = item->GetIdTable(); s.visual = visual;
                depot.push_back(s);
            }
            Log("depot rebuilt (%s): %u fashion(s) worn=%d", why, (unsigned)depot.size(),
                (worn && wornVisual != INVALID_ID) ? 1 : 0);
            for (size_t i = 0; i < depot.size() && i < 8; ++i)
                Log("  depot[%u] item=%d visual=%d bag=%d", (unsigned)i, depot[i].itemId, depot[i].visual, depot[i].bagIndex);
        }

        // 300 list bars ask for every slot twice per refresh (NewExterior_DressBox.lua g_MaxBarNum = 300), so the
        // scan is cached; 250 ms is short enough that a bag change during the frame's own refresh is still seen.
        // The SERVER array wins whenever it has arrived: its indices are the nVecIndex the CY list works with.
        const std::vector< Slot >& DepotCached()
        {
            if (g_haveServer) return ServerDepot();
            AskServerDepot("no server depot yet");
            if (!g_depotBuilt || GetTickCount() - g_depotAt > 250) RebuildDepot("lazy");
            return Depot();
        }

        const Slot* DepotAt(int index)
        {
            const std::vector< Slot >& d = DepotCached();
            if (index < 0 || (size_t)index >= d.size()) return NULL;
            return &d[index];
        }

        int DepotIndexOfItem(int itemId)
        {
            const std::vector< Slot >& d = DepotCached();
            for (size_t i = 0; i < d.size(); ++i) if (d[i].itemId == itemId) return (int)i;
            return -1;
        }

        int VisualOfFashion(int itemId, int hintIndex)
        {
            const Slot* s = DepotAt(hintIndex);
            if (s && s->itemId == itemId) return s->visual;
            const int idx = DepotIndexOfItem(itemId);
            s = DepotAt(idx);
            return s ? s->visual : INVALID_ID;
        }

        // The fashion the player is WEARING comes from the equip container (equip point 16), never from the depot
        // array: with the server array the worn one sits at the character's own fashion_depot_index, and with the
        // bag-derived one it is entry 0. Both are found by matching the item id.
        int WornFashionItem(int* index = NULL)
        {
            CDataPool* pool = CDataPool::GetMe();
            tObject_Item* worn = pool ? pool->UserEquip_GetItem((HUMAN_EQUIP)HEQUIP_DRESS) : NULL;
            const int visual = DressVisualOf(worn);
            const int item = (worn && visual != INVALID_ID) ? worn->GetIdTable() : 0;
            if (index) *index = item > 0 ? DepotIndexOfItem(item) : -1;
            return item;
        }

        // The action item the ICON of a depot slot is drawn from. ActionButton:SetActionItem(id) looks the id up in
        // the action system (UILuaControl.cpp:1059), so only an action that REALLY exists can draw an icon, and the
        // client only has actions for items it holds itself: the one worn at point 16 (NAMETYPE_EQUIP, keyed by
        // equip point) and the ones in the bag (NAMETYPE_PACKAGEITEM, keyed by bag slot). A fashion that lives ONLY
        // in the server's fashion container has no action here - it answers s_InvalidAction, i.e. an EMPTY slot
        // rather than somebody else's icon. Resolving by ITEM ID, never by the depot's own index, is what keeps a
        // 100-slot server array from painting the worn fashion's icon into all 100 boxes.
        tActionItem* DepotAction(int index)
        {
            const Slot* s = DepotAt(index);
            CActionSystem* actions = CActionSystem::GetMe();
            CDataPool* pool = CDataPool::GetMe();
            if (!s || s->itemId <= 0 || !actions || !pool) return NULL;
            if (s->bagIndex >= 0) return actions->EnumAction(s->bagIndex, NAMETYPE_PACKAGEITEM);
            tObject_Item* worn = pool->UserEquip_GetItem((HUMAN_EQUIP)HEQUIP_DRESS);
            if (worn && worn->GetIdTable() == s->itemId) return actions->EnumAction(HEQUIP_DRESS, NAMETYPE_EQUIP);
            for (int i = 0; i < CYS_CLIENT_BAG_SLOTS; ++i)
            {
                tObject_Item* item = pool->UserBag_GetItem(i);
                if (item && item->GetIdTable() == s->itemId) return actions->EnumAction(i, NAMETYPE_PACKAGEITEM);
            }
            return NULL;   // in the server's fashion container only: no icon yet, see the handoff mục 4
        }

        int PushAction(LuaPlus::LuaState* s, tActionItem* action, int locked)
        {
            if (!CActionItem::s_pMetaTable)
            {
                // Without the metatable an action object would answer no method at all - exactly the crash this
                // branch is removing. Two numbers is what the generated stub did; say so once.
                Log("CActionItem::s_pMetaTable is not ready; the depot cannot answer an object yet");
                s->PushNumber(0); s->PushNumber(0);
                return 2;
            }
            LuaPlus::LuaObject obj = s->BoxPointer(action ? (void*)action : (void*)&CActionItem::s_InvalidAction);
            obj.SetMetaTable(*CActionItem::s_pMetaTable);
            obj.PushStack();
            s->PushInteger(locked);
            return 2;
        }

        // ---- FashionDepot ------------------------------------------------------------------------------------
        // FashionDepot:LuaFnGetFashionDepotItem(kho, i) -> ActionItem, bLocked   (NewExterior_DressBox.lua:1049)
        // kho 1 = the player's wardrobe, 2 = the child's (not carried by this client) -> empty.
        int FashionGetDepotItem(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            const int depotType = args[2].IsNumber() ? (int)args[2].GetNumber() : 1;
            const int index = args[3].IsNumber() ? (int)args[3].GetNumber() : -1;
            if (depotType != 1) return PushAction(s, NULL, 0);
            return PushAction(s, DepotAction(index), 0);
        }

        // FashionDepot:LuaFnGetFashionId(kho, i) -> the fashion's ITEM id. NumberingFashion.txt keys its rows by
        // the same item id (column 1: 10127900...), so the item id IS the "exterior id" of a 时装.
        int FashionGetFashionId(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            const int depotType = args[2].IsNumber() ? (int)args[2].GetNumber() : 1;
            const int index = args[3].IsNumber() ? (int)args[3].GetNumber() : -1;
            const Slot* slot = depotType == 1 ? DepotAt(index) : NULL;
            s->PushInteger(slot ? slot->itemId : 0);
            return 1;
        }

        int FashionRefreshDepot(LuaPlus::LuaState* s)
        {
            AskServerDepot("LuaFnRefreshFashionDepot");
            if (!g_haveServer) RebuildDepot("LuaFnRefreshFashionDepot");
            (void)s;
            return 0;
        }

        // ---- Exterior: what the player wears right now -------------------------------------------------------
        // Exterior:LuaFnGetExteriorFashionInUse() -> itemId, depotIndex. 0 when nothing is worn: every caller
        // tests `if nCurFashionId ~= nil and nCurFashionId > 0`.
        int ExteriorGetFashionInUse(LuaPlus::LuaState* s)
        {
            int index = -1;
            const int item = WornFashionItem(&index);
            s->PushInteger(item);
            s->PushInteger(index);
            return 2;
        }

        int SelfRaceId()
        {
            CObjectManager* objects = CObjectManager::GetMe();
            CObject_PlayerMySelf* self = objects ? objects->GetMySelf() : NULL;
            CCharacterData* data = self ? self->GetCharacterData() : NULL;
            return data ? data->Get_RaceID() : 1;
        }

        // Exterior:LuaFnGetExteriorRaceID() -> 0 female / 1 male. NewExterior_PlayerFrame.lua:31-39 indexes
        // g_CameraPosition[sex] with it, so a wrong answer means the wrong camera (branch `wardrobe` measured the
        // stub's 0 giving a MALE character the female camera h=0.85 d=7.2 p=0.10 instead of d=7.5 p=0.28).
        // CY (0x1403eaef0) answers the PREVIEWED sex first and only then the character's own - same order here.
        int ExteriorGetRaceId(LuaPlus::LuaState* s)
        {
            const Fit* sex = FindFit("SEX");
            const int race = sex ? sex->id : SelfRaceId();
            s->PushInteger(race == 0 ? 0 : 1);
            return 1;
        }

        // ---- Exterior: the fitting set -----------------------------------------------------------------------
        // Exterior:LuaFnSetCurrentExteriorSetInfo(key [, id [, a [, b]]])
        //   "RESET"           - drop everything being tried on (NewExterior_DressBox.lua:157/181/1627/2044)
        //   "RESETDRESSSTYLE" - drop only the dye/style slot
        int ExteriorSetCurrentSetInfo(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            if (!args[2].IsString()) return 0;
            const std::string key = Key(args[2].GetString());
            if (key == "RESET")
            {
                const size_t had = Fitting().size();
                Fitting().clear();
                Log("fitting RESET (%u key(s) dropped)", (unsigned)had);
                return 0;
            }
            if (key == "RESETDRESSSTYLE") { Fitting().erase("DRESSSTYLE"); return 0; }
            Fit f;
            f.id = args[3].IsNumber() ? (int)args[3].GetNumber() : 0;
            f.a  = args[4].IsNumber() ? (int)args[4].GetNumber() : 0;
            f.b  = args[5].IsNumber() ? (int)args[5].GetNumber() : 0;
            f.c  = args[6].IsNumber() ? (int)args[6].GetNumber() : 0;
            if (f.id <= 0 && key != "SEX") Fitting().erase(key);
            else Fitting()[key] = f;
            Log("fitting %s = %d,%d,%d,%d (%u key(s) on)", key.c_str(), f.id, f.a, f.b, f.c, (unsigned)Fitting().size());
            return 0;
        }

        // Exterior:LuaFnGetCurrentExteriorSetInfo(key) -> id, a, b, c. Four numbers is the shape recovered from B
        // (LuaApiGen_Exterior.cpp: "nnnn"); the frames read 1..4 of them depending on the slot.
        int ExteriorGetCurrentSetInfo(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            const Fit* f = args[2].IsString() ? FindFit(args[2].GetString()) : NULL;
            s->PushInteger(f ? f->id : 0);
            s->PushInteger(f ? f->a : 0);
            s->PushInteger(f ? f->b : 0);
            s->PushInteger(f ? f->c : 0);
            return 4;
        }

        // Exterior:LuaFnInitCurrentExteriorSet() - the frame opens showing what the player HAS ON, so the set
        // starts as the current look and "change" means "differs from this".
        // "SEX" SURVIVES on purpose: NewExterior_DressBox_ChangeSex() (line 2125) writes the key and then calls
        // NewExterior_DressBox_Show(), which calls this - clearing it here would make the gender button a no-op
        // and CY's own button image would never flip. Anything else is dropped.
        int ExteriorInitCurrentSet(LuaPlus::LuaState* s)
        {
            const Fit* sex = FindFit("SEX");
            const Fit keepSex = sex ? *sex : Fit();
            const bool hadSex = sex != NULL;
            Fitting().clear();
            if (hadSex) Fitting()["SEX"] = keepSex;
            AskServerDepot("LuaFnInitCurrentExteriorSet");
            if (!g_haveServer) RebuildDepot("LuaFnInitCurrentExteriorSet");
            int index = -1;
            const int worn = WornFashionItem(&index);
            if (worn > 0) { Fit f; f.id = worn; f.a = index; f.b = 0; f.c = 0; Fitting()["FASHION"] = f; }
            Log("fitting init: worn fashion=%d idx=%d depot=%u(server=%d) sex_kept=%d", worn, index,
                (unsigned)DepotCached().size(), g_haveServer ? 1 : 0, hadSex ? keepSex.id : -1);
            (void)s;
            return 0;
        }

        int ExteriorRestoreFitting(LuaPlus::LuaState* s) { return ExteriorInitCurrentSet(s); }

        // Exterior:LuaFnGetExteriorPlayerFittingCount() - how many slots are being tried on.
        int ExteriorFittingCount(LuaPlus::LuaState* s) { s->PushInteger((int)Fitting().size()); return 1; }

        // Exterior:LuaFnIsHaveExteriorChange() - 1 when the fitting differs from what is worn, which is what the
        // "save / restore" buttons of every NewExterior_* frame enable themselves on.
        int ExteriorIsHaveChange(LuaPlus::LuaState* s)
        {
            const Fit* fashion = FindFit("FASHION");
            const int worn = WornFashionItem();
            int changed = 0;
            if (fashion && fashion->id != worn) changed = 1;
            if (!fashion && worn > 0) changed = 1;
            if (FindFit("SEX") && FindFit("SEX")->id != (SelfRaceId() == 0 ? 0 : 1)) changed = 1;
            s->PushInteger(changed);
            return 1;
        }

        // Exterior:LuaFnUpdateExteriorAvatarFashion(id, idx) - CY's direct "put this fashion on the avatar".
        // NewExterior_DressBox.lua:1021 has it commented out (the fitting road below covers it), but the Weapon /
        // HairStyle frames use the same family, so the write is kept in ONE place: the fitting set.
        int ExteriorUpdateAvatarFashion(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            Fit f;
            f.id = args[2].IsNumber() ? (int)args[2].GetNumber() : 0;
            f.a  = args[3].IsNumber() ? (int)args[3].GetNumber() : 0;
            f.b = f.c = 0;
            if (f.id > 0) Fitting()["FASHION"] = f; else Fitting().erase("FASHION");
            Log("avatar fashion = %d (idx %d)", f.id, f.a);
            return 0;
        }

        // Exterior:LuaFnUnUseExteriorFashion(kho) - "take it off" in the preview: id 0 means no fashion, and
        // ApplyFitting turns that into DressVisual = INVALID_ID on the avatar only.
        int ExteriorUnUseFashion(LuaPlus::LuaState* s)
        {
            Fit f; f.id = 0; f.a = -1; f.b = f.c = 0;
            Fitting()["FASHION"] = f;
            Log("fitting FASHION = none (preview take-off)");
            (void)s;
            return 0;
        }

        // Exterior:LuaFnExteriorFashionDepotItemClick(kho, i) -> 1 when the click was consumed as a chat
        // hyperlink (shift-click). NewExterior_DressBox.lua:1215 RETURNS EARLY on 1, so this must answer 0 for a
        // plain click or no fashion can ever be selected. Implemented (not left as a stub) so the live log proves
        // the click path ran.
        int ExteriorFashionDepotItemClick(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            const int index = args[3].IsNumber() ? (int)args[3].GetNumber() : -1;
            const Slot* slot = DepotAt(index);
            Log("depot item click idx=%d item=%d (hyperlink=0)", index, slot ? slot->itemId : 0);
            s->PushInteger(0);
            return 1;
        }

        // ---- CYS-WARD3 20/09 (nhanh `wardrobe`): CUA DUY NHAT CUA NGUOI CHOI VAO PHONG THAY DO ----------------
        //
        // Nguoi dung bao "khung UI van con loi (Nhan vat, thong tin, phong thay do)". Hai nhanh truoc
        // (`wardrobe`, `wardrobe-2`) da chung minh khung MO DUOC va doi do duoc  -  nhung ca hai deu mo no bang
        // MOT PROBE C++ day thang su kien (`CysHost_MeshWin.cpp:505` trong khoi `CYS_MESHWIN_LIVE`), nen
        // KHONG LUOT NAO di qua cai nut that su cua nguoi choi. Duong do nhu sau, da kiem tung chang:
        //
        //   SelfEquip.layout.xml:838  <Window Name="SelfEquip_Yirong_Icon">  Tooltip #{DECOW_160126_73}
        //        = "Nhan de mo giao dien Ngoai hinh, co the xem va thay doi Thoi Trang, O khi huyen suc,
        //           Kieu mat, Kieu toc, Mau toc, Phu the, Toa ky, Anh dai dien, ... Trang suc dau, ..."
        //        <Event Name="Clicked" Function="SelfEquip_OnYirong();"/>
        //   SelfEquip.lua:3757        function SelfEquip_OnYirong()
        //                                 Exterior:LuaFnInitExteriorFashionList(1, 1)
        //                                 --PushEvent("OPEN_EXTERIOR_FASHION", 1, 1)     <- CY DA CHU THICH
        //
        // CY bo dong `PushEvent` di va chuyen no VAO chinh ham host nay; cap tham so giu nguyen. Doc duoc
        // CA HAI phia nen khong phai suy tu ten ham:
        //   - phia GOI: 12 cho goi, SelfEquip (1,1) = kho cua nguoi choi; 11 cho con lai trong `*_OpenInfant()`
        //     goi (2,1) = kho thoi trang CON CAI;
        //   - phia NHAN: NewExterior_DressBox.lua:130 mo khi `arg0 == m_PlayerfashionDepotType` (=1),
        //     NewExterior_InfantDressBox.lua:58 mo khi `arg0 == 2`; ca hai doc `arg1 == 1` = dat lai bo thu do.
        //
        // Stub sinh tu dong tra so 0 va KHONG lam gi (`LuaApiGen_Exterior.cpp:247`), con `CysHost_Package.cpp:115`
        // dang ky `Nothing`  -  ca hai deu la khong-lam-gi. Ba chang doc lap cho thay khung KHONG CO CUA NAO KHAC:
        //   (1) `PushEvent("OPEN_EXTERIOR*")` ngoai ho `NewExterior_*` chi co dong DA CHU THICH o SelfEquip.lua:3765;
        //   (2) KHONG mot cho nao trong `Src/` day `GE_OPEN_EXTERIOR*` (ngoai probe tren);
        //   (3) `GCExteriorInfo` khong co handler phia client, nen khong co duong tu server.
        // => nut nay chet => ca 18 khung phong thay do khong the mo bang tay nguoi choi.
        void PushEventTwoArgs(const char* name, int a0, int a1)
        {
            if (!CEventSystem::GetMe()) return;
            char s0[32] = {}, s1[32] = {};
            _snprintf(s0, sizeof(s0) - 1, "%d", a0);
            _snprintf(s1, sizeof(s1) - 1, "%d", a1);
            std::vector< STRING > params;
            params.push_back(s0);
            params.push_back(s1);
            const BOOL ok = CEventSystem::GetMe()->PushEventByName(name, params);
            Log("event %s(%s,%s) pushed=%d", name, s0, s1, ok ? 1 : 0);
        }

        // Exterior:LuaFnInitExteriorFashionList(kho, datLai)
        int ExteriorInitFashionList(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            // Mac dinh (1, 1) = kho nguoi choi + dat lai, dung nhu dong PushEvent CY da chu thich o SelfEquip.
            const int depot = args[2].IsNumber() ? (int)args[2].GetNumber() : 1;
            const int reset = args[3].IsNumber() ? (int)args[3].GetNumber() : 1;
            Log("InitExteriorFashionList(%d,%d) - mo phong thay do tu nut nguoi choi", depot, reset);
            PushEventTwoArgs("OPEN_EXTERIOR_FASHION", depot, reset);
            s->PushInteger(0);   // chu ky CY: tra mot so; khong cho goi nao trong 12 cho dung gia tri nay
            return 1;
        }

        // Exterior:LuaFnAskOpenExterior(loai) - CAI THE ben trong phong thay do (70 luot goi / 11 khung).
        //
        // Cung mot lop benh voi cua ngoai: stub khong lam gi, nen mo duoc phong thay do roi thi MOI CAI THE
        // van chet. Bang loai duoi day doc o PHIA NHAN (`g_ExteriorType` + `if tonumber(arg0) == g_ExteriorType`),
        // KHONG suy tu ten ham goi  -  va viec do da sua duoc hai cho neu chi doc phia goi:
        //   * NewExterior_Headdress khai `g_ExteriorType = 1` va NewExterior_Widget khai `= 0`, TRUNG voi
        //     Weapon(1)/Ride(0); nhung ca hai KHONG dang ky canh `OPEN_EXTERIOR` nao (chung mo bang
        //     OrnamentsScript:AskOrnamentsInfo) nen khong co va cham that.
        //   * loai 6 (khung anh dai dien) KHONG CO khung nao nhan trong cay nay  -  nut do se khong lam gi,
        //     va do la dung voi bo du lieu nay, khong phai loi moi.
        // Phia nhan (NewExterior_Ride.lua:95-110 la khuon chung): arg0 = loai, arg1 = 0 nghia la AN neu dang
        // hien; khac 0 thi MO. Nen day (loai, 1).
        //   0 Toa ky (NewExterior_Ride)  | 1 Huyen vu (NewExterior_Weapon)  | 2 Phu the (NewExterior_PetPossJian)
        //   3 Kieu mat (NewExterior_Facestyle)  | 4 Kieu toc (NewExterior_HairStyle)
        //   5 Anh dai dien (NewExterior_PlayerFrame)  | 7 Toc con cai (NewExterior_InfantHairStyle)
        int ExteriorAskOpenExterior(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            const int type = args[2].IsNumber() ? (int)args[2].GetNumber() : -1;
            if (type < 0) { Log("AskOpenExterior: thieu tham so loai - bo qua"); return 0; }
            Log("AskOpenExterior(%d) - doi the trong phong thay do", type);
            PushEventTwoArgs("OPEN_EXTERIOR", type, 1);
            return 0;   // chu ky stub sinh tu dong: rets = "" (khong tra gia tri nao)
        }

        struct Entry { const char* receiver; const char* name; int (*fn)(LuaPlus::LuaState*); };
        const Entry kEntries[] = {
            {"FashionDepot", "LuaFnGetFashionDepotItem",            FashionGetDepotItem},
            {"FashionDepot", "LuaFnGetFashionId",                   FashionGetFashionId},
            {"FashionDepot", "LuaFnRefreshFashionDepot",            FashionRefreshDepot},
            {"Exterior",     "LuaFnGetExteriorFashionInUse",        ExteriorGetFashionInUse},
            {"Exterior",     "LuaFnGetExteriorRaceID",              ExteriorGetRaceId},
            {"Exterior",     "LuaFnSetCurrentExteriorSetInfo",      ExteriorSetCurrentSetInfo},
            {"Exterior",     "LuaFnGetCurrentExteriorSetInfo",      ExteriorGetCurrentSetInfo},
            {"Exterior",     "LuaFnInitCurrentExteriorSet",         ExteriorInitCurrentSet},
            {"Exterior",     "LuaFnRestoreExteriorPlayerFittingData", ExteriorRestoreFitting},
            {"Exterior",     "LuaFnGetExteriorPlayerFittingCount",  ExteriorFittingCount},
            {"Exterior",     "LuaFnIsHaveExteriorChange",           ExteriorIsHaveChange},
            {"Exterior",     "LuaFnUpdateExteriorAvatarFashion",    ExteriorUpdateAvatarFashion},
            {"Exterior",     "LuaFnUnUseExteriorFashion",           ExteriorUnUseFashion},
            {"Exterior",     "LuaFnExteriorFashionDepotItemClick",  ExteriorFashionDepotItemClick},
            {"Exterior",     "LuaFnInitExteriorFashionList",        ExteriorInitFashionList},  // CYS-WARD3 cua ngoai
            {"Exterior",     "LuaFnAskOpenExterior",                ExteriorAskOpenExterior},  // CYS-WARD3 cai the
        };
    }

    // XEM TRUOC GIOI TINH DANG TAT - CO LY DO, DUNG BAT LAI MA KHONG DOC MUC 5 CUA BAN GIAO.
    // live-1 (19/09 19:45:36) da do: dong log "avatar built with the previewed sex 0 (own 1)" roi NGAY SAU DO
    // Access violation trong OgreMain.dll+0x8B5AF (`mov rbx,[rcx+0x100]` voi rcx = 0), tuc Set_RaceID() doi chung
    // toc tren mot fake object DANG bi moc vao cua so RTT thi lam chet tien trinh. Dung 1/1 lan.
    // Doi chung toc tren fake object KHONG phai bao gio cung chet (avatar vo hon `My_Wuhun` doi Set_RaceID sang
    // model 2341 van song), nen nghi can la: object dang gan cua so + dang co render texture, dung lai model thi
    // con tro entity ben Ogre thanh rac. Chua truy tiep - do la mot nhanh rieng.
    // Khoa SEX VAN duoc luu va LuaFnGetExteriorRaceID van tra ve no (nut doi gioi tinh van lat anh, bang camera
    // van doi), chi rieng MODEL la khong dung lai.
    int RaceIdFor(const char* objectName, int selfRaceId)
    {
        if (!objectName || strcmp(objectName, "Exterior_Player") != 0) return selfRaceId;
        const Fit* sex = FindFit("SEX");
        if (!sex) return selfRaceId;
        const int race = sex->id == 0 ? 0 : 1;
        if (race != selfRaceId)
            Log("previewed sex %d differs from own %d - model NOT rebuilt (crash guard, see the handoff muc 5)",
                race, selfRaceId);
        return selfRaceId;
    }

    void ApplyFitting(const char* objectName, CObject_Character* dst)
    {
        if (!objectName || strcmp(objectName, "Exterior_Player") != 0 || !dst) return;
        // Set_DressVisual asserts CHECK_MUST_NOT(CT_MONSTER); CY registers Exterior_Ride as a CObject_PlayerNPC,
        // so the type is checked and never assumed (branch `wardrobe`, trap 3).
        if (dst->GetCharacterType() != CObject_Character::CT_PLAYEROTHER) return;
        CCharacterData* data = dst->GetCharacterData();
        if (!data) return;

        const Fit* fashion = FindFit("FASHION");
        if (!fashion) return;                       // nothing being tried on: the avatar stays as MySelf
        const int visual = fashion->id > 0 ? VisualOfFashion(fashion->id, fashion->a) : INVALID_ID;
        if (fashion->id > 0 && visual == INVALID_ID)
        {
            Log("fitting FASHION=%d is not in the client depot; avatar left as worn", fashion->id);
            return;
        }
        if (data->Get_DressVisual() == visual) return;
        const int before = data->Get_DressVisual();
        data->Set_DressVisual(visual);
        ++g_applied;
        Log("avatar dress visual %d -> %d (fashion item %d)", before, visual, fashion->id);
    }

    void SetServerDepot(const int* itemIds, const int* visuals, int count)
    {
        std::vector< Slot >& d = ServerDepot();
        d.clear();
        int filled = 0;
        for (int i = 0; i < count; ++i)
        {
            Slot s; s.bagIndex = -2; s.itemId = itemIds[i]; s.visual = visuals[i];
            if (s.itemId > 0) ++filled;
            d.push_back(s);
        }
        g_haveServer = true;
        Log("server depot: %d slot(s), %d hold a fashion", count, filled);
        for (int i = 0, shown = 0; i < count && shown < 10; ++i)
            if (d[i].itemId > 0) { Log("  server depot[%d] item=%d visual=%d", i, d[i].itemId, d[i].visual); ++shown; }
    }

    bool HaveServerDepot() { return g_haveServer; }

    int DepotCount() { return (int)DepotCached().size(); }

    int DepotFilled()
    {
        const std::vector< Slot >& d = DepotCached();
        int n = 0;
        for (size_t i = 0; i < d.size(); ++i) if (d[i].itemId > 0) ++n;
        return n;
    }

    // CY list row (1-based; NewExterior_DressBox_ItemClicked(nIndex) reads g_PlayerFashionInfoList[nIndex] whose
    // nVecIndex is nIndex-1) of the first fashion that is NOT the one already on. 0 when there is none, and the
    // probe then knows the run cannot prove a change.
    int PickRow()
    {
        const int worn = WornFashionItem();
        const std::vector< Slot >& d = DepotCached();
        for (size_t i = 0; i < d.size(); ++i)
            if (d[i].itemId > 0 && d[i].itemId != worn) return (int)i + 1;
        return 0;
    }

    int FittingCount() { return (int)Fitting().size(); }
    int AppliedCount() { return g_applied; }

    int Register(LuaPlus::LuaState* state)
    {
        if (!state) return 0;
        CysWardrobeCatalog::Register(state);
        LuaPlus::LuaObject globals = state->GetGlobals();
        int registered = 0;
        // CYS-WARD3: cong tac A/B. `CYS_WARD3_OFF=1` KHONG dang ky rieng ham mo cua, nen stub sinh tu dong giu
        // lai o (khong lam gi)  -  ve A cua phep do chay tren DUNG MOT BINARY, chi khac mot bien moi truong.
        char off[8] = {};
        const bool ward3Off = ::GetEnvironmentVariableA("CYS_WARD3_OFF", off, sizeof(off)) == 1 && off[0] == '1';
        for (size_t i = 0; i < sizeof(kEntries) / sizeof(kEntries[0]); ++i)
        {
            const Entry& e = kEntries[i];
            if (ward3Off && (strcmp(e.name, "LuaFnInitExteriorFashionList") == 0 ||
                             strcmp(e.name, "LuaFnAskOpenExterior") == 0))
            {
                TDU_Log("CYS-WARD3: CYS_WARD3_OFF=1 - KHONG dang ky %s (ve A)", e.name);
                continue;
            }
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
        TDU_Log("CYS-WARD2: host functions registered=%d of %d", n, (int)(sizeof(kEntries) / sizeof(kEntries[0])));
    }
}

// ---- CYS_WARD3_LIVE=1: do CHINH CAI NUT cua nguoi choi, khong day su kien thay no -------------------------------
//
// Day la cho hai nhanh truoc truot: probe cua `meshwindow`/`wardrobe-2` mo phong thay do bang
// `PushEventByName("OPEN_EXTERIOR_FASHION","1","1")` (CysHost_MeshWin.cpp:505). Lam vay la BO QUA cai cua  - 
// su kien duoc day tu C++ thi khung mo, nhung nguoi choi khong co cach nao day su kien do.
// Probe nay chay DUNG cau lenh ma `SelfEquip.layout.xml:838 <Event Name="Clicked">` chay: `SelfEquip_OnYirong()`.
//
// In trang thai TRUOC va SAU (luat: "probe phai in trang thai TRUOC, khong chi SAU"  -  neu khong thi khong phan
// biet duoc "da lam va thanh cong" voi "chua lam gi ca").
// DOI CHUNG AM trong chinh luot do: `NewExterior_Ride` PHAI van dong ca truoc lan sau (cu bam mo the THOI TRANG,
// khong phai the TOA KY). Neu no cung "shown=1" thi phep do dang noi doi, khong phai bug da het.
namespace CysWard3Probe
{
    namespace
    {
        enum Step { Off, Wait, OpenEquip, Click, After, TabClick, AfterTab, Done };
        struct State { bool evaluated; Step step; DWORD at; };
        State& S() { static State s = { false, Off, 0 }; return s; }

        void Log(const char* fmt, ...)
        {
            char text[1024] = {};
            va_list args; va_start(args, fmt);
            _vsnprintf(text, sizeof(text) - 1, fmt, args);
            va_end(args);
            TDU_Log("CYS-WARD3 live: %s", text);
        }
        bool EnvFlag(const char* name)
        {
            char text[8] = {};
            const DWORD n = ::GetEnvironmentVariableA(name, text, sizeof(text));
            return n == 1 && text[0] == '1';
        }
        DWORD Age() { return GetTickCount() - S().at; }
        void Go(Step next, const char* why) { S().step = next; S().at = GetTickCount(); Log("buoc %d: %s", (int)next, why); }
        bool Shown(const char* w) { return CGameProcedure::s_pUISystem && CGameProcedure::s_pUISystem->IsWindowShow(w) != FALSE; }

        // Mot dong duy nhat de cham diem mot ve A/B.
        void Report(const char* when)
        {
            Log("%s: SelfEquip=%d NewExterior_DressBox=%d NewExterior_PlayerFrame=%d | DOI CHUNG AM NewExterior_Ride=%d",
                when, Shown("SelfEquip") ? 1 : 0, Shown("NewExterior_DressBox") ? 1 : 0,
                Shown("NewExterior_PlayerFrame") ? 1 : 0, Shown("NewExterior_Ride") ? 1 : 0);
        }
    }

    bool Tick()
    {
        State& s = S();
        if (!s.evaluated)
        {
            s.evaluated = true;
            if (EnvFlag("CYS_WARD3_LIVE")) { s.step = Wait; s.at = GetTickCount(); }
            Log("driver %s ward3_off=%d", s.step == Wait ? "bat" : "tat", EnvFlag("CYS_WARD3_OFF") ? 1 : 0);
        }
        if (s.step == Off || s.step == Done) return true;
        if (!CysModernGame::IsInWorld()) { Log("ra khoi the gioi o buoc %d", (int)s.step); s.step = Done; return true; }
        switch (s.step)
        {
        case Wait:
            if (Age() < 2500) break;
            Report("khoi dau (chua mo gi)");
            if (CEventSystem::GetMe()) CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP, 1);
            Go(OpenEquip, "GE_OPEN_EQUIP 1 - mo khung Nhan vat nhu menu chinh cua CY");
            break;
        case OpenEquip:
            if (Age() < 3000) break;
            Report("TRUOC khi bam nut Ngoai hinh");
            CysWorldReplay::LiveShot("w3-truoc");
            Go(Click, "chup xong anh TRUOC");
            break;
        case Click:
            if (Age() < 600) break;
            {
                // DUNG cau lenh cua `<Event Name="Clicked" Function="SelfEquip_OnYirong();"/>`.
                CScriptSystem* scripts = CScriptSystem::GetMe();
                if (!scripts) { Log("khong co he script - bo luot"); Go(Done, "loi"); break; }
                const CysCheckedScriptLua::Result r =
                    scripts->EvaluateScript("SelfEquip_Env", "SelfEquip_OnYirong()");
                Log("bam nut: SelfEquip_OnYirong() -> status=%d usable=%d %s", r.status, r.stateUsable ? 1 : 0, r.error);
            }
            Go(After, "da chay cau lenh cua nut");
            break;
        case After:
            if (Age() < 3000) break;
            Report("SAU khi bam nut Ngoai hinh");
            CysWorldReplay::LiveShot("w3-sau");
            Go(TabClick, "chup xong anh SAU");
            break;
        case TabClick:
            if (Age() < 800) break;
            {
                // Cai the "Toa ky" cua chinh khung vua mo: NewExterior_DressBox.lua NewExterior_DressBox_OpenRide()
                // -> Exterior:LuaFnAskOpenExterior(0). O buoc tren, NewExterior_Ride la DOI CHUNG AM (phai = 0);
                // o buoc nay chinh no phai = 1. Mot cua so dong vai ca hai vai thi phep do khong the "luon dung".
                CScriptSystem* scripts = CScriptSystem::GetMe();
                if (scripts)
                {
                    const CysCheckedScriptLua::Result r =
                        scripts->EvaluateScript("NewExterior_DressBox_Env", "NewExterior_DressBox_OpenRide()");
                    Log("bam the Toa ky: NewExterior_DressBox_OpenRide() -> status=%d usable=%d %s",
                        r.status, r.stateUsable ? 1 : 0, r.error);
                }
            }
            Go(AfterTab, "da chay cau lenh cua the Toa ky");
            break;
        case AfterTab:
            if (Age() < 3000) break;
            Report("SAU khi bam the Toa ky");
            CysWorldReplay::LiveShot("w3-the-toaky");
            Go(Done, "xong");
            break;
        default:
            break;
        }
        // GIU rig lai trong khi probe con dang chay. Tra `true` vo dieu kien thi rig di tiep va THOAT
        // GAME truoc khi probe kip bam nut - lan chay `live-a-0-KHONG-CHAY-DU` va `live-a-1` dau tien
        // dung 13 giay roi tat, chi kip in mot dong "driver bat". Khuon dung la cua CysMeshWinProbe.
        return s.step == Done;
    }
}
