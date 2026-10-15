// CYS: read-only Lua host queries backed by game-owned services.
#pragma once

#include <cstdint>
#include <string>

namespace LuaPlus { class LuaObject; class LuaState; }

namespace CysHostQueries
{
    struct LoginServerInfo
    {
        std::string name;
        int status = 0, recommendLevel = 0, isNew = 0, provider = -1;
        int rowOrdinal = 0, areaIndex = 0, serverId = 0, serverIndex = 0;
    };
    // Each Lua closure copies the descriptor. Context is borrowed and must remain
    // valid until its Lua state is released; registration never owns game objects.
    struct Services
    {
        void* context = nullptr;
        std::int32_t (*bagItemTableIndex)(void*, std::int32_t) = nullptr;
        // Borrowed result must remain valid through lua_pushstring on this thread.
        const char* (*areaDescription)(void*, std::int32_t) = nullptr;
        std::int32_t (*areaRecommendLevel)(void*, std::int32_t) = nullptr;
        void (*setCurrentServerPage)(void*, std::int32_t) = nullptr;
        std::int32_t (*setLoginServerKeyword)(void*, const std::string&) = nullptr;
        bool (*keywordLoginServerInfo)(void*, std::int32_t, LoginServerInfo&) = nullptr;
    };

    // Extend the existing boxed PlayerPackage metatable, only when the method is
    // nil. Return the number added. A missing receiver/metatable throws a fixed
    // integration error; never create a placeholder or replace the receiver.
    unsigned Register(LuaPlus::LuaObject& globals, const Services& services);
    // Same nil-only contract for the existing GameProduceLogin receiver.
    unsigned RegisterLogin(LuaPlus::LuaObject& globals, const Services& services);
    unsigned RegisterGlLogin(LuaPlus::LuaObject& globals, const Services& services);
    // The native legacy binding and contract tests share the actual tuple writer.
    int PushLoginServerInfo(LuaPlus::LuaState* state, const LoginServerInfo* info);

    struct AccountServices
    {
        void* context = nullptr;
        bool (*acceptingInput)(void*) = nullptr;
        int (*copyEditText)(void*, const char*, char*, unsigned) = nullptr;
        void (*submit)(void*, const std::string&, const std::string&) = nullptr;
    };
    // Shared native binding: GL suffix reads real editboxes; legacy accepts two texts.
    int CheckAccount(LuaPlus::LuaState* state, const AccountServices& services);
}
