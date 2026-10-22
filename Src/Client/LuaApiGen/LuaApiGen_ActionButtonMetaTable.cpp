




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_ActionButtonMetaTable_EnumEquipExtAttr(LuaPlus::LuaState* state) { return Stub(state, "ActionButtonMetaTable", "EnumEquipExtAttr", "n"); }

        int LAG_ActionButtonMetaTable_GetEquipAttrCount(LuaPlus::LuaState* state) { return Stub(state, "ActionButtonMetaTable", "GetEquipAttrCount", "n"); }

        int LAG_ActionButtonMetaTable_GetEquipDur(LuaPlus::LuaState* state) { return Stub(state, "ActionButtonMetaTable", "GetEquipDur", "n"); }

        int LAG_ActionButtonMetaTable_GetEquipDurValue(LuaPlus::LuaState* state) { return Stub(state, "ActionButtonMetaTable", "GetEquipDurValue", "nn"); }

        int LAG_ActionButtonMetaTable_GetEquipPoint(LuaPlus::LuaState* state) { return Stub(state, "ActionButtonMetaTable", "GetEquipPoint", "n"); }

        int LAG_ActionButtonMetaTable_GetItemColorInShop(LuaPlus::LuaState* state) { return Stub(state, "ActionButtonMetaTable", "GetItemColorInShop", "s"); }

        int LAG_ActionButtonMetaTable_GetItemID(LuaPlus::LuaState* state) { return Stub(state, "ActionButtonMetaTable", "GetItemID", "n"); }

        int LAG_ActionButtonMetaTable_GetItemTableIndex(LuaPlus::LuaState* state) { return Stub(state, "ActionButtonMetaTable", "GetItemTableIndex", "n"); }

        int LAG_ActionButtonMetaTable_GetOwnerItemID(LuaPlus::LuaState* state) { return Stub(state, "ActionButtonMetaTable", "GetOwnerItemID", "n"); }

        int LAG_ActionButtonMetaTable_IsActionFlash(LuaPlus::LuaState* state) { return Stub(state, "ActionButtonMetaTable", "IsActionFlash", "b"); }

        int LAG_ActionButtonMetaTable_IsEnable(LuaPlus::LuaState* state) { return Stub(state, "ActionButtonMetaTable", "IsEnable", "n"); }

        int LAG_ActionButtonMetaTable_SetLockStatus(LuaPlus::LuaState* state) { return Stub(state, "ActionButtonMetaTable", "SetLockStatus", ""); }
    }

    void Register_ActionButtonMetaTable(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "EnumEquipExtAttr")) table.Register("EnumEquipExtAttr", LAG_ActionButtonMetaTable_EnumEquipExtAttr);
        if (IsMissing(table, "GetEquipAttrCount")) table.Register("GetEquipAttrCount", LAG_ActionButtonMetaTable_GetEquipAttrCount);
        if (IsMissing(table, "GetEquipDur")) table.Register("GetEquipDur", LAG_ActionButtonMetaTable_GetEquipDur);
        if (IsMissing(table, "GetEquipDurValue")) table.Register("GetEquipDurValue", LAG_ActionButtonMetaTable_GetEquipDurValue);
        if (IsMissing(table, "GetEquipPoint")) table.Register("GetEquipPoint", LAG_ActionButtonMetaTable_GetEquipPoint);
        if (IsMissing(table, "GetItemColorInShop")) table.Register("GetItemColorInShop", LAG_ActionButtonMetaTable_GetItemColorInShop);
        if (IsMissing(table, "GetItemID")) table.Register("GetItemID", LAG_ActionButtonMetaTable_GetItemID);
        if (IsMissing(table, "GetItemTableIndex")) table.Register("GetItemTableIndex", LAG_ActionButtonMetaTable_GetItemTableIndex);
        if (IsMissing(table, "GetOwnerItemID")) table.Register("GetOwnerItemID", LAG_ActionButtonMetaTable_GetOwnerItemID);
        if (IsMissing(table, "IsActionFlash")) table.Register("IsActionFlash", LAG_ActionButtonMetaTable_IsActionFlash);
        if (IsMissing(table, "IsEnable")) table.Register("IsEnable", LAG_ActionButtonMetaTable_IsEnable);
        if (IsMissing(table, "SetLockStatus")) table.Register("SetLockStatus", LAG_ActionButtonMetaTable_SetLockStatus);
    }
}
