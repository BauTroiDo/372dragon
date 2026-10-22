




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_SecWeaponfiguration_EnumSecWeaponfigeAction(LuaPlus::LuaState* state) { return Stub(state, "SecWeaponfiguration", "EnumSecWeaponfigeAction", "o"); }

        int LAG_SecWeaponfiguration_GetSecWeaponfigeActionItemCount(LuaPlus::LuaState* state) { return Stub(state, "SecWeaponfiguration", "GetSecWeaponfigeActionItemCount", "n"); }

        int LAG_SecWeaponfiguration_SecWeaponfigeActionCanbeCancel(LuaPlus::LuaState* state) { return Stub(state, "SecWeaponfiguration", "SecWeaponfigeActionCanbeCancel", "n"); }
    }

    void Register_SecWeaponfiguration(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "EnumSecWeaponfigeAction")) table.Register("EnumSecWeaponfigeAction", LAG_SecWeaponfiguration_EnumSecWeaponfigeAction);
        if (IsMissing(table, "GetSecWeaponfigeActionItemCount")) table.Register("GetSecWeaponfigeActionItemCount", LAG_SecWeaponfiguration_GetSecWeaponfigeActionItemCount);
        if (IsMissing(table, "SecWeaponfigeActionCanbeCancel")) table.Register("SecWeaponfigeActionCanbeCancel", LAG_SecWeaponfiguration_SecWeaponfigeActionCanbeCancel);
    }
}
