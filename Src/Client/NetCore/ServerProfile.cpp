// CYS: strict parser for Patch/CysServerProfile.txt (see ServerProfile.h).
#include "ServerProfile.h"
#include <algorithm>

namespace cys { namespace net {

namespace {

std::string trim(const std::string& value) {
    size_t begin = 0, end = value.size();
    while (begin < end && (value[begin] == ' ' || value[begin] == '\t')) ++begin;
    while (end > begin && (value[end - 1] == ' ' || value[end - 1] == '\t')) --end;
    return value.substr(begin, end - begin);
}

bool parsePort(const std::string& text, int& port) {
    if (text.empty() || text.size() > 5) return false;
    int value = 0;
    for (const char c : text) {
        if (c < '0' || c > '9') return false;
        value = value * 10 + (c - '0');
    }
    if (value < 1 || value > 65535 || (text.size() > 1 && text[0] == '0')) return false;
    port = value;
    return true;
}

bool validName(const std::string& name) {
    if (name.empty() || name.size() > 32) return false;
    for (const char c : name)
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.'))
            return false;
    return true;
}

bool validAccount(const std::string& account) {
    if (account.empty() || account.size() > 49) return false;
    for (const char c : account)
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-')) return false;
    return true;
}

std::vector<std::string> splitList(const std::string& text) {
    std::vector<std::string> out;
    size_t start = 0;
    while (true) {
        const size_t comma = text.find(',', start);
        out.push_back(trim(text.substr(start, comma == std::string::npos ? std::string::npos : comma - start)));
        if (comma == std::string::npos) break;
        start = comma + 1;
    }
    return out;
}

struct Pending {
    ServerProfile profile;
    int headerLine = 0;
    bool name = false, login = false, gamePort = false, hosts = false, accounts = false;
};

} // namespace

ServerProfileParse ParseServerProfiles(const std::string& text) {
    ServerProfileParse result;
    auto fail = [&](int line, const char* error) {
        result.ok = false; result.line = line; result.error = error; result.profiles.clear();
        return result;
    };
    if (text.size() > MaxServerProfileBytes) return fail(0, "file too large");
    if (text.find('\0') != std::string::npos) return fail(0, "NUL byte");
    bool version = false;
    bool open = false;
    Pending current;
    std::vector<ServerProfile> profiles;
    auto close = [&](int line) -> const char* {
        if (!open) return "";
        if (!current.name || !current.login || !current.gamePort || !current.hosts) { (void)line; return "profile misses a required key"; }
        const auto& p = current.profile;
        if (std::find(p.allowedHosts.begin(), p.allowedHosts.end(), p.login.host) == p.allowedHosts.end())
            return "login host is not in allowed_hosts";
        for (const auto& other : profiles) {
            if (other.login.host == p.login.host && other.login.port == p.login.port) return "duplicate login endpoint";
            if (other.name == p.name) return "duplicate profile name";
        }
        if (profiles.size() >= MaxServerProfiles) return "too many profiles";
        profiles.push_back(current.profile);
        current = Pending();
        open = false;
        return "";
    };
    size_t pos = 0;
    int lineNo = 0;
    while (pos <= text.size()) {
        size_t eol = text.find('\n', pos);
        std::string raw = text.substr(pos, eol == std::string::npos ? std::string::npos : eol - pos);
        pos = eol == std::string::npos ? text.size() + 1 : eol + 1;
        ++lineNo;
        if (!raw.empty() && raw.back() == '\r') raw.pop_back();
        for (const unsigned char c : raw)
            if (c >= 0x80 || (c < 0x20 && c != '\t')) return fail(lineNo, "non-ASCII or control byte");
        const std::string line = trim(raw);
        if (line.empty() || line[0] == '#' || line[0] == ';') continue;
        if (!version) {
            if (line != "VERSION 1") return fail(lineNo, "first statement must be VERSION 1");
            version = true;
            continue;
        }
        if (line == "[profile]") {
            const char* error = close(lineNo);
            if (*error) return fail(current.headerLine, error);
            open = true;
            current.headerLine = lineNo;
            continue;
        }
        if (line[0] == '[') return fail(lineNo, "unknown section");
        if (!open) return fail(lineNo, "key outside a [profile] section");
        const size_t eq = line.find('=');
        if (eq == std::string::npos) return fail(lineNo, "expected key=value");
        const std::string key = trim(line.substr(0, eq));
        const std::string value = trim(line.substr(eq + 1));
        auto& p = current.profile;
        if (key == "name") {
            if (current.name) return fail(lineNo, "duplicate key");
            if (!validName(value)) return fail(lineNo, "invalid profile name");
            p.name = value; current.name = true;
        } else if (key == "login") {
            if (current.login) return fail(lineNo, "duplicate key");
            const size_t colon = value.rfind(':');
            int port = 0;
            if (colon == std::string::npos || !parsePort(value.substr(colon + 1), port)) return fail(lineNo, "invalid login port");
            const std::string host = value.substr(0, colon);
            if (!IsAllowListLiteral(host)) return fail(lineNo, "login host must be a loopback or private LAN IPv4 literal");
            p.login.host = host; p.login.port = static_cast<uint16_t>(port); current.login = true;
        } else if (key == "game_port") {
            if (current.gamePort) return fail(lineNo, "duplicate key");
            int port = 0;
            if (value == "reply") { p.gamePortFromReply = true; p.gamePort = 0; }
            else if (parsePort(value, port)) { p.gamePortFromReply = false; p.gamePort = static_cast<uint16_t>(port); }
            else return fail(lineNo, "invalid game_port");
            current.gamePort = true;
        } else if (key == "allowed_hosts") {
            if (current.hosts) return fail(lineNo, "duplicate key");
            auto hosts = splitList(value);
            if (hosts.empty() || hosts.size() > MaxAllowedHosts) return fail(lineNo, "allowed_hosts needs 1..8 entries");
            for (size_t i = 0; i < hosts.size(); ++i) {
                if (!IsAllowListLiteral(hosts[i])) return fail(lineNo, "allowed_hosts entry must be a loopback or private LAN IPv4 literal");
                if (std::find(hosts.begin(), hosts.begin() + static_cast<std::ptrdiff_t>(i), hosts[i]) != hosts.begin() + static_cast<std::ptrdiff_t>(i))
                    return fail(lineNo, "duplicate allowed_hosts entry");
            }
            p.allowedHosts = hosts; current.hosts = true;
        } else if (key == "accounts") {
            if (current.accounts) return fail(lineNo, "duplicate key");
            auto accounts = splitList(value);
            if (accounts.empty() || accounts.size() > 32) return fail(lineNo, "accounts needs 1..32 entries");
            for (const auto& account : accounts)
                if (!validAccount(account)) return fail(lineNo, "invalid account name");
            p.accounts = accounts; current.accounts = true;
        } else {
            return fail(lineNo, "unknown key");
        }
    }
    if (!version) return fail(0, "missing VERSION 1");
    const char* error = close(lineNo);
    if (*error) return fail(current.headerLine, error);
    if (profiles.empty()) return fail(0, "no [profile] section");
    result.ok = true;
    result.line = 0;
    result.error = "";
    result.profiles = std::move(profiles);
    return result;
}

const ServerProfile* FindServerProfile(const std::vector<ServerProfile>& profiles, const std::string& host, int port) {
    for (const auto& profile : profiles)
        if (profile.login.host == host && static_cast<int>(profile.login.port) == port) return &profile;
    return nullptr;
}

bool ProfileAllowsAccount(const ServerProfile& profile, const std::string& account) {
    if (profile.accounts.empty()) return true;
    return std::find(profile.accounts.begin(), profile.accounts.end(), account) != profile.accounts.end();
}

}} // namespace cys::net
