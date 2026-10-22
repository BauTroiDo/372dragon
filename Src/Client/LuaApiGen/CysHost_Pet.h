#pragma once









#include "LuaPlus.h"

namespace CysHostPet
{
    struct Services
    {
        void* context = nullptr;


        int (*petLocation)(void* context, int index) = nullptr;

        void (*setPetLocation)(void* context, int index, int location) = nullptr;

        void (*updatePetList)(void* context) = nullptr;

        int (*petIndexByGuid)(void* context, unsigned int high, unsigned int low) = nullptr;

        int (*petGeneration)(void* context, int index) = nullptr;

        bool (*haveCurrentPet)(void* context) = nullptr;

        // ---- pet-gc512 (17/09): cells of GCDetailAttrib_Pet (512) that the 0.85 SDATA_PET has no field for -------
        // Pet:GetLixing(index) (B +0x2bc640: pet-int of the record; wire u8 lingxing). -1 = empty slot.
        int (*lingxing)(void* context, int index) = nullptr;
        // Pet:GetCriticalAttack(index) (B +0x2b2390: pet-int[0x24]; wire mind_attack 会心攻击). -1 = empty.
        int (*mindAttack)(void* context, int index) = nullptr;
        // Pet:GetCriticalDefence(index) (B +0x2b2430: pet-int[0x25]; wire mind_defend 会心防御). -1 = empty.
        int (*mindDefend)(void* context, int index) = nullptr;
        // Pet:GetSavvy(index) (B +0x2b5a10: pet-int[0x43]; wire wuxing 悟性, 1..10). -1 = empty.
        int (*wuxing)(void* context, int index) = nullptr;
        // Pet:GetTitleNum(index) (B +0x2b95c0: size of the titles vector at pet-int[0x50..0x52]). 0 = empty.
        int (*titleCount)(void* context, int index) = nullptr;
        // Pet:GetGrowRate(index) (B +0x2b5ab0: (int)((float)pet-int[0x45] * 1000)); wire growth_rate (-1 = not appraised).
        int (*growRatePerMille)(void* context, int index) = nullptr;
        // Pet:GetPetType(index) (B +0x2bc8e0: byte at pet+0x17c; wire unknow_13 = define.PET_TYPE 0 baby/1 variance/2 wild).
        int (*petType)(void* context, int index) = nullptr;
        // Pet:GetLastProcreateLevel(index) (B +0x2b0330: pet-int[0x11], between level and exp = wire used_procreate_count;
        // Pet.lua 1054 "改成记录已经繁殖次数"). -1 = empty.
        int (*usedProcreateCount)(void* context, int index) = nullptr;
        // Pet:IsPetHaveEquip(index) (B +0x2bb490 -> helper over the record's equipment): 1 when any of the 6 slots is used.
        int (*hasEquip)(void* context, int index) = nullptr;
        // Pet:SetSelectPetIdx(index) (B +0x2b8fc0: writes the index into the four pet preview objects at +0x70).
        void (*setSelectedPet)(void* context, int index) = nullptr;
        // Pet:GetData("ATTACKCOLD" ...) (B +0x2bb530: the element cells [0x27..0x32] of the SELECTED pet). false = unknown key.
        bool (*elementOfSelected)(void* context, const char* key, int& value) = nullptr;
        // Pet:GetSkillIDbyIndex(index, pos) (B +0x2b2560 -> CDataPool helper): DBC_SKILL_DATA id in that skill slot, -1.
        int (*skillIdAt)(void* context, int index, int pos) = nullptr;

        int (*takeLevel)(void* context, int index) = nullptr;

        int (*growLevel)(void* context, int index, int ratePerMille) = nullptr;

        // ---- CYS-PETSKILL (19/09) ---------------------------------------------------------------------------
        // Pet:GetAttackTrait(index) (B +0x2b58c0: AttackTraits row of pet-int[0x26], pushes name then icon).
        // false = no pet / no row; B pushes two empty strings in that case and the window hides the icon widget.
        bool (*attackTrait)(void* context, int index, const char** name, const char** icon) = nullptr;
        // Pet:GetAttackTraitID(index): the raw 攻击特性ID the row above is looked up with. -1 = empty slot.
        int (*attackTraitId)(void* context, int index) = nullptr;
        // Pet:GetPercent_Lx(index) (B +0x2bc1c0: PetLingXing row of the data id and main_perception band, column
        // 4 + 灵性 level - 1). Per mille; 0 when the pet is not awakened or has no row.
        int (*percentLx)(void* context, int index) = nullptr;
        // Pet:IsFreeing(index) (B +0x2bcc20 -> a client flag of the pet record, set when 放生 is sent). 1 or 0.
        int (*isFreeing)(void* context, int index) = nullptr;
        bool (*isPossession)(void* context, int index) = nullptr;
        void (*restorePet)(void* context, int index) = nullptr;
        int (*possessionIndex)(void* context) = nullptr;
        void (*possessionPet)(void* context, int index) = nullptr;
        int (*lingxingNext)(void* context, int index, bool chance) = nullptr;
        void (*skillLevelupInfo)(void* context, int skill, int index, int* sixValues) = nullptr;
    };

    // Registers every function (replacing the catalog stubs). Returns the number of functions registered.
    int Register(LuaPlus::LuaState* state, const Services& services);
}
