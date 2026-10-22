#pragma once




















#include "LuaPlus.h"

namespace CysMeshWinHost
{
    int Register(LuaPlus::LuaState* state);   // returns how many host functions were (re)registered
    void RegisterHost();                      // resolves the Lua state from CScriptSystem
    int WuhunModelId(int itemTableId, int wuhunLevel);   // KFSBase lookup; -1 = unknown item / no table
    bool UpdateWuhunModel();                  // the body of DataPool:KFS_UpdateKFSModel
}

namespace CysMeshWinProbe
{
    bool Tick();   // true when off or finished (same contract as CysHostHost2::Tick)
}
