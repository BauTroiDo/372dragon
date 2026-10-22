// CYS-MESHWIN 19/09: DataPool:KFS_UpdateKFSModel + the MeshWindow live probe. See CysHost_MeshWin.h.
#include "CysHost_MeshWin.h"
#include "DataPool/CysWuhunData.h"
#include "Network/CysWuhunNet.h"
#include "CysHost_Host2.h"
#include "CysHost_Wardrobe.h"   // CYS-WARD2: the fitting set laid over the wardrobe avatar
#include "LuaApiGen.h"
#include "Network/CysModernGame.h"
#include "Network/CysWorldReplay.h"
#include "Event/GMEventSystem.h"
#include "Script/GMScriptSystem.h"
#include "Script/CysCheckedScriptLua.h"   // CYS-MESHEX: checked Lua statements from the probe
#include "GameStruct_Script.h"            // CYS-MESHEX: X_PARAM of a GE_UI_COMMAND
#include "Procedure/GameProcedure.h"
#include "DataPool/GMDataPool.h"
#include "DataPool/GMDP_CharacterData.h"          // CYS-MESHEX: SetFakeObjDataEx copies the appearance fields
#include "Object/Item/Obj_Item.h"
#include "Object/ObjectManager.h"                 // CYS-MESHEX: GetMySelf()
#include "Object/Character/Obj_PlayerMySelf.h"    // CYS-MESHEX
#include "Object/Character/Obj_PlayerOther.h"     // CYS-MESHEX
#include "FakeObject/GMFakeObjSystem.h"
#include "DBC/GMDataBase.h"
#include "TDEventDefine.h"
#include "TDUISystem.h"
#include "TDUtil.h"
#include "TDException.h"
#include "CysUiInputBridge.h"   // CysUiGetWindowRectUtf8: screen rectangle of the model window for the shot
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <vector>   // CYS-WARDROBE: PushEventByName parameters

namespace CysMeshWinHost
{
    namespace
    {
        DBC::DBCFile* g_kfsBase = NULL;
        bool g_kfsBaseTried = false;
        unsigned g_logs = 0;

        void Log(const char* fmt, ...)
        {
            if (g_logs++ >= 64) return;
            char text[512] = {};
            va_list args; va_start(args, fmt);
            _vsnprintf(text, sizeof(text) - 1, fmt, args);
            va_end(args);
            TDU_Log("CYS-MESHWIN: %s", text);
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



        DBC::DBCFile* KfsBase()
        {
            if (g_kfsBaseTried) return g_kfsBase;
            g_kfsBaseTried = true;
            DBC::DBCFile* dbc = new DBC::DBCFile(0xEE);
            if (!CDataBase::Util_OpenDBCFromTxt("KFSBase.txt", dbc))
            {
                Log("KFSBase.txt NOT FOUND (ConfigFolder) - wuhun avatars keep no model");
                delete dbc;
                return NULL;
            }
            if (dbc->GetFieldsNum() < 15)
            {
                Log("KFSBase.txt shape %ux%u, expected >= 15 columns - table ignored", dbc->GetFieldsNum(), dbc->GetRecordsNum());
                delete dbc;
                return NULL;
            }
            g_kfsBase = dbc;
            Log("KFSBase.txt loaded: %u rows x %u columns", dbc->GetRecordsNum(), dbc->GetFieldsNum());
            return g_kfsBase;
        }

        CObject_Item* EquippedWuhun()
        {
            CDataPool* pool = CDataPool::GetMe();
            if (!pool) return NULL;
            tObject_Item* item = pool->UserEquip_GetItem((HUMAN_EQUIP)18);   // CY: ItemContainerMgr->vf[0x1b](0x12)
            if (!item) return NULL;
            CObject_Item* obj = (CObject_Item*)item;
            return obj->GetItemClass() == ICLASS_EQUIP ? obj : NULL;         // CY: item->vf[3]() == 1
        }

        int DataPoolKfsUpdateModel(LuaPlus::LuaState*)
        {
            UpdateWuhunModel();
            return 0;
        }














        int CopiedFields = 0;

        bool CopyMySelfAppearance(const char* objectName)
        {
            CFakeObjSystem* fake = CFakeObjSystem::GetMe();
            CObjectManager* objects = CObjectManager::GetMe();
            if (!fake || !objects) return false;
            CObject_PlayerMySelf* self = objects->GetMySelf();
            if (!self) { Log("SetFakeObjDataEx(%s): no MySelf yet", objectName); return false; }

            // CY creates the object from its registered entry on demand; so does this (GMFakeObjSystem.cpp).
            tObject* target = fake->EnsureExObject(objectName);
            if (!target) { Log("SetFakeObjDataEx(%s): not a fake object and not a CY Ex entry", objectName); return false; }

            CObject_Character* dst = (CObject_Character*)target;
            CCharacterData* src = self->GetCharacterData();
            CCharacterData* dstData = dst->GetCharacterData();
            if (!src || !dstData) return false;




            const int raceId = CysWardrobeHost::RaceIdFor(objectName, src->Get_RaceID());
            dstData->Set_RaceID(raceId);          // rebuilds the model; every other field only refines it

            // The player-only fields throw on a CT_MONSTER target (GMDP_CharacterData.cpp CHECK_MUST_NOT), and CY
            // registers "Exterior_Ride" as CObject_PlayerNPC, so the type is checked, never assumed.
            int fields = 1;
            if (dst->GetCharacterType() == CObject_Character::CT_PLAYEROTHER)
            {
                dstData->Set_HairMesh(src->Get_HairMesh());
                dstData->Set_HairColor(src->Get_HairColor());
                dstData->Set_FaceMesh(src->Get_FaceMesh());
                fields += 3;
                for (int point = 0; point < HEQUIP_NUMBER; ++point)
                {
                    dstData->Set_Equip((HUMAN_EQUIP)point, point==HEQUIP_WEAPON?src->Get_WeaponAppearance():src->Get_Equip((HUMAN_EQUIP)point));
                    dstData->Set_EquipGem((HUMAN_EQUIP)point, src->Get_EquipGem((HUMAN_EQUIP)point));
                    fields += 2;
                }
                for(int slot=0;slot<2;++slot) dstData->Set_Ornament(slot,src->Get_OrnamentId(slot),src->Get_OrnamentPos(slot));
                dstData->Set_DressVisual(src->Get_DressVisual());   // CY's special point 16
                dstData->Set_WuhunAppearance(src->Get_WuhunItem(),src->Get_WuhunVisual());
                dstData->Set_AssaultAppearance(src->Get_AssaultItem(),src->Get_AssaultVisual());
                ++fields;
            }


            CysWardrobeHost::ApplyFitting(objectName, dst);
            dst->SetFaceDir(0.0f);
            if (objectName && strcmp(objectName, "Exterior_Player") == 0) CysWardrobeCatalog::Preview(dst);
            CopiedFields = fields;
            Log("SetFakeObjDataEx %s: race=%d hair=%d/%u face=%d weapon=%d dress=%d fields=%d type=%d",
                objectName, raceId, src->Get_HairMesh(), src->Get_HairColor(), src->Get_FaceMesh(),
                src->Get_Equip(HEQUIP_WEAPON), src->Get_DressVisual(), fields, (int)dst->GetCharacterType());
            return true;
        }

        int GlobalSetFakeObjDataEx(LuaPlus::LuaState* state)
        {

            if (!state) return 0;
            LuaPlus::LuaStack args(state);
            if (!args[1].IsString())
            {
                Log("LUA: Lua_SetFakeObjDataEx  Param Error");
                return 0;
            }
            CopyMySelfAppearance(args[1].GetString());
            return 0;
        }











        int ExteriorUpdatePlayerData(LuaPlus::LuaState*)
        {
            CopyMySelfAppearance("Exterior_Player");
            return 0;   // CY pushes nothing
        }

        // CY NewExterior_Ride.lua:982-985, mount-only view. Exterior_Ride is
        // a creature fake, so use its ModelID, never player appearance fields.
        int ExteriorUpdateAvatarMount(LuaPlus::LuaState* state)
        {
            LuaPlus::LuaStack args(state);
            if (!args[2].IsNumber()) return 0;
            const int id = args[2].GetInteger();
            CFakeObjSystem* fake = CFakeObjSystem::GetMe();
            CObject_Character* obj = fake ? (CObject_Character*)fake->FindFakeObject("Exterior_Ride") : NULL;
            if (!obj || obj->GetCharacterType() != CObject_Character::CT_MONSTER) return 0;
            DBC_DEFINEHANDLE(mounts, DBC_CHARACTER_MOUNT)
            const _DBC_CHARACTER_MOUNT* mount = (const _DBC_CHARACTER_MOUNT*)mounts->Search_Index_EQU(id);
            if (!mount) return 0;
            obj->GetCharacterData()->Set_ModelID(mount->m_nModelID);
            obj->SetFaceDir(0.0f);
            return 0;
        }

        // GL GMTool passes a MonsterAttrExTable id for the portrait and a
        // server-resolved CharModelEx id for its generic creature preview.
        int MonsterNameAndIcon(LuaPlus::LuaState* state)
        {
            LuaPlus::LuaStack args(state);
            DBC_DEFINEHANDLE(creatures, DBC_CREATURE_ATT)
            const _DBC_CREATURE_ATT* row = args[2].IsNumber() ?
                (const _DBC_CREATURE_ATT*)creatures->Search_Index_EQU(args[2].GetInteger()) : NULL;
            state->PushString(row && row->pName ? row->pName : "");
            state->PushString(row && row->szIconName ? row->szIconName : "");
            return 2;
        }

        int RabbitModel(LuaPlus::LuaState* state)
        {
            LuaPlus::LuaStack args(state);
            if (!args[2].IsNumber()) return 0;
            const int id = args[2].GetInteger();
            DBC_DEFINEHANDLE(models, DBC_CHARACTER_MODEL)
            if (id <= 0 || !models->Search_Index_EQU(id)) return 0;
            CFakeObjSystem* fake = CFakeObjSystem::GetMe();
            CObject_Character* obj = fake ? (CObject_Character*)fake->EnsureExObject("Rabbit") : NULL;
            if (!obj || obj->GetCharacterType() != CObject_Character::CT_MONSTER) return 0;
            obj->GetCharacterData()->Set_ModelID(id);
            obj->SetFaceDir(0.0f);
            Log("GM pet preview model=%d", id);
            return 0;
        }

        const DBC::DBCFile::FIELD* GiftCell(int item, int column)
        {
            static DBC::DBCFile* table=[](){auto t=new DBC::DBCFile(0x158);
                if(!CDataBase::Util_OpenDBCFromTxt("OptionalGiftBox.txt",t)||t->GetFieldsNum()!=31){delete t;return (DBC::DBCFile*)NULL;}return t;}();
            if(!table)return NULL;
            for(unsigned row=0;row<table->GetRecordsNum();++row){auto key=table->Search_Posistion(row,1);
                if(key&&key->iValue==item)return table->Search_Posistion(row,column);}
            return NULL;
        }
        int BagItemTableIndex(LuaPlus::LuaState* state)
        {
            LuaPlus::LuaStack a(state);
            auto pool=CDataPool::GetMe();
            const int pos=a[2].IsNumber()?a[2].GetInteger():-1;
            auto item=pool?pool->UserBag_GetItem(pos):NULL;
            state->PushInteger(item?item->GetIdTable():-1);
            return 1;
        }
        // GL ce0c4fec...: 14023e220 reads +2c/+30/+34 then +8/+10/+18;
        // 14023e3e0 reads +38/+3c, stride 10h (five item/count pairs).
        int OptionalGiftInfo(LuaPlus::LuaState* state)
        {
            LuaPlus::LuaStack a(state);if(!a[1].IsNumber()||!GiftCell(a[1].GetInteger(),1))return 0;
            for(int c=8;c<=10;++c)state->PushInteger(GiftCell(a[1].GetInteger(),c)->iValue);
            for(int c=2;c<=4;++c)state->PushString(GiftCell(a[1].GetInteger(),c)->pString);
            return 6;
        }
        int OptionalGiftItems(LuaPlus::LuaState* state)
        {
            LuaPlus::LuaStack a(state);if(!a[1].IsNumber()||!GiftCell(a[1].GetInteger(),1))return 0;
            for(int c=11;c<=27;c+=4){state->PushInteger(GiftCell(a[1].GetInteger(),c)->iValue);state->PushInteger(GiftCell(a[1].GetInteger(),c+1)->iValue);}
            return 10;
        }

        struct Entry { const char* receiver; const char* name; int (*fn)(LuaPlus::LuaState*); };
        const Entry kEntries[] = {
            {"PlayerPackage", "GetItemTableIndex", BagItemTableIndex},
            {NULL, "LuaFnGetOptionalGiftBoxInfo", OptionalGiftInfo},
            {NULL, "LuaFnGetOptionalGiftBoxGiftInfo", OptionalGiftItems},
            {"DataPool", "GetMonsterNameAndIcon", MonsterNameAndIcon},
            {"DataPool", "SetRabbitModel", RabbitModel},
            {"DataPool", "KFS_UpdateKFSModel", DataPoolKfsUpdateModel},
            {"Exterior", "LuaFnUpdateExteriorAvatarMount", ExteriorUpdateAvatarMount},
            {NULL,       "SetFakeObjDataEx",   GlobalSetFakeObjDataEx},   // CYS-MESHEX: a _G function, not a method
            {"Exterior", "LuaFnUpdateExteriorPlayerData", ExteriorUpdatePlayerData},   // CYS-WARDROBE
        };
    }

    int WuhunModelId(int itemTableId, int wuhunLevel)
    {
        DBC::DBCFile* dbc = KfsBase();
        if (!dbc) return -1;
        // On x64 a DBC record is not an array of FIELD (CysPowerNet.cpp:206) - cells are read with Search_Posistion.
        const int rows = (int)dbc->GetRecordsNum();
        for (int row = 0; row < rows; ++row)
        {
            const DBC::DBCFile::FIELD* key = dbc->Search_Posistion(row, 0);
            if (!key || key->iValue != itemTableId) continue;
            const int col = (wuhunLevel >= 1 && wuhunLevel <= 4) ? 10 + wuhunLevel : 10;
            const DBC::DBCFile::FIELD* cell = dbc->Search_Posistion(row, col);
            return cell ? cell->iValue : -1;
        }
        return -1;
    }

    bool UpdateWuhunModel()
    {
        CDataPool* pool = CDataPool::GetMe();
        if (!pool) return false;
        CObject_Item* wuhun = EquippedWuhun();
        const int item = wuhun ? wuhun->GetIdTable() : -1;
        auto self=CObjectManager::GetMe()->GetMySelf();
        const auto appearance=self?CysWuhunData::Find(self->GetCharacterData()->Get_WuhunVisual()):nullptr;
        const int huan=CysWuhunNet::PreviewModel();
        const int model = wuhun ? (huan>0?huan:appearance?appearance->model:WuhunModelId(item,0)) : -1;
        Log("KFS_UpdateKFSModel equipped=%d item=%d model=%d", wuhun ? 1 : 0, item, model);
        // Wuhun.lua detaches the RTT before this call. Clear on empty/unknown
        // equipment as CY does, otherwise the last equipped soul stays visible.
        pool->Wuhun_SetModel(model);
        return model > 0;
    }

    int Register(LuaPlus::LuaState* state)
    {
        if (!state) return 0;
        LuaPlus::LuaObject globals = state->GetGlobals();
        int registered = 0;
        for (size_t i = 0; i < sizeof(kEntries) / sizeof(kEntries[0]); ++i)
        {
            const Entry& e = kEntries[i];
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
        TDU_Log("CYS-MESHWIN: host functions registered=%d", n);
    }
}

// ---- CYS_MESHWIN_LIVE=1: open the three model windows the user asked about, log + shoot, close ------------------
namespace CysMeshWinProbe
{
    namespace
    {
        // CYS-MESHEX 19/09: the meshwindow steps (Equip..WuhunClose) are kept as they ran in live-7/8/10; the Ex
        // steps after them open the two CY frames that the Dress*/NewExterior_* group needs SetFakeObjDataEx for,
        // and drive the six *Ex functions that had no call yet.
        enum Step { Off, Wait, Equip, EquipRotate, EquipRotShot, EquipShot, EquipClose,
                    Pet, PetShot, PetClose, Wuhun, WuhunShot, WuhunClose,
                    WardrobeOpen, WardrobeShot, WardrobeRotate, WardrobeRotShot, WardrobeZoom,
                    WardrobeZoomShot, WardrobeRest, WardrobeRestShot, WardrobeClose,
                    DressOpen, DressRelist, DressTry, DressTryShot, DressSex, DressSexShot,   // CYS-WARD2
                    DressShot, DressClose, WardrobeClosed, PortraitReopen, PortraitClose, PortraitMove, Done };
        struct State
        {
            bool evaluated = false;
            Step step = Off;
            DWORD at = 0;
            bool wuhunPushed = false;
            bool portraitOnly = false;
            float portraitCamera[3] = {};
            float moveX = 0, moveZ = 0;
            CysUiInputBridge::GetWindowRectUtf8 rect = nullptr;
        };
        State& S() { static State s; return s; }

        bool EnvFlag(const char* name)
        {
            char text[8] = {};
            const DWORD n = ::GetEnvironmentVariableA(name, text, sizeof(text));
            return n == 1 && text[0] == '1';
        }
        void Log(const char* fmt, ...)
        {
            char text[1024] = {};
            va_list args; va_start(args, fmt);
            _vsnprintf(text, sizeof(text) - 1, fmt, args);
            va_end(args);
            TDU_Log("CYS-MESHWIN live: %s", text);
        }
        void Go(Step next, const char* why) { S().step = next; S().at = GetTickCount(); Log("step %d: %s", (int)next, why); }
        DWORD Age() { return GetTickCount() - S().at; }
        bool Shown(const char* window) { return CGameProcedure::s_pUISystem && CGameProcedure::s_pUISystem->IsWindowShow(window); }
        const char* Bound(const char* window)
        {
            const char* obj = CFakeObjSystem::GetMe() ? CFakeObjSystem::GetMe()->GetWindowObject(window) : NULL;
            return obj ? obj : "-";
        }
        void Shot(const char* label) { CysWorldReplay::LiveShot(label); }
        void Push(GAME_EVENT_ID id, int arg) { if (CEventSystem::GetMe()) CEventSystem::GetMe()->PushEvent(id, arg); }

        // CYS-MESHEX: the Dress*/NewExterior_* frames are opened by GE_UI_COMMAND + the X_PARAM the server would
        // have filled (CDataPool::X_PARAM_Set, GMDataPool.cpp:4742). Int 0 is the NPC's server id in both frames;
        // both survive an unknown one (DataPool:GetNPCIDByServerID returns -1 and CareObject is simply skipped).
        void PushUiCommand(int uiIndex, int npcServerId)
        {
            CDataPool* pool = CDataPool::GetMe();
            if (!pool || !CEventSystem::GetMe()) return;
            X_PARAM* param = pool->X_PARAM_Get();
            param->CleanUp();
            param->AddIntValue(npcServerId);
            CEventSystem::GetMe()->PushEvent(GE_UI_COMMAND, uiIndex);
            Log("UI_COMMAND %d (X_PARAM int0=%d)", uiIndex, npcServerId);
        }

        // CYS-WARDROBE: push an event the 0.85 enum does not have. CEventSystem keys handlers by NAME
        // (UIWindowMng.cpp:370 RegisterEventHandle(strEventName, ...)), so the whole CY event family the wardrobe
        // registers (OPEN_EXTERIOR, ADD_EXTERIOR, ...) is reachable without touching GAME_EVENT_ID.
        void PushEventByName(const char* name, const char* arg0, const char* arg1)
        {
            if (!CEventSystem::GetMe()) return;
            std::vector< STRING > params;
            params.push_back(arg0 ? arg0 : "");
            if (arg1) params.push_back(arg1);
            const BOOL ok = CEventSystem::GetMe()->PushEventByName(name, params);
            Log("event %s(%s,%s) pushed=%d", name, arg0 ? arg0 : "", arg1 ? arg1 : "", ok ? 1 : 0);
        }

        // CYS-MESHEX: one CY Lua statement, run in the frame's own environment (its "<name>_Env" table, so "this"
        // resolves) through the checked road that restores the stack (CysCheckedScriptLua). These are the exact
        // statements the frame's own buttons run - the probe replaces the click, not the call.
        void Lua(const char* envTable, const char* statement)
        {
            CScriptSystem* scripts = CScriptSystem::GetMe();
            if (!scripts) { Log("lua skipped (no script system): %s", statement); return; }
            const CysCheckedScriptLua::Result r = scripts->EvaluateScript(envTable, statement);
            Log("lua [%s] %s -> status=%d usable=%d %s", envTable, statement, r.status, r.stateUsable ? 1 : 0, r.error);
        }
        // The line a live run is judged by: window shown + the model window bound to a fake object + where the
        // model window sits on screen (CEGUI pixels, x y w h) so the shot can be cropped and counted.
        void Report(const char* frame, const char* meshWindow)
        {
            float r[4] = {};
            const int rc = S().rect ? S().rect(meshWindow, r) : -1;
            Log("%s shown=%d bound(%s)=%s rect=%s%.0f,%.0f,%.0f,%.0f", frame, Shown(frame) ? 1 : 0, meshWindow, Bound(meshWindow),
                rc == 1 ? "" : "? ", r[0], r[1], r[2], r[3]);
        }
    }

    bool Tick()
    {
        State& s = S();
        if (!s.evaluated)
        {
            s.evaluated = true;
            if (EnvFlag("CYS_MESHWIN_LIVE")) { s.step = Wait; s.at = GetTickCount(); }
            s.portraitOnly = EnvFlag("CYS_SELFEQUIP_PORTRAIT_LIVE");
            if (s.portraitOnly) { s.step = Wait; s.at = GetTickCount(); }
            if (HMODULE ui = GetModuleHandleA("UI_CEGUI.dll"))
                s.rect = reinterpret_cast<CysUiInputBridge::GetWindowRectUtf8>(GetProcAddress(ui, "CysUiGetWindowRectUtf8"));
            Log("driver %s rect=%d", s.step == Wait ? "enabled" : "disabled", s.rect ? 1 : 0);
        }
        if (s.step == Off || s.step == Done) return true;
        if (!CysModernGame::IsInWorld()) { Log("left the world at step %d", (int)s.step); s.step = Done; return true; }
        switch (s.step)
        {
        case Wait:
            if (Age() < 2000) break;
            Push(GE_OPEN_EQUIP, 1);            // OpenEquip(1) of the CY main menu -> SelfEquip.lua OPEN_EQUIP
            Go(Equip, "OPEN_EQUIP 1");
            break;
        case Equip:
            if (Age() < 3000) break;           // SelfEquip.lua:750 AttachWindowEx("Player") ran on open; give the RTT ~30 frames
            Report("SelfEquip", "SelfEquip_FakeObject");
            Shot("mw-selfequip");
            if (s.portraitOnly)
            {
                CFakeObjSystem::GetMe()->GetCamera("SelfEquip_FakeObject", &s.portraitCamera[0], &s.portraitCamera[1], &s.portraitCamera[2], NULL);
                Log("portrait opened camera=%.4f,%.4f,%.4f", s.portraitCamera[0], s.portraitCamera[1], s.portraitCamera[2]);
            }
            // CYS-MESHEX: the statement SelfEquip.lua:2559 (SelfEquip_Modle_TurnLeft) runs on the left arrow.
            Lua("SelfEquip_Env", "SelfEquip_FakeObject:RotateBeginEx(\"Player\", -0.3)");
            Go(EquipRotate, "RotateBeginEx Player");
            break;
        case EquipRotate:
            if (Age() < 2500) break;           // ~75 ticks of CFakeObjSystem::Tick at 0.15 rad each
            Shot("mx-selfequip-rot");
            Lua("SelfEquip_Env", "SelfEquip_FakeObject:RotateEndEx()");
            Go(EquipRotShot, "RotateEndEx");
            break;
        case EquipRotShot:
            if (Age() < 1500) break;
            Shot("mx-selfequip-rotend");       // two shots after RotateEnd must agree; the rotating pair must not
            Go(EquipShot, "SelfEquip rotate done");
            break;
        case EquipShot:
            if (Age() < 800) break;
            Push(GE_OPEN_EQUIP, 1);            // OPEN_EQUIP on a visible SelfEquip = SelfEquip_CloseFunction (toggle)
            Go(EquipClose, "OPEN_EQUIP again (close)");
            break;
        case EquipClose:
            if (Age() < 1200) break;
            Report("SelfEquip", "SelfEquip_FakeObject");
            if (s.portraitOnly)
            {
                Push(GE_OPEN_EQUIP, 1);
                Go(PortraitReopen, "reopen SelfEquip to check camera does not compound");
                break;
            }
            Push(GE_TOGLE_PET_PAGE, -1);       // Pet.lua:319 TOGLE_PET_PAGE (arg outside 0..PET_MAX -> no preselect)
            Go(Pet, "TOGLE_PET_PAGE");
            break;
        case PortraitReopen:
        {
            if (Age() < 2500) break;
            float h=0,d=0,p=0;
            const bool ok = CFakeObjSystem::GetMe()->GetCamera("SelfEquip_FakeObject", &h, &d, &p, NULL) &&
                Shown("SelfEquip") && fabs(h-s.portraitCamera[0]) < .001f &&
                fabs(d-s.portraitCamera[1]) < .001f && fabs(p-s.portraitCamera[2]) < .001f;
            Report("SelfEquip", "SelfEquip_FakeObject");
            Shot("selfequip-portrait-reopen");
            Log("portrait reopened camera=%.4f,%.4f,%.4f stable=%d", h,d,p,ok ? 1 : 0);
            Push(GE_OPEN_EQUIP, 1);
            Go(PortraitClose, "close before measuring movement");
            break;
        }
        case PortraitClose:
        {
            if (Age() < 1200) break;
            CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
            if (!self || Shown("SelfEquip")) { Log("portrait FAILED close/self"); Go(Done,"portrait failed"); break; }
            s.moveX=self->GetPosition().x; s.moveZ=self->GetPosition().z;
            Log("portrait postclose from=%.3f,%.3f shown=0", s.moveX,s.moveZ);
            if (!CysWorldReplay::LiveGroundClick(4)) { Log("portrait FAILED move request"); Go(Done,"portrait failed"); break; }
            Go(PortraitMove, "observe movement with SelfEquip closed");
            break;
        }
        case PortraitMove:
        {
            if (Age() < 3000) break;
            CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
            if (!self) { Log("portrait FAILED lost self"); Go(Done,"portrait failed"); break; }
            const float x=self->GetPosition().x,z=self->GetPosition().z;
            const float distance=sqrt((x-s.moveX)*(x-s.moveX)+(z-s.moveZ)*(z-s.moveZ));
            Shot("selfequip-portrait-postclose");
            Log("portrait DONE from=%.3f,%.3f to=%.3f,%.3f distance=%.3f shown=%d pass=%d",
                s.moveX,s.moveZ,x,z,distance,Shown("SelfEquip") ? 1 : 0, distance >= .5f && !Shown("SelfEquip") ? 1 : 0);
            Go(Done,"portrait complete");
            break;
        }
        case Pet:
            if (Age() < 3000) break;           // Pet.lua:518 AttachWindowEx("My_Pet"); Pet:SetModel only with a pet
            Report("Pet", "Pet_FakeObject");
            Shot("mw-pet");
            Go(PetShot, "Pet shot");
            break;
        case PetShot:
            if (Age() < 800) break;
            Push(GE_TOGLE_PET_PAGE, -1);       // toggle closes -> Pet_OnHidden -> DetachWindowEx("My_Pet")
            Go(PetClose, "TOGLE_PET_PAGE again (close)");
            break;
        case PetClose:
            if (Age() < 1200) break;
            Report("Pet", "Pet_FakeObject");
            s.wuhunPushed = CysHostHost2::ToggleWuhunPage();   // Wuhun.lua:325-327 SetFakeObject("") / KFS_UpdateKFSModel / SetFakeObject("My_Wuhun")
            Go(Wuhun, s.wuhunPushed ? "ToggleWuhunPage" : "ToggleWuhunPage refused (not in the main procedure)");
            break;
        case Wuhun:
            if (Age() < 3000) break;
            Report("Wuhun", "Wuhun_FakeObject");
            Shot("mw-wuhun");
            Go(WuhunShot, "Wuhun shot");
            break;
        case WuhunShot:
            if (Age() < 800) break;
            if (Shown("Wuhun")) CysHostHost2::ToggleWuhunPage();
            Go(WuhunClose, "ToggleWuhunPage again (close)");
            break;
        case WuhunClose:
            if (Age() < 1200) break;
            Report("Wuhun", "Wuhun_FakeObject");
            // CYS-WARDROBE: NewExterior_PlayerFrame.lua:103 opens on OPEN_EXTERIOR when arg0 == its own type (5) and
            // the window is hidden. The name-keyed push is used because the 0.85 event enum has no OPEN_EXTERIOR
            // (the whole CY wardrobe event family is missing; RegisterEventHandle keys by string, so this works).
            PushEventByName("OPEN_EXTERIOR", "5", "1");
            Go(WardrobeOpen, "OPEN_EXTERIOR 5 (NewExterior_PlayerFrame)");
            break;

        // ---- CYS-WARDROBE: the wardrobe's main frame. Its model window binds "Exterior_Player" (a CY fakeEx entry
        // this tree never created) and its model comes from Exterior:LuaFnUpdateExteriorPlayerData(). _Show() then
        // calls UpdateObj -> UpdateCamera -> GetCameraEx + SetCameraEx.
        case WardrobeOpen:
            if (Age() < 3500) break;
            Report("NewExterior_PlayerFrame", "NewExterior_PlayerFrame_FakeObject");
            Shot("mx-wardrobe");
            Lua("NewExterior_PlayerFrame_Env",
                "NewExterior_PlayerFrame_FakeObject:RotateBeginEx(\"Exterior_Player\", -0.3)");
            Go(WardrobeShot, "wardrobe shot + RotateBeginEx");
            break;
        case WardrobeShot:
            if (Age() < 2500) break;
            Shot("mx-wardrobe-rot");
            Lua("NewExterior_PlayerFrame_Env", "NewExterior_PlayerFrame_FakeObject:RotateEndEx()");
            Go(WardrobeRotate, "wardrobe RotateEndEx");
            break;
        case WardrobeRotate:
            if (Age() < 1500) break;
            Shot("mx-wardrobe-rotend");
            Lua("NewExterior_PlayerFrame_Env", "NewExterior_PlayerFrame_ZoomIn()");   // -> UpdateCamera -> Get/SetCameraEx
            Go(WardrobeRotShot, "wardrobe ZoomIn");
            break;
        case WardrobeRotShot:
            if (Age() < 1500) break;
            Shot("mx-wardrobe-zoom");
            Lua("NewExterior_PlayerFrame_Env",
                "NewExterior_PlayerFrame_FakeObject:ChangeCameraDistanceEx(\"Exterior_Player\", 0, 1.8)");
            Go(WardrobeZoom, "ChangeCameraDistanceEx +1.8");
            break;
        case WardrobeZoom:
            if (Age() < 1500) break;
            Shot("mx-wardrobe-dist");
            Lua("NewExterior_PlayerFrame_Env", "NewExterior_PlayerFrame_FakeObject:RestPositonEx()");
            Go(WardrobeZoomShot, "RestPositonEx");
            break;
        case WardrobeZoomShot:
            if (Age() < 1500) break;
            Shot("mx-wardrobe-rest");
            Go(WardrobeRest, "rest shot");
            break;
        case WardrobeRest:
            if (Age() < 400) break;
            Report("NewExterior_PlayerFrame", "NewExterior_PlayerFrame_FakeObject");
            PushEventByName("OPEN_EXTERIOR", "5", "0");   // arg1 == 0 on a visible window = hide (line 106-110)
            Go(WardrobeRestShot, "OPEN_EXTERIOR 5 again (close)");
            break;
        case WardrobeRestShot:
            if (Age() < 1500) break;
            Report("NewExterior_PlayerFrame", "NewExterior_PlayerFrame_FakeObject");
            Go(WardrobeClose, "wardrobe closed");
            break;
        case WardrobeClose:
            if (Age() < 400) break;
            // CYS-WARDROBE: the SECOND wardrobe frame, to show the fix is not one frame's luck. NewExterior_DressBox
            // (the 时装 tab a player uses to change clothes) opens on its OWN event with arg0 = 1 (the player's own
            // wardrobe, m_PlayerfashionDepotType) and arg1 = 1 (reset the fitting); it binds the same Exterior_Player.
            PushEventByName("OPEN_EXTERIOR_FASHION", "1", "1");
            Go(DressOpen, "OPEN_EXTERIOR_FASHION 1 (NewExterior_DressBox)");
            break;
        case DressOpen:
            if (Age() < 3500) break;
            Report("NewExterior_DressBox", "NewExterior_DressBox_FakeObject");
            // CYS-WARD2: the frame built its 300 list rows on open, possibly before GCAskFashionDepotData came
            // back. One more _Show() rebuilds the rows from the SERVER array, so the row this probe clicks is
            // the row a player would see.
            Log("wardrobe(open) depot=%d filled=%d server=%d fitting=%d applied=%d",
                CysWardrobeHost::DepotCount(), CysWardrobeHost::DepotFilled(),
                CysWardrobeHost::HaveServerDepot() ? 1 : 0, CysWardrobeHost::FittingCount(),
                CysWardrobeHost::AppliedCount());
            Lua("NewExterior_DressBox_Env", "NewExterior_DressBox_Show()");
            Go(DressRelist, "re-list with the server depot");
            break;
        case DressRelist:
        {
            if (Age() < 2500) break;
            Shot("mx-dressbox");
            const int row = CysWardrobeHost::PickRow();
            Log("wardrobe(list) depot=%d filled=%d server=%d row_to_click=%d", CysWardrobeHost::DepotCount(),
                CysWardrobeHost::DepotFilled(), CysWardrobeHost::HaveServerDepot() ? 1 : 0, row);
            // NewExterior_DressBox_ItemClicked is the frame's own click handler (line 1219): MakeHyperlink ->
            // SetCurrentExteriorSetInfo("FASHION", id, idx) -> UpdateObj -> UpdateLeftBtn. row 0 = this character
            // owns no second fashion, and the run then proves only that the frame draws.
            if (row > 0)
            {
                char stmt[64] = {};
                _snprintf(stmt, sizeof(stmt) - 1, "NewExterior_DressBox_ItemClicked(%d)", row);
                Lua("NewExterior_DressBox_Env", stmt);
            }
            else Log("no second fashion on this character - nothing to try on");
            Go(DressTry, "ItemClicked = try a fashion on");
            break;
        }
        case DressTry:
            if (Age() < 2500) break;
            Shot("mx-dressbox-try");
            Log("after try: depot=%d fitting=%d applied=%d", CysWardrobeHost::DepotCount(),
                CysWardrobeHost::FittingCount(), CysWardrobeHost::AppliedCount());
            Lua("NewExterior_DressBox_Env", "NewExterior_DressBox_ChangeSex()");
            Go(DressTryShot, "ChangeSex (preview the other sex)");
            break;
        case DressTryShot:
            if (Age() < 3000) break;
            Shot("mx-dressbox-sex");
            Lua("NewExterior_DressBox_Env", "NewExterior_DressBox_ChangeSex()");
            Go(DressSex, "ChangeSex back");
            break;
        case DressSex:
            if (Age() < 3000) break;
            Shot("mx-dressbox-sexback");
            Lua("NewExterior_DressBox_Env", "Exterior:LuaFnUnUseExteriorFashion(1) NewExterior_DressBox_UpdateObj()");
            Go(DressSexShot, "take the fashion off in the preview");
            break;
        case DressSexShot:
            if (Age() < 2500) break;
            Shot("mx-dressbox-off");
            Log("after take-off: depot=%d fitting=%d applied=%d", CysWardrobeHost::DepotCount(),
                CysWardrobeHost::FittingCount(), CysWardrobeHost::AppliedCount());
            Report("NewExterior_DressBox", "NewExterior_DressBox_FakeObject");
            Go(DressShot, "dressbox shots done");
            break;
        case DressShot:
            if (Age() < 800) break;
            PushEventByName("OPEN_EXTERIOR_FASHION", "0", "0");   // arg0 == 0 on a visible window = hide
            Go(DressClose, "OPEN_EXTERIOR_FASHION 0 (close)");
            break;
        case DressClose:
            if (Age() < 1500) break;
            Report("NewExterior_DressBox", "NewExterior_DressBox_FakeObject");
            Go(WardrobeClosed, "wardrobe done");
            break;
        case WardrobeClosed:
            if (Age() < 400) break;
            Go(Done, "finished");
            break;
        default:
            break;
        }
        return s.step == Done;
    }
}
