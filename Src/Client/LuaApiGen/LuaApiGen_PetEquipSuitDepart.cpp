




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_PetEquipSuitDepart_ConfirmDepart(LuaPlus::LuaState* state) { return Stub(state, "PetEquipSuitDepart", "ConfirmDepart", ""); }

        int LAG_PetEquipSuitDepart_GetPetEquipDepartInfo(LuaPlus::LuaState* state) { return Stub(state, "PetEquipSuitDepart", "GetPetEquipDepartInfo", "nnn"); }

        int LAG_PetEquipSuitDepart_SetPetEquipDepartFunc(LuaPlus::LuaState* state) { return Stub(state, "PetEquipSuitDepart", "SetPetEquipDepartFunc", "o"); }

        int LAG_PetEquipSuitDepart_ShowConfirm(LuaPlus::LuaState* state) { return Stub(state, "PetEquipSuitDepart", "ShowConfirm", "o"); }
    }

    void Register_PetEquipSuitDepart(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ConfirmDepart")) table.Register("ConfirmDepart", LAG_PetEquipSuitDepart_ConfirmDepart);
        if (IsMissing(table, "GetPetEquipDepartInfo")) table.Register("GetPetEquipDepartInfo", LAG_PetEquipSuitDepart_GetPetEquipDepartInfo);
        if (IsMissing(table, "SetPetEquipDepartFunc")) table.Register("SetPetEquipDepartFunc", LAG_PetEquipSuitDepart_SetPetEquipDepartFunc);
        if (IsMissing(table, "ShowConfirm")) table.Register("ShowConfirm", LAG_PetEquipSuitDepart_ShowConfirm);
    }
}
