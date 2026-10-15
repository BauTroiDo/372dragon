// CYS-INFOLINK: CY 3.71 quest-text hyperlink tags  #{_INFOxxx<x>,<y>,<scene>,<target>}
//
// Before this header the project dropped every one of these tags: ParserString_RuntimeNew had no branch for
// them and _IsValidDictionKey missed, so the whole "#{...}" produced ZERO characters (measured: qlog-crash
// handoff, UILuaControl.cpp ComplexWindow::AddTextElement tombstone, 205 - 32 - 26 - 4 = 143 = utf32=143).
//
// EVIDENCE - read-only disassembly of the shipped CY 3.71 client
//   Build\re\cy-oracle\CYGame\Bin64\UI_CEGUI.dll, image base 0x180000000 (llvm-objdump -d).
//   Every tag sits in the runtime string parser FUN_18004b050 (== CUIStringSystem::ParserString_RuntimeNew,
//   the same function CysDialogVars documents at 0x18004b146) as one block of the #{IDSTR} chain:
//
//     substr(0, N) == "_TAG"                                   e.g. 0x18004e326 "_INFOAIM"   (.rdata 0x18008f3a8)
//     sscanf(strID.c_str(), "_TAG%d,%d,%d,%s", &x, &y, &scene, name)      0x18004e391/0x18004e398 (sscanf @IAT 0x180085c38)
//     <filter>->vt+0x90(name, name, 4)  -> NULL means "drop the tag"      0x18004e3bc
//     if (name == "0") name-slot becomes <filter>->vt+0x148(scene)        0x18004e40f   (scene display name)
//     _snprintf(buf, 0x80, <template>, x, y, scene, [type,] name, [sceneName,] x, y)   (_snprintf @IAT 0x180085c20)
//     ParserString_RuntimeNew(buf, tmp); out += tmp;                      0x18004e4e7 - recursive, 0x18004b050
//
//   Templates in .rdata (dumped byte-exact):
//     0x18008f3d0  "#aB{%d,%d,%d,0,%s}#u%s[%d,%d]#u#aE"     target == "0"  -> shows <sceneName>[x,y]
//     0x18008f3f8  "#aB{%d,%d,%d,0,%s}#u[%d,%d]#u#aE"       normal          -> shows [x,y]
//     0x18008f470  "#aB{%d,%d,%d,%d,%s}#u%s[%d,%d]#u#aE"    (type passed in a register)
//     0x18008f498  "#aB{%d,%d,%d,%d,%s}#u[%d,%d]#u#aE"
//     0x18008f5c0  "#aB{%d,%d,%d,1,%s}#u[%d,%d]#u#aE"
//     0x18008f610  "#aB{%d,%d,%d,3,%s}#u[%d,%d]#u#aE"
//     0x18008f658  "#aB{%d,%d,%d,4,%s}#u[%d,%d]#u#aE"
//     0x18008fb70  "#aB{%d,%d,%d,2,%d}#u[%d,%d]#u#aE"
//
//   Tag -> link type (the 4th field of the #aB{} key), each read at the _snprintf of that tag's own block:
//     _INFOAIM     0x18004e326  type 0 (literal in template)     _INFOKILL   0x18004f40d  type 1  (0x18008f5c0)
//     _INFOMAP     0x18004e52e  type 0 + colour wrap (see below) _GETITEM    0x18004f5cb  type 3  (0x18008f610)
//     _INFOCITY    0x18004e746  type 5  (0x18004e85f  $0x5)      _GETPET     0x18004f785  type 4  (0x18008f658)
//     _INFO2CITY   0x18004e952  type 5  (0x18004ea6b  $0x5)      _INFOUSEITEM 0x1800510d1 type 2  (0x18008fb70)
//     _INFOHOME    0x18004eb7a  type 6  (0x18004ec93  $0x6)
//     _INFO2HOME   0x18004ed86  type 6  (0x18004ee9f  $0x6)
//     _INFO2WYXZ   0x18004efae  type 8  (0x18004f0d6  $0x8)  - format has FIVE fields "%d,%d,%d,%d,%s"
//     _INFO2LINE   0x18004f1e5  type 7  (0x18004f2fe  $0x7)
//
//   _INFOMAP additionally brackets its expansion with two utf32 markers appended straight to the output
//   String32 (0x18004e6ef  0xE80099E5, 0x18004e70d  0xE800CCFF; operator+=(utf32) @IAT 0x180085710).
//   0xE8 is not a marker the 0.85 CEGUI font layer knows, so it is NOT emitted here - see the handoff.
//
//   The click side is CY's CUISystem::handleHyperLinkLeftActive at 0x1800714c0 (registered for the CEGUI
//   event "HyperLinkLeftActive" at 0x18006aa82). It does exactly:
//     sscanf(key, "%d,%d,%d,%d,%s", &x, &y, &scene, &type, target)   0x1800716c3, requires >= 4 fields
//   so the key layout is  <x>,<y>,<scene>,<type>,<target>  - NOT the 0.85 "<sid>,<x>,<y>##w" layout that
//   UISystem.cpp already understood.
//
// Header-only on purpose (same shape as CysDialogVars.h / CysPackedFormat.h): the parser, the click handler
// and Tests\luaapi\info_link_tests.cpp all compile one copy.
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
        // CYS-INFOPARITY 19/09: true only for _INFOMAP. CY brackets that expansion with two raw utf32 codes
        // (0xE80099E5 before, 0xE800CCFF after: 0x18004e6ef / 0x18004e70d) - 0xE8 is the font layer's "link
        // colour" marker (CEGUIBase.dll drawTextLine case 0x18004cda4), so map links are drawn in #0099E5 and
        // the default #00CCFF is restored right after. The caller appends the codes; Format() cannot carry them.
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

        // _INFO2WYXZ carries one extra int before the name ("_INFO2WYXZ%d,%d,%d,%d,%s", 0x18008f548). It is
        // pushed through unchanged as part of the target so the key keeps CY's field count.
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

    // CY handleHyperLinkLeftActive 0x18007191d/0x18007192d: the _INFOUSEITEM target is taken as an item table
    // index only when it is exactly 8 characters long and starts with '1'..'9' (then atoi). Returns 0 otherwise.
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

    // Click side: the string CEGUIFontBase collected between '{' and '}' - "x,y,scene,type,target".
    // Mirrors CY 0x1800716c3: four integers are mandatory, the target may be empty.
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
