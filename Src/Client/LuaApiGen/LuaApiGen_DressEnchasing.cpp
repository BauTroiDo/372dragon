




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_DressEnchasing_Do_Dress_SeparateGem(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "Do_Dress_SeparateGem", ""); }

        int LAG_DressEnchasing_Dress_ComposeShowInfo(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "Dress_ComposeShowInfo", ""); }

        int LAG_DressEnchasing_Dress_EnchaseShowInfo(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "Dress_EnchaseShowInfo", "o"); }

        int LAG_DressEnchasing_Dress_PlayUISoundFuncNew(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "Dress_PlayUISoundFuncNew", "o"); }

        int LAG_DressEnchasing_EnableDressEnchasePreview(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "EnableDressEnchasePreview", ""); }

        int LAG_DressEnchasing_FittingOnDress(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "FittingOnDress", ""); }

        int LAG_DressEnchasing_FittingOnDressNew(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "FittingOnDressNew", ""); }

        int LAG_DressEnchasing_Get_Dress_Gem_Level(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "Get_Dress_Gem_Level", "n"); }

        int LAG_DressEnchasing_Lua_DressTransferBindConfirmed(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "Lua_DressTransferBindConfirmed", ""); }

        int LAG_DressEnchasing_Lua_FittingOnDressTransfer(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "Lua_FittingOnDressTransfer", "n"); }

        int LAG_DressEnchasing_Lua_FittingOnDressTransferOver(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "Lua_FittingOnDressTransferOver", ""); }

        int LAG_DressEnchasing_Lua_OpenDressTransferFitting(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "Lua_OpenDressTransferFitting", ""); }

        int LAG_DressEnchasing_OpenDressEnchaseFitting(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "OpenDressEnchaseFitting", ""); }

        int LAG_DressEnchasing_RestoreDressEnchaseFitting(LuaPlus::LuaState* state) { return Stub(state, "DressEnchasing", "RestoreDressEnchaseFitting", ""); }
    }

    void Register_DressEnchasing(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "Do_Dress_SeparateGem")) table.Register("Do_Dress_SeparateGem", LAG_DressEnchasing_Do_Dress_SeparateGem);
        if (IsMissing(table, "Dress_ComposeShowInfo")) table.Register("Dress_ComposeShowInfo", LAG_DressEnchasing_Dress_ComposeShowInfo);
        if (IsMissing(table, "Dress_EnchaseShowInfo")) table.Register("Dress_EnchaseShowInfo", LAG_DressEnchasing_Dress_EnchaseShowInfo);
        if (IsMissing(table, "Dress_PlayUISoundFuncNew")) table.Register("Dress_PlayUISoundFuncNew", LAG_DressEnchasing_Dress_PlayUISoundFuncNew);
        if (IsMissing(table, "EnableDressEnchasePreview")) table.Register("EnableDressEnchasePreview", LAG_DressEnchasing_EnableDressEnchasePreview);
        if (IsMissing(table, "FittingOnDress")) table.Register("FittingOnDress", LAG_DressEnchasing_FittingOnDress);
        if (IsMissing(table, "FittingOnDressNew")) table.Register("FittingOnDressNew", LAG_DressEnchasing_FittingOnDressNew);
        if (IsMissing(table, "Get_Dress_Gem_Level")) table.Register("Get_Dress_Gem_Level", LAG_DressEnchasing_Get_Dress_Gem_Level);
        if (IsMissing(table, "Lua_DressTransferBindConfirmed")) table.Register("Lua_DressTransferBindConfirmed", LAG_DressEnchasing_Lua_DressTransferBindConfirmed);
        if (IsMissing(table, "Lua_FittingOnDressTransfer")) table.Register("Lua_FittingOnDressTransfer", LAG_DressEnchasing_Lua_FittingOnDressTransfer);
        if (IsMissing(table, "Lua_FittingOnDressTransferOver")) table.Register("Lua_FittingOnDressTransferOver", LAG_DressEnchasing_Lua_FittingOnDressTransferOver);
        if (IsMissing(table, "Lua_OpenDressTransferFitting")) table.Register("Lua_OpenDressTransferFitting", LAG_DressEnchasing_Lua_OpenDressTransferFitting);
        if (IsMissing(table, "OpenDressEnchaseFitting")) table.Register("OpenDressEnchaseFitting", LAG_DressEnchasing_OpenDressEnchaseFitting);
        if (IsMissing(table, "RestoreDressEnchaseFitting")) table.Register("RestoreDressEnchaseFitting", LAG_DressEnchasing_RestoreDressEnchaseFitting);
    }
}
