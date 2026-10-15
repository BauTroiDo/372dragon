#pragma once
// CYS: server profiles for the modern (skynet) protocol, read from Patch/CysServerProfile.txt.
// A profile binds one login endpoint of the login list to its game-port policy, the host
// allow-list and an optional account filter, so Game.exe needs no endpoint constants.
// Pure parser: no file, socket or WXClient dependency. Format (ASCII, LF or CRLF):
//
//   VERSION 1
//   # full-line comments start with '#' or ';'
//   [profile]
//   name=cys-server
//   login=127.0.0.1:15733
//   game_port=15734            (1..65535, or "reply" = the port named by LCRetCharLogin)
//   allowed_hosts=127.0.0.1    (1..8 loopback/private LAN IPv4 literals; must contain the login host)
//   accounts=test00            (optional comma list; absent = any account the transport accepts)
//
// Every key is required once per profile except accounts; unknown keys, duplicate keys or
// duplicate login endpoints reject the whole file. See Docs/specs/net/cys-server_vi.md.

#include "NetCommon.h"
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

namespace cys { namespace net {

struct ServerProfile {
    std::string name;
    Endpoint login;
    uint16_t gamePort = 0;          // 0 only when gamePortFromReply
    bool gamePortFromReply = false;
    std::vector<std::string> allowedHosts;
    std::vector<std::string> accounts; // empty = no account filter
};

struct ServerProfileParse {
    bool ok = false;
    int line = 0;             // 1-based line of the first error (0 = whole file)
    const char* error = "";   // fixed diagnostic, never file text
    std::vector<ServerProfile> profiles;
};

constexpr size_t MaxServerProfileBytes = 64 * 1024;
constexpr size_t MaxServerProfiles = 16;

ServerProfileParse ParseServerProfiles(const std::string& text);
// Exact host/port match of a login endpoint; nullptr when no profile names it.
const ServerProfile* FindServerProfile(const std::vector<ServerProfile>& profiles, const std::string& host, int port);
bool ProfileAllowsAccount(const ServerProfile& profile, const std::string& account);

}} // namespace cys::net
