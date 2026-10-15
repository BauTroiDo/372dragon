// Explicit StrDictionary profiles. Only display values are transcoded; keys stay byte-exact.
#pragma once
#include <windows.h>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>

namespace CysUiDictionary
{
    struct Table
    {
        std::map<std::string, std::string> entries;
        size_t rows = 0;
        size_t duplicates = 0;
        UINT sourceCodePage = 0;
    };

    inline std::string Convert(const std::string& value, UINT from, UINT to)
    {
        if (value.empty()) return value;
        const int count = MultiByteToWideChar(from, MB_ERR_INVALID_CHARS, value.data(), static_cast<int>(value.size()), nullptr, 0);
        if (!count) throw std::runtime_error("StrDictionary: invalid source encoding");
        if (from == to) return value;
        std::wstring wide(count, 0);
        if (MultiByteToWideChar(from, MB_ERR_INVALID_CHARS, value.data(), static_cast<int>(value.size()), &wide[0], count) != count)
            throw std::runtime_error("StrDictionary: decode failed");
        BOOL replaced = FALSE;
        BOOL* replacement = to == CP_UTF8 ? nullptr : &replaced;
        const DWORD flags = to == CP_UTF8 ? 0 : WC_NO_BEST_FIT_CHARS;
        const int size = WideCharToMultiByte(to, flags, wide.data(), count, nullptr, 0, nullptr, replacement);
        if (!size || replaced) throw std::runtime_error("StrDictionary: display encoding cannot represent value");
        std::string result(size, 0);
        if (WideCharToMultiByte(to, flags, wide.data(), count, &result[0], size, nullptr, replacement) != size || replaced)
            throw std::runtime_error("StrDictionary: encode failed");
        return result;
    }

    inline std::vector<std::string> Split(const std::string& line)
    {
        std::vector<std::string> fields;
        size_t begin = 0;
        for (;;) {
            const size_t end = line.find('\t', begin);
            fields.push_back(line.substr(begin, end == std::string::npos ? end : end - begin));
            if (end == std::string::npos) return fields;
            begin = end + 1;
        }
    }

    inline Table Parse(const std::string& bytes, UINT displayCodePage)
    {
        if (bytes.empty() || bytes.size() > 64 * 1024 * 1024 || bytes.find('\0') != std::string::npos)
            throw std::runtime_error("StrDictionary: invalid file size or NUL");
        if (displayCodePage != CP_UTF8 && displayCodePage != 936)
            throw std::runtime_error("StrDictionary: unsupported display encoding");
        Table result;
        size_t begin = bytes.compare(0, 3, "\xef\xbb\xbf") == 0 ? 3 : 0;
        size_t lineNumber = 0, columns = 0;
        for (; begin < bytes.size(); ++lineNumber) {
            const size_t end = bytes.find('\n', begin);
            std::string line = bytes.substr(begin, end == std::string::npos ? end : end - begin);
            begin = end == std::string::npos ? bytes.size() : end + 1;
            if (!line.empty() && line.back() == '\r') line.pop_back();
            if (line.size() > 65536) throw std::runtime_error("StrDictionary: line limit exceeded");
            if (lineNumber == 0) {
                if (line == "STRING\tSTRING") { columns = 2; result.sourceCodePage = CP_UTF8; }
                else if (line == "INT\tSTRING\tSTRING") { columns = 3; result.sourceCodePage = 936; }
                else throw std::runtime_error("StrDictionary: unsupported column schema");
                continue;
            }
            // DBC repeats its type row as the description header in both observed profiles.
            if (lineNumber == 1) {
                if (Split(line).size() != columns) throw std::runtime_error("StrDictionary: description column mismatch");
                continue;
            }
            if (line.empty() || line[0] == '#') continue;
            const std::vector<std::string> fields = Split(line);
            if (fields.size() != columns) throw std::runtime_error("StrDictionary: row column mismatch");
            if (++result.rows > 200000) throw std::runtime_error("StrDictionary: row limit exceeded");
            if (columns == 3 && (fields[0].empty() || fields[0].find_first_not_of("0123456789") != std::string::npos))
                throw std::runtime_error("StrDictionary: invalid legacy ID");
            const std::string& key = fields[columns - 2];
            // Validate keys without changing the bytes used by resource/template lookup.
            Convert(key, result.sourceCodePage, result.sourceCodePage);
            const std::string value = Convert(fields.back(), result.sourceCodePage, displayCodePage);
            if (result.entries.count(key)) ++result.duplicates;
            result.entries[key] = value; // The original dictionary also uses the last occurrence.
        }
        if (lineNumber < 2 || !result.rows) throw std::runtime_error("StrDictionary: missing headers or records");
        return result;
    }
}
