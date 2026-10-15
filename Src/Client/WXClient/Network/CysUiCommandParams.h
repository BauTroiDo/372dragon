#pragma once
#include <cstddef>
#include <cstring>

// GCUICommand.bos: offsets point at each terminating NUL, including empty
// strings. Validate completely before changing the fixed-size legacy buffer.
namespace CysUiCommandParams {
template<class Packet, class Params>
bool Copy(const Packet& p, Params& out) {
    const std::size_t ni = p.m_Param_m_IntCount, ns = p.m_Param_m_StrCount;
    if (ni >= 16 || ns >= 16 || ni != p.m_Param_m_aIntValue.size() ||
        ns != p.m_Param_m_aStrOffset.size() ||
        ni > sizeof(out.m_aIntValue) / sizeof(out.m_aIntValue[0]) ||
        ns > sizeof(out.m_aStrOffset) / sizeof(out.m_aStrOffset[0])) return false;
    const auto& bytes = p.m_Param_m_aStrValue;
    if (bytes.size() > sizeof(out.m_aStrValue) || (ns == 0 && !bytes.empty())) return false;
    std::size_t start = 0;
    for (std::size_t i = 0; i < ns; ++i) {
        const std::size_t end = p.m_Param_m_aStrOffset[i];
        if (end < start || end >= bytes.size() || bytes[end] != '\0' ||
            bytes.find('\0', start) != end) return false;
        start = end + 1;
    }
    if (start != bytes.size()) return false;
    out.CleanUp();
    out.m_IntCount = static_cast<unsigned char>(ni);
    out.m_StrCount = static_cast<unsigned char>(ns);
    for (std::size_t i = 0; i < ni; ++i) out.m_aIntValue[i] = p.m_Param_m_aIntValue[i];
    for (std::size_t i = 0; i < ns; ++i) out.m_aStrOffset[i] = p.m_Param_m_aStrOffset[i];
    if (!bytes.empty()) std::memcpy(out.m_aStrValue, bytes.data(), bytes.size());
    return true;
}
}
