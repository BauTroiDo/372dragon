#pragma once
namespace LuaPlus { class LuaObject; }

namespace CysHostInput
{
    struct Services
    {
        void* context = nullptr;
        const char* (*activeInputName)(void*) = nullptr;
        int (*capsLockStatus)(void*) = nullptr;
    };
    // Copies the descriptor; its borrowed context must outlive the Lua state.
    // Register before LuaApiGen::RegisterAll. Existing host functions win.
    unsigned Register(LuaPlus::LuaObject& globals, const Services& services);
}
