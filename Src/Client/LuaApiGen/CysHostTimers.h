// CYS: Lua timer contract recovered from B; see Docs/specs/lua/timers_vi.md.
#pragma once

#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <string>

namespace LuaPlus { class LuaObject; }

namespace CysHostTimers
{
    using TimerId = std::uintptr_t;
    class Manager;

    class Backend
    {
    public:
        virtual ~Backend() = default;
        virtual TimerId Start(std::uint32_t milliseconds) = 0;
        virtual void Kill(TimerId id) = 0;
        virtual void Evaluate(const std::string& owner, const std::string& expression) = 0;
        virtual void Bind(const std::weak_ptr<Manager>& manager) { (void)manager; }
        // Forget routing only when a record is erased, not on numeric KillTimer.
        virtual void Forget(TimerId id) { (void)id; }
        virtual void ReportError(const std::string& message) noexcept;
    };

    class Manager
    {
    public:
        static std::shared_ptr<Manager> Create(const std::shared_ptr<Backend>& backend);
        ~Manager() noexcept;
        Manager(const Manager&) = delete;
        Manager& operator=(const Manager&) = delete;

        std::int32_t Set(const std::string& owner, const std::string& expression,
                         double milliseconds);
        void KillId(double id);
        void KillExpression(const std::string& expression);
        void Clear();
        void Dispatch(TimerId id);

    private:
        struct Record
        {
            TimerId platformId;
            std::string owner;
            std::string expression;
        };
        explicit Manager(const std::shared_ptr<Backend>& backend);
        std::shared_ptr<Backend> m_backend;
        std::map<std::uint32_t, Record> m_records;
    };

    struct WindowsCallbacks
    {
        std::function<void(const std::string&, const std::string&)> evaluate;
        std::function<void(const std::string&)> reportError;
    };

    // Create and use on the game/message-pump thread. Errors must remain visible.
    // TimerProc catches callback exceptions, reports them, and never crosses Win32.
    std::shared_ptr<Backend> MakeWindowsBackend(const WindowsCallbacks& callbacks);

    // Weak closures fail clearly after the owning manager is released.
    // Register only nil slots, before LuaApiGen::RegisterAll; return number added.
    unsigned Register(LuaPlus::LuaObject& globals, const std::shared_ptr<Manager>& manager);
}
