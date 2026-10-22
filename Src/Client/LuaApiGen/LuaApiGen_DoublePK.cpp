




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_DoublePK_GetBuffInfo(LuaPlus::LuaState* state) { return Stub(state, "DoublePK", "GetBuffInfo", "nn"); }


        int LAG_DoublePK_GetBuffListInfo(LuaPlus::LuaState* state) { return Stub(state, "DoublePK", "GetBuffListInfo", "n"); }

        int LAG_DoublePK_GetBuffRemainTime(LuaPlus::LuaState* state) { return Stub(state, "DoublePK", "GetBuffRemainTime", "n"); }

        int LAG_DoublePK_GetGuessInfo(LuaPlus::LuaState* state) { return Stub(state, "DoublePK", "GetGuessInfo", "nn"); }

        int LAG_DoublePK_GetGuessRemainTime(LuaPlus::LuaState* state) { return Stub(state, "DoublePK", "GetGuessRemainTime", "n"); }


        int LAG_DoublePK_GetIdentityInfo(LuaPlus::LuaState* state) { return Stub(state, "DoublePK", "GetIdentityInfo", "nnnn"); }


        int LAG_DoublePK_GetIdentityInfoByGuID(LuaPlus::LuaState* state) { return Stub(state, "DoublePK", "GetIdentityInfoByGuID", "nns"); }
    }

    void Register_DoublePK(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetBuffInfo")) table.Register("GetBuffInfo", LAG_DoublePK_GetBuffInfo);
        if (IsMissing(table, "GetBuffListInfo")) table.Register("GetBuffListInfo", LAG_DoublePK_GetBuffListInfo);
        if (IsMissing(table, "GetBuffRemainTime")) table.Register("GetBuffRemainTime", LAG_DoublePK_GetBuffRemainTime);
        if (IsMissing(table, "GetGuessInfo")) table.Register("GetGuessInfo", LAG_DoublePK_GetGuessInfo);
        if (IsMissing(table, "GetGuessRemainTime")) table.Register("GetGuessRemainTime", LAG_DoublePK_GetGuessRemainTime);
        if (IsMissing(table, "GetIdentityInfo")) table.Register("GetIdentityInfo", LAG_DoublePK_GetIdentityInfo);
        if (IsMissing(table, "GetIdentityInfoByGuID")) table.Register("GetIdentityInfoByGuID", LAG_DoublePK_GetIdentityInfoByGuID);
    }
}
