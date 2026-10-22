
#pragma once
#include "LuaPlus.h"

namespace LuaApiGen
{
    //! Stubs for host functions only the CY 3.71 UI scripts call (see the .cpp header comment). Never overrides an
    //! existing function; call right after RegisterAll().
    void RegisterCyExtras(LuaPlus::LuaState* pState);
}
