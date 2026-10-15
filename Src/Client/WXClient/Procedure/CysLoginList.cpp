// CYS: independently implemented reader for the documented plaintext profile.
#include "CysLoginList.h"

#include <windows.h>
#include <algorithm>
#include <fstream>
#include <stdexcept>
#include <utility>

namespace CysLoginList
{
    namespace
    {
        const std::size_t maxFileBytes = 2 * 1024 * 1024;
        const std::size_t maxLineBytes = 16 * 1024;

        void Fail(std::size_t line, const char* reason)
        {
            throw std::runtime_error("CYS login list line " + std::to_string(line) + ": " + reason);
        }

        int Integer(const std::string& text, std::size_t line)
        {
            if (text.empty()) Fail(line, "empty integer");
            std::size_t i = text[0] == '-' ? 1 : 0;
            if (i == text.size()) Fail(line, "invalid integer");
            unsigned long long value = 0;
            const unsigned long long limit = i ? 2147483648ULL : 2147483647ULL;
            for (; i < text.size(); ++i)
            {
                if (text[i] < '0' || text[i] > '9') Fail(line, "invalid integer");
                value = value * 10 + (text[i] - '0');
                if (value > limit) Fail(line, "integer out of range");
            }
            if (text[0] == '-') return static_cast<int>(-static_cast<long long>(value));
            return static_cast<int>(value);
        }

        Endpoint Address(const std::string& text, std::size_t line)
        {
            Endpoint result;
            if (text.empty()) return result;
            const auto colon = text.find(':');
            if (colon == std::string::npos || colon == 0 || colon > 63 ||
                text.find(':', colon + 1) != std::string::npos)
                Fail(line, "expected host:port");
            result.host = text.substr(0, colon);
            for (unsigned char c : result.host)
                if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                      (c >= '0' && c <= '9') || c == '-' || c == '.'))
                    Fail(line, "invalid endpoint host");
            result.port = Integer(text.substr(colon + 1), line);
            if (result.port < 1 || result.port > 65535) Fail(line, "invalid endpoint port");
            return result;
        }
    }

    std::vector<Area> Parse(const std::string& utf8)
    {
        if (utf8.empty() || utf8.size() > maxFileBytes) Fail(0, "invalid file size");
        if (utf8.find('\0') != std::string::npos) Fail(0, "embedded NUL");
        if (!MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8.data(),
                                static_cast<int>(utf8.size()), nullptr, 0))
            Fail(0, "expected UTF-8 plaintext");

        std::vector<Area> areas;
        bool begun = false, ended = false;
        bool recommendSection = false;
        int rowOrdinal = 0;
        std::size_t start = utf8.compare(0, 3, "\xef\xbb\xbf") == 0 ? 3 : 0;
        std::size_t lineNumber = 0;
        while (start < utf8.size())
        {
            ++lineNumber;
            const auto newline = utf8.find('\n', start);
            const auto end = newline == std::string::npos ? utf8.size() : newline;
            if (end - start > maxLineBytes) Fail(lineNumber, "line too long");
            std::string line = utf8.substr(start, end - start);
            start = newline == std::string::npos ? utf8.size() : newline + 1;
            while (!line.empty() && line.back() == '\r') line.pop_back();
            const auto first = line.find_first_not_of("\t ");
            if (first == std::string::npos) continue;
            line.erase(0, first);
            if (line[0] == '#') continue;
            if (line.compare(0, 7, "VERSION") == 0 && !begun) continue;
            if (line == "SERVER_BEGIN")
            {
                if (begun) Fail(lineNumber, "duplicate SERVER_BEGIN");
                begun = true;
                continue;
            }
            if (line == "SERVER_END")
            {
                if (!begun || ended) Fail(lineNumber, "unexpected SERVER_END");
                ended = true;
                continue;
            }
            if (ended)
            {
                if (line == "RECOMMENDAREA_BEGIN") { recommendSection = true; continue; }
                if (line == "RECOMMENDAREA_END") { recommendSection = false; continue; }
                if (!recommendSection) continue;
                const auto comma = line.find(',');
                if (comma == std::string::npos || comma == 0 || line.find(',', comma + 1) != std::string::npos)
                    Fail(lineNumber, "expected recommendation name and level");
                const std::string name = line.substr(0, comma);
                const int level = (std::max)(0, Integer(line.substr(comma + 1), lineNumber));
                for (auto& area : areas) if (area.name == name) area.recommendLevel = level;
                continue;
            }
            if (!begun) Fail(lineNumber, "expected SERVER_BEGIN");

            std::vector<std::string> columns;
            std::size_t from = 0;
            for (;;)
            {
                const auto comma = line.find(',', from);
                columns.push_back(line.substr(from, comma == std::string::npos ? comma : comma - from));
                if (comma == std::string::npos) break;
                from = comma + 1;
            }
            if (columns.size() != 14 && columns.size() != 15) Fail(lineNumber, "expected 14 or 15 columns");
            if (columns[0].empty() || columns[1].empty()) Fail(lineNumber, "empty region or server name");
            const int group = Integer(columns[12], lineNumber);
            if (group < 0 || group > 2) Fail(lineNumber, "invalid region group");
            Server server;
            server.name = columns[1];
            server.provider = Integer(columns[2], lineNumber);
            server.status = Integer(columns[4], lineNumber);
            server.rowOrdinal = rowOrdinal++;
            server.serverId = Integer(columns[3], lineNumber);
            server.recommendLevel = (std::max)(0, Integer(columns[5], lineNumber));
            server.isNew = Integer(columns[6], lineNumber) != 0;
            if (server.provider < 0 || server.provider > 2) Fail(lineNumber, "invalid provider");
            if (server.status < 0 || (server.status > 4 && server.status != 10)) Fail(lineNumber, "invalid server status");
            for (std::size_t i = 0; i != 4; ++i) server.endpoints[i] = Address(columns[8 + i], lineNumber);
            if (server.endpoints[0].host.empty()) Fail(lineNumber, "primary endpoint is required");
            if (group == 2) continue;
            auto area = std::find_if(areas.begin(), areas.end(), [&](const Area& value) { return value.name == columns[0]; });
            if (area == areas.end())
            {
                areas.push_back(Area{});
                area = areas.end() - 1;
                area->name = columns[0];
                area->description = columns[7];
            }
            area->servers.push_back(std::move(server));
        }
        if (!begun || !ended) Fail(lineNumber, "missing SERVER_BEGIN or SERVER_END");
        if (recommendSection) Fail(lineNumber, "missing RECOMMENDAREA_END");
        return areas;
    }

    std::vector<Match> Search(const std::vector<Area>& areas, const std::string& keyword)
    {
        std::vector<Match> matches;
        if (keyword.empty()) return matches;
        if (keyword.find('\0') != std::string::npos || keyword.size() > maxLineBytes ||
            !MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, keyword.data(),
                                static_cast<int>(keyword.size()), nullptr, 0))
            throw std::runtime_error("CYS login search requires UTF-8 text");
        for (std::size_t a = 0; a < areas.size(); ++a)
        {
            for (std::size_t s = 0; s < areas[a].servers.size(); ++s)
            {
                const auto& server = areas[a].servers[s];
                if (server.status == 10 || server.name.find(keyword) == std::string::npos) continue;
                const bool duplicate = std::any_of(matches.begin(), matches.end(), [&](const Match& match) {
                    return match.areaIndex == static_cast<int>(a) &&
                        areas[a].servers[match.serverIndex].name == server.name;
                });
                if (!duplicate) matches.push_back(Match{static_cast<int>(a), static_cast<int>(s)});
            }
        }
        return matches;
    }

    std::vector<Area> LoadFile(const char* path)
    {
        std::ifstream stream(path, std::ios::binary | std::ios::ate);
        if (!stream) Fail(0, "cannot open file");
        const auto length = stream.tellg();
        if (length <= 0 || length > static_cast<std::streamoff>(maxFileBytes)) Fail(0, "invalid file size");
        std::string bytes(static_cast<std::size_t>(length), '\0');
        stream.seekg(0);
        if (!stream.read(&bytes[0], static_cast<std::streamsize>(bytes.size()))) Fail(0, "cannot read file");
        return Parse(bytes);
    }
}
