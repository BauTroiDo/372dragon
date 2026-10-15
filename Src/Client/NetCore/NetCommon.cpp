#include "NetCommon.h"
#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>
#include <algorithm>
#include <vector>

namespace cys { namespace net {

const char* ErrorCodeName(ErrorCode code) {
    switch (code) {
    case ErrorCode::None: return "none";
    case ErrorCode::InvalidInput: return "invalid_input";
    case ErrorCode::Busy: return "busy";
    case ErrorCode::WrongThread: return "wrong_thread";
    case ErrorCode::ConnectFailed: return "connect_failed";
    case ErrorCode::Timeout: return "timeout";
    case ErrorCode::Io: return "io";
    case ErrorCode::PeerClosed: return "peer_closed";
    case ErrorCode::Decode: return "decode";
    case ErrorCode::UnexpectedPacket: return "unexpected_packet";
    case ErrorCode::Limit: return "limit";
    case ErrorCode::Internal: return "internal";
    case ErrorCode::NotReady: return "not_ready";
    }
    return "unknown";
}

bool IsLoopbackLiteral(const std::string& host) {
    if (host.empty() || host.size() > 15 || host.find('\0') != std::string::npos) return false;
    for (const char c : host)
        if (!((c >= '0' && c <= '9') || c == '.')) return false;
    IN_ADDR address{};
    if (InetPtonA(AF_INET, host.c_str(), &address) != 1) return false;
    return (ntohl(address.S_un.S_addr) >> 24) == 127;
}

namespace {
bool parseDotted(const std::string& host, uint32_t& value) {
    if (host.empty() || host.size() > 15 || host.find('\0') != std::string::npos) return false;
    for (const char c : host)
        if (!((c >= '0' && c <= '9') || c == '.')) return false;
    IN_ADDR address{};
    if (InetPtonA(AF_INET, host.c_str(), &address) != 1) return false;
    value = ntohl(address.S_un.S_addr);
    return true;
}
} // namespace

// CYS: allow-list policy for configured server profiles.
bool IsPrivateLanLiteral(const std::string& host) {
    uint32_t v = 0;
    if (!parseDotted(host, v)) return false;
    return (v >> 24) == 10 || (v >> 20) == ((172u << 4) | 1u) || (v >> 16) == ((192u << 8) | 168u);
}

bool IsLocalInterfaceAddress(const std::string& host) {
    uint32_t wanted = 0;
    if (!parseDotted(host, wanted)) return false;
    ULONG size = 16 * 1024;
    std::vector<unsigned char> buffer;
    ULONG rc = ERROR_BUFFER_OVERFLOW;
    for (int attempt = 0; attempt < 4 && rc == ERROR_BUFFER_OVERFLOW; ++attempt) {
        buffer.assign(size, 0);
        rc = GetAdaptersAddresses(AF_INET, GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST | GAA_FLAG_SKIP_DNS_SERVER,
                                  nullptr, reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data()), &size);
    }
    if (rc != NO_ERROR) return false;
    for (auto* adapter = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data()); adapter; adapter = adapter->Next) {
        for (auto* unicast = adapter->FirstUnicastAddress; unicast; unicast = unicast->Next) {
            const SOCKADDR* sa = unicast->Address.lpSockaddr;
            if (!sa || sa->sa_family != AF_INET) continue;
            if (ntohl(reinterpret_cast<const sockaddr_in*>(sa)->sin_addr.S_un.S_addr) == wanted) return true;
        }
    }
    return false;
}

bool IsAllowListLiteral(const std::string& host) {
    return IsLoopbackLiteral(host) || IsPrivateLanLiteral(host);
}

bool ValidAllowedHosts(const std::vector<std::string>& allowedHosts) {
    if (allowedHosts.size() > MaxAllowedHosts) return false;
    for (const auto& host : allowedHosts)
        if (!IsAllowListLiteral(host)) return false;
    return true;
}

bool IsHostAllowed(const std::string& host, const std::vector<std::string>& allowedHosts) {
    if (allowedHosts.empty()) return IsLoopbackLiteral(host);
    if (!ValidAllowedHosts(allowedHosts) ||
        std::find(allowedHosts.begin(), allowedHosts.end(), host) == allowedHosts.end()) return false;
    return IsLoopbackLiteral(host) || (IsPrivateLanLiteral(host) && IsLocalInterfaceAddress(host));
}

}} // namespace cys::net
