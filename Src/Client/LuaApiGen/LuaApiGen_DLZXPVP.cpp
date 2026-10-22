




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_DLZXPVP_GetSceneData(LuaPlus::LuaState* state) { return Stub(state, "DLZXPVP", "GetSceneData", "nnnn"); }

        int LAG_DLZXPVP_GetSceneData_DLSY(LuaPlus::LuaState* state) { return Stub(state, "DLZXPVP", "GetSceneData_DLSY", "nnnn"); }
    }

    void Register_DLZXPVP(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetSceneData")) table.Register("GetSceneData", LAG_DLZXPVP_GetSceneData);
        if (IsMissing(table, "GetSceneData_DLSY")) table.Register("GetSceneData_DLSY", LAG_DLZXPVP_GetSceneData_DLSY);
    }
}
