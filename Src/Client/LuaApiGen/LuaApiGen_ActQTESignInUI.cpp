




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_ActQTESignInUI_Lua_ChangeCamera(LuaPlus::LuaState* state) { return Stub(state, "ActQTESignInUI", "Lua_ChangeCamera", ""); }

        int LAG_ActQTESignInUI_Lua_ChangeModelVisible(LuaPlus::LuaState* state) { return Stub(state, "ActQTESignInUI", "Lua_ChangeModelVisible", ""); }

        int LAG_ActQTESignInUI_Lua_GetQuestionInfo(LuaPlus::LuaState* state) { return Stub(state, "ActQTESignInUI", "Lua_GetQuestionInfo", "n"); }

        int LAG_ActQTESignInUI_Lua_GetTeamInfo(LuaPlus::LuaState* state) { return Stub(state, "ActQTESignInUI", "Lua_GetTeamInfo", "nn"); }

        int LAG_ActQTESignInUI_Lua_GetTotal(LuaPlus::LuaState* state) { return Stub(state, "ActQTESignInUI", "Lua_GetTotal", "n"); }

        int LAG_ActQTESignInUI_Lua_Reset(LuaPlus::LuaState* state) { return Stub(state, "ActQTESignInUI", "Lua_Reset", ""); }

        int LAG_ActQTESignInUI_Lua_SetQuestionInfo(LuaPlus::LuaState* state) { return Stub(state, "ActQTESignInUI", "Lua_SetQuestionInfo", "o"); }

        int LAG_ActQTESignInUI_Lua_SetTeamInfo(LuaPlus::LuaState* state) { return Stub(state, "ActQTESignInUI", "Lua_SetTeamInfo", "o"); }

        int LAG_ActQTESignInUI_Lua_SetTotal(LuaPlus::LuaState* state) { return Stub(state, "ActQTESignInUI", "Lua_SetTotal", ""); }
    }

    void Register_ActQTESignInUI(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "Lua_ChangeCamera")) table.Register("Lua_ChangeCamera", LAG_ActQTESignInUI_Lua_ChangeCamera);
        if (IsMissing(table, "Lua_ChangeModelVisible")) table.Register("Lua_ChangeModelVisible", LAG_ActQTESignInUI_Lua_ChangeModelVisible);
        if (IsMissing(table, "Lua_GetQuestionInfo")) table.Register("Lua_GetQuestionInfo", LAG_ActQTESignInUI_Lua_GetQuestionInfo);
        if (IsMissing(table, "Lua_GetTeamInfo")) table.Register("Lua_GetTeamInfo", LAG_ActQTESignInUI_Lua_GetTeamInfo);
        if (IsMissing(table, "Lua_GetTotal")) table.Register("Lua_GetTotal", LAG_ActQTESignInUI_Lua_GetTotal);
        if (IsMissing(table, "Lua_Reset")) table.Register("Lua_Reset", LAG_ActQTESignInUI_Lua_Reset);
        if (IsMissing(table, "Lua_SetQuestionInfo")) table.Register("Lua_SetQuestionInfo", LAG_ActQTESignInUI_Lua_SetQuestionInfo);
        if (IsMissing(table, "Lua_SetTeamInfo")) table.Register("Lua_SetTeamInfo", LAG_ActQTESignInUI_Lua_SetTeamInfo);
        if (IsMissing(table, "Lua_SetTotal")) table.Register("Lua_SetTotal", LAG_ActQTESignInUI_Lua_SetTotal);
    }
}
