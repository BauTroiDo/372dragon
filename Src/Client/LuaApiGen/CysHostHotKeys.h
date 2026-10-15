// CYS: SetCanUseHotKey bridge to the game-owned input service.
#pragma once
#include <cstdint>
namespace LuaPlus { class LuaObject; }

namespace CysHostHotKeys
{
    struct Services
    {
        void* context = nullptr;
        void (*setCanUseHotKey)(void*, std::int32_t) = nullptr;
    };
    // Copies the descriptor; the borrowed context outlives its Lua state.
    // Extends only a nil method in the existing boxed DataPool metatable.
    unsigned Register(LuaPlus::LuaObject& globals, const Services& services);
}
