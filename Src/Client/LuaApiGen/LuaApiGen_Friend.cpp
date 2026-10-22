




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_Friend_AgreeMarry(LuaPlus::LuaState* state) { return Stub(state, "Friend", "AgreeMarry", "o"); }

        int LAG_Friend_IsPlayerIsFriendNotTemp(LuaPlus::LuaState* state) { return Stub(state, "Friend", "IsPlayerIsFriendNotTemp", "n"); }
    }

    void Register_Friend(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AgreeMarry")) table.Register("AgreeMarry", LAG_Friend_AgreeMarry);
        if (IsMissing(table, "IsPlayerIsFriendNotTemp")) table.Register("IsPlayerIsFriendNotTemp", LAG_Friend_IsPlayerIsFriendNotTemp);
    }
}
