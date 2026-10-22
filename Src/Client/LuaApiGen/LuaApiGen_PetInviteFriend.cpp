




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_PetInviteFriend_SendAuditMsg(LuaPlus::LuaState* state) { return Stub(state, "PetInviteFriend", "SendAuditMsg", ""); }


        int LAG_PetInviteFriend_ShowPetFriends(LuaPlus::LuaState* state) { return Stub(state, "PetInviteFriend", "ShowPetFriends", ""); }


        int LAG_PetInviteFriend_ShowSearchPage(LuaPlus::LuaState* state) { return Stub(state, "PetInviteFriend", "ShowSearchPage", ""); }
    }

    void Register_PetInviteFriend(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "SendAuditMsg")) table.Register("SendAuditMsg", LAG_PetInviteFriend_SendAuditMsg);
        if (IsMissing(table, "ShowPetFriends")) table.Register("ShowPetFriends", LAG_PetInviteFriend_ShowPetFriends);
        if (IsMissing(table, "ShowSearchPage")) table.Register("ShowSearchPage", LAG_PetInviteFriend_ShowSearchPage);
    }
}
