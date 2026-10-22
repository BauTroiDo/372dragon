




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_ShenqiUpgrade_GetShenqiUpMaterial(LuaPlus::LuaState* state) { return Stub(state, "ShenqiUpgrade", "GetShenqiUpMaterial", "nn"); }

        int LAG_ShenqiUpgrade_GetShenqiUpMaterialKind(LuaPlus::LuaState* state) { return Stub(state, "ShenqiUpgrade", "GetShenqiUpMaterialKind", "n"); }

        int LAG_ShenqiUpgrade_GetShenqiUpgradeInfo(LuaPlus::LuaState* state) { return Stub(state, "ShenqiUpgrade", "GetShenqiUpgradeInfo", "nn"); }
    }

    void Register_ShenqiUpgrade(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetShenqiUpMaterial")) table.Register("GetShenqiUpMaterial", LAG_ShenqiUpgrade_GetShenqiUpMaterial);
        if (IsMissing(table, "GetShenqiUpMaterialKind")) table.Register("GetShenqiUpMaterialKind", LAG_ShenqiUpgrade_GetShenqiUpMaterialKind);
        if (IsMissing(table, "GetShenqiUpgradeInfo")) table.Register("GetShenqiUpgradeInfo", LAG_ShenqiUpgrade_GetShenqiUpgradeInfo);
    }
}
