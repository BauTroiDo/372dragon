// CYS-PET: Lua glue of the CY 珍兽 (pet) windows. See CysHost_Pet.h.
//
// Every function below was recovered from the original x64 client (B = client\Bin64\Game.exe, byte-identical code in
// client_GL\Bin64); the RVA of each is quoted at its definition. Read-only decompiles: Build/re/host-pet/.
// Pet stubs whose B implementation reads a field or a table that the 0.85 pet record / the private server does not
// have are NOT implemented here on purpose - a wrong answer is worse than the stub's logged 0.
#include "CysHost_Pet.h"
#include "LuaApiGen.h"
#include <cstring>

namespace CysHostPet
{
    namespace
    {
        Services g_services;

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
            if (o.IsNil()) return globals.CreateTable(name);
            return LuaPlus::LuaObject();
        }

        // Receiver methods are called as Table:Fn(a, b): stack 1 = self, 2.. = arguments.
        int IntArg(LuaPlus::LuaState* s, int index, int fallback)
        {
            LuaPlus::LuaStack args(s);
            return args[index].IsNumber() ? static_cast<int>(args[index].GetNumber()) : fallback;
        }

        // Pet:GetPetLocation(index)  B Game.exe+0x2b5120
        //   B: pet = CDataPool::Pet_GetPet(index); if (!pet || pet->m_nIsPresent == -1) throw; push pet-int[0x47].
        //   Here: -1 for an empty slot instead of the throw. The CY scripts only ever compare the result with -1
        //   ("is this pet already used by another window"), and -1 is the answer they need for a slot with no pet;
        //   the catalog stub's 0 makes every window believe the pet is busy (Pet.lua 2053, PetProcreate.lua 41, ...).
        int GetPetLocationFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1);
            s->PushInteger(g_services.petLocation ? g_services.petLocation(g_services.context, index) : -1);
            return 1;
        }

        // Pet:SetPetLocation(index, location)  B Game.exe+0x2b5080
        //   B: pet = Pet_GetPet(index); if (pet && pet->m_nIsPresent != -1) pet-int[0x47] = location; returns nothing.
        //   The window ids the CY scripts store: 1 PetLevelup, 2/21 PetNeidan_Lianhua, 3 PetSavvyGGD, 5 PetHuanhua /
        //   PetLianHua, 7 MissionReply, 10 PetLingXingUp, 12 PetSavvy, 16 PetProcreate, 17 PetRHD, 18 PetChangeModel.
        int SetPetLocationFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1), location = IntArg(s, 3, -1);
            if (g_services.setPetLocation) g_services.setPetLocation(g_services.context, index, location);
            return 0;
        }

        // Pet:UpdatePetList()  B Game.exe+0x2bc8b0 -> CEventSystem::PushEvent(0xe8).
        //   B event 0xe8 = 0.85 GE_UPDATE_PET_LIST ("UPDATE_PET_LIST"): the pet-list block of B's event enum is the
        //   0.85 block shifted by +27, anchored three times (GE_OPEN_PET_LIST 0xca->0xe5 in Pet:ShowPetList,
        //   GE_CLOSE_PET_LIST 0xcc->0xe7 in the same function, GE_OPEN_ITEM_COFFER 0xd1->0xec in
        //   PlayerPackage:OpenLockFrame). PetList.lua registers "UPDATE_PET_LIST" and rebuilds its list on it.
        int UpdatePetListFn(LuaPlus::LuaState* s)
        {
            (void)s;
            if (g_services.updatePetList) g_services.updatePetList(g_services.context);
            return 0;
        }

        // Pet:GetPetIndexByGUID(high, low)  B Game.exe+0x2ae270
        //   B: CDataPool::Pet_GetPetByGuid(PET_GUID_t{m_uHighSection = arg1, m_uLowSection = arg2}) -> slot or -1.
        //   Argument order verified against Pet:GetGUID (pushes high then low) and the CY call sites
        //   (PetSavvy.lua 426 "GetPetIndexByGUID(mainPet.guid.high, mainPet.guid.low)").
        int GetPetIndexByGuidFn(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            if (!args[2].IsNumber() || !args[3].IsNumber()) { s->PushInteger(-1); return 1; }
            const unsigned int high = static_cast<unsigned int>(args[2].GetNumber());
            const unsigned int low = static_cast<unsigned int>(args[3].GetNumber());
            s->PushInteger(g_services.petIndexByGuid ? g_services.petIndexByGuid(g_services.context, high, low) : -1);
            return 1;
        }

        // Pet:GetGeneration(index)  B Game.exe+0x2bc6f0
        //   B reads the same pet-record int as Pet:GetType (B Game.exe+0x2b03d0, pet-int[0x18]), and 0.85's
        //   Pet::GetType pushes m_nEraCount (几代宠, the pet's generation) - so GetGeneration = m_nEraCount.
        //   Pet.lua 1035 only tests ">= 100" (the CY "ancient" pets), so an empty slot must not answer with a number
        //   that passes: -1.
        int GetGenerationFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1);
            s->PushInteger(g_services.petGeneration ? g_services.petGeneration(g_services.context, index) : -1);
            return 1;
        }

        // Player:IsHaveCurrentPet()  B Game.exe+0x2dca90
        //   B: guid = MySelf->GetCharacterData()->Get_CurrentPetGUID(); pet = CDataPool::Pet_GetPet(guid);
        //      push (pet && pet->m_nIsPresent != -1). Same accessor pair as 0.85's Pet::GetIsFighting.
        int IsHaveCurrentPetFn(LuaPlus::LuaState* s)
        {
            s->PushBoolean(g_services.haveCurrentPet && g_services.haveCurrentPet(g_services.context));
            return 1;
        }

        // DataPool:GetLeftProtectTime()  B Game.exe+0x26d4d0
        //   B's whole body is `lua_pushnumber(L, 0.0); return 1;` - the account-theft protection countdown was cut
        //   from the client. Pet.lua 1838/2031/2928 gate "release / unlock a pet" on `> 0`, so 0 = allowed.
        int GetLeftProtectTimeFn(LuaPlus::LuaState* s)
        {
            s->PushInteger(0);
            return 1;
        }

        // ---- pet-gc512: cells of GCDetailAttrib_Pet (512) the 0.85 record has no field for ---------------------
        // Each of these is, in B, "pet = Pet_GetPet(index); if (!pet || pet[0] == -1) throw; push pet-cell". The
        // cell -> wire field pairing is in CysPetNet.cpp (file header). An empty slot answers -1 (0 for counts)
        // instead of B's Lua error, for the same reason as GetPetLocation.
        typedef int (*CellFn)(void*, int);
        int PushCell(LuaPlus::LuaState* s, CellFn fn, int empty)
        {
            const int index = IntArg(s, 2, -1);
            s->PushInteger(fn ? fn(g_services.context, index) : empty);
            return 1;
        }
        int GetLixingFn(LuaPlus::LuaState* s) // B +0x2bc640: display level, not the encoded generation.
        {
            const int index = IntArg(s, 2, -1);
            const int raw = g_services.lingxing ? g_services.lingxing(g_services.context, index) : -1;
            s->PushInteger(raw >= 100 && raw <= 110 ? raw - 100 : 0);
            return 1;
        }
        int GetCriticalAttackFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.mindAttack, -1); }      // B +0x2b2390 [0x24]
        int GetCriticalDefenceFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.mindDefend, -1); }     // B +0x2b2430 [0x25]
        int GetSavvyFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.wuxing, -1); }                   // B +0x2b5a10 [0x43]
        int GetTitleNumFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.titleCount, 0); }             // B +0x2b95c0 [0x50..0x52]
        int GetGrowRateFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.growRatePerMille, -1000); }   // B +0x2b5ab0 [0x45]*1000
        int GetPetTypeFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.petType, -1); }                // B +0x2bc8e0 byte +0x17c
        int GetLastProcreateLevelFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.usedProcreateCount, -1); } // B +0x2b0330 [0x11]
        int IsPetHaveEquipFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.hasEquip, 0); }            // B +0x2bb490

        // Pet:SetSelectPetIdx(index)  B Game.exe+0x2b8fc0: stores the index (Pet.lua 370/691/711/929 select the
        //   pet of the window; -1 = nothing selected). Returns nothing.
        int SetSelectPetIdxFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1);
            if (g_services.setSelectedPet) g_services.setSelectedPet(g_services.context, index);
            return 0;
        }

        // Pet:GetData(key)  B Game.exe+0x2bb530: key is one of ATTACK/DEFENCE/RESISTOTHER + COLD/FIRE/LIGHT/POISON
        //   (12 memcmp branches in the decompile), read from the SELECTED pet (SetSelectPetIdx). Unknown key or no
        //   selected pet: 0 (B pushes an uninitialised number there; 0 is what the stub answered).
        int GetDataFn(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            int value = 0;
            if (args[2].IsString() && g_services.elementOfSelected)
                g_services.elementOfSelected(g_services.context, args[2].GetString(), value);
            s->PushInteger(value);
            return 1;
        }

        // Pet:GetSkillIDbyIndex(index, pos)  B Game.exe+0x2b2560 -> CDataPool helper(index, pos), pushes a number.
        //   PetLevelup.lua 146-151 uses the same `pos` it just passed to Pet:EnumPetSkill(index, pos, "petskill"),
        //   i.e. the PET_SKILL::m_nPosIndex slot; the id is the DBC_SKILL_DATA id Pet_SetSkill resolved. -1 = empty.
        int GetSkillIDbyIndexFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1), pos = IntArg(s, 3, -1);
            s->PushInteger(g_services.skillIdAt ? g_services.skillIdAt(g_services.context, index, pos) : -1);
            return 1;
        }

        // Pet:GetTakeLevel(index)  B Game.exe+0x2b5850 -> FUN_1401c3af0(pet): DBC 0x70 (PetAttrTable) row of pet[5]
        //   (m_nDataID), int at +0x14 = GL column 3 = 可携带等级 (CY column 4 m_TakeLevel). No pet / no row: B pushes an
        //   uninitialised number; 0 here (Pet.lua 815/1135/3051 compare it with the player level / 65).
        int GetTakeLevelFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.takeLevel, 0); }

        // Pet:GetPetGrowLevel(index, rate)  B Game.exe+0x2b47d0 -> FUN_1401c39a0(pet, (int)rate): the same PetAttrTable
        //   row, thresholds at +0xa4/+0xa8/+0xac/+0xb0 = GL columns 39..42 = 成长率1..4 (CY m_GrowRate0..3): rate <= t1 -> 0
        //   (Thường), <= t2 -> 1, <= t3 -> 2, <= t4 -> 3, else 4 (Hoàn mỹ); rate < 0 (not appraised) -> -1 ("Vô danh").
        int GetPetGrowLevelFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1), rate = IntArg(s, 3, -1);
            s->PushInteger(g_services.growLevel ? g_services.growLevel(g_services.context, index, rate) : -1);
            return 1;
        }

        // ---- CYS-PETSKILL (19/09) -----------------------------------------------------------------------------
        // Pet:GetAttackTrait(index)  B Game.exe+0x2b58c0: s_pAttackTrait = GetDataBase(0xbe) = AttackTraits.txt;
        //   row = Search_Index_EQU((short)pet[0x26]); pushes row column 1 (the tooltip text) then column 2 (the
        //   imageset entry), or two empty strings when there is no row. Pet.lua 1535 takes both and only shows the
        //   widget when the icon is not empty - which is how the school rows (empty icon) stay hidden.
        int GetAttackTraitFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1);
            const char* name = "";
            const char* icon = "";
            if (g_services.attackTrait) g_services.attackTrait(g_services.context, index, &name, &icon);
            s->PushString(name ? name : "");
            s->PushString(icon ? icon : "");
            return 2;
        }

        // Pet:GetAttackTraitID(index): the 攻击特性ID itself (Pet.lua 1854/1884, PetNeidan.lua 758 pick the 内丹
        //   branch with it). Same cell GetAttackTrait looks the row up with.
        int GetAttackTraitIDFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.attackTraitId, -1); }

        // Pet:GetPercent_Lx(index)  B Game.exe+0x2bc1c0: PetLingXing (DBC 0xfe) row whose 宠物编号 is the pet's data
        //   id and whose band contains main_perception, column 4 + (灵性 level - 1). Per mille: Pet.lua 1185 prints
        //   value / 10 as "(+x.x%)" and only when > 0, which is also what an un-awakened pet answers.
        int GetPercentLxFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.percentLx, 0); }

        // Pet:IsFreeing(index)  B Game.exe+0x2bcc20: a client flag of the pet record, set when this client sent the
        //   放生 request. Pet.lua 2060 refuses a second 放生 while it is 1. 0 = no request in flight.
        int IsFreeingFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.isFreeing, 0); }

        // CY Pet.lua:1985 toggles possession for the selected slot. State is
        // the authoritative character GUID, including after relogin.
        int IsPossessionFn(LuaPlus::LuaState* s) {
            s->PushBoolean(g_services.isPossession && g_services.isPossession(g_services.context, IntArg(s, 2, -1)));
            return 1;
        }
        int PossessionIndexFn(LuaPlus::LuaState* s) {
            s->PushInteger(g_services.possessionIndex ? g_services.possessionIndex(g_services.context) : -1);
            return 1;
        }
        int LingxingChanceFn(LuaPlus::LuaState* s) {
            s->PushInteger(g_services.lingxingNext ? g_services.lingxingNext(g_services.context, IntArg(s, 2, -1), true) : 0);return 1;
        }
        int LingxingNextFn(LuaPlus::LuaState* s) {
            s->PushInteger(g_services.lingxingNext ? g_services.lingxingNext(g_services.context, IntArg(s, 2, -1), false) : 0);return 1;
        }
        int SkillLevelupInfoFn(LuaPlus::LuaState* s) {
            int values[6]={-1,0,0,0,0,0};
            if(g_services.skillLevelupInfo)g_services.skillLevelupInfo(g_services.context,IntArg(s,2,-1),IntArg(s,3,-1),values);
            for(int value:values)s->PushInteger(value);return 6;
        }
        int RestorePetFn(LuaPlus::LuaState* s) {
            if (g_services.restorePet) g_services.restorePet(g_services.context, IntArg(s, 2, -1));
            return 0;
        }
        int PossessionPetFn(LuaPlus::LuaState* s) {
            if (g_services.possessionPet) g_services.possessionPet(g_services.context, IntArg(s, 2, -1));
            return 0;
        }

        struct Entry { const char* receiver; const char* name; int (*fn)(LuaPlus::LuaState*); bool force; };

        const Entry kEntries[] = {
            {"Pet", "GetPetLocation", GetPetLocationFn, true},
            {"Pet", "SetPetLocation", SetPetLocationFn, true},
            {"Pet", "UpdatePetList", UpdatePetListFn, true},
            {"Pet", "GetPetIndexByGUID", GetPetIndexByGuidFn, true},
            {"Pet", "GetGeneration", GetGenerationFn, true},
            {"Player", "IsHaveCurrentPet", IsHaveCurrentPetFn, true},
            {"DataPool", "GetLeftProtectTime", GetLeftProtectTimeFn, true},
            // pet-gc512
            {"Pet", "GetLixing", GetLixingFn, true},
            {"Pet", "GetCriticalAttack", GetCriticalAttackFn, true},
            {"Pet", "GetCriticalDefence", GetCriticalDefenceFn, true},
            {"Pet", "GetSavvy", GetSavvyFn, true},
            {"Pet", "GetTitleNum", GetTitleNumFn, true},
            {"Pet", "GetGrowRate", GetGrowRateFn, true},
            {"Pet", "GetPetType", GetPetTypeFn, true},
            {"Pet", "GetLastProcreateLevel", GetLastProcreateLevelFn, true},
            {"Pet", "IsPetHaveEquip", IsPetHaveEquipFn, true},
            {"Pet", "SetSelectPetIdx", SetSelectPetIdxFn, true},
            {"Pet", "GetData", GetDataFn, true},
            {"Pet", "GetSkillIDbyIndex", GetSkillIDbyIndexFn, true},
            {"Pet", "GetTakeLevel", GetTakeLevelFn, true},
            {"Pet", "GetPetGrowLevel", GetPetGrowLevelFn, true},
            // CYS-PETSKILL (19/09)
            {"Pet", "GetAttackTrait", GetAttackTraitFn, true},
            {"Pet", "GetAttackTraitID", GetAttackTraitIDFn, true},
            {"Pet", "GetPercent_Lx", GetPercentLxFn, true},
            {"Pet", "IsFreeing", IsFreeingFn, true},
            {"Pet", "GetIsPossession", IsPossessionFn, true},
            {"Pet", "LuaFnGetPossessionPetIndex", PossessionIndexFn, true},
            {"Pet", "PossessionPet", PossessionPetFn, true},
            {"Pet", "RestorePet", RestorePetFn, true},
            {"Pet", "GetRate_LxUp", LingxingChanceFn, true},
            {"Pet", "GetPercent_LxUp", LingxingNextFn, true},
            {"Pet", "GetPetSkillLevelupInfo", SkillLevelupInfoFn, true},
        };
    }

    int Register(LuaPlus::LuaState* state, const Services& services)
    {
        g_services = services;
        if (!state) return 0;
        LuaPlus::LuaObject globals = state->GetGlobals();
        int registered = 0;
        for (const Entry& e : kEntries)
        {
            LuaPlus::LuaObject table = std::strcmp(e.receiver, "_G") == 0 ? globals : Receiver(globals, e.receiver);
            if (!table.IsTable()) continue;
            if (!e.force && !LuaApiGen::IsMissing(table, e.name)) continue;
            table.Register(e.name, e.fn);
            ++registered;
        }
        return registered;
    }
}
