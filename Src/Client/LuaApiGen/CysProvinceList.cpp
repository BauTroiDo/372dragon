#include "CysHostProvinces.h"
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <algorithm>
#include <cstring>
#include <limits>
#include <stdexcept>

namespace CysHostProvinces
{
    namespace
    {
        std::uint32_t U32(const char* bytes)
        {
            const auto* p = reinterpret_cast<const unsigned char*>(bytes);
            return p[0] | (std::uint32_t(p[1]) << 8) | (std::uint32_t(p[2]) << 16) | (std::uint32_t(p[3]) << 24);
        }
        std::string Decode(const char* bytes, std::size_t length, UINT codePage)
        {
            if (!length) return {};
            const int count = MultiByteToWideChar(codePage, MB_ERR_INVALID_CHARS, bytes, static_cast<int>(length), nullptr, 0);
            if (!count) throw std::runtime_error("CityIdOfChina: invalid text encoding");
            if (codePage == CP_UTF8) return std::string(bytes, length);
            std::wstring wide(count, 0);
            if (MultiByteToWideChar(codePage, MB_ERR_INVALID_CHARS, bytes, static_cast<int>(length), &wide[0], count) != count)
                throw std::runtime_error("CityIdOfChina: text conversion failed");
            const int size = WideCharToMultiByte(CP_UTF8, 0, wide.data(), count, nullptr, 0, nullptr, nullptr);
            std::string output(size, 0);
            if (!size || WideCharToMultiByte(CP_UTF8, 0, wide.data(), count, &output[0], size, nullptr, nullptr) != size)
                throw std::runtime_error("CityIdOfChina: UTF-8 conversion failed");
            return output;
        }
        void Append(Catalog& result, std::int32_t cityId, const std::string& cityName, const std::string& provinceName)
        {
            auto province = std::find_if(result.provinces.begin(), result.provinces.end(),
                [&](const Province& value) { return value.name == provinceName; });
            if (province == result.provinces.end())
            {
                result.provinces.push_back({static_cast<std::int32_t>(result.provinces.size()), provinceName, {}});
                province = result.provinces.end() - 1;
            }
            province->cities.push_back({cityId, cityName});
        }
        std::vector<std::string> Columns(const std::string& line)
        {
            std::vector<std::string> result;
            std::size_t start = 0;
            for (;;)
            {
                const auto end = line.find('\t', start);
                result.push_back(line.substr(start, end == std::string::npos ? end : end - start));
                if (end == std::string::npos) return result;
                start = end + 1;
            }
        }
        std::int32_t Integer(const std::string& value)
        {
            if (value.empty()) throw std::runtime_error("CityIdOfChina: missing integer");
            const bool negative = value[0] == '-';
            std::size_t index = negative ? 1 : 0;
            if (index == value.size()) throw std::runtime_error("CityIdOfChina: missing digits");
            std::int64_t number = 0;
            for (; index < value.size(); ++index)
            {
                if (value[index] < '0' || value[index] > '9') throw std::runtime_error("CityIdOfChina: invalid integer");
                number = number * 10 + value[index] - '0';
                if (number > std::int64_t((std::numeric_limits<std::int32_t>::max)()) + (negative ? 1 : 0))
                    throw std::runtime_error("CityIdOfChina: integer outside int32");
            }
            return static_cast<std::int32_t>(negative ? -number : number);
        }
        Catalog ParseText(const char* bytes, std::size_t size)
        {
            if (std::memchr(bytes, 0, size)) throw std::runtime_error("CityIdOfChina: NUL in text table");
            const UINT codePage = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, bytes, static_cast<int>(size), nullptr, 0) ? CP_UTF8 : 936;
            std::string text = Decode(bytes, size, codePage);
            if (text.compare(0, 3, "\xef\xbb\xbf") == 0) text.erase(0, 3);
            Catalog result;
            unsigned header = 0, columnCount = 0, rows = 0;
            for (std::size_t start = 0; start < text.size();)
            {
                const auto end = text.find('\n', start);
                std::string line = text.substr(start, end == std::string::npos ? end : end - start);
                start = end == std::string::npos ? text.size() : end + 1;
                if (!line.empty() && line.back() == '\r') line.pop_back();
                if (line.empty() || line[0] == '#') continue;
                if (line.size() > 32768) throw std::runtime_error("CityIdOfChina: text row too long");
                const auto fields = Columns(line);
                if (!header)
                {
                    if (fields == std::vector<std::string>{"INT", "STRING", "STRING", "INT"}) columnCount = 4;
                    else if (fields == std::vector<std::string>{"INT", "INT", "STRING", "STRING", "INT"}) columnCount = 5;
                    else throw std::runtime_error("CityIdOfChina: text column type mismatch");
                    ++header; continue;
                }
                if (fields.size() != columnCount) throw std::runtime_error("CityIdOfChina: text column count mismatch");
                if (header == 1) { ++header; continue; }
                if (++rows > 100000) throw std::runtime_error("CityIdOfChina: too many rows");
                const unsigned id = columnCount == 5 ? 1 : 0;
                if (id) Integer(fields[0]);
                Integer(fields[id + 3]);
                Append(result, Integer(fields[id]), fields[id + 1], fields[id + 2]);
            }
            if (header != 2) throw std::runtime_error("CityIdOfChina: missing text headers");
            return result;
        }
    }

    Catalog Parse(const char* bytes, std::size_t size)
    {
        if (!bytes || !size || size > 2 * 1024 * 1024)
            throw std::runtime_error("CityIdOfChina: expected a bounded DBC table");
        if (size < 4 || U32(bytes) != 0xddbbcc00) return ParseText(bytes, size);
        if (size < 36 || U32(bytes + 4) != 5)
            throw std::runtime_error("CityIdOfChina: expected five-column binary DBC");
        const std::uint32_t rows = U32(bytes + 8), stringsSize = U32(bytes + 12);
        const std::uint32_t expectedTypes[] = {0, 0, 2, 2, 0};
        for (unsigned i = 0; i < 5; ++i)
            if (U32(bytes + 16 + i * 4) != expectedTypes[i])
                throw std::runtime_error("CityIdOfChina: column type mismatch");
        const std::uint64_t stringsBegin = 36 + std::uint64_t(rows) * 20;
        if (rows > 100000 || stringsBegin + stringsSize != size || !stringsSize)
            throw std::runtime_error("CityIdOfChina: invalid record/string block sizes");
        const char* strings = bytes + static_cast<std::size_t>(stringsBegin);
        if (strings[stringsSize - 1] != 0)
            throw std::runtime_error("CityIdOfChina: unterminated string block");
        const UINT codePage = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, strings, static_cast<int>(stringsSize), nullptr, 0) ? CP_UTF8 : 936;
        // Validate the complete block even if no row happens to reference bad bytes.
        Decode(strings, stringsSize, codePage);
        const auto textAt = [&](std::uint32_t offset) {
            if (offset >= stringsSize) throw std::runtime_error("CityIdOfChina: string offset outside block");
            const char* begin = strings + offset;
            const auto* end = static_cast<const char*>(std::memchr(begin, 0, stringsSize - offset));
            if (!end) throw std::runtime_error("CityIdOfChina: unterminated cell");
            return Decode(begin, static_cast<std::size_t>(end - begin), codePage);
        };
        Catalog result;
        for (std::uint32_t i = 0; i < rows; ++i)
        {
            const char* row = bytes + 36 + i * 20;
            std::string cityName = textAt(U32(row + 8));
            std::string provinceName = textAt(U32(row + 12));
            std::int32_t cityId;
            const std::uint32_t rawId = U32(row + 4);
            std::memcpy(&cityId, &rawId, sizeof(cityId));
            Append(result, cityId, cityName, provinceName);
        }
        return result;
    }
}
