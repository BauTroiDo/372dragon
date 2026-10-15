// CYS: exercise the real event callback typedef and storage, including bits above 32.
#include "TDEventDefine.h"
#include "TDEventSystem.h"
#include "GMEventSystem.h"

#include <cstdio>
#include <memory>
#include <type_traits>

namespace
{
    typedef EVENT_DEFINE::REGISTER_STRUCT::value_type::second_type Owner;
    UINT_PTR observed = 0;
    void WINAPI Record(const EVENT*, Owner value) { observed = value; }

    bool RoundTrip(const char* name, UINT_PTR token)
    {
        EVENT_DEFINE::REGISTER_STRUCT registrations;
        registrations.push_back(std::make_pair(Record, static_cast<Owner>(token)));
        observed = 0;
        const auto& callback = registrations.front();
        callback.first(nullptr, callback.second);
        bool ok = observed == token;
        std::printf("%s %s expected=0x%llX actual=0x%llX\n", ok ? "PASS" : "FAIL", name,
                    static_cast<unsigned long long>(token), static_cast<unsigned long long>(observed));
        return ok;
    }
}

int main()
{
    unsigned passed = 0;
    unsigned total = 5;
    std::printf("OWNER_BYTES=%u POINTER_BYTES=%u\n", static_cast<unsigned>(sizeof(Owner)), static_cast<unsigned>(sizeof(void*)));
    passed += RoundTrip("integer_owner_42", UINT_PTR(42));
    const UINT_PTR highToken = sizeof(UINT_PTR) > 4 ? static_cast<UINT_PTR>(0x10000001234ull) : UINT_PTR(0x1234);
    passed += RoundTrip("owner_bit40", highToken);
    std::unique_ptr<int> object(new int(7));
    passed += RoundTrip("heap_pointer_owner", reinterpret_cast<UINT_PTR>(object.get()));
    typedef void (tEventSystem::*BaseRegistration)(const STRING&, FUNC_EVENT_HANDLE, UINT_PTR);
    typedef void (CEventSystem::*ConcreteRegistration)(const STRING&, FUNC_EVENT_HANDLE, UINT_PTR);
    const bool baseWide = std::is_same<decltype(&tEventSystem::RegisterEventHandle), BaseRegistration>::value;
    const bool concreteWide = std::is_same<decltype(&CEventSystem::RegisterEventHandle), ConcreteRegistration>::value;
    std::printf("%s interface_registration_owner_pointer_sized\n", baseWide ? "PASS" : "FAIL");
    std::printf("%s concrete_registration_owner_pointer_sized\n", concreteWide ? "PASS" : "FAIL");
    passed += baseWide;
    passed += concreteWide;
    std::printf("RESULT passed=%u failed=%u total=%u\n", passed, total-passed, total);
    return passed == total ? 0 : 1;
}
