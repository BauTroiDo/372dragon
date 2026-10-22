




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_OrnamentsScript_AskOrnamentsInfo(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "AskOrnamentsInfo", ""); }

        int LAG_OrnamentsScript_GetOrnamentsDestPos(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOrnamentsDestPos", "nnn"); }

        int LAG_OrnamentsScript_GetOrnamentsDisplayState(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOrnamentsDisplayState", "n"); }

        int LAG_OrnamentsScript_GetOrnamentsID(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOrnamentsID", "n"); }

        int LAG_OrnamentsScript_GetOrnamentsInfo(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOrnamentsInfo", "nnnnnnn"); }

        int LAG_OrnamentsScript_GetOrnamentsItemInfo(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOrnamentsItemInfo", "nnn"); }

        int LAG_OrnamentsScript_GetOrnamentsLifeTime(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOrnamentsLifeTime", "n"); }

        int LAG_OrnamentsScript_GetOrnamentsListID(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOrnamentsListID", "n"); }

        int LAG_OrnamentsScript_GetOrnamentsMaxCount(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOrnamentsMaxCount", "n"); }

        int LAG_OrnamentsScript_GetOrnamentsPos(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOrnamentsPos", "nnn"); }

        int LAG_OrnamentsScript_GetOrnamentsToolTip(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOrnamentsToolTip", ""); }

        int LAG_OrnamentsScript_GetOrnamentsUseID(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOrnamentsUseID", "n"); }

        int LAG_OrnamentsScript_GetOrnamentsUsePos(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOrnamentsUsePos", "nnn"); }

        int LAG_OrnamentsScript_GetOtherOrnamentsIDInUse(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetOtherOrnamentsIDInUse", "n"); }

        int LAG_OrnamentsScript_GetPlayerOrnamentsInfo(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetPlayerOrnamentsInfo", "nnnnn"); }

        int LAG_OrnamentsScript_GetPlayerOrnamentsTip(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "GetPlayerOrnamentsTip", "n"); }

        int LAG_OrnamentsScript_InitOrnamentsListInfo(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "InitOrnamentsListInfo", ""); }

        int LAG_OrnamentsScript_IsBigOrnamentsHead(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "IsBigOrnamentsHead", "n"); }

        int LAG_OrnamentsScript_IsHaveOrnamentsShowTip(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "IsHaveOrnamentsShowTip", "n"); }

        int LAG_OrnamentsScript_IsOrnamentsItem(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "IsOrnamentsItem", "n"); }

        int LAG_OrnamentsScript_IsOwnOrnamentsItem(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "IsOwnOrnamentsItem", "n"); }


        int LAG_OrnamentsScript_RemoveOrnamentsTip(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "RemoveOrnamentsTip", ""); }

        int LAG_OrnamentsScript_ResetOrnamentsUseInfo(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "ResetOrnamentsUseInfo", ""); }


        int LAG_OrnamentsScript_TakeOffOrnaments(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "TakeOffOrnaments", ""); }

        int LAG_OrnamentsScript_UpdateTBOrnamentsID(LuaPlus::LuaState* state) { return Stub(state, "OrnamentsScript", "UpdateTBOrnamentsID", ""); }
    }

    void Register_OrnamentsScript(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AskOrnamentsInfo")) table.Register("AskOrnamentsInfo", LAG_OrnamentsScript_AskOrnamentsInfo);
        if (IsMissing(table, "GetOrnamentsDestPos")) table.Register("GetOrnamentsDestPos", LAG_OrnamentsScript_GetOrnamentsDestPos);
        if (IsMissing(table, "GetOrnamentsDisplayState")) table.Register("GetOrnamentsDisplayState", LAG_OrnamentsScript_GetOrnamentsDisplayState);
        if (IsMissing(table, "GetOrnamentsID")) table.Register("GetOrnamentsID", LAG_OrnamentsScript_GetOrnamentsID);
        if (IsMissing(table, "GetOrnamentsInfo")) table.Register("GetOrnamentsInfo", LAG_OrnamentsScript_GetOrnamentsInfo);
        if (IsMissing(table, "GetOrnamentsItemInfo")) table.Register("GetOrnamentsItemInfo", LAG_OrnamentsScript_GetOrnamentsItemInfo);
        if (IsMissing(table, "GetOrnamentsLifeTime")) table.Register("GetOrnamentsLifeTime", LAG_OrnamentsScript_GetOrnamentsLifeTime);
        if (IsMissing(table, "GetOrnamentsListID")) table.Register("GetOrnamentsListID", LAG_OrnamentsScript_GetOrnamentsListID);
        if (IsMissing(table, "GetOrnamentsMaxCount")) table.Register("GetOrnamentsMaxCount", LAG_OrnamentsScript_GetOrnamentsMaxCount);
        if (IsMissing(table, "GetOrnamentsPos")) table.Register("GetOrnamentsPos", LAG_OrnamentsScript_GetOrnamentsPos);
        if (IsMissing(table, "GetOrnamentsToolTip")) table.Register("GetOrnamentsToolTip", LAG_OrnamentsScript_GetOrnamentsToolTip);
        if (IsMissing(table, "GetOrnamentsUseID")) table.Register("GetOrnamentsUseID", LAG_OrnamentsScript_GetOrnamentsUseID);
        if (IsMissing(table, "GetOrnamentsUsePos")) table.Register("GetOrnamentsUsePos", LAG_OrnamentsScript_GetOrnamentsUsePos);
        if (IsMissing(table, "GetOtherOrnamentsIDInUse")) table.Register("GetOtherOrnamentsIDInUse", LAG_OrnamentsScript_GetOtherOrnamentsIDInUse);
        if (IsMissing(table, "GetPlayerOrnamentsInfo")) table.Register("GetPlayerOrnamentsInfo", LAG_OrnamentsScript_GetPlayerOrnamentsInfo);
        if (IsMissing(table, "GetPlayerOrnamentsTip")) table.Register("GetPlayerOrnamentsTip", LAG_OrnamentsScript_GetPlayerOrnamentsTip);
        if (IsMissing(table, "InitOrnamentsListInfo")) table.Register("InitOrnamentsListInfo", LAG_OrnamentsScript_InitOrnamentsListInfo);
        if (IsMissing(table, "IsBigOrnamentsHead")) table.Register("IsBigOrnamentsHead", LAG_OrnamentsScript_IsBigOrnamentsHead);
        if (IsMissing(table, "IsHaveOrnamentsShowTip")) table.Register("IsHaveOrnamentsShowTip", LAG_OrnamentsScript_IsHaveOrnamentsShowTip);
        if (IsMissing(table, "IsOrnamentsItem")) table.Register("IsOrnamentsItem", LAG_OrnamentsScript_IsOrnamentsItem);
        if (IsMissing(table, "IsOwnOrnamentsItem")) table.Register("IsOwnOrnamentsItem", LAG_OrnamentsScript_IsOwnOrnamentsItem);
        if (IsMissing(table, "RemoveOrnamentsTip")) table.Register("RemoveOrnamentsTip", LAG_OrnamentsScript_RemoveOrnamentsTip);
        if (IsMissing(table, "ResetOrnamentsUseInfo")) table.Register("ResetOrnamentsUseInfo", LAG_OrnamentsScript_ResetOrnamentsUseInfo);
        if (IsMissing(table, "TakeOffOrnaments")) table.Register("TakeOffOrnaments", LAG_OrnamentsScript_TakeOffOrnaments);
        if (IsMissing(table, "UpdateTBOrnamentsID")) table.Register("UpdateTBOrnamentsID", LAG_OrnamentsScript_UpdateTBOrnamentsID);
    }
}
