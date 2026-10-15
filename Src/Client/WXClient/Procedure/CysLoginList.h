// CYS: typed UTF-8 login-list input; see Docs/specs/lua/login-areas_vi.md.
#pragma once

#include <array>
#include <string>
#include <vector>

namespace CysLoginList
{
    struct Endpoint
    {
        std::string host;
        int port = 0;
    };
    struct Server
    {
        std::string name;
        int provider = 0;
        int status = 0;
        int rowOrdinal = 0;
        int serverId = 0;
        int recommendLevel = 0;
        bool isNew = false;
        std::array<Endpoint, 4> endpoints;
    };
    struct Area
    {
        std::string name;
        std::string description;
        int recommendLevel = 0;
        std::vector<Server> servers;
    };

    // Normal-region view (column 12 = 0 or 1), in first-seen order. An existing
    // area's description is never replaced by a later server row. Malformed
    // input throws with a line number; no partially parsed list is published.
    std::vector<Area> Parse(const std::string& utf8);
    std::vector<Area> LoadFile(const char* path);

    struct Match
    {
        int areaIndex = 0;
        int serverIndex = 0;
    };
    std::vector<Match> Search(const std::vector<Area>& areas, const std::string& keyword);
}
