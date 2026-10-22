




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_KFRCBOSS_LuaFnIsCKFRCBOSSGTScene(LuaPlus::LuaState* state) { return Stub(state, "KFRCBOSS", "LuaFnIsCKFRCBOSSGTScene", "n"); }


        int LAG_KFRCBOSS_LuaFnIsCKFRCBOSSLTScene(LuaPlus::LuaState* state) { return Stub(state, "KFRCBOSS", "LuaFnIsCKFRCBOSSLTScene", "n"); }


        int LAG_KFRCBOSS_LuaFnIsCKFRCBOSSScene(LuaPlus::LuaState* state) { return Stub(state, "KFRCBOSS", "LuaFnIsCKFRCBOSSScene", "n"); }

        int LAG_KFRCBOSS_LuaFnKFRCBOSSIsCanRelive(LuaPlus::LuaState* state) { return Stub(state, "KFRCBOSS", "LuaFnKFRCBOSSIsCanRelive", "n"); }
    }

    void Register_KFRCBOSS(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "LuaFnIsCKFRCBOSSGTScene")) table.Register("LuaFnIsCKFRCBOSSGTScene", LAG_KFRCBOSS_LuaFnIsCKFRCBOSSGTScene);
        if (IsMissing(table, "LuaFnIsCKFRCBOSSLTScene")) table.Register("LuaFnIsCKFRCBOSSLTScene", LAG_KFRCBOSS_LuaFnIsCKFRCBOSSLTScene);
        if (IsMissing(table, "LuaFnIsCKFRCBOSSScene")) table.Register("LuaFnIsCKFRCBOSSScene", LAG_KFRCBOSS_LuaFnIsCKFRCBOSSScene);
        if (IsMissing(table, "LuaFnKFRCBOSSIsCanRelive")) table.Register("LuaFnKFRCBOSSIsCanRelive", LAG_KFRCBOSS_LuaFnKFRCBOSSIsCanRelive);
    }
}
