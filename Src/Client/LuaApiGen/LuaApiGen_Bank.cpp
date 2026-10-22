




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_Bank_GetBagMoney(LuaPlus::LuaState* state) { return Stub(state, "Bank", "GetBagMoney", "nnn"); }


        int LAG_Bank_GetNpcId(LuaPlus::LuaState* state) { return Stub(state, "Bank", "GetNpcId", "n"); }


        int LAG_Bank_PackUpBank(LuaPlus::LuaState* state) { return Stub(state, "Bank", "PackUpBank", ""); }


        int LAG_Bank_SetOpenWhichBank(LuaPlus::LuaState* state) { return Stub(state, "Bank", "SetOpenWhichBank", ""); }
    }

    void Register_Bank(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetBagMoney")) table.Register("GetBagMoney", LAG_Bank_GetBagMoney);
        if (IsMissing(table, "GetNpcId")) table.Register("GetNpcId", LAG_Bank_GetNpcId);
        if (IsMissing(table, "PackUpBank")) table.Register("PackUpBank", LAG_Bank_PackUpBank);
        if (IsMissing(table, "SetOpenWhichBank")) table.Register("SetOpenWhichBank", LAG_Bank_SetOpenWhichBank);
    }
}
