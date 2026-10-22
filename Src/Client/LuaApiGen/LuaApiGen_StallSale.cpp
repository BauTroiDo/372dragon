




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_StallSale_AddAcqStallItem(LuaPlus::LuaState* state) { return Stub(state, "StallSale", "AddAcqStallItem", ""); }

        int LAG_StallSale_ConfirmRemoveStall(LuaPlus::LuaState* state) { return Stub(state, "StallSale", "ConfirmRemoveStall", ""); }

        int LAG_StallSale_GetAcqStallItem(LuaPlus::LuaState* state) { return Stub(state, "StallSale", "GetAcqStallItem", "nnnn"); }

        int LAG_StallSale_GetAcqStallItemNum(LuaPlus::LuaState* state) { return Stub(state, "StallSale", "GetAcqStallItemNum", "n"); }

        int LAG_StallSale_GetCoinType(LuaPlus::LuaState* state) { return Stub(state, "StallSale", "GetCoinType", "n"); }

        int LAG_StallSale_GetMaxAcqStallItemNum(LuaPlus::LuaState* state) { return Stub(state, "StallSale", "GetMaxAcqStallItemNum", "n"); }

        int LAG_StallSale_GetStallType(LuaPlus::LuaState* state) { return Stub(state, "StallSale", "GetStallType", "n"); }


        int LAG_StallSale_OpenAcqStall(LuaPlus::LuaState* state) { return Stub(state, "StallSale", "OpenAcqStall", ""); }


        int LAG_StallSale_OpenPetList(LuaPlus::LuaState* state) { return Stub(state, "StallSale", "OpenPetList", ""); }


        int LAG_StallSale_RemoveAcqStallItem(LuaPlus::LuaState* state) { return Stub(state, "StallSale", "RemoveAcqStallItem", ""); }

        int LAG_StallSale_UnlockSelItem(LuaPlus::LuaState* state) { return Stub(state, "StallSale", "UnlockSelItem", ""); }
    }

    void Register_StallSale(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AddAcqStallItem")) table.Register("AddAcqStallItem", LAG_StallSale_AddAcqStallItem);
        if (IsMissing(table, "ConfirmRemoveStall")) table.Register("ConfirmRemoveStall", LAG_StallSale_ConfirmRemoveStall);
        if (IsMissing(table, "GetAcqStallItem")) table.Register("GetAcqStallItem", LAG_StallSale_GetAcqStallItem);
        if (IsMissing(table, "GetAcqStallItemNum")) table.Register("GetAcqStallItemNum", LAG_StallSale_GetAcqStallItemNum);
        if (IsMissing(table, "GetCoinType")) table.Register("GetCoinType", LAG_StallSale_GetCoinType);
        if (IsMissing(table, "GetMaxAcqStallItemNum")) table.Register("GetMaxAcqStallItemNum", LAG_StallSale_GetMaxAcqStallItemNum);
        if (IsMissing(table, "GetStallType")) table.Register("GetStallType", LAG_StallSale_GetStallType);
        if (IsMissing(table, "OpenAcqStall")) table.Register("OpenAcqStall", LAG_StallSale_OpenAcqStall);
        if (IsMissing(table, "OpenPetList")) table.Register("OpenPetList", LAG_StallSale_OpenPetList);
        if (IsMissing(table, "RemoveAcqStallItem")) table.Register("RemoveAcqStallItem", LAG_StallSale_RemoveAcqStallItem);
        if (IsMissing(table, "UnlockSelItem")) table.Register("UnlockSelItem", LAG_StallSale_UnlockSelItem);
    }
}
