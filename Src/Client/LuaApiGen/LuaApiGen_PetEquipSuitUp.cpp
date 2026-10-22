




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_PetEquipSuitUp_GetPetEquipUpMaterial(LuaPlus::LuaState* state) { return Stub(state, "PetEquipSuitUp", "GetPetEquipUpMaterial", "nns"); }

        int LAG_PetEquipSuitUp_GetPetEquipUpProductInfo(LuaPlus::LuaState* state) { return Stub(state, "PetEquipSuitUp", "GetPetEquipUpProductInfo", "nnnns"); }

        int LAG_PetEquipSuitUp_UpdateProductAction(LuaPlus::LuaState* state) { return Stub(state, "PetEquipSuitUp", "UpdateProductAction", "ob"); }
    }

    void Register_PetEquipSuitUp(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetPetEquipUpMaterial")) table.Register("GetPetEquipUpMaterial", LAG_PetEquipSuitUp_GetPetEquipUpMaterial);
        if (IsMissing(table, "GetPetEquipUpProductInfo")) table.Register("GetPetEquipUpProductInfo", LAG_PetEquipSuitUp_GetPetEquipUpProductInfo);
        if (IsMissing(table, "UpdateProductAction")) table.Register("UpdateProductAction", LAG_PetEquipSuitUp_UpdateProductAction);
    }
}
