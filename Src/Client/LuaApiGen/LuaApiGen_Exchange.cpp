




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_Exchange_CloseExchangeInfo(LuaPlus::LuaState* state) { return Stub(state, "Exchange", "CloseExchangeInfo", ""); }

        int LAG_Exchange_GetOthersGUID(LuaPlus::LuaState* state) { return Stub(state, "Exchange", "GetOthersGUID", "n"); }

        int LAG_Exchange_GetTickCount(LuaPlus::LuaState* state) { return Stub(state, "Exchange", "GetTickCount", "n"); }

        int LAG_Exchange_GetWeGameLimit(LuaPlus::LuaState* state) { return Stub(state, "Exchange", "GetWeGameLimit", "n"); }

        int LAG_Exchange_SendEnableAcceptBtn(LuaPlus::LuaState* state) { return Stub(state, "Exchange", "SendEnableAcceptBtn", ""); }
    }

    void Register_Exchange(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "CloseExchangeInfo")) table.Register("CloseExchangeInfo", LAG_Exchange_CloseExchangeInfo);
        if (IsMissing(table, "GetOthersGUID")) table.Register("GetOthersGUID", LAG_Exchange_GetOthersGUID);
        if (IsMissing(table, "GetTickCount")) table.Register("GetTickCount", LAG_Exchange_GetTickCount);
        if (IsMissing(table, "GetWeGameLimit")) table.Register("GetWeGameLimit", LAG_Exchange_GetWeGameLimit);
        if (IsMissing(table, "SendEnableAcceptBtn")) table.Register("SendEnableAcceptBtn", LAG_Exchange_SendEnableAcceptBtn);
    }
}
