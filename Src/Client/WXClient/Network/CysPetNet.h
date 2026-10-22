#pragma once
























#include <cstdint>
#include <memory>

namespace pg { class Packet; class GCDetailAttrib_Pet; }
struct SDATA_PET;
class Packet;

namespace CysPetNet
{
    // Decode an external view without replacing the bag or inspected-pet metadata.
    void FillExternal(const pg::GCDetailAttrib_Pet& packet, SDATA_PET& out);
    // Registers the pet host functions (called from CysModernGame::Start, before the world arrives).
    void RegisterHost();

    // ---- packets (CysModernHandlers hooks) --------------------------------------------------------------------
    // A world packet of this module (stashed by CysModernHandlers until the scene is ready): 512, 1216, 52, 666.
    bool IsWorldPacket(uint16_t id);
    // Returns true when the packet was consumed.
    bool Dispatch(const pg::Packet& packet);
    // Translate one 0.85 packet of the pet windows to its CY layout (nullptr = not a pet packet).
    std::unique_ptr<pg::Packet> Translate(Packet* legacy);
    // GCDetailAttrib of the own character, flags[8] & 0x10: the current (summoned) pet GUID. 0.85 applied it in
    // GCDetailAttribHandler; the CY port of that handler does not, so CysModernHandlers forwards it here.
    void OnCurrentPetGuid(unsigned high, unsigned low);
    void OnSoulPetGuid(unsigned high, unsigned low);
    int PossessionIndex();

    // ---- pet slot marker (Pet:SetPetLocation / Pet:GetPetLocation) ---------------------------------------------
    // -1 = free / empty slot / slot reused by another pet.
    int PetLocation(int index);
    void SetPetLocation(int index, int location);

    // ---- CY-only cells of the pet in slot `index` (all -1 / 0 when the slot is empty) ----------------------------
    int Lingxing(int index);            // 灵性 (u8 on the wire)
    int MindAttack(int index);          // 会心攻击 mind_attack (Pet:GetCriticalAttack)
    int MindDefend(int index);          // 会心防御 mind_defend (Pet:GetCriticalDefence)
    int Wuxing(int index);              // 悟性 wuxing (Pet:GetSavvy)
    int TitleCount(int index);          // titles[] entries != -1 (Pet:GetTitleNum)
    int GrowRatePerMille(int index);    // (int)(growth_rate * 1000) exactly as B pushes it; -1000 = not appraised
    int PetType(int index);             // define.PET_TYPE: 0 baby, 1 variance, 2 wild (Pet:GetPetType)
    int UsedProcreateCount(int index);  // used_procreate_count (Pet:GetLastProcreateLevel, see CysHost_Pet.cpp)
    int HasEquip(int index);            // 1 when any of the 6 pet equipment slots holds an item
    // Pet:SetSelectPetIdx / Pet:GetData("ATTACKCOLD" ...): the selected pet of the Pet window and its 12 element cells.
    void SetSelectedPet(int index);
    int SelectedPet();
    // key: ATTACK|DEFENCE|RESISTOTHER + COLD|FIRE|LIGHT|POISON (B GetData); false when unknown key / no pet.
    bool ElementOfSelected(const char* key, int& value);
    // Skill id (DBC_SKILL_DATA id) in skill slot `pos` of the pet in slot `index`, -1 when empty.
    int SkillIdAt(int index, int pos);


    int TakeLevel(int index);


    int GrowLevel(int index, int ratePerMille);

    // ---- CYS-PETSKILL 19/09 (pet-skill-12) ----------------------------------------------------------------------
    int AttackType(int index);          // 攻击特性ID, the AttackTraits row id (MonsterAttrExTable 攻击特性ID); -1 = none
    int MainPerception(int index);      // main_perception (the server sends con_perception); -1 = unknown
    // Pet:GetAttackTrait(index): AttackTraits (DBC_PET_ATTACK_TRAIT, B's 0xbe) row of the pet's attack type. Both
    // strings point into the table and stay valid; false = no pet / no row, and B pushes two empty strings then.
    bool AttackTrait(int index, const char*& name, const char*& icon);
    // Pet:GetPercent_Lx(index): PetLingXing (DBC_PET_LINGXING, B's 0xfe) bonus in PER MILLE for the pet's 灵性 level.
    // 0 when the pet has not been awakened (server lingxing 0, i.e. outside 101..110) or has no matching row - the CY
    // window only prints the "(+x.x%)" line when the value is > 0.
    int PercentLx(int index);
    // Pet:IsFreeing(index): 1 between the CGManipulatePet(MANIPULATE_FREEPET) this client sent for the pet in the slot
    // and the server's GCManipulatePetRet / GCRemovePet answer for it. B reads a flag of its own pet record set in the
    // same place; the CY window uses it to stop a second 放生 while the first is in flight.
    int IsFreeing(int index);

    struct Counters
    {
        unsigned detailPackets;     // GCDetailAttrib_Pet received
        unsigned detailApplied;     // ... applied to a bag slot
        unsigned detailTarget;      // ... applied to the target pet (context menu of another player's pet)
        unsigned detailDropped;     // ... no free slot / unsupported extra view (exchange, stall, shop)
        unsigned newPets;           // GCNewPet
        unsigned removedPets;       // GCRemovePet
        unsigned manipulateRets;    // GCManipulatePetRet
        unsigned manipulateSent;    // CGManipulatePet translated
        unsigned skillsBeyondSlots; // CY skills that did not fit the 0.85 skill slots (PET_MAX_SKILL_COUNT)
    };
    Counters Get();
}
