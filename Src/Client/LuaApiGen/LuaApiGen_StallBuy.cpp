




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_StallBuy_AcqStallItem_EnterSell(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "AcqStallItem_EnterSell", ""); }

        int LAG_StallBuy_CheckItemPrice(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "CheckItemPrice", "nn"); }

        int LAG_StallBuy_GetAcqItemCount(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "GetAcqItemCount", "n"); }

        int LAG_StallBuy_GetAcqStallItem(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "GetAcqStallItem", "nnnn"); }

        int LAG_StallBuy_GetCoinType(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "GetCoinType", "n"); }

        int LAG_StallBuy_GetItemMaxLayedNum(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "GetItemMaxLayedNum", "n"); }

        int LAG_StallBuy_GetItemName(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "GetItemName", "s"); }


        int LAG_StallBuy_GetItemNum(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "GetItemNum", "n"); }

        int LAG_StallBuy_GetPrePrice(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "GetPrePrice", "n"); }

        int LAG_StallBuy_GetStallType(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "GetStallType", "n"); }

        int LAG_StallBuy_IsHaveObject(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "IsHaveObject", "n"); }


        int LAG_StallBuy_OpenAcqStall(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "OpenAcqStall", ""); }


        int LAG_StallBuy_OpenMessageFrame(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "OpenMessageFrame", ""); }


        int LAG_StallBuy_OpenStallByObjID(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "OpenStallByObjID", ""); }


        int LAG_StallBuy_SellAcqStall(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "SellAcqStall", "n"); }

        int LAG_StallBuy_SetPrePrice(LuaPlus::LuaState* state) { return Stub(state, "StallBuy", "SetPrePrice", "o"); }
    }

    void Register_StallBuy(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AcqStallItem_EnterSell")) table.Register("AcqStallItem_EnterSell", LAG_StallBuy_AcqStallItem_EnterSell);
        if (IsMissing(table, "CheckItemPrice")) table.Register("CheckItemPrice", LAG_StallBuy_CheckItemPrice);
        if (IsMissing(table, "GetAcqItemCount")) table.Register("GetAcqItemCount", LAG_StallBuy_GetAcqItemCount);
        if (IsMissing(table, "GetAcqStallItem")) table.Register("GetAcqStallItem", LAG_StallBuy_GetAcqStallItem);
        if (IsMissing(table, "GetCoinType")) table.Register("GetCoinType", LAG_StallBuy_GetCoinType);
        if (IsMissing(table, "GetItemMaxLayedNum")) table.Register("GetItemMaxLayedNum", LAG_StallBuy_GetItemMaxLayedNum);
        if (IsMissing(table, "GetItemName")) table.Register("GetItemName", LAG_StallBuy_GetItemName);
        if (IsMissing(table, "GetItemNum")) table.Register("GetItemNum", LAG_StallBuy_GetItemNum);
        if (IsMissing(table, "GetPrePrice")) table.Register("GetPrePrice", LAG_StallBuy_GetPrePrice);
        if (IsMissing(table, "GetStallType")) table.Register("GetStallType", LAG_StallBuy_GetStallType);
        if (IsMissing(table, "IsHaveObject")) table.Register("IsHaveObject", LAG_StallBuy_IsHaveObject);
        if (IsMissing(table, "OpenAcqStall")) table.Register("OpenAcqStall", LAG_StallBuy_OpenAcqStall);
        if (IsMissing(table, "OpenMessageFrame")) table.Register("OpenMessageFrame", LAG_StallBuy_OpenMessageFrame);
        if (IsMissing(table, "OpenStallByObjID")) table.Register("OpenStallByObjID", LAG_StallBuy_OpenStallByObjID);
        if (IsMissing(table, "SellAcqStall")) table.Register("SellAcqStall", LAG_StallBuy_SellAcqStall);
        if (IsMissing(table, "SetPrePrice")) table.Register("SetPrePrice", LAG_StallBuy_SetPrePrice);
    }
}
