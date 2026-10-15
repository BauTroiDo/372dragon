// CYS: clean-room timer manager from the documented host contract.
#include "CysHostTimers.h"
#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif
#include "LuaPlus.h"

#include <cmath>
#include <cstdio>
#include <exception>
#include <limits>
#include <new>
#include <stdexcept>
#include <utility>

namespace CysHostTimers
{
    namespace
    {
        void DefaultReport(const char* message) noexcept
        {
            std::fputs("CysHostTimers: ", stderr);
            std::fputs(message, stderr);
            std::fputc('\n', stderr);
#ifdef _WIN32
            OutputDebugStringA("CysHostTimers: ");
            OutputDebugStringA(message);
            OutputDebugStringA("\n");
#endif
        }

        void ReportCurrentFailure(Backend& backend, const char* operation) noexcept
        {
            try
            {
                try { throw; }
                catch (const std::exception&)
                {
                    backend.ReportError(std::string(operation) + ": C++ exception");
                }
                catch (const LuaPlus::LuaException&)
                {
                    backend.ReportError(std::string(operation) + ": Lua exception");
                }
                catch (...)
                {
                    backend.ReportError(std::string(operation) + ": unknown exception");
                }
            }
            catch (...)
            {
                DefaultReport(operation);
            }
        }

        std::int32_t ToInt32(double value)
        {
            const std::int32_t minimum = (std::numeric_limits<std::int32_t>::min)();
            if (!std::isfinite(value))
                return minimum;
            const double truncated = std::trunc(value);
            if (truncated < static_cast<double>(minimum) ||
                truncated > static_cast<double>((std::numeric_limits<std::int32_t>::max)()))
                return minimum;
            return static_cast<std::int32_t>(truncated);
        }

        void CancelAndForget(Backend& backend, TimerId id)
        {
            std::exception_ptr failure;
            try { backend.Kill(id); }
            catch (...)
            {
                failure = std::current_exception();
                ReportCurrentFailure(backend, "timer cancellation failed");
            }
            try { backend.Forget(id); }
            catch (...)
            {
                if (!failure) failure = std::current_exception();
                ReportCurrentFailure(backend, "timer route cleanup failed");
            }
            if (failure) std::rethrow_exception(failure);
        }

#ifdef _WIN32
        class WindowsBackend;
        struct Route
        {
            const WindowsBackend* identity;
            std::weak_ptr<Manager> manager;
            std::weak_ptr<WindowsBackend> backend;
        };
        using RouteMap = std::map<TimerId, Route>;
        std::shared_ptr<RouteMap> GetRoutes()
        {
            static thread_local std::shared_ptr<RouteMap> routes = std::make_shared<RouteMap>();
            return routes;
        }
        void CALLBACK TimerProc(HWND, UINT, UINT_PTR id, DWORD) noexcept;

        class WindowsBackend final : public Backend,
                                     public std::enable_shared_from_this<WindowsBackend>
        {
        public:
            explicit WindowsBackend(const WindowsCallbacks& callbacks)
                : m_callbacks(callbacks), m_thread(GetCurrentThreadId()), m_routes(GetRoutes())
            {
                if (!m_callbacks.evaluate)
                    throw std::invalid_argument("timer evaluation service is unavailable");
            }

            ~WindowsBackend() noexcept override
            {
                if (GetCurrentThreadId() != m_thread)
                {
                    DefaultReport("Windows backend destroyed outside its message-pump thread");
                    return;
                }
                for (auto it = m_routes->begin(); it != m_routes->end();)
                {
                    if (it->second.identity == this)
                    {
                        ::KillTimer(nullptr, static_cast<UINT_PTR>(it->first));
                        it = m_routes->erase(it);
                    }
                    else ++it;
                }
            }

            void Bind(const std::weak_ptr<Manager>& manager) override
            {
                CheckThread();
                if (!m_manager.expired())
                    throw std::logic_error("Windows timer backend already has a manager");
                m_manager = manager;
            }

            TimerId Start(std::uint32_t milliseconds) override
            {
                CheckThread();
                if (m_manager.expired())
                    throw std::runtime_error("timer manager is unavailable");
                const UINT_PTR id = ::SetTimer(nullptr, 0, milliseconds, TimerProc);
                if (id == 0)
                {
                    ReportError("SetTimer failed with Windows error " + std::to_string(GetLastError()));
                    return 0;
                }
                try
                {
                    (*m_routes)[static_cast<TimerId>(id)] = Route{this, m_manager, shared_from_this()};
                }
                catch (...)
                {
                    ::KillTimer(nullptr, id);
                    throw;
                }
                return static_cast<TimerId>(id);
            }

            void Kill(TimerId id) override
            {
                CheckThread();
                const auto found = m_routes->find(id);
                // A different manager may now own an ID released by a numeric kill.
                if (found != m_routes->end() && found->second.identity == this)
                    ::KillTimer(nullptr, static_cast<UINT_PTR>(id));
            }

            void Forget(TimerId id) override
            {
                CheckThread();
                const auto found = m_routes->find(id);
                if (found != m_routes->end() && found->second.identity == this)
                    m_routes->erase(found);
            }

            void Evaluate(const std::string& owner, const std::string& expression) override
            {
                CheckThread();
                m_callbacks.evaluate(owner, expression);
            }

            void ReportError(const std::string& message) noexcept override
            {
                if (!m_callbacks.reportError)
                {
                    DefaultReport(message.c_str());
                    return;
                }
                try { m_callbacks.reportError(message); }
                catch (...)
                {
                    DefaultReport(message.c_str());
                    DefaultReport("the timer error reporter also failed");
                }
            }

        private:
            void CheckThread() const
            {
                if (GetCurrentThreadId() != m_thread)
                    throw std::logic_error("Windows timers require their message-pump thread");
            }
            WindowsCallbacks m_callbacks;
            DWORD m_thread;
            std::weak_ptr<Manager> m_manager;
            // Keep routes alive if static manager cleanup follows TLS destruction.
            std::shared_ptr<RouteMap> m_routes;
        };

        void CALLBACK TimerProc(HWND, UINT, UINT_PTR id, DWORD) noexcept
        {
            try
            {
                const auto routes = GetRoutes();
                const auto found = routes->find(static_cast<TimerId>(id));
                if (found == routes->end()) return;
                const auto manager = found->second.manager.lock();
                const auto backend = found->second.backend.lock();
                if (!manager || !backend)
                {
                    ::KillTimer(nullptr, id);
                    routes->erase(found);
                    return;
                }
                try { manager->Dispatch(static_cast<TimerId>(id)); }
                catch (...) { ReportCurrentFailure(*backend, "timer callback failed"); }
            }
            catch (...)
            {
                DefaultReport("timer callback routing failed");
            }
        }
#endif

        struct WeakHandle
        {
            std::weak_ptr<Manager> manager;
            bool alive;
        };
        const char* const handleMetatable = "CysHostTimers.WeakManager";
        class ExpiredManager : public std::runtime_error
        {
        public:
            ExpiredManager() : std::runtime_error("timer manager is unavailable") {}
        };

        int CollectHandle(lua_State* state)
        {
            auto* handle = static_cast<WeakHandle*>(luaL_checkudata(state, 1, handleMetatable));
            if (!handle)
                return luaL_error(state, "timer collector requires a timer-manager handle");
            if (handle->alive)
            {
                handle->manager.~weak_ptr<Manager>();
                handle->alive = false;
            }
            return 0;
        }

        std::shared_ptr<Manager> GetManager(lua_State* state)
        {
            auto* handle = static_cast<WeakHandle*>(lua_touserdata(state, lua_upvalueindex(1)));
            if (handle && handle->alive)
            {
                auto manager = handle->manager.lock();
                if (manager) return manager;
            }
            throw ExpiredManager();
        }

        int SetTimer(lua_State* state)
        {
            const auto manager = GetManager(state);
            if (!lua_isstring(state, 1) || !lua_isstring(state, 2) ||
                lua_type(state, 3) != LUA_TNUMBER)
            {
                lua_pushnumber(state, -1);
                return 1;
            }
            const std::int32_t id = manager->Set(lua_tostring(state, 1), lua_tostring(state, 2),
                                                  lua_tonumber(state, 3));
            lua_pushnumber(state, static_cast<lua_Number>(id));
            return 1;
        }

        int KillTimer(lua_State* state)
        {
            const auto manager = GetManager(state);
            if (lua_type(state, 1) == LUA_TNUMBER)
                manager->KillId(lua_tonumber(state, 1));
            else if (lua_type(state, 1) == LUA_TSTRING)
                manager->KillExpression(lua_tostring(state, 1));
            else
            {
                lua_pushboolean(state, 0);
                return 1;
            }
            lua_pushboolean(state, 1);
            return 1;
        }

        int ClearAllTimer(lua_State* state)
        {
            GetManager(state)->Clear();
            return 0;
        }

        int CallLua(lua_State* state, lua_CFunction function)
        {
            try { return function(state); }
            catch (const ExpiredManager&)
            {
                lua_pushstring(state, "timer service failed: timer manager is unavailable");
            }
            catch (const std::exception&)
            {
                lua_pushstring(state, "timer service failed: C++ exception");
            }
            catch (const LuaPlus::LuaException&)
            {
                lua_pushstring(state, "timer service failed: Lua exception");
            }
            catch (...)
            {
                lua_pushstring(state, "timer service failed: unknown exception");
            }
            // Lua errors are raised only after shared pointers/strings unwind.
            return lua_error(state);
        }

        int LuaSetTimer(lua_State* state) { return CallLua(state, SetTimer); }
        int LuaKillTimer(lua_State* state) { return CallLua(state, KillTimer); }
        int LuaClearAllTimer(lua_State* state) { return CallLua(state, ClearAllTimer); }

        unsigned RegisterOne(LuaPlus::LuaObject& globals, const char* name,
                             lua_CFunction function, const std::shared_ptr<Manager>& manager)
        {
            if (!globals.GetByName(name).IsNil()) return 0;
            lua_State* state = globals.GetState()->GetCState();
            globals.PushStack();
            lua_pushstring(state, name);
            new (lua_newuserdata(state, sizeof(WeakHandle))) WeakHandle{manager, true};
            luaL_getmetatable(state, handleMetatable);
            lua_setmetatable(state, -2);
            lua_pushcclosure(state, function, 1);
            lua_rawset(state, -3);
            lua_pop(state, 1);
            return 1;
        }
    }

    void Backend::ReportError(const std::string& message) noexcept
    {
        DefaultReport(message.c_str());
    }

    Manager::Manager(const std::shared_ptr<Backend>& backend) : m_backend(backend) {}

    std::shared_ptr<Manager> Manager::Create(const std::shared_ptr<Backend>& backend)
    {
        if (!backend) throw std::invalid_argument("timer backend is unavailable");
        std::shared_ptr<Manager> manager(new Manager(backend));
        backend->Bind(manager);
        return manager;
    }

    Manager::~Manager() noexcept
    {
        try { Clear(); }
        catch (...) { ReportCurrentFailure(*m_backend, "timer manager shutdown failed"); }
    }

    std::int32_t Manager::Set(const std::string& owner, const std::string& expression,
                              double milliseconds)
    {
        Record record{0, std::string(owner.c_str()), std::string(expression.c_str())};
        const TimerId id = m_backend->Start(static_cast<std::uint32_t>(ToInt32(milliseconds)));
        if (id == 0) return 0;
        if (id > static_cast<TimerId>((std::numeric_limits<std::int32_t>::max)()))
        {
            CancelAndForget(*m_backend, id);
            m_backend->ReportError("Windows timer ID exceeds the positive int32 Lua contract");
            return 0;
        }
        record.platformId = id;
        try
        {
            // B inserts by unsigned ID and retains an old record on ID reuse.
            m_records.emplace(static_cast<std::uint32_t>(id), std::move(record));
        }
        catch (...)
        {
            const std::exception_ptr failure = std::current_exception();
            try { CancelAndForget(*m_backend, id); }
            catch (...) { ReportCurrentFailure(*m_backend, "failed timer insertion cleanup"); }
            std::rethrow_exception(failure);
        }
        return static_cast<std::int32_t>(id);
    }

    void Manager::KillId(double id)
    {
        const auto found = m_records.find(static_cast<std::uint32_t>(ToInt32(id)));
        if (found != m_records.end()) m_backend->Kill(found->second.platformId);
    }

    void Manager::KillExpression(const std::string& expression)
    {
        const std::string text(expression.c_str());
        for (auto it = m_records.begin(); it != m_records.end(); ++it)
        {
            if (it->second.expression == text)
            {
                const TimerId id = it->second.platformId;
                m_records.erase(it);
                CancelAndForget(*m_backend, id);
                return;
            }
        }
    }

    void Manager::Clear()
    {
        std::map<std::uint32_t, Record> records;
        records.swap(m_records);
        std::exception_ptr failure;
        for (const auto& entry : records)
        {
            try { CancelAndForget(*m_backend, entry.second.platformId); }
            catch (...)
            {
                if (!failure) failure = std::current_exception();
            }
        }
        if (failure) std::rethrow_exception(failure);
    }

    void Manager::Dispatch(TimerId id)
    {
        if (id > static_cast<TimerId>((std::numeric_limits<std::uint32_t>::max)())) return;
        const auto found = m_records.find(static_cast<std::uint32_t>(id));
        if (found == m_records.end()) return;
        const Record record = found->second;
        const auto backend = m_backend;
        if (!record.owner.empty() && !record.expression.empty())
            backend->Evaluate(record.owner, record.expression);
    }

    std::shared_ptr<Backend> MakeWindowsBackend(const WindowsCallbacks& callbacks)
    {
#ifdef _WIN32
        return std::make_shared<WindowsBackend>(callbacks);
#else
        (void)callbacks;
        throw std::runtime_error("Windows timer backend is unavailable on this platform");
#endif
    }

    unsigned Register(LuaPlus::LuaObject& globals, const std::shared_ptr<Manager>& manager)
    {
        if (!manager) throw std::invalid_argument("timer manager is unavailable");
        lua_State* state = globals.GetState()->GetCState();
        if (luaL_newmetatable(state, handleMetatable))
        {
            lua_pushstring(state, "__gc");
            lua_pushcfunction(state, CollectHandle);
            lua_rawset(state, -3);
            lua_pushstring(state, "__metatable");
            lua_pushstring(state, "CysHostTimers weak manager");
            lua_rawset(state, -3);
        }
        lua_pop(state, 1);
        unsigned added = RegisterOne(globals, "SetTimer", LuaSetTimer, manager);
        added += RegisterOne(globals, "KillTimer", LuaKillTimer, manager);
        added += RegisterOne(globals, "ClearAllTimer", LuaClearAllTimer, manager);
        return added;
    }
}
