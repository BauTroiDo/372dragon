#pragma once
#include <cmath>
#include <locale>
#include <map>
#include <sstream>
#include <string>
#include <vector>

// Internal creation UI adapter. CY Camera_Main is a Model_Parameter row ID;
// the existing RTT renderer takes the corresponding "height;distance" value.
// This does not change the public appearance catalog or renderer ABI.
namespace CysCreateRoleAppearance
{
class CameraTable
{
    std::map<int, std::string> rows_;

    static std::vector<std::string> Fields(const std::string& line)
    {
        std::vector<std::string> result;
        std::size_t start = 0;
        for (;;)
        {
            const std::size_t end = line.find('\t', start);
            result.push_back(line.substr(start, end == std::string::npos ? end : end - start));
            if (end == std::string::npos) return result;
            start = end + 1;
        }
    }

    static bool Id(const std::string& text, int& id)
    {
        if (text.empty()) return false;
        id = 0;
        for (char digit : text)
        {
            if (digit < '0' || digit > '9' || id > (2147483647 - (digit - '0')) / 10)
                return false;
            id = id * 10 + (digit - '0');
        }
        return true;
    }

    static bool Number(const std::string& text, bool distance)
    {
        std::istringstream stream(text);
        stream.imbue(std::locale::classic());
        double value = 0;
        stream >> std::noskipws >> value;
        return stream && stream.eof() && std::isfinite(value) && value <= 1000.0 &&
            (distance ? value > 0.0 : value >= 0.0);
    }

public:
    bool Load(const char* bytes, std::size_t size, std::string& error)
    {
        error.clear();
        if (!bytes || !size || size > 1024 * 1024)
        { error = "invalid CY camera table size"; return false; }
        std::istringstream stream(std::string(bytes, size));
        std::map<int, std::string> next;
        std::string line;
        unsigned header = 0;
        while (std::getline(stream, line))
        {
            while (!line.empty() && line.back() == '\r') line.pop_back();
            if (line.empty()) continue;
            const auto fields = Fields(line);
            if (fields.size() != 4)
            { error = "CY camera row width differs from ISFF"; return false; }
            if (header < 2)
            {
                if (fields[0] != "INT" || fields[1] != "STRING" || fields[2] != "FLOAT" || fields[3] != "FLOAT")
                { error = "CY camera schema differs from ISFF"; return false; }
                ++header;
                continue;
            }
            int id = 0;
            if (!Id(fields[0], id) || !Number(fields[2], false) || !Number(fields[3], true) ||
                next.size() >= 4096 || !next.emplace(id, fields[2] + ";" + fields[3]).second)
            { error = "invalid or duplicate CY camera row"; return false; }
        }
        if (header != 2 || next.empty())
        { error = "empty CY camera table"; return false; }
        rows_.swap(next);
        return true;
    }

    bool Resolve(const std::string& rowId, std::string& value, std::string& error) const
    {
        error.clear();
        int id = 0;
        if (!Id(rowId, id))
        { error = "CY Camera_Main must be a row ID"; return false; }
        const auto found = rows_.find(id);
        if (found == rows_.end())
        { error = "CY Camera_Main row is unavailable"; return false; }
        value = found->second;
        return true;
    }
};
}
