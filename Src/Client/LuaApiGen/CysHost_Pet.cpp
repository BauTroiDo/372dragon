





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






        int GetPetLocationFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1);
            s->PushInteger(g_services.petLocation ? g_services.petLocation(g_services.context, index) : -1);
            return 1;
        }





        int SetPetLocationFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1), location = IntArg(s, 3, -1);
            if (g_services.setPetLocation) g_services.setPetLocation(g_services.context, index, location);
            return 0;
        }






        int UpdatePetListFn(LuaPlus::LuaState* s)
        {
            (void)s;
            if (g_services.updatePetList) g_services.updatePetList(g_services.context);
            return 0;
        }





        int GetPetIndexByGuidFn(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            if (!args[2].IsNumber() || !args[3].IsNumber()) { s->PushInteger(-1); return 1; }
            const unsigned int high = static_cast<unsigned int>(args[2].GetNumber());
            const unsigned int low = static_cast<unsigned int>(args[3].GetNumber());
            s->PushInteger(g_services.petIndexByGuid ? g_services.petIndexByGuid(g_services.context, high, low) : -1);
            return 1;
        }






        int GetGenerationFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1);
            s->PushInteger(g_services.petGeneration ? g_services.petGeneration(g_services.context, index) : -1);
            return 1;
        }




        int IsHaveCurrentPetFn(LuaPlus::LuaState* s)
        {
            s->PushBoolean(g_services.haveCurrentPet && g_services.haveCurrentPet(g_services.context));
            return 1;
        }




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



        int SetSelectPetIdxFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1);
            if (g_services.setSelectedPet) g_services.setSelectedPet(g_services.context, index);
            return 0;
        }




        int GetDataFn(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            int value = 0;
            if (args[2].IsString() && g_services.elementOfSelected)
                g_services.elementOfSelected(g_services.context, args[2].GetString(), value);
            s->PushInteger(value);
            return 1;
        }




        int GetSkillIDbyIndexFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1), pos = IntArg(s, 3, -1);
            s->PushInteger(g_services.skillIdAt ? g_services.skillIdAt(g_services.context, index, pos) : -1);
            return 1;
        }




        int GetTakeLevelFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.takeLevel, 0); }




        int GetPetGrowLevelFn(LuaPlus::LuaState* s)
        {
            const int index = IntArg(s, 2, -1), rate = IntArg(s, 3, -1);
            s->PushInteger(g_services.growLevel ? g_services.growLevel(g_services.context, index, rate) : -1);
            return 1;
        }






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




        int GetPercentLxFn(LuaPlus::LuaState* s) { return PushCell(s, g_services.percentLx, 0); }



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
