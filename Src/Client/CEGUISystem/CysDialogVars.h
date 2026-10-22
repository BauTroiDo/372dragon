








#pragma once

#include <cstdlib>
#include <string>
#include <vector>

namespace CysDialogVars
{
    // Inclusive byte range [lo, hi] in which a '$' is copied verbatim together with the next byte.
    struct Range { int lo; int hi; };


    class Provider
    {
    public:
        virtual ~Provider() {}
        // vt+0xb8: who 0 = MySelf name, who 1 = main target name when it is a CObject_Character, else "".
        virtual std::string Name(int who) = 0;
        // vt+0xc0: who 0 = MySelf, who 1 = main target; 0 female, 1 male, anything else unknown (-1).
        virtual int Sex(int who) = 0;
        // vt+0xc8: MySelf string at CY character data +0x4940 ("" in cross-server mode).
        virtual std::string UserString() = 0;
        // UI dictionary lookup (CY this+8 map); false when the key is missing.
        virtual bool Lookup(const std::string& key, std::string& value) = 0;
    };

    inline const char* SexKey(char variable, int sex)
    {
        // CY tables are indexed by the sex value (0 = _Woman, 1 = _Man).
        static const char* const keys[4][2] = {
            { "GMGameInterface_Script_Talk_Info_G_Woman", "GMGameInterface_Script_Talk_Info_G_Man" },
            { "GMGameInterface_Script_Talk_Info_g_Woman", "GMGameInterface_Script_Talk_Info_g_Man" },
            { "GMGameInterface_Script_Talk_Info_R_Woman", "GMGameInterface_Script_Talk_Info_R_Man" },
            { "GMGameInterface_Script_Talk_Info_r_Woman", "GMGameInterface_Script_Talk_Info_r_Man" },
        };
        int row = variable == 'G' ? 0 : variable == 'g' ? 1 : variable == 'R' ? 2 : 3;
        return keys[row][sex == 0 ? 0 : 1];
    }


    inline std::vector<Range> ProtectedRanges(const std::string& s)
    {
        std::vector<Range> ranges;
        const size_t n = s.size();
        size_t i = 0;
        while (i < n)
        {
            if (s[i] != '#') { ++i; continue; }
            if (i + 1 == n) break;
            if (s[i + 1] != '{' || i + 2 == n) { ++i; continue; }
            if (s[i + 2] == '_')
            {
                if (s.compare(i + 2, 8, "_INFOMSG") != 0) { ++i; continue; }
                const int len = std::atoi(s.substr(i + 10, 3).c_str());
                const size_t close = i + 13 + static_cast<size_t>(len);
                if (len < 0 || close >= n || s[close] != '}') break; // CY writes "<ERROR>" and stops here
                Range r = { static_cast<int>(i) - 1, static_cast<int>(close) };
                ranges.push_back(r);
                i = close + 1;
                continue;
            }
            const size_t star = s.find('*', i + 2);
            const size_t close = s.find('}', i + 2);
            if (star != std::string::npos && star + 1 < n && star < close)
            {
                const unsigned char length = star + 2 < n ? static_cast<unsigned char>(s[star + 2]) : 0;
                const size_t end = star + length;
                if (end < n && s[end] == '}')
                {
                    Range r = { static_cast<int>(i) - 1, static_cast<int>(end) };
                    ranges.push_back(r);
                    i = end + 1;
                    continue;
                }
            }
            ++i;
        }
        return ranges;
    }


    inline void Expand(const std::string& src, Provider* provider, const std::vector<Range>& ranges, std::string& out)
    {
        out.clear();
        if (!provider) { out = src; return; }
        const size_t n = src.size();
        size_t from = 0;
        size_t at = src.find('$');
        while (at != std::string::npos)
        {
            out.append(src, from, at - from);
            const char v = at + 1 < n ? src[at + 1] : '\0';
            bool inRange = false;
            for (size_t k = 0; k < ranges.size(); ++k)
                if (ranges[k].lo <= static_cast<int>(at) && static_cast<int>(at) <= ranges[k].hi) { inRange = true; break; }
            if (inRange)
            {
                out.append(src, at, 2);
                from = at + 2;
            }
            else if (at + 1 < n && v == 'N') { out += provider->Name(0); from = at + 2; }
            else if (at + 1 < n && v == 'n') { out += provider->Name(1); from = at + 2; }
            else if (at + 1 < n && v == 'U') { out += provider->UserString(); from = at + 2; }
            else if (at + 1 < n && (v == 'G' || v == 'g' || v == 'R' || v == 'r'))
            {
                const int sex = provider->Sex(v == 'g' ? 1 : 0);
                if (static_cast<unsigned>(sex) < 2)
                {
                    std::string value;
                    if (provider->Lookup(SexKey(v, sex), value)) out += value;
                }
                from = at + 2;
            }
            else
            {
                from = at + 1; // unknown variable: only the '$' is dropped
            }
            if (from >= n) return;
            at = src.find('$', from);
        }
        out.append(src, from, std::string::npos);
    }
}
