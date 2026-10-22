#include "StdAfx.h"
#include "CysPetSoul.h"
#include "CysPetNet.h"























#include "CysHost_Pet.h"
#include "..\Script\GMScriptSystem.h"
#include "..\DataPool\GMDataPool.h"
#include "..\DataPool\GMDP_Struct_Pet.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\ObjectCommandDef.h"
#include "..\Object\GMObjectLoadQueue.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\Object\Character\Obj_PlayerNPC.h"
#include "..\World\WorldManager.h"
#include "..\WxRender\RenderSystem.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Procedure\CysOfflineUiCapture.h"
#include "..\Action\GMActionSystem.h"
#include "..\Event\GMEventSystem.h"
#include "..\DBC\GMDataBase.h"
#include "TDDBC_Struct.h"
#include "TDEventDefine.h"
#include "TDUtil.h"
#include <cstring>
#include <cstdarg>
#include <string>
#include "CysPetUpgradeData.inl"
#include "../FakeObject/GMFakeObjSystem.h"
#include "PgPackets_pet.h"
#include "PgPackets_item.h"

#if defined(CYS_HAVE_NETCORE)
#include "CysModernGame.h"
#include "PgPackets_pet_detail_types.h"
#include "PgPackets_movement.h"
#include "PgPackets_misc.h"
#include "CGManipulatePet.h"
#include "CGSetPetAttrib.h"
#endif

// CYS-PETSKILL 19/09 (pet-skill-12): the two pet skill counts, asserted where they are used so a later edit of
// either enum fails the build instead of silently shrinking the pet window back to six buttons.
//   PET_MAX_SKILL_COUNT = PET_SKILL_INDEX_NUMBERS  - the CLIENT pool / CY wire count (13 = 2 activate + 11 positive)
//   MAX_PET_SKILL_COUNT                            - the 0.85 GCDetailAttrib_Pet packet array, deliberately still 6
// The server itself fills at most 12 of the 13 (pet_detail.lua get_skill_max_control_by_player = 2 and _by_ai = 10),
// which is exactly the PETSKILL_BUTTONS_NUM = 12 of the CY Pet window; cell 13 is always INVAILD_ID on the wire.
static_assert(PET_MAX_SKILL_COUNT == 13, "CYS-PETSKILL: the CY pet record carries 13 skill cells");
static_assert(PET_SKILL_INDEX_MENPAI == 5, "CYS-PETSKILL: the six 0.85 cells keep their index");
static_assert(PET_SKILL_INDEX_CY_POSITIVE_5 == 6, "CYS-PETSKILL: the first cell CY added is index 6");
static_assert(PET_SKILL_INDEX_CY_POSITIVE_11 == 12, "CYS-PETSKILL: the last cell is index 12");
static_assert(MAX_PET_SKILL_COUNT == 6, "CYS-PETSKILL: the 0.85 packet array must NOT follow the pool count");

namespace
{
    // ---- state ---------------------------------------------------------------------------------------------------
    // B lets the "used by window N" marker live in the pet record; 0.85's record has no room for it, so it is kept
    // beside the slot. The GUID that was in the slot when the marker was set is stored with it: if the slot is emptied
    // or reused by another pet (GCRemovePet / GCDetailAttrib_Pet), the marker of the old pet is not answered for the
    // new one.
    struct PetMark { UINT high; UINT low; int location; };
    PetMark g_mark[HUMAN_PET_MAX_COUNT] = {};
    UINT g_soulHigh = 0, g_soulLow = 0;

    // The CY-only cells of the pet record (no field in the 0.85 SDATA_PET), keyed by the GUID of the pet in the slot.
    struct PetCy
    {
        UINT high, low;
        int lingxing, mindAttack, mindDefend, wuxing, usedProcreate, petType, attackType, growPerMille, titleCount, hasEquip;
        int mainPerception;   // CYS-PETSKILL: main_perception, the band selector of PetLingXing (server: con_perception)
        int element[12];   // [kind * 4 + element]: kind 0 ATTACK (att_), 1 DEFENCE (def_), 2 RESISTOTHER (reduce_def_)
    };
    PetCy g_cy[HUMAN_PET_MAX_COUNT] = {};
    PetCy g_targetCy = {};
    // CYS-PETSKILL 19/09: Pet:IsFreeing. B keeps the "放生 sent, waiting for the server" flag in its own pet record
    // and the CY Pet window reads it back before it lets a second 放生 through (Pet.lua:2060). 0.85's SDATA_PET has
    // no such field, so the flag lives here, keyed by the pet GUID, and is cleared by the server's own answer
    // (GCManipulatePetRet FREESUCC / FREEFALID, or GCRemovePet when the pet is gone).
    struct PetFreeing { UINT high, low; bool pending; };
    PetFreeing g_freeing = { 0, 0, false };
    bool g_stateInit = false;
    int g_selectedPet = -1;              // Pet:SetSelectPetIdx (B: the int at +0x70 of the four pet preview objects)
    CysPetNet::Counters g_counters = {};
    unsigned g_logs = 0;

    void PetLog(const char* fmt, ...)
    {
        if (g_logs++ >= 200) return;
        char text[512] = {};
        va_list args; va_start(args, fmt);
        _vsnprintf(text, sizeof(text) - 1, fmt, args);
        va_end(args);
        TDU_Log("CYS pet: %s", text);
    }

    void ResetCyData(PetCy& cy)
    {
        std::memset(&cy, 0, sizeof(cy));
        cy.lingxing = cy.mindAttack = cy.mindDefend = cy.wuxing = -1;
        cy.usedProcreate = cy.petType = cy.attackType = -1;
        cy.growPerMille = -1000;
        cy.mainPerception = -1;
    }
    void ResetCy(int i) { ResetCyData(g_cy[i]); }

    void InitState()
    {
        if (g_stateInit) return;
        for (int i = 0; i < HUMAN_PET_MAX_COUNT; ++i)
        {
            g_mark[i].high = 0; g_mark[i].low = 0; g_mark[i].location = -1;
            ResetCy(i);
        }
        g_freeing.high = g_freeing.low = 0; g_freeing.pending = false;   // CYS-PETSKILL
        g_stateInit = true;
    }

    SDATA_PET* PetAt(int index)
    {
        if (index < 0 || index >= HUMAN_PET_MAX_COUNT) return NULL;
        CDataPool* pool = CDataPool::GetMe();
        if (!pool) return NULL;
        SDATA_PET* pet = pool->Pet_GetPet(index);
        if (!pet || pet->m_nIsPresent == INVALID_ID) return NULL;
        return pet;
    }

    // The CY cells of slot `index`, only while the slot still holds the pet they were stored for.
    const PetCy* CyAt(int index)
    {
        InitState();
        SDATA_PET* pet = PetAt(index);
        if (!pet) return NULL;
        const PetCy& cy = g_cy[index];
        if (cy.high != pet->m_GUID.m_uHighSection || cy.low != pet->m_GUID.m_uLowSection) return NULL;
        return &cy;
    }

    CObject_PlayerMySelf* Self()
    {
        return CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : NULL;
    }

    bool IsMain()
    {
        return CGameProcedure::GetActiveProcedure() == (CGameProcedure*)CGameProcedure::s_pProcMain;
    }

    // ---- Services of LuaApiGen/CysHost_Pet.cpp ------------------------------------------------------------
    int HostPetLocation(void*, int index) { return CysPetNet::PetLocation(index); }
    void HostSetPetLocation(void*, int index, int location) { CysPetNet::SetPetLocation(index, location); }

    void HostUpdatePetList(void*)
    {
        if (CEventSystem::GetMe()) CEventSystem::GetMe()->PushEvent(GE_UPDATE_PET_LIST);
    }

    int HostPetIndexByGuid(void*, UINT high, UINT low)
    {
        CDataPool* pool = CDataPool::GetMe();
        if (!pool) return -1;
        PET_GUID_t guid;
        guid.m_uHighSection = high;
        guid.m_uLowSection = low;
        if (guid.IsNull()) return -1;
        return pool->Pet_GetPetByGuid(guid);
    }

    int HostPetGeneration(void*, int index)
    {
        SDATA_PET* pet = PetAt(index);
        return pet ? pet->m_nEraCount : -1;
    }

    bool HostHaveCurrentPet(void*)
    {
        CObject_PlayerMySelf* self = Self();
        if (!self) return false;
        CCharacterData* data = self->GetCharacterData();
        CDataPool* pool = CDataPool::GetMe();
        if (!data || !pool) return false;
        const PET_GUID_t guid = data->Get_CurrentPetGUID();
        if (guid.IsNull()) return false;
        SDATA_PET* pet = pool->Pet_GetPet(guid);
        return pet != NULL && pet->m_nIsPresent != INVALID_ID;
    }

    int HostLingxing(void*, int i) { return CysPetNet::Lingxing(i); }
    bool HostIsPossession(void*, int i) {
        SDATA_PET* pet = PetAt(i);
        return pet && pet->m_GUID.m_uHighSection == g_soulHigh && pet->m_GUID.m_uLowSection == g_soulLow;
    }
    int HostPossessionIndex(void*) { return CysPetNet::PossessionIndex(); }
    void SendPossession(int i, bool separate) {
#if defined(CYS_HAVE_NETCORE)
        SDATA_PET* pet = PetAt(i);
        if (!pet || (separate && !HostIsPossession(nullptr, i))) return;
        std::unique_ptr<pg::CGManipulatePet> out(new pg::CGManipulatePet);
        out->pet_guid.m_uHighSection = pet->m_GUID.m_uHighSection;
        out->pet_guid.m_uLowSection = pet->m_GUID.m_uLowSection;
        out->m_objID = Self() ? Self()->GetServerID() : 0;
        out->type = separate ? 5 : 4;
        CysModernGame::SendModern(std::move(out));
#endif
    }
    void HostPossessionPet(void*, int i) { SendPossession(i, false); }
    void HostRestorePet(void*, int i) { SendPossession(i, true); }
    // CY PetLingXingUp.lua displays chance and aptitude bonus of the NEXT level.
    int HostLingxingNext(void*, int i, bool chance) {
        auto pet=PetAt(i);auto cy=CyAt(i);if(!pet||!cy)return 0;
        const int level=cy->lingxing-100;if(level<0||level>=10)return 0;
        auto db=CDataBaseSystem::GetMe()->GetDataBase(DBC_PET_LINGXING);if(!db)return 0;
        for(int n=0;n<(int)db->GetRecordsNum();++n){
            auto row=(const _DBC_PET_LINGXING*)db->Search_LineNum_EQU(n);
            if(row && row->nPetType==pet->m_nDataID && row->nMainPerceptionMin<=cy->mainPerception && cy->mainPerception<row->nMainPerceptionMax)
                return chance?row->nUpPercent[level]:row->nBonus[level];
        }
        return 0;
    }
    void HostSkillLevelupInfo(void*, int skill, int index, int* values) {
        if(!PetAt(index))return;
        for(const auto& row:kCyPetUpgrade){
            if(row[0]!=skill)continue;
            for(int k=0;k<6;++k)values[k]=row[k+1];
            return;
        }
    }
    int HostMindAttack(void*, int i) { return CysPetNet::MindAttack(i); }
    int HostMindDefend(void*, int i) { return CysPetNet::MindDefend(i); }
    int HostWuxing(void*, int i) { return CysPetNet::Wuxing(i); }
    int HostTitleCount(void*, int i) { return CysPetNet::TitleCount(i); }
    int HostGrowRate(void*, int i) { return CysPetNet::GrowRatePerMille(i); }
    int HostPetType(void*, int i) { return CysPetNet::PetType(i); }
    int HostUsedProcreate(void*, int i) { return CysPetNet::UsedProcreateCount(i); }
    int HostHasEquip(void*, int i) { return CysPetNet::HasEquip(i); }
    void HostSetSelectedPet(void*, int i) { CysPetNet::SetSelectedPet(i); }
    bool HostElementOfSelected(void*, const char* key, int& value) { return CysPetNet::ElementOfSelected(key, value); }
    int HostSkillIdAt(void*, int i, int pos) { return CysPetNet::SkillIdAt(i, pos); }
    // CYS-PETSKILL (19/09)
    bool HostAttackTrait(void*, int i, const char** name, const char** icon)
    {
        const char* n = "";
        const char* c = "";
        const bool ok = CysPetNet::AttackTrait(i, n, c);
        if (name) *name = n;
        if (icon) *icon = c;
        return ok;
    }
    int HostAttackTraitId(void*, int i) { return CysPetNet::AttackType(i); }
    int HostPercentLx(void*, int i) { return CysPetNet::PercentLx(i); }
    int HostIsFreeing(void*, int i) { return CysPetNet::IsFreeing(i); }
    int HostTakeLevel(void*, int i) { return CysPetNet::TakeLevel(i); }
    int HostGrowLevel(void*, int i, int rate) { return CysPetNet::GrowLevel(i, rate); }

    // PetAttrTable row of the pet in slot `index` (CY 54-column layout of _DBC_PET_EX_ATT; B reads the same cells of
    // its 51-column GL table: +0x14 take level, +0x24 food type, +0xa4.. the growth thresholds).
    const _DBC_PET_EX_ATT* PetRow(int index)
    {
        SDATA_PET* pet = PetAt(index);
        if (!pet || pet->m_nDataID < 0) return NULL;
        const tDataBase* db = CDataBaseSystem::GetMe() ? CDataBaseSystem::GetMe()->GetDataBase(DBC_PET_EX_ATT) : NULL;
        return db ? (const _DBC_PET_EX_ATT*)db->Search_Index_EQU(pet->m_nDataID) : NULL;
    }

    // ---- CYS-PET probe (CYS_PET_PROBE=1, evidence runs only; same idea as CYS_POWER_PROBE) ---------------------
    // Drives the host functions THROUGH LUA on the client's own timer and writes what they answer to WXClient.log.
    // pet-gc512: once the bag has arrived it also opens the CY Pet window (TogglePetPage, the main-menu button's own
    // call) and captures it; with CYS_PET_PROBE_SUMMON=1 it then presses the window's own summon / recall host
    // functions (Pet:Go_Fight / Pet:Go_Relax) on slot 0 and captures both states.
    //
    // The stages wait for an OBSERVED STATE CHANGE (Player:IsHaveCurrentPet flipping true then false), never for a
    // number of timer ticks: the client's SetTimer repeats in bursts - live-2 ran ticks 16..24 inside the same second -
    // so a "wait N ticks" gate fires before the server's GCManipulatePetRet arrives and captures the previous state
    // (live-2's "recalled" PNG was byte-identical to "summoned" for exactly that reason).
    int LuaProbeLog(LuaPlus::LuaState* state)
    {
        LuaPlus::LuaStack args(state);
        TDU_Log("CYS-PET probe: %s", args[2].IsString() ? args[2].GetString() : "?");
        return 0;
    }

    // Pet:CysPetProbeCounters(): the module's counters as one log line. They are the only way to see that nothing was
    // dropped silently - detailDropped > 0 would mean a GCDetailAttrib_Pet found no slot (or carried a trade/stall
    // view), skillsBeyondSlots > 0 that a REAL skill did not fit the six 0.85 slots.
    int LuaProbeCounters(LuaPlus::LuaState* state)
    {
        (void)state;
        const CysPetNet::Counters c = CysPetNet::Get();
        TDU_Log("CYS-PET probe: counters detail=%u applied=%u target=%u dropped=%u new_pets=%u removed=%u "
                "manipulate_ret=%u manipulate_sent=%u skills_beyond_slots=%u",
                c.detailPackets, c.detailApplied, c.detailTarget, c.detailDropped, c.newPets, c.removedPets,
                c.manipulateRets, c.manipulateSent, c.skillsBeyondSlots);
        return 0;
    }

    int LuaProbeShot(LuaPlus::LuaState* state)
    {
        LuaPlus::LuaStack args(state);
        const char* label = args[2].IsString() ? args[2].GetString() : "shot";
        char path[MAX_PATH] = {};
        CreateDirectoryA("..\\ScreenShots", NULL);
        // The run id keeps every capture unique. run_world_gui_live.ps1 only copies PNGs that were NOT in the folder
        // before the run, so a fixed name is silently left behind when an earlier (even aborted) run made one - that
        // is how live-2's Pet-window capture stayed in the stage instead of the evidence folder.
        static const unsigned long s_run = ::GetTickCount();
        _snprintf(path, MAX_PATH - 1, "..\\ScreenShots\\cys-pet-%lu-%s.png", s_run, label);
        try
        {
            cysCaptureOfflineUi(CGameProcedure::s_pGfxSystem, path);
            TDU_Log("CYS-PET probe: capture=%s file=%s", label, path);
        }
        catch (const std::exception& e)
        {
            TDU_Log("CYS-PET probe: capture %s failed: %s", label, e.what());
        }
        return 0;
    }

    const char* const kProbeChunk =
        "CysPetProbeRuns = 0\n"
        "CysPetProbeOpened = false\n"
        "CysPetProbeShot = false\n"
        "CysPetProbeStage = 0\n"
        "CysPetProbeMark = 0\n"
        "CysPetProbeSummon = CysPetProbeSummon or 0\n"
        "function CysPetProbe_Slot(i)\n"
        "  local hi, lo = Pet:GetGUID(i)\n"
        "  local before = Pet:GetPetLocation(i)\n"
        "  Pet:SetPetLocation(i, 12)\n"
        "  local set12 = Pet:GetPetLocation(i)\n"
        "  Pet:SetPetLocation(i, -1)\n"
        "  Pet:CysPetProbeLog('slot ' .. i .. ' name=' .. tostring(Pet:GetPetList_Appoint(i))"
        "    .. ' guid=' .. tostring(hi) .. '/' .. tostring(lo)"
        "    .. ' level=' .. tostring(Pet:GetLevel(i)) .. ' hp=' .. tostring(Pet:GetHP(i)) .. '/' .. tostring(Pet:GetMaxHP(i))"
        "    .. ' happy=' .. tostring(Pet:GetHappy(i)) .. ' life=' .. tostring(Pet:GetNaturalLife(i))"
        "    .. ' aitype=' .. tostring(Pet:GetAIType(i)) .. ' str=' .. tostring(Pet:GetStr(i)) .. ' strapt=' .. tostring(Pet:GetStrAptitude(i))"
        "    .. ' basic=' .. tostring(Pet:GetBasic(i)) .. ' pot=' .. tostring(Pet:GetPotential(i))"
        "    .. ' patt=' .. tostring(Pet:GetPhysicsAttack(i)) .. ' pdef=' .. tostring(Pet:GetPhysicsRecovery(i))"
        "    .. ' hit=' .. tostring(Pet:GetShootProbability(i)) .. ' miss=' .. tostring(Pet:GetMiss(i)))\n"
        "  Pet:CysPetProbeLog('slot ' .. i .. ' cy: lixing=' .. tostring(Pet:GetLixing(i))"
        "    .. ' crit=' .. tostring(Pet:GetCriticalAttack(i)) .. '/' .. tostring(Pet:GetCriticalDefence(i))"
        "    .. ' savvy=' .. tostring(Pet:GetSavvy(i)) .. ' titles=' .. tostring(Pet:GetTitleNum(i))"
        "    .. ' grow=' .. tostring(Pet:GetGrowRate(i)) .. ' type=' .. tostring(Pet:GetPetType(i))"
        "    .. ' procreate=' .. tostring(Pet:GetLastProcreateLevel(i)) .. ' equip=' .. tostring(Pet:IsPetHaveEquip(i))"
        "    .. ' take=' .. tostring(Pet:GetTakeLevel(i)) .. ' growlvl=' .. tostring(Pet:GetPetGrowLevel(i, Pet:GetGrowRate(i)))"
        "    .. ' skill0=' .. tostring(Pet:GetSkillIDbyIndex(i, 0)) .. ' gen=' .. tostring(Pet:GetGeneration(i))"
        "    .. ' idx=' .. tostring(Pet:GetPetIndexByGUID(hi, lo)) .. ' fighting=' .. tostring(Pet:GetIsFighting(i))"
        "    .. ' loc=' .. tostring(before) .. '/' .. tostring(set12) .. '/' .. tostring(Pet:GetPetLocation(i)))\n"
        // CYS-PETSKILL 19/09: the 12-button proof, measured through the SAME two paths the window uses.
        //   ids    = Pet:GetSkillIDbyIndex(i, pos) - the pool cell (0..PET_MAX_SKILL_COUNT-1)
        //   act    = Pet:EnumPetSkill(i, pos, 'petskill'):GetID() - the ACTION Pet.lua feeds to PETSKILL_BUTTONS[k]
        // Before this branch, pos 6..12 could not exist in either: PutSkill dropped them and UserPetSkill_Update
        // looped to MAX_PET_SKILL_COUNT = 6. `nid`/`nact` are the two numbers to compare between runs.
        "  local ids, acts, nid, nact = '', '', 0, 0\n"
        "  for pos = 0, 12 do\n"
        "    local id = Pet:GetSkillIDbyIndex(i, pos)\n"
        "    ids = ids .. tostring(id) .. ' '\n"
        "    if tonumber(id) ~= nil and tonumber(id) >= 0 then nid = nid + 1 end\n"
        "    local a = Pet:EnumPetSkill(i, pos, 'petskill')\n"
        "    local aid = 0\n"
        "    if a ~= nil then aid = a:GetID() end\n"
        "    acts = acts .. tostring(aid) .. ' '\n"
        "    if aid ~= 0 then nact = nact + 1 end\n"
        "  end\n"
        "  local tname, ticon = Pet:GetAttackTrait(i)\n"
        "  Pet:CysPetProbeLog('slot ' .. i .. ' petskill: nid=' .. nid .. ' nact=' .. nact"
        "    .. ' ids=[' .. ids .. '] actions=[' .. acts .. ']')\n"
        "  Pet:CysPetProbeLog('slot ' .. i .. ' petskill12: trait_id=' .. tostring(Pet:GetAttackTraitID(i))"
        "    .. ' trait_icon=' .. tostring(ticon) .. ' trait_name_len=' .. tostring(string.len(tostring(tname)))"
        "    .. ' percent_lx=' .. tostring(Pet:GetPercent_Lx(i)) .. ' freeing=' .. tostring(Pet:IsFreeing(i)))\n"
        "end\n"
        "function CysPetProbe_Tick()\n"
        "  CysPetProbeRuns = CysPetProbeRuns + 1\n"
        "  if CysPetProbeRuns > 80 or CysPetProbeStage >= 9 then return end\n"
        "  local ok, err = pcall(function()\n"
        "    local n = Pet:GetPet_Count()\n"
        "    Pet:CysPetProbeLog('run=' .. CysPetProbeRuns .. ' Pet:GetPet_Count()=' .. tostring(n)"
        "      .. ' Player:IsHaveCurrentPet()=' .. tostring(Player:IsHaveCurrentPet())"
        "      .. ' DataPool:GetLeftProtectTime()=' .. tostring(DataPool:GetLeftProtectTime())"
        "      .. ' Pet:GetPetIndexByGUID(0,0)=' .. tostring(Pet:GetPetIndexByGUID(0,0)))\n"
        "    if CysPetProbeRuns <= 2 or math.mod(CysPetProbeRuns, 10) == 0 then\n"
        "      for i = 0, 5 do\n"
        "        if Pet:IsPresent(i) then CysPetProbe_Slot(i)\n"
        "        else Pet:CysPetProbeLog('slot ' .. i .. ' empty loc=' .. tostring(Pet:GetPetLocation(i))) end\n"
        "      end\n"
        "    end\n"
        "    if n > 0 and not CysPetProbeOpened then\n"
        "      Pet:SetSelectPetIdx(0)\n"
        "      Pet:CysPetProbeLog('GetData(sel 0): ATTACKCOLD=' .. tostring(Pet:GetData('ATTACKCOLD'))"
        "        .. ' DEFENCEFIRE=' .. tostring(Pet:GetData('DEFENCEFIRE')) .. ' RESISTOTHERPOISON=' .. tostring(Pet:GetData('RESISTOTHERPOISON')))\n"
        "      Pet:UpdatePetList()\n"
        "      TogglePetPage()\n"
        "      CysPetProbeOpened = true\n"
        "      CysPetProbeMark = CysPetProbeRuns\n"
        "      Pet:CysPetProbeLog('TogglePetPage() called at run ' .. CysPetProbeRuns)\n"
        // CYS-PETSKILL 19/09: chụp ở nhịp NGAY SAU khi mở khung (+1), không phải +3. Lượt live-gui-2 chết ở giây
        // thứ 8 sau khi vào thế giới, tức 4 s sau TogglePetPage(), nên cổng +3 nhịp (~9 s) không bao giờ tới:
        // số đo 12 ô có đủ nhưng ẢNH KHUNG thì mất. Bằng chứng nào cần mắt người thì phải chụp SỚM NHẤT có thể.
        "    elseif CysPetProbeOpened and not CysPetProbeShot and CysPetProbeRuns >= CysPetProbeMark + 1 then\n"
        "      CysPetProbeShot = true\n"
        "      Pet:CysPetProbeShot('frame')\n"
        "      CysPetProbeMark = CysPetProbeRuns\n"
        "      if CysPetProbeSummon ~= 1 then TogglePetPage() Pet:CysPetProbeCounters() CysPetProbeStage = 9 end\n"
        "    elseif CysPetProbeShot and CysPetProbeSummon == 1 then\n"
        "      if CysPetProbeStage == 0 then\n"
        "        Pet:Go_Fight(0)\n"
        "        Pet:CysPetProbeLog('Pet:Go_Fight(0) called at run ' .. CysPetProbeRuns)\n"
        "        CysPetProbeStage = 1\n"
        "        CysPetProbeMark = CysPetProbeRuns\n"
        // STATE GATE, not a tick count: wait until GCManipulatePetRet ret=3 CALLUPSUCC has set the current pet GUID.
        "      elseif CysPetProbeStage == 1 and Player:IsHaveCurrentPet() then\n"
        "        Pet:CysPetProbeLog('after Go_Fight (run ' .. CysPetProbeRuns .. ', waited ' .. (CysPetProbeRuns - CysPetProbeMark)"
        "          .. ' ticks): Player:IsHaveCurrentPet()=true Pet:GetIsFighting(0)=' .. tostring(Pet:GetIsFighting(0)))\n"
        "        Pet:CysPetProbeShot('summoned')\n"
        "        Pet:Go_Relax(0)\n"
        "        Pet:CysPetProbeLog('Pet:Go_Relax(0) called at run ' .. CysPetProbeRuns)\n"
        "        CysPetProbeStage = 2\n"
        "        CysPetProbeMark = CysPetProbeRuns\n"
        // ... and until ret=7 RECALLSUCC has cleared it again. Capturing on a tick count photographed the summoned
        // pet and called it "recalled" (live-2: both PNGs byte-identical).
        "      elseif CysPetProbeStage == 2 and not Player:IsHaveCurrentPet() then\n"
        "        Pet:CysPetProbeLog('after Go_Relax: Player:IsHaveCurrentPet()=' .. tostring(Player:IsHaveCurrentPet())"
        "          .. ' Pet:GetIsFighting(0)=' .. tostring(Pet:GetIsFighting(0)))\n"
        "        Pet:CysPetProbeShot('recalled')\n"
        "        TogglePetPage()\n"
        "        Pet:CysPetProbeCounters()\n"
        "        CysPetProbeStage = 9\n"
        "      end\n"
        "    end\n"
        "  end)\n"
        "  if not ok then Pet:CysPetProbeLog('ERROR ' .. tostring(err)) end\n"
        // CYS-PETSKILL 19/09: 1500 ms thay vì 3000. Đo trên ba nhánh hôm nay, lượt nào chết thì chết ở giây
        // 37-40 của tiến trình (audio meter t_ms 37407 / 38218 / 39828) — trong khi vào được thế giới đã mất ~31 s.
        // Nhịp 3 s đẩy ảnh khung ra ngoài cửa sổ đó; 1,5 s thì ảnh rơi vào ~34-35 s.
        "  if CysPetProbeStage < 9 then SetTimer('CysPetProbe', 'CysPetProbe_Tick()', 1500) end\n"
        "end\n"
        "SetTimer('CysPetProbe', 'CysPetProbe_Tick()', 1500)\n";

    void StartProbe(LuaPlus::LuaState* state)
    {
        char probe[8] = {};
        ::GetEnvironmentVariableA("CYS_PET_PROBE", probe, sizeof(probe));
        if (probe[0] != '1') return;
        LuaPlus::LuaObject globals = state->GetGlobals();
        LuaPlus::LuaObject petTable = globals.GetByName("Pet");
        if (petTable.IsUserData())
        {
            LuaPlus::LuaObject meta = petTable.GetMetaTable();
            LuaPlus::LuaObject index = meta.IsTable() ? meta.GetByName("__index") : LuaPlus::LuaObject();
            petTable = index.IsTable() ? index : meta;
        }
        if (!petTable.IsTable()) { TDU_Log("CYS-PET probe: no Pet receiver"); return; }
        petTable.Register("CysPetProbeLog", LuaProbeLog);
        petTable.Register("CysPetProbeShot", LuaProbeShot);
        petTable.Register("CysPetProbeCounters", LuaProbeCounters);
        char summon[8] = {};
        ::GetEnvironmentVariableA("CYS_PET_PROBE_SUMMON", summon, sizeof(summon));
        state->DoString(summon[0] == '1' ? "CysPetProbeSummon = 1" : "CysPetProbeSummon = 0");
        state->DoString(kProbeChunk);
        TDU_Log("CYS-PET probe: armed (CYS_PET_PROBE=1, summon=%s), first tick in 3000 ms", summon[0] == '1' ? "1" : "0");
    }
}

// ---- marker ------------------------------------------------------------------------------------------------------
int CysPetNet::PetLocation(int index)
{
    InitState();
    SDATA_PET* pet = PetAt(index);
    if (!pet) return -1;
    const PetMark& mark = g_mark[index];
    if (mark.high != pet->m_GUID.m_uHighSection || mark.low != pet->m_GUID.m_uLowSection) return -1;
    return mark.location;
}

void CysPetNet::SetPetLocation(int index, int location)
{
    InitState();
    SDATA_PET* pet = PetAt(index);
    if (!pet) return; // B ignores the call for an empty slot too (it never reaches the store)
    g_mark[index].high = pet->m_GUID.m_uHighSection;
    g_mark[index].low = pet->m_GUID.m_uLowSection;
    g_mark[index].location = location;
}

// ---- CY-only cells ------------------------------------------------------------------------------------------------
int CysPetNet::Lingxing(int index) { const PetCy* c = CyAt(index); return c ? c->lingxing : -1; }
int CysPetNet::MindAttack(int index) { const PetCy* c = CyAt(index); return c ? c->mindAttack : -1; }
int CysPetNet::MindDefend(int index) { const PetCy* c = CyAt(index); return c ? c->mindDefend : -1; }
int CysPetNet::Wuxing(int index) { const PetCy* c = CyAt(index); return c ? c->wuxing : -1; }
int CysPetNet::TitleCount(int index) { const PetCy* c = CyAt(index); return c ? c->titleCount : 0; }
int CysPetNet::GrowRatePerMille(int index) { const PetCy* c = CyAt(index); return c ? c->growPerMille : -1000; }
int CysPetNet::PetType(int index) { const PetCy* c = CyAt(index); return c ? c->petType : -1; }
int CysPetNet::UsedProcreateCount(int index) { const PetCy* c = CyAt(index); return c ? c->usedProcreate : -1; }
int CysPetNet::HasEquip(int index) { const PetCy* c = CyAt(index); return c ? c->hasEquip : 0; }
void CysPetNet::SetSelectedPet(int index) { g_selectedPet = index; }
int CysPetNet::SelectedPet() { return g_selectedPet; }

bool CysPetNet::ElementOfSelected(const char* key, int& value)
{
    value = 0;
    if (!key) return false;
    int kind = -1; size_t skip = 0;
    if (std::strncmp(key, "ATTACK", 6) == 0) { kind = 0; skip = 6; }
    else if (std::strncmp(key, "DEFENCE", 7) == 0) { kind = 1; skip = 7; }
    else if (std::strncmp(key, "RESISTOTHER", 11) == 0) { kind = 2; skip = 11; }
    if (kind < 0) return false;
    int element = -1;
    const char* rest = key + skip;
    if (std::strcmp(rest, "COLD") == 0) element = 0;
    else if (std::strcmp(rest, "FIRE") == 0) element = 1;
    else if (std::strcmp(rest, "LIGHT") == 0) element = 2;
    else if (std::strcmp(rest, "POISON") == 0) element = 3;
    if (element < 0) return false;
    // B: the index stored by SetSelectPetIdx must be a slot (it tests "> 9" and then Pet_GetPet); an empty or
    // unset selection answers 0, the value the stub answered too.
    const PetCy* c = CyAt(g_selectedPet);
    if (!c) return true;
    value = c->element[kind * 4 + element];
    return true;
}

int CysPetNet::SkillIdAt(int index, int pos)
{
    CDataPool* pool = CDataPool::GetMe();
    if (!pool || !PetAt(index)) return -1;
    PET_SKILL* skill = pool->Pet_GetSkill(index, pos);
    return (skill && skill->m_pDefine) ? skill->m_pDefine->m_nID : -1;
}

int CysPetNet::TakeLevel(int index)
{
    const _DBC_PET_EX_ATT* row = PetRow(index);
    return row ? row->m_TakeLevel : 0;
}

int CysPetNet::GrowLevel(int index, int ratePerMille)
{
    if (ratePerMille < 0) return -1;
    const _DBC_PET_EX_ATT* row = PetRow(index);
    if (!row) return -1;
    if (ratePerMille <= row->m_GrowRate0) return 0;
    if (ratePerMille <= row->m_GrowRate1) return 1;
    if (ratePerMille <= row->m_GrowRate2) return 2;
    return (ratePerMille > row->m_GrowRate3) ? 4 : 3;
}

// ---- CYS-PETSKILL 19/09 (pet-skill-12) ------------------------------------------------------------------------
int CysPetNet::AttackType(int index) { const PetCy* c = CyAt(index); return c ? c->attackType : -1; }
int CysPetNet::MainPerception(int index) { const PetCy* c = CyAt(index); return c ? c->mainPerception : -1; }





bool CysPetNet::AttackTrait(int index, const char*& name, const char*& icon)
{
    name = "";
    icon = "";
    const int type = AttackType(index);
    if (type < 0) return false;
    const tDataBase* db = CDataBaseSystem::GetMe() ? CDataBaseSystem::GetMe()->GetDataBase(DBC_PET_ATTACK_TRAIT) : NULL;
    if (!db) return false;
    const _DBC_PET_ATTACK_TRAIT* row =
        (const _DBC_PET_ATTACK_TRAIT*)db->Search_Index_EQU((INT)(short)type);
    if (!row) return false;
    if (row->szName) name = row->szName;
    if (row->szIcon) icon = row->szIcon;
    return true;
}






int CysPetNet::PercentLx(int index)
{
    SDATA_PET* pet = PetAt(index);
    const PetCy* cy = CyAt(index);
    if (!pet || !cy) return 0;
    const int level = cy->lingxing - 101;           // server: lingxing = 100 + 灵性 level, 0 while not awakened
    if (level < 0 || level >= 10) return 0;
    const tDataBase* db = CDataBaseSystem::GetMe() ? CDataBaseSystem::GetMe()->GetDataBase(DBC_PET_LINGXING) : NULL;
    if (!db) return 0;
    const INT rows = (INT)db->GetRecordsNum();
    for (INT i = 0; i < rows; ++i)
    {
        const _DBC_PET_LINGXING* row = (const _DBC_PET_LINGXING*)db->Search_LineNum_EQU(i);
        if (!row || row->nPetType != pet->m_nDataID) continue;
        if (row->nMainPerceptionMin > cy->mainPerception || cy->mainPerception >= row->nMainPerceptionMax) continue;
        return row->nBonus[level];
    }
    return 0;
}

int CysPetNet::IsFreeing(int index)
{
    InitState();
    SDATA_PET* pet = PetAt(index);
    if (!pet || !g_freeing.pending) return 0;
    return (g_freeing.high == pet->m_GUID.m_uHighSection && g_freeing.low == pet->m_GUID.m_uLowSection) ? 1 : 0;
}

CysPetNet::Counters CysPetNet::Get() { return g_counters; }

int CysPetNet::PossessionIndex() { return HostPetIndexByGuid(nullptr, g_soulHigh, g_soulLow); }
void CysPetNet::OnSoulPetGuid(unsigned high, unsigned low) {
    if (g_soulHigh == high && g_soulLow == low) return;
    g_soulHigh = high; g_soulLow = low;
    if (CEventSystem::GetMe()) CEventSystem::GetMe()->PushEvent(GE_UPDATE_PET_PAGE);
}

void CysPetNet::OnCurrentPetGuid(unsigned high, unsigned low)
{
    CObject_PlayerMySelf* self = Self();
    if (!self || !self->GetCharacterData()) return;
    PET_GUID_t guid;
    guid.m_uHighSection = high;
    guid.m_uLowSection = low;
    const PET_GUID_t old = self->GetCharacterData()->Get_CurrentPetGUID();
    if (old != guid) PetLog("current pet guid %u:%u -> %u:%u (GCDetailAttrib)", old.m_uHighSection, old.m_uLowSection, high, low);
    self->GetCharacterData()->Set_CurrentPetGUID(guid);   // pushes GE_UPDATE_PET_PAGE + tool bar refresh when it changes
}

// ---- packets -------------------------------------------------------------------------------------------------------
#if defined(CYS_HAVE_NETCORE)
namespace
{
    bool Has(const int64_t* f, int index1, int64_t mask) { return (pg::at1(f, 11, index1) & mask) == mask; }

    void SetGuid(PET_GUID_t& out, const pg::PetGUID& in)
    {
        out.m_uHighSection = in.m_uHighSection;
        out.m_uLowSection = in.m_uLowSection;
    }

    // One CY skill cell (id -1 = empty, the server's define.INVAILD_ID) into skill slot `pos` of the bag pet `slot`
    // (or of the target pet when slot < 0). Pet_SetSkill resolves the id in DBC_SKILL_DATA and clears the slot when
    // the id is unknown - the same path the 0.85 handler used for its six _OWN_SKILL cells.
    void PutSkill(int slot, int pos, int32_t id)
    {
        CDataPool* pool = CDataPool::GetMe();
        if (!pool) return;
        if (pos >= PET_MAX_SKILL_COUNT)
        {
            if (id >= 0) ++g_counters.skillsBeyondSlots;
            return;
        }
        // Only touch the pool when the slot really changes. The server sets ALL 13 skill flags on every refresh -
        // pet_detail_types.lua set_activate_skill_1(nil) -> "skill = skill or define.INVAILD_ID" still sets the flag -
        // so a pet with no skills still carries 13 cells of -1. Each Pet_SetSkill runs CActionSystem::CleanInvalidAction
        // over the whole action map and pushes GE_UPDATE_PET_PAGE, i.e. 6 pointless UI refreshes per pet per packet
        // (30 for the 5 pets of CYTest14) while the pet window is open.
        PET_SKILL* current = (slot < 0) ? pool->TargetPet_GetSkill(pos) : pool->Pet_GetSkill(slot, pos);
        const int currentId = (current && current->m_pDefine) ? current->m_pDefine->m_nID : -1;
        if (currentId == id) return;
        _OWN_SKILL own;
        own.m_nSkillID = static_cast<SkillID_t>(id);
        if (slot < 0) pool->TargetPet_SetSkill(pos, &own);
        else pool->Pet_SetSkill(slot, pos, &own);
    }

    // CYS-PETSKILL 19/09: how many of the 13 CY skill cells carry a real id (>= 0). The server sets all 13 flags on
    // every refresh even for a pet with no skill at all (set_activate_skill_1(nil) -> INVAILD_ID still sets the flag),
    // so the flags alone say nothing - only the ids do. This is the number the "12 buttons" work has to move.
    int CountWireSkills(const pg::GCDetailAttrib_Pet& p, const int64_t* f)
    {
        const struct { int index1; int64_t mask; int32_t id; } cells[13] = {
            {6, 0x04, p.skills_activate_1_id}, {6, 0x08, p.skills_activate_2_id},
            {6, 0x10, p.skills_positive_1_id}, {6, 0x20, p.skills_positive_2_id},
            {6, 0x40, p.skills_positive_3_id}, {6, 0x80, p.skills_positive_4_id},
            {7, 0x01, p.skills_positive_5_id}, {7, 0x02, p.skills_positive_6_id},
            {7, 0x04, p.skills_positive_7_id}, {7, 0x08, p.skills_positive_8_id},
            {7, 0x10, p.skills_positive_9_id}, {7, 0x20, p.skills_positive_10_id},
            {7, 0x40, p.skills_positive_11_id} };
        int n = 0;
        for (int i = 0; i < 13; ++i) if (Has(f, cells[i].index1, cells[i].mask) && cells[i].id >= 0) ++n;
        return n;
    }

    // The field -> SDATA_PET assignment of GCDetailAttrib_PetHandler.cpp (normal branch), on the CY layout.
    // slot >= 0: a bag pet (g_cy[slot] gets the CY cells); slot < 0: the target pet (context menu of another pet).
    void FillPet(SDATA_PET& pet, int slot, const pg::GCDetailAttrib_Pet& p, const int64_t* f, bool updateSkills = true)
    {
        pet.m_nIsPresent = 2;   // 0.85: "received the detail data"
        if (Has(f, 1, 0x01)) pet.m_idServer = static_cast<ObjID_t>(p.m_objID);
        if (Has(f, 1, 0x02)) pet.m_nDataID = static_cast<INT>(p.data_index);
        if (Has(f, 1, 0x04)) pet.m_szName = p.name;
        if (Has(f, 1, 0x08)) pet.m_nAIType = static_cast<INT>(p.ai_type);
        if (Has(f, 1, 0x10)) SetGuid(pet.m_SpouseGUID, p.spouse_GUID);
        if (Has(f, 1, 0x20))
        {
            const INT oldLevel = pet.m_nLevel;
            pet.m_nLevel = static_cast<INT>(p.level);
            if (slot >= 0 && oldLevel != -1 && pet.m_nLevel > oldLevel)
                PetLog("pet %s leveled %d -> %d", pet.m_szName.c_str(), oldLevel, pet.m_nLevel);
        }
        if (Has(f, 1, 0x80))
        {
            pet.m_nExp = static_cast<INT>(p.exp);
            if (pet.m_nExp < 0) pet.m_nExp = 0;
        }
        if (Has(f, 2, 0x01)) { pet.m_nHP = static_cast<INT>(p.hp); if (pet.m_nHP < 0) pet.m_nHP = 0; }
        if (Has(f, 2, 0x02)) pet.m_nHPMax = static_cast<INT>(p.hp_max);
        if (Has(f, 2, 0x04)) pet.m_nAge = static_cast<INT>(p.life_span);
        if (Has(f, 2, 0x10)) pet.m_nHappiness = p.happiness;
        if (Has(f, 2, 0x20)) pet.m_nAttPhysics = static_cast<INT>(p.attrib_att_physics);
        if (Has(f, 2, 0x40)) pet.m_nAttMagic = static_cast<INT>(p.attrib_att_magic);
        if (Has(f, 2, 0x80)) pet.m_nDefPhysics = static_cast<INT>(p.attrib_def_physics);
        if (Has(f, 3, 0x01)) pet.m_nDefMagic = static_cast<INT>(p.attrib_def_magic);
        if (Has(f, 3, 0x02)) pet.m_nHit = static_cast<INT>(p.attrib_hit);
        if (Has(f, 3, 0x04)) pet.m_nMiss = static_cast<INT>(p.attrib_miss);
        if (Has(f, 4, 0x01)) pet.m_nAttrStrApt = static_cast<INT>(p.str_perception);
        if (Has(f, 4, 0x02)) pet.m_nAttrConApt = static_cast<INT>(p.con_perception);
        if (Has(f, 4, 0x04)) pet.m_nAttrDexApt = static_cast<INT>(p.dex_perception);
        if (Has(f, 4, 0x08)) pet.m_nAttrSprApt = static_cast<INT>(p.spr_perception);
        if (Has(f, 4, 0x10)) pet.m_nAttrIntApt = static_cast<INT>(p.int_perception);
        if (Has(f, 5, 0x04)) pet.m_nAttrStr = static_cast<INT>(p.str);
        if (Has(f, 5, 0x08)) pet.m_nAttrCon = static_cast<INT>(p.con);
        if (Has(f, 5, 0x10)) pet.m_nAttrDex = static_cast<INT>(p.dex);
        if (Has(f, 5, 0x20)) pet.m_nAttrSpr = static_cast<INT>(p.spr);
        if (Has(f, 5, 0x40)) pet.m_nAttrInt = static_cast<INT>(p.int_);
        if (Has(f, 5, 0x80)) pet.m_nBasic = static_cast<INT>(p.gengu);        // 根骨 = 0.85 PET_DETAIL_ATTR_GENGU
        if (Has(f, 6, 0x01)) pet.m_nPot = static_cast<INT>(p.point_remain);
        // Skills: CY carries 2 activate + 11 positive cells in this wire order; 0.85 has PET_MAX_SKILL_COUNT slots.
        if (updateSkills) {
        if (Has(f, 6, 0x04)) PutSkill(slot, 0, p.skills_activate_1_id);
        if (Has(f, 6, 0x08)) PutSkill(slot, 1, p.skills_activate_2_id);
        if (Has(f, 6, 0x10)) PutSkill(slot, 2, p.skills_positive_1_id);
        if (Has(f, 6, 0x20)) PutSkill(slot, 3, p.skills_positive_2_id);
        if (Has(f, 6, 0x40)) PutSkill(slot, 4, p.skills_positive_3_id);
        if (Has(f, 6, 0x80)) PutSkill(slot, 5, p.skills_positive_4_id);
        if (Has(f, 7, 0x01)) PutSkill(slot, 6, p.skills_positive_5_id);
        if (Has(f, 7, 0x02)) PutSkill(slot, 7, p.skills_positive_6_id);
        if (Has(f, 7, 0x04)) PutSkill(slot, 8, p.skills_positive_7_id);
        if (Has(f, 7, 0x08)) PutSkill(slot, 9, p.skills_positive_8_id);
        if (Has(f, 7, 0x10)) PutSkill(slot, 10, p.skills_positive_9_id);
        if (Has(f, 7, 0x20)) PutSkill(slot, 11, p.skills_positive_10_id);
        if (Has(f, 7, 0x40)) PutSkill(slot, 12, p.skills_positive_11_id);
        }

        // CY-only cells (see the file header for the B record evidence of each).
        PetCy& cy = slot < 0 ? g_targetCy : g_cy[slot];
        if (cy.high != pet.m_GUID.m_uHighSection || cy.low != pet.m_GUID.m_uLowSection)
        {
            ResetCyData(cy);
            cy.high = pet.m_GUID.m_uHighSection;
            cy.low = pet.m_GUID.m_uLowSection;
        }
        if (Has(f, 1, 0x40)) cy.usedProcreate = p.used_procreate_count;
        if (Has(f, 2, 0x08)) { cy.lingxing = p.lingxing; pet.m_nEraCount = p.lingxing; }
        if (Has(f, 3, 0x08)) cy.mindAttack = static_cast<int>(p.mind_attack);
        if (Has(f, 3, 0x10)) cy.mindDefend = static_cast<int>(p.mind_defend);
        if (Has(f, 3, 0x20)) cy.attackType = p.attack_type;
        if (Has(f, 7, 0x80)) cy.wuxing = static_cast<int>(p.wuxing);
        if (Has(f, 8, 0x01)) cy.growPerMille = static_cast<int>(p.growth_rate * 1000.0f);   // B: (int)((float)[0x45] * 1000.0)
        if (Has(f, 8, 0x02))
        {
            int count = 0;
            for (size_t k = 0; k < p.titles.size(); ++k) if (p.titles[k] != -1) ++count;
            cy.titleCount = count;
        }
        if (Has(f, 10, 0x40)) cy.mainPerception = static_cast<int>(p.main_perception);   // CYS-PETSKILL: PetLingXing band
        if (Has(f, 10, 0x80)) cy.petType = p.unknow_13;
        {
            // The six equipment views are always written by the server (empty = Item_cls.new(), item_index -1).
            bool any = false;
            if (Has(f, 8, 0x10) && p.equip_list_1.item_index >= 0) any = true;
            if (Has(f, 8, 0x20) && p.equip_list_2.item_index >= 0) any = true;
            if (Has(f, 8, 0x40) && p.equip_list_3.item_index >= 0) any = true;
            if (Has(f, 8, 0x80) && p.equip_list_4.item_index >= 0) any = true;
            if (Has(f, 9, 0x01) && p.equip_list_5.item_index >= 0) any = true;
            if (Has(f, 9, 0x02) && p.equip_list_6.item_index >= 0) any = true;
            cy.hasEquip = any ? 1 : 0;
        }
        if (Has(f, 9, 0x04)) cy.element[0] = static_cast<int>(p.att_cold);
        if (Has(f, 9, 0x08)) cy.element[4] = static_cast<int>(p.def_cold);
        if (Has(f, 9, 0x10)) cy.element[8] = static_cast<int>(p.reduce_def_cold);
        if (Has(f, 9, 0x20)) cy.element[1] = static_cast<int>(p.att_fire);
        if (Has(f, 9, 0x40)) cy.element[5] = static_cast<int>(p.def_fire);
        if (Has(f, 9, 0x80)) cy.element[9] = static_cast<int>(p.reduce_def_fire);
        if (Has(f, 10, 0x01)) cy.element[2] = static_cast<int>(p.att_light);
        if (Has(f, 10, 0x02)) cy.element[6] = static_cast<int>(p.def_light);
        if (Has(f, 10, 0x04)) cy.element[10] = static_cast<int>(p.reduce_def_light);
        if (Has(f, 10, 0x08)) cy.element[3] = static_cast<int>(p.att_poison);
        if (Has(f, 10, 0x10)) cy.element[7] = static_cast<int>(p.def_poison);
        if (Has(f, 10, 0x20)) cy.element[11] = static_cast<int>(p.reduce_def_poison);
    }

    void OnDetailAttribPet(const pg::GCDetailAttrib_Pet& p)
    {
        CysPetSoul::RememberPet(p);
        ++g_counters.detailPackets;
        if (!IsMain()) return;
        CDataPool* pool = CDataPool::GetMe();
        if (!pool) return;
        InitState();
        int64_t f[11];
        bool hasRage = false, hasRageMax = false, elf = false;
        pg::deriveDetailAttribPetFlags(p.nf.data(), f, &hasRage, &hasRageMax, &elf);
        bool anyFlag = false;
        for (int i = 0; i < 11; ++i) if (f[i]) anyFlag = true;

        PET_GUID_t guid;
        SetGuid(guid, p.guid);

        // The trailing byte block = the 0.85 ExtraInfo (length byte + data): 0 = a bag pet, 1 byte [4] = the context
        // menu of another player's pet (server: send_pets_detail(who, 4)); exchange / stall / player shop views are
        // longer (GCExchangePetView_t / GCStallPetView_t) and belong to windows this module does not serve.
        const int extra = p.unknow_6;
        if (extra == 1 && !p.unknow_7.empty() && p.unknow_7[0] == 4)
        {
            SDATA_PET* target = pool->TargetPet_GetPet();
            if (!target) return;
            target->m_GUID = guid;
            if (!anyFlag) return;
            FillPet(*target, -1, p, f);
            ++g_counters.detailTarget;
            PetLog("GCDetailAttrib_Pet target view guid=%u:%u data=%d level=%d", guid.m_uHighSection, guid.m_uLowSection,
                   target->m_nDataID, target->m_nLevel);
            CEventSystem::GetMe()->PushEvent(GE_VIEW_EXCHANGE_PET);
            return;
        }
        if (extra != 0)
        {
            ++g_counters.detailDropped;
            PetLog("GCDetailAttrib_Pet with extra view len=%d type=%d ignored (exchange/stall/shop pets are not served here)",
                   extra, p.unknow_7.empty() ? -1 : p.unknow_7[0]);
            return;
        }

        // 0.85: the slot holding this GUID, else the first slot with a null GUID.
        int slot = -1;
        for (int i = 0; i < HUMAN_PET_MAX_COUNT && slot < 0; ++i)
        {
            SDATA_PET* pet = pool->Pet_GetPet(i);
            if (pet && pet->m_GUID == guid) slot = i;
        }
        for (int i = 0; i < HUMAN_PET_MAX_COUNT && slot < 0; ++i)
        {
            SDATA_PET* pet = pool->Pet_GetPet(i);
            if (pet && pet->m_GUID.IsNull()) slot = i;
        }
        if (slot < 0)
        {
            ++g_counters.detailDropped;
            PetLog("GCDetailAttrib_Pet guid=%u:%u: no free slot (%d slots)", guid.m_uHighSection, guid.m_uLowSection, HUMAN_PET_MAX_COUNT);
            return;
        }
        SDATA_PET* pet = pool->Pet_GetPet(slot);
        pet->m_GUID = guid;
        if (!anyFlag) return;
        FillPet(*pet, slot, p, f);
        ++g_counters.detailApplied;
        if (g_counters.detailApplied <= 12 || (g_counters.detailApplied % 50) == 0)
            PetLog("GCDetailAttrib_Pet #%u slot=%d guid=%u:%u obj=%d data=%d name=%s level=%d hp=%d/%d gengu=%d wuxing=%d lingxing=%d "
                   "crit=%d/%d grow=%d type=%d titles=%d equip=%d elf=%d count=%d atk_trait=%d main_perc=%d skills=%d/%d",
                   g_counters.detailApplied, slot, guid.m_uHighSection, guid.m_uLowSection, (int)pet->m_idServer, pet->m_nDataID,
                   pet->m_szName.c_str(), pet->m_nLevel, pet->m_nHP, pet->m_nHPMax, pet->m_nBasic, g_cy[slot].wuxing, g_cy[slot].lingxing,
                   g_cy[slot].mindAttack, g_cy[slot].mindDefend, g_cy[slot].growPerMille, g_cy[slot].petType, g_cy[slot].titleCount,
                   // CYS-PETSKILL: atk_trait / main_perc feed Pet:GetAttackTrait and Pet:GetPercent_Lx; skills = how
                   // many of the 13 CY cells carried a real id, over how many slots the pool now has.
                   g_cy[slot].hasEquip, elf ? 1 : 0, pool->Pet_GetCount(), g_cy[slot].attackType, g_cy[slot].mainPerception,
                   CountWireSkills(p, f), (int)PET_MAX_SKILL_COUNT);
        CEventSystem::GetMe()->PushEvent(GE_UPDATE_PET_PAGE);
    }

    // GCNewPetHandler.cpp on the CY layout. The pet object is a CObject_PlayerNPC of NPC_TYPE_PET; its model comes
    // with the GCCharBaseAttrib the load queue asks for (Set_RaceID), exactly like the 0.85 flow.
    void OnNewPet(const pg::GCNewPet& p)
    {
        ++g_counters.newPets;
        if (!IsMain()) return;
        CScene* scene = (CScene*)CWorldManager::GetMe()->GetActiveScene();
        if (!scene || !scene->IsValidPosition(fVector2(p.world_pos_x, p.world_pos_y)))
        {
            PetLog("GCNewPet obj=%u at (%.1f,%.1f): invalid position, skipped", p.m_objID, p.world_pos_x, p.world_pos_y);
            return;
        }
        CObjectManager* objects = CObjectManager::GetMe();
        fVector3 game;
        CGameProcedure::s_pGfxSystem->Axis_Trans(CRenderSystem::AX_PLAN, fVector3(p.world_pos_x, 0.0f, p.world_pos_y), CRenderSystem::AX_GAME, game);
        CObject_PlayerNPC* npc = (CObject_PlayerNPC*)objects->FindServerObject((INT)p.m_objID);
        if (!npc)
        {
            npc = objects->NewPlayerNPC((INT)p.m_objID);
            SObjectInit init;
            init.m_fvPos = game;
            init.m_fvRot = fVector3(0.0f, 0.0f, 0.0f);
            npc->Initial(&init);
        }
        else
        {
            npc->SetMapPosition(fVector2(game.x, game.z));
            npc->SetFaceDir(0.0f);
            npc->Enable(OSF_VISIABLE);
            npc->Disalbe(OSF_OUT_VISUAL_FIELD);
        }
        npc->SetNpcType(NPC_TYPE_PET);
        npc->GetCharacterData()->Set_MoveSpeed(p.speed);
        SCommand_Object command;
        command.m_wID = OC_IDLE;
        command.m_afParam[0] = game.x;
        command.m_afParam[1] = game.z;
        command.m_abParam[2] = FALSE;
        npc->PushCommand(&command);
        objects->GetLoadQueue()->TryAddLoadTask(npc->GetID(), CObject_Character::CT_MONSTER);
        npc->PushDebugString("GCNewPet");
        npc->SetMsgTime(CGameProcedure::s_pTimeSystem->GetTimeNow());
        PetLog("GCNewPet obj=%u model=%d at (%.1f,%.1f) speed=%.2f", p.m_objID, p.unknow_1, p.world_pos_x, p.world_pos_y, p.speed);
    }

    // GCRemovePetHandler.cpp.
    void OnRemovePet(const pg::GCRemovePet& p)
    {
        ++g_counters.removedPets;
        if (!IsMain()) return;
        CDataPool* pool = CDataPool::GetMe();
        if (!pool) return;
        PET_GUID_t guid;
        SetGuid(guid, p.guid);
        // CYS-PETSKILL: the pet is gone, so a 放生 that was still in flight for it is answered.
        InitState();
        if (g_freeing.pending && g_freeing.high == guid.m_uHighSection && g_freeing.low == guid.m_uLowSection)
            g_freeing.pending = false;
        for (int i = 0; i < HUMAN_PET_MAX_COUNT; ++i)
        {
            SDATA_PET* pet = pool->Pet_GetPet(i);
            if (!pet || !(pet->m_GUID == guid)) continue;
            PetLog("GCRemovePet guid=%u:%u slot=%d (%s)", guid.m_uHighSection, guid.m_uLowSection, i, pet->m_szName.c_str());
            pet->CleanUp();
            ResetCy(i);
            g_mark[i].location = -1;
            CActionSystem::GetMe()->UpdateToolBarForPetSkill();
            CEventSystem::GetMe()->PushEvent(GE_UPDATE_PET_PAGE);
            return;
        }
        PetLog("GCRemovePet guid=%u:%u: not in the bag", guid.m_uHighSection, guid.m_uLowSection);
    }

    // GCManipulatePetRetHandler.cpp. The 0.85 handler only announced the result (Chinese debug strings) and refreshed
    // the window; the CY windows show their own texts, so only the log keeps the strings. The current-pet GUID is set
    // here as well as from GCDetailAttrib (both say the same thing; this one arrives first).
    void OnManipulatePetRet(const pg::GCManipulatePetRet& p)
    {
        ++g_counters.manipulateRets;
        if (!IsMain()) return;
        static const char* const kNames[] = {
            "CAPTUREFALID", "CAPTURESUCC", "CALLUPFALID", "CALLUPSUCC", "FREEFALID", "FREESUCC",
            "RECALLFALID", "RECALLSUCC", "SOULMELTINGFAILED", "SOULMELTINGSUCC" };
        const char* name = (p.ret >= 0 && p.ret < 10) ? kNames[p.ret] : "?";
        PetLog("GCManipulatePetRet ret=%d %s guid=%u:%u is_fighting=%u", p.ret, name, p.guid.m_uHighSection, p.guid.m_uLowSection, p.is_fighting);
        // CYS-PETSKILL: the 放生 answer (4 FREEFALID / 5 FREESUCC) disarms Pet:IsFreeing.
        InitState();
        if ((p.ret == 4 || p.ret == 5) && g_freeing.pending
            && g_freeing.high == p.guid.m_uHighSection && g_freeing.low == p.guid.m_uLowSection)
            g_freeing.pending = false;
        CObject_PlayerMySelf* self = Self();
        if (self && self->GetCharacterData())
        {
            PET_GUID_t guid;
            SetGuid(guid, p.guid);
            if (p.ret == 3) self->GetCharacterData()->Set_CurrentPetGUID(guid);                        // CALLUPSUCC
            else if ((p.ret == 5 || p.ret == 7) && self->GetCharacterData()->Get_CurrentPetGUID() == guid) // FREESUCC / RECALLSUCC
            {
                PET_GUID_t none;
                none.Reset();
                self->GetCharacterData()->Set_CurrentPetGUID(none);
            }
        }
        CEventSystem::GetMe()->PushEvent(GE_UPDATE_PET_PAGE);
    }
}

namespace {
#include "CysPetBank.inl"
}

void CysPetNet::FillExternal(const pg::GCDetailAttrib_Pet& p, SDATA_PET& out)
{
    int64_t flags[11];bool rage=false,rageMax=false,elf=false;
    pg::deriveDetailAttribPetFlags(p.nf.data(),flags,&rage,&rageMax,&elf);
    const auto saved=g_targetCy;
    // External lists retain the complete wire packet for their detail window.
    // Filling a list row must not replace skills of the currently inspected pet.
    SetGuid(out.m_GUID,p.guid);FillPet(out,-1,p,flags,false);
    g_targetCy=saved;
}

bool CysPetNet::IsWorldPacket(uint16_t id)
{
    return id == pg::GCDetailAttrib_Pet::PACKET_ID || id == pg::GCNewPet::PACKET_ID
        || id == pg::GCRemovePet::PACKET_ID || id == pg::GCManipulatePetRet::PACKET_ID
        || id == pg::GCPetBankListUPData::PACKET_ID || id == pg::GCPetBankAddPet::PACKET_ID
        || id == pg::GCBankBegin::PACKET_ID || id == pg::GCPacketStream::PACKET_ID;
}

bool CysPetNet::Dispatch(const pg::Packet& packet)
{
    if(BankDispatch(packet))return true;
    switch (packet.packetId())
    {
    case pg::GCDetailAttrib_Pet::PACKET_ID: OnDetailAttribPet(static_cast<const pg::GCDetailAttrib_Pet&>(packet)); return true;
    case pg::GCNewPet::PACKET_ID: OnNewPet(static_cast<const pg::GCNewPet&>(packet)); return true;
    case pg::GCRemovePet::PACKET_ID: OnRemovePet(static_cast<const pg::GCRemovePet&>(packet)); return true;
    case pg::GCManipulatePetRet::PACKET_ID: OnManipulatePetRet(static_cast<const pg::GCManipulatePetRet&>(packet)); return true;
    default: return false;
    }
}

std::unique_ptr<pg::Packet> CysPetNet::Translate(Packet* legacy)
{
    if (!legacy) return nullptr;
    if (legacy->GetPacketID() == PACKET_CG_SET_PETATTRIB) {
        const Packets::CGSetPetAttrib* in = static_cast<const Packets::CGSetPetAttrib*>(legacy);
        std::unique_ptr<pg::CGSetPetAttrib> out(new pg::CGSetPetAttrib);
        out->guid.m_uHighSection = in->GetGUID().m_uHighSection;
        out->guid.m_uLowSection = in->GetGUID().m_uLowSection;
        if (in->IsUpdateAttrib(SET_PET_ATTRIB_NAME)) {
            out->name = in->GetName();
            if (out->name.empty() || out->name.size() >= MAX_CHARACTER_NAME) return nullptr;
            out->len = static_cast<uint8_t>(out->name.size());
            out->m_Flags[0] |= 1;
        }
        const ENUM_SET_PET_ATTRIB keys[] = {SET_PET_ATTRIB_STR_INCREMENT, SET_PET_ATTRIB_CON_INCREMENT,
            SET_PET_ATTRIB_DEX_INCREMENT, SET_PET_ATTRIB_SPR_INCREMENT, SET_PET_ATTRIB_INT_INCREMENT};
        for (int i = 0; i < 5; ++i) {
            if (!in->IsUpdateAttrib(keys[i])) continue;
            const int value = i == 0 ? in->GetStrIncrement() : i == 1 ? in->GetConIncrement() :
                i == 2 ? in->GetDexIncrement() : i == 3 ? in->GetSprIncrement() : in->GetIntIncrement();
            if (value < 0) return nullptr;
            out->m_Flags[0] |= static_cast<uint8_t>(1 << (i + 1));
            if (i == 0) out->str_increment = value;
            else if (i == 1) out->con_increment = value;
            else if (i == 2) out->dex_increment = value;
            else if (i == 3) out->spr_increment = value;
            else out->int_increment = value;
        }
        return std::unique_ptr<pg::Packet>(out.release());
    }
    if (legacy->GetPacketID() != PACKET_CG_MANIPULATEPET) return nullptr;
    const Packets::CGManipulatePet* in = static_cast<const Packets::CGManipulatePet*>(legacy);
    std::unique_ptr<pg::CGManipulatePet> out(new pg::CGManipulatePet);
    CObject_PlayerMySelf* self = Self();
    out->m_objID = self ? static_cast<uint32_t>(self->GetServerID()) : 0;
    out->pet_guid.m_uHighSection = in->GetGUID().m_uHighSection;
    out->pet_guid.m_uLowSection = in->GetGUID().m_uLowSection;
    out->type = in->GetManipulateType();
    // CYS-PETSKILL 19/09: arm Pet:IsFreeing here, the one place a 放生 leaves this client (Pet:Free_Confirm ->
    // CGManipulatePet type 2). Cleared by GCManipulatePetRet FREESUCC/FREEFALID or GCRemovePet for the same GUID.
    if (out->type == Packets::MANIPULATE_FREEPET)
    {
        InitState();
        g_freeing.high = out->pet_guid.m_uHighSection;
        g_freeing.low = out->pet_guid.m_uLowSection;
        g_freeing.pending = true;
    }
    ++g_counters.manipulateSent;
    PetLog("CGManipulatePet type=%d guid=%u:%u sent", out->type, out->pet_guid.m_uHighSection, out->pet_guid.m_uLowSection);
    return std::unique_ptr<pg::Packet>(out.release());
}

#else
bool CysPetNet::IsWorldPacket(uint16_t) { return false; }
bool CysPetNet::Dispatch(const pg::Packet&) { return false; }
std::unique_ptr<pg::Packet> CysPetNet::Translate(Packet*) { return nullptr; }
#endif

void CysPetNet::RegisterHost()
{
    CScriptSystem* scripts = CScriptSystem::GetMe();
    if (!scripts || !scripts->GetLuaState()) return;
    InitState();
    g_soulHigh = g_soulLow = 0;
#if defined(CYS_HAVE_NETCORE)
    RegisterBankHosts(scripts->GetLuaState());
#endif
    CysHostPet::Services services;
    services.petLocation = HostPetLocation;
    services.setPetLocation = HostSetPetLocation;
    services.updatePetList = HostUpdatePetList;
    services.petIndexByGuid = HostPetIndexByGuid;
    services.petGeneration = HostPetGeneration;
    services.haveCurrentPet = HostHaveCurrentPet;
    services.lingxing = HostLingxing;
    services.mindAttack = HostMindAttack;
    services.mindDefend = HostMindDefend;
    services.wuxing = HostWuxing;
    services.titleCount = HostTitleCount;
    services.growRatePerMille = HostGrowRate;
    services.petType = HostPetType;
    services.usedProcreateCount = HostUsedProcreate;
    services.hasEquip = HostHasEquip;
    services.setSelectedPet = HostSetSelectedPet;
    services.elementOfSelected = HostElementOfSelected;
    services.skillIdAt = HostSkillIdAt;
    services.takeLevel = HostTakeLevel;
    services.growLevel = HostGrowLevel;
    services.attackTrait = HostAttackTrait;       // CYS-PETSKILL
    services.attackTraitId = HostAttackTraitId;   // CYS-PETSKILL
    services.percentLx = HostPercentLx;           // CYS-PETSKILL
    services.isFreeing = HostIsFreeing;           // CYS-PETSKILL
    services.isPossession = HostIsPossession;
    services.restorePet = HostRestorePet;
    services.lingxingNext = HostLingxingNext;
    services.skillLevelupInfo = HostSkillLevelupInfo;
    services.possessionIndex = HostPossessionIndex;
    services.possessionPet = HostPossessionPet;
    const int n = CysHostPet::Register(scripts->GetLuaState(), services);
    TDU_Log("CYS-PET: host functions registered=%d (Pet / PetList / PetBank windows)", n);
    StartProbe(scripts->GetLuaState());
}
