

















































#pragma once

#include <cstddef>
#include <string>

namespace CysInfoLink
{
    // A parsed tag or a parsed #aB{} key. CY keeps x/y/scene as plain ints and the target as a byte string
    // (an NPC name in the source code page for every type except 2, where it is an item table index).
    struct Link
    {
        int         x;
        int         y;
        int         scene;
        int         type;
        std::string target;




        bool        mapTag;

        Link() : x(0), y(0), scene(0), type(0), mapTag(false) {}
    };

    struct Entry { const char* tag; size_t len; int type; };

    // Longest tags first so a prefix never shadows a longer sibling. Tags that exist in CY but carry a
    // different meaning (_INFOMSG, _INFOID, _INFOUSR, _INFOACHV, _INFOPNE, _INFOXZ, _INFOSER, _INFOTZZ,
    // _BUYFROMYBSHOP) are deliberately absent: they are not coordinate links.
    inline const Entry* Tags(size_t& count)
    {
        static const Entry table[] = {
            { "_INFOUSEITEM", 12, 2 },
            { "_INFO2WYXZ",   10, 8 },
            { "_INFO2CITY",   10, 5 },
            { "_INFO2HOME",   10, 6 },
            { "_INFO2LINE",   10, 7 },
            { "_INFOCITY",     9, 5 },
            { "_INFOHOME",     9, 6 },
            { "_INFOKILL",     9, 1 },
            { "_GETITEM",      8, 3 },
            { "_INFOAIM",      8, 0 },
            { "_INFOMAP",      8, 0 },
            { "_GETPET",       7, 4 },
        };
        count = sizeof(table) / sizeof(table[0]);
        return table;
    }

    // CY parses with "%d": it stops at the first byte that is not part of an integer. The shipped
    // StrDictionary also holds 402 rows whose coordinates are "133.5,259.9" or unresolved "%s1,%s2,%s3"
    // packed-format slots. "%d" would take 133 and then fail on '.', leaving CY reading uninitialised stack,
    // so this reader accepts (and truncates) a fractional part instead - strictly safer, same visible result.
    inline bool ReadInt(const std::string& s, size_t& i, int& out)
    {
        const size_t begin = i;
        bool negative = false;
        if (i < s.size() && (s[i] == '+' || s[i] == '-')) { negative = (s[i] == '-'); ++i; }
        size_t digits = 0;
        long long value = 0;
        while (i < s.size() && s[i] >= '0' && s[i] <= '9')
        {
            if (value < 100000000LL) value = value * 10 + (s[i] - '0');
            ++digits; ++i;
        }
        if (digits == 0) { i = begin; return false; }
        if (i < s.size() && s[i] == '.')
        {
            ++i;                                            // truncate towards zero, like "%d" stopping at '.'
            while (i < s.size() && s[i] >= '0' && s[i] <= '9') ++i;
        }
        out = static_cast<int>(negative ? -value : value);
        return true;
    }

    // '#', '{' and '}' inside the target would be re-read by the parser (or would close the key early in
    // CEGUIFontBase's link scanner, which toggles on '{' / '}'), so they never reach the key.
    inline std::string SafeTarget(const std::string& raw)
    {
        std::string out;
        out.reserve(raw.size());
        for (size_t i = 0; i < raw.size(); ++i)
        {
            const char c = raw[i];
            if (c == '#' || c == '{' || c == '}') continue;
            out.push_back(c);
        }
        return out;
    }

    // strID is the text between "#{" and "}". Returns false for every key that is not a coordinate link.
    inline bool Parse(const std::string& strID, Link& out)
    {
        size_t count = 0;
        const Entry* table = Tags(count);
        const Entry* hit = 0;
        for (size_t t = 0; t < count; ++t)
        {
            if (strID.size() > table[t].len && strID.compare(0, table[t].len, table[t].tag) == 0)
            {
                hit = &table[t];
                break;
            }
        }
        if (!hit) return false;

        size_t i = hit->len;
        Link link;
        link.type = hit->type;
        link.mapTag = (hit->len == 8 && strID.compare(0, 8, "_INFOMAP") == 0);
        if (!ReadInt(strID, i, link.x)) return false;
        if (i >= strID.size() || strID[i] != ',') return false;
        ++i;
        if (!ReadInt(strID, i, link.y)) return false;
        if (i >= strID.size() || strID[i] != ',') return false;
        ++i;
        if (!ReadInt(strID, i, link.scene)) return false;



        if (i < strID.size() && strID[i] == ',')
        {
            ++i;
            link.target = SafeTarget(strID.substr(i));
        }
        // Fewer than four fields is normal in the shipped data (29 rows, e.g. "#{_INFOAIM208,313,579}"):
        // CY's sscanf returns 3 and leaves the memset'd name buffer empty, so the link still works.
        out = link;
        return true;
    }

    inline void AppendInt(std::string& s, int v)
    {
        char tmp[16];
        int len = 0;
        long long n = v;                                    // -INT_MIN needs the wider type
        const bool negative = n < 0;
        if (negative) n = -n;
        do { tmp[len++] = static_cast<char>('0' + static_cast<int>(n % 10)); n /= 10; } while (n != 0 && len < 15);
        if (negative) s.push_back('-');
        while (len > 0) s.push_back(tmp[--len]);
    }

    // The CY template, byte for byte: "#aB{x,y,scene,type,target}#u[x,y]#u#aE".
    // "#u" is what CY underlines the visible text with. Since CYS-INFOPARITY (19/09) the parser turns the pair
    // into utf32 0xE6/0xE7 and CEGUIFontBase.cpp draws the line, exactly like CY's UI_CEGUI.dll + CEGUIBase.dll.
    inline std::string Format(const Link& link)
    {
        std::string out;
        out.reserve(48 + link.target.size());
        out += "#aB{";
        AppendInt(out, link.x);  out.push_back(',');
        AppendInt(out, link.y);  out.push_back(',');
        AppendInt(out, link.scene); out.push_back(',');
        AppendInt(out, link.type);  out.push_back(',');
        out += link.target;
        out += "}#u[";
        AppendInt(out, link.x);  out.push_back(',');
        AppendInt(out, link.y);
        out += "]#u#aE";
        return out;
    }

    inline bool Expand(const std::string& strID, std::string& out)
    {
        Link link;
        if (!Parse(strID, link)) return false;
        out = Format(link);
        return true;
    }

    // Same, and hands the parsed tag back (the caller needs mapTag for the 0xE8 colour bracket).
    inline bool Expand(const std::string& strID, std::string& out, Link* parsed)
    {
        Link link;
        if (!Parse(strID, link)) return false;
        out = Format(link);
        if (parsed) *parsed = link;
        return true;
    }



    inline int UseItemID(const std::string& target)
    {
        if (target.size() != 8 || target[0] < '1' || target[0] > '9') return 0;
        int value = 0;
        for (size_t i = 0; i < target.size(); ++i)
        {
            if (target[i] < '0' || target[i] > '9') return 0;
            value = value * 10 + (target[i] - '0');
        }
        return value;
    }



    inline bool ParseKey(const std::string& key, Link& out)
    {
        size_t i = 0;
        Link link;
        if (!ReadInt(key, i, link.x)) return false;
        if (i >= key.size() || key[i] != ',') return false;
        ++i;
        if (!ReadInt(key, i, link.y)) return false;
        if (i >= key.size() || key[i] != ',') return false;
        ++i;
        if (!ReadInt(key, i, link.scene)) return false;
        if (i >= key.size() || key[i] != ',') return false;
        ++i;
        if (!ReadInt(key, i, link.type)) return false;
        if (i < key.size())
        {
            if (key[i] != ',') return false;
            link.target = key.substr(i + 1);
        }
        out = link;
        return true;
    }
}
