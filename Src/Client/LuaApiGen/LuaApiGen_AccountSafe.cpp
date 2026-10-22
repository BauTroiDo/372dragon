




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_AccountSafe_SendLoginSafeCheckMsg(LuaPlus::LuaState* state) { return Stub(state, "AccountSafe", "SendLoginSafeCheckMsg", ""); }


        int LAG_AccountSafe_SendRequestSafeCodeMsg(LuaPlus::LuaState* state) { return Stub(state, "AccountSafe", "SendRequestSafeCodeMsg", ""); }
    }

    void Register_AccountSafe(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "SendLoginSafeCheckMsg")) table.Register("SendLoginSafeCheckMsg", LAG_AccountSafe_SendLoginSafeCheckMsg);
        if (IsMissing(table, "SendRequestSafeCodeMsg")) table.Register("SendRequestSafeCodeMsg", LAG_AccountSafe_SendRequestSafeCodeMsg);
    }
}
