// CYS: real Lua globals backed by the game services; see Docs/specs/lua/host-api_vi.md.
#pragma once

#include <string>
#include <vector>

namespace LuaPlus { class LuaObject; }

namespace CysHostGlobals
{
    // The game owns context for the lifetime of the Lua state. Each closure copies
    // this descriptor, so registering another Lua state cannot replace its services.
    struct Services
    {
        void* context = nullptr;
        void (*pushEvent)(void*, const std::string&, const std::vector<std::string>&) = nullptr;
        void (*closeWindow)(void*, const std::string&, bool) = nullptr;
        bool (*openWindowBlocked)(void*) = nullptr;
        std::string (*dictionaryText)(void*, const std::string&) = nullptr;
        std::string (*stripTextColour)(void*, const std::string&) = nullptr;
    };

    // Register only nil slots, before LuaApiGen::RegisterAll. Return the number added.
    unsigned Register(LuaPlus::LuaObject& globals, const Services& services);
    unsigned RegisterTalk(LuaPlus::LuaObject& globals, const Services& services);
}
