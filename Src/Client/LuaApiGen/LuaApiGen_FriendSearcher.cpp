




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_FriendSearcher_ClearFingerList(LuaPlus::LuaState* state) { return Stub(state, "FriendSearcher", "ClearFingerList", ""); }


        int LAG_FriendSearcher_FriendSearchAdvance(LuaPlus::LuaState* state) { return Stub(state, "FriendSearcher", "FriendSearchAdvance", ""); }


        int LAG_FriendSearcher_FriendSearchByID(LuaPlus::LuaState* state) { return Stub(state, "FriendSearcher", "FriendSearchByID", ""); }


        int LAG_FriendSearcher_FriendSearchByName(LuaPlus::LuaState* state) { return Stub(state, "FriendSearcher", "FriendSearchByName", ""); }

        int LAG_FriendSearcher_GetFriendFromPage(LuaPlus::LuaState* state) { return Stub(state, "FriendSearcher", "GetFriendFromPage", "s"); }

        int LAG_FriendSearcher_GetFriendNumberInPage(LuaPlus::LuaState* state) { return Stub(state, "FriendSearcher", "GetFriendNumberInPage", "n"); }

        int LAG_FriendSearcher_GetFriendPageNumber(LuaPlus::LuaState* state) { return Stub(state, "FriendSearcher", "GetFriendPageNumber", "n"); }

        int LAG_FriendSearcher_OpenFriendSearch(LuaPlus::LuaState* state) { return Stub(state, "FriendSearcher", "OpenFriendSearch", ""); }
    }

    void Register_FriendSearcher(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ClearFingerList")) table.Register("ClearFingerList", LAG_FriendSearcher_ClearFingerList);
        if (IsMissing(table, "FriendSearchAdvance")) table.Register("FriendSearchAdvance", LAG_FriendSearcher_FriendSearchAdvance);
        if (IsMissing(table, "FriendSearchByID")) table.Register("FriendSearchByID", LAG_FriendSearcher_FriendSearchByID);
        if (IsMissing(table, "FriendSearchByName")) table.Register("FriendSearchByName", LAG_FriendSearcher_FriendSearchByName);
        if (IsMissing(table, "GetFriendFromPage")) table.Register("GetFriendFromPage", LAG_FriendSearcher_GetFriendFromPage);
        if (IsMissing(table, "GetFriendNumberInPage")) table.Register("GetFriendNumberInPage", LAG_FriendSearcher_GetFriendNumberInPage);
        if (IsMissing(table, "GetFriendPageNumber")) table.Register("GetFriendPageNumber", LAG_FriendSearcher_GetFriendPageNumber);
        if (IsMissing(table, "OpenFriendSearch")) table.Register("OpenFriendSearch", LAG_FriendSearcher_OpenFriendSearch);
    }
}
