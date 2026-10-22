




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_DressGem_GemFittingOnDress(LuaPlus::LuaState* state) { return Stub(state, "DressGem", "GemFittingOnDress", ""); }

        int LAG_DressGem_GemFittingOnOrigDress(LuaPlus::LuaState* state) { return Stub(state, "DressGem", "GemFittingOnOrigDress", ""); }

        int LAG_DressGem_GetCountByDressGemType(LuaPlus::LuaState* state) { return Stub(state, "DressGem", "GetCountByDressGemType", "n"); }

        int LAG_DressGem_GetGemName(LuaPlus::LuaState* state) { return Stub(state, "DressGem", "GetGemName", "s"); }

        int LAG_DressGem_GetGemQuality(LuaPlus::LuaState* state) { return Stub(state, "DressGem", "GetGemQuality", "n"); }

        int LAG_DressGem_GetIndexIDByProperty(LuaPlus::LuaState* state) { return Stub(state, "DressGem", "GetIndexIDByProperty", "n"); }

        int LAG_DressGem_GetItemNameByProperty(LuaPlus::LuaState* state) { return Stub(state, "DressGem", "GetItemNameByProperty", "ss"); }

        int LAG_DressGem_GetSameProperty(LuaPlus::LuaState* state) { return Stub(state, "DressGem", "GetSameProperty", "n"); }

        int LAG_DressGem_IsGemOnDressByItemIndex(LuaPlus::LuaState* state) { return Stub(state, "DressGem", "IsGemOnDressByItemIndex", "nnnn"); }

        int LAG_DressGem_IsGemOnDressByType(LuaPlus::LuaState* state) { return Stub(state, "DressGem", "IsGemOnDressByType", ""); }

        int LAG_DressGem_RestoreDressGemFitting(LuaPlus::LuaState* state) { return Stub(state, "DressGem", "RestoreDressGemFitting", ""); }
    }

    void Register_DressGem(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GemFittingOnDress")) table.Register("GemFittingOnDress", LAG_DressGem_GemFittingOnDress);
        if (IsMissing(table, "GemFittingOnOrigDress")) table.Register("GemFittingOnOrigDress", LAG_DressGem_GemFittingOnOrigDress);
        if (IsMissing(table, "GetCountByDressGemType")) table.Register("GetCountByDressGemType", LAG_DressGem_GetCountByDressGemType);
        if (IsMissing(table, "GetGemName")) table.Register("GetGemName", LAG_DressGem_GetGemName);
        if (IsMissing(table, "GetGemQuality")) table.Register("GetGemQuality", LAG_DressGem_GetGemQuality);
        if (IsMissing(table, "GetIndexIDByProperty")) table.Register("GetIndexIDByProperty", LAG_DressGem_GetIndexIDByProperty);
        if (IsMissing(table, "GetItemNameByProperty")) table.Register("GetItemNameByProperty", LAG_DressGem_GetItemNameByProperty);
        if (IsMissing(table, "GetSameProperty")) table.Register("GetSameProperty", LAG_DressGem_GetSameProperty);
        if (IsMissing(table, "IsGemOnDressByItemIndex")) table.Register("IsGemOnDressByItemIndex", LAG_DressGem_IsGemOnDressByItemIndex);
        if (IsMissing(table, "IsGemOnDressByType")) table.Register("IsGemOnDressByType", LAG_DressGem_IsGemOnDressByType);
        if (IsMissing(table, "RestoreDressGemFitting")) table.Register("RestoreDressGemFitting", LAG_DressGem_RestoreDressGemFitting);
    }
}
