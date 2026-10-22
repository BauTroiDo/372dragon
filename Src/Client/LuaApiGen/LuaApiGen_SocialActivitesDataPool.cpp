




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_SocialActivitesDataPool_AddPlayerMsg(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "AddPlayerMsg", "o"); }

        int LAG_SocialActivitesDataPool_ClearMakeFriendQue(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "ClearMakeFriendQue", ""); }

        int LAG_SocialActivitesDataPool_ClearSocialAvtivitesData(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "ClearSocialAvtivitesData", ""); }


        int LAG_SocialActivitesDataPool_GetArrayEcahRoundCampByIndex(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "GetArrayEcahRoundCampByIndex", "nnsnnnnnnnnns"); }


        int LAG_SocialActivitesDataPool_GetGoodGamePlayerByIndex(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "GetGoodGamePlayerByIndex", "nsn"); }

        int LAG_SocialActivitesDataPool_GetMakeFriendsQueFront(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "GetMakeFriendsQueFront", "nssnn"); }

        int LAG_SocialActivitesDataPool_GetNTime(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "GetNTime", "n"); }


        int LAG_SocialActivitesDataPool_GetTopLikedByMeByIndex(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "GetTopLikedByMeByIndex", "nnsnnnnnnnnns"); }


        int LAG_SocialActivitesDataPool_GetTopMostskillsToMe(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "GetTopMostskillsToMe", "nnsnnnnnnnnns"); }


        int LAG_SocialActivitesDataPool_GetTopMostskillsToMeOppositesex(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "GetTopMostskillsToMeOppositesex", "nnsnnnnnnnnns"); }


        int LAG_SocialActivitesDataPool_GetTopMostskillsToOther(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "GetTopMostskillsToOther", "nnsnnnnnnnnns"); }


        int LAG_SocialActivitesDataPool_GetTopMostskillsToOtherOppositesex(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "GetTopMostskillsToOtherOppositesex", "nnsnnnnnnnnns"); }


        int LAG_SocialActivitesDataPool_GetToplikedByotherByIndex(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "GetToplikedByotherByIndex", "nnsnnnnnnnnns"); }


        int LAG_SocialActivitesDataPool_SocialActivities_ChangeModel_AsTarget(LuaPlus::LuaState* state) { return Stub(state, "SocialActivitesDataPool", "SocialActivities_ChangeModel_AsTarget", "n"); }
    }

    void Register_SocialActivitesDataPool(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AddPlayerMsg")) table.Register("AddPlayerMsg", LAG_SocialActivitesDataPool_AddPlayerMsg);
        if (IsMissing(table, "ClearMakeFriendQue")) table.Register("ClearMakeFriendQue", LAG_SocialActivitesDataPool_ClearMakeFriendQue);
        if (IsMissing(table, "ClearSocialAvtivitesData")) table.Register("ClearSocialAvtivitesData", LAG_SocialActivitesDataPool_ClearSocialAvtivitesData);
        if (IsMissing(table, "GetArrayEcahRoundCampByIndex")) table.Register("GetArrayEcahRoundCampByIndex", LAG_SocialActivitesDataPool_GetArrayEcahRoundCampByIndex);
        if (IsMissing(table, "GetGoodGamePlayerByIndex")) table.Register("GetGoodGamePlayerByIndex", LAG_SocialActivitesDataPool_GetGoodGamePlayerByIndex);
        if (IsMissing(table, "GetMakeFriendsQueFront")) table.Register("GetMakeFriendsQueFront", LAG_SocialActivitesDataPool_GetMakeFriendsQueFront);
        if (IsMissing(table, "GetNTime")) table.Register("GetNTime", LAG_SocialActivitesDataPool_GetNTime);
        if (IsMissing(table, "GetTopLikedByMeByIndex")) table.Register("GetTopLikedByMeByIndex", LAG_SocialActivitesDataPool_GetTopLikedByMeByIndex);
        if (IsMissing(table, "GetTopMostskillsToMe")) table.Register("GetTopMostskillsToMe", LAG_SocialActivitesDataPool_GetTopMostskillsToMe);
        if (IsMissing(table, "GetTopMostskillsToMeOppositesex")) table.Register("GetTopMostskillsToMeOppositesex", LAG_SocialActivitesDataPool_GetTopMostskillsToMeOppositesex);
        if (IsMissing(table, "GetTopMostskillsToOther")) table.Register("GetTopMostskillsToOther", LAG_SocialActivitesDataPool_GetTopMostskillsToOther);
        if (IsMissing(table, "GetTopMostskillsToOtherOppositesex")) table.Register("GetTopMostskillsToOtherOppositesex", LAG_SocialActivitesDataPool_GetTopMostskillsToOtherOppositesex);
        if (IsMissing(table, "GetToplikedByotherByIndex")) table.Register("GetToplikedByotherByIndex", LAG_SocialActivitesDataPool_GetToplikedByotherByIndex);
        if (IsMissing(table, "SocialActivities_ChangeModel_AsTarget")) table.Register("SocialActivities_ChangeModel_AsTarget", LAG_SocialActivitesDataPool_SocialActivities_ChangeModel_AsTarget);
    }
}
