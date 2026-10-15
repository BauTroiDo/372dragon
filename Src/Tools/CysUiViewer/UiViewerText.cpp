// CysUiViewer - UI texts. CYS: new tool (2026-09-12). Keep this file ASCII.
#include "UiViewerText.h"
#include "UiViewerOptions.h"
#include "CysInfoLink.h"	// CYS-INFOLINK: one copy of the CY tag expansion, shared with UIString.cpp

#include <windows.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

namespace cysui
{
    namespace
    {
        bool readWholeFile(const std::string& path, std::string& data)
        {
            FILE* f = std::fopen(path.c_str(), "rb");
            if (!f)
                return false;
            std::fseek(f, 0, SEEK_END);
            long n = std::ftell(f);
            std::fseek(f, 0, SEEK_SET);
            data.resize(n > 0 ? (size_t)n : 0);
            size_t got = n > 0 ? std::fread(&data[0], 1, (size_t)n, f) : 0;
            std::fclose(f);
            data.resize(got);
            return true;
        }

        // Splits on '\n' only (never on 0x85 etc.), strips one trailing '\r'.
        void splitLines(const std::string& data, std::vector<std::string>& lines)
        {
            size_t pos = 0;
            if (data.size() >= 3 && (unsigned char)data[0] == 0xEF && (unsigned char)data[1] == 0xBB &&
                (unsigned char)data[2] == 0xBF)
                pos = 3;
            while (pos < data.size())
            {
                size_t e = data.find('\n', pos);
                if (e == std::string::npos)
                    e = data.size();
                size_t end = e;
                if (end > pos && data[end - 1] == '\r')
                    --end;
                lines.push_back(data.substr(pos, end - pos));
                pos = e + 1;
            }
        }

        unsigned hexValue(const std::string& s)
        {
            unsigned v = 0;
            for (size_t i = 0; i < s.size(); ++i)
            {
                char c = s[i];
                unsigned d;
                if (c >= '0' && c <= '9') d = (unsigned)(c - '0');
                else if (c >= 'a' && c <= 'f') d = (unsigned)(c - 'a' + 10);
                else if (c >= 'A' && c <= 'F') d = (unsigned)(c - 'A' + 10);
                else break;
                v = v * 16 + d;
            }
            return v;
        }

        bool isHex6(const std::string& s, size_t p)
        {
            if (p + 6 > s.size())
                return false;
            for (size_t i = p; i < p + 6; ++i)
            {
                char c = s[i];
                if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')))
                    return false;
            }
            return true;
        }

        void appendUtf8(CEGUI::String& out, const std::string& run)
        {
            if (!run.empty())
                out += CEGUI::String((const CEGUI::utf8*)run.c_str());
        }
    }

    bool TextResolver::loadDictionary(const std::string& path, std::string& error)
    {
        std::string data;
        if (!readWholeFile(path, data))
        {
            error = "cannot read " + path;
            return false;
        }
        std::vector<std::string> lines;
        splitLines(data, lines);
        for (size_t i = 2; i < lines.size(); ++i) // two header rows (column types, column names)
        {
            const std::string& l = lines[i];
            size_t tab = l.find('\t');
            if (tab == std::string::npos || tab == 0)
                continue;
            m_dict[l.substr(0, tab)] = l.substr(tab + 1); // later rows win, as in CUIStringSystem::Init
        }
        return true;
    }

    void TextResolver::appendRun(CEGUI::String& out, const std::string& run) const
    {
        if (run.empty())
            return;
        if (m_codePage == 65001 || m_codePage <= 0)
        {
            appendUtf8(out, run);
            return;
        }
        const std::wstring w = utf8ToWide(run);
        const UINT cp = (UINT)m_codePage;
        int n = WideCharToMultiByte(cp, 0, w.data(), (int)w.size(), NULL, 0, NULL, NULL);
        std::string mb(n > 0 ? (size_t)n : 0, '\0');
        if (n > 0)
            WideCharToMultiByte(cp, 0, w.data(), (int)w.size(), &mb[0], n, NULL, NULL);
        int wn = mb.empty() ? 0 : MultiByteToWideChar(cp, 0, mb.data(), (int)mb.size(), NULL, 0);
        std::wstring back(wn > 0 ? (size_t)wn : 0, L'\0');
        if (wn > 0)
            MultiByteToWideChar(cp, 0, mb.data(), (int)mb.size(), &back[0], wn);
        appendUtf8(out, wideToUtf8(back));
    }

    void TextResolver::resolveKey(const std::string& id, CEGUI::String& out, int depth)
    {
        // CYS-INFOLINK 19/09: keep the mirror in step with ParserString_RuntimeNew - the game now expands the CY
        // coordinate tags (#{_INFOAIM..} and family, 12.213 of them in StrDictionary.txt) into the inline
        // hyperlink "#aB{x,y,scene,type,target}#u[x,y]#u#aE". Without this branch the viewer (and every width
        // measurement taken with it) would keep counting those tags as zero characters.
        {
            std::string infoLink;
            CysInfoLink::Link parsed;
            if (CysInfoLink::Expand(id, infoLink, &parsed))
            {
                // CYS-INFOPARITY 19/09: _INFOMAP colour bracket, same raw codes UIString.cpp appends (CY 0x18004e6ef).
                if (parsed.mapTag) out += (CEGUI::utf32)0xE80099E5;
                out += resolve(infoLink, depth + 1);
                if (parsed.mapTag) out += (CEGUI::utf32)0xE800CCFF;
                return;
            }
        }
        if (id.compare(0, 5, "_ITEM") == 0)
        {
            appendUtf8(out, "[item]");
            return;
        }
        if (id.compare(0, 5, "_TIME") == 0)
        {
            appendUtf8(out, "[time]");
            return;
        }
        if (id.compare(0, 6, "_MONEY") == 0)
        {
            int money = std::atoi(id.c_str() + 6);
            char buf[128] = { 0 };
            int gold = money / 10000, silver = (money % 10000) / 100, copper = money % 100;
            std::string s;
            if (gold) { std::sprintf(buf, "%d#-02", gold); s += buf; }
            if (silver) { std::sprintf(buf, "%d#-03", silver); s += buf; }
            if (copper) { std::sprintf(buf, "%d#-04", copper); s += buf; }
            out += resolve(s, depth + 1);
            return;
        }
        std::unordered_map<std::string, std::string>::const_iterator it = m_dict.find(id);
        if (it != m_dict.end())
        {
            ++m_resolved;
            out += resolve(it->second, depth + 1);
            return;
        }
        // KEY*arg1*arg2 -> value of KEY with $1$ $2$ ... replaced
        size_t star = id.find('*');
        if (star != std::string::npos)
        {
            it = m_dict.find(id.substr(0, star));
            if (it != m_dict.end())
            {
                std::vector<std::string> args;
                size_t p = star + 1;
                while (p <= id.size())
                {
                    size_t q = id.find('*', p);
                    args.push_back(id.substr(p, q == std::string::npos ? std::string::npos : q - p));
                    if (q == std::string::npos)
                        break;
                    p = q + 1;
                }
                std::string v = it->second;
                for (size_t a = 0; a < args.size() && a < 9; ++a)
                {
                    char tag[8];
                    std::sprintf(tag, "$%d$", (int)a + 1);
                    size_t at;
                    while ((at = v.find(tag)) != std::string::npos)
                        v.replace(at, 3, args[a]);
                }
                ++m_resolved;
                out += resolve(v, depth + 1);
                return;
            }
        }
        ++m_missing[id]; // the game drops unknown keys silently
    }

    CEGUI::String TextResolver::resolve(const std::string& s, int depth)
    {
        CEGUI::String out;
        if (depth > 8)
            return out;
        std::string run;
        bool blink = false;
        bool underline = false;   // CYS-INFOPARITY: "#u" toggle, mirrors UIString.cpp / CY [rbp-0x68]
        size_t i = 0;
        const size_t n = s.size();
        while (i < n)
        {
            char c = s[i];
            if (c != '#')
            {
                run += c;
                ++i;
                continue;
            }
            appendRun(out, run);
            run.clear();
            if (i + 1 >= n)
                break;
            char k = s[i + 1];
            switch (k)
            {
            case 'R': out += (CEGUI::utf32)0xFBFF0000; i += 2; break;
            case 'G': out += (CEGUI::utf32)0xFB00FF00; i += 2; break;
            case 'B': out += (CEGUI::utf32)0xFB0000FF; i += 2; break;
            case 'K': out += (CEGUI::utf32)0xFB000000; i += 2; break;
            case 'Y': out += (CEGUI::utf32)0xFBFFFF00; i += 2; break;
            case 'W': out += (CEGUI::utf32)0xFBFFFFFF; i += 2; break;
            case 'b': out += (CEGUI::utf32)0xE0000000; blink = true; i += 2; break;
            case 'c':
            case 'e':
                {
                    unsigned rgb = hexValue(s.substr(i + 2, 6)) & 0x00FFFFFF;
                    out += (CEGUI::utf32)((k == 'c' ? 0xFB000000u : 0xFC000000u) | rgb);
                    i += 8;
                }
                break;
            case 'g':
                // #gRRGGBB (modern client data, 8,371 uses in client_GL StrDictionary) is unknown to the 0.85 parser,
                // which would print "gRRGGBB"; the viewer draws it as a #c colour and counts it.
                if (isHex6(s, i + 2))
                {
                    ++m_markup["#gRRGGBB"];
                    out += (CEGUI::utf32)(0xFB000000u | (hexValue(s.substr(i + 2, 6)) & 0x00FFFFFF));
                    i += 8;
                }
                else
                {
                    ++m_markup["#g"];
                    i += 1;
                }
                break;
            case 'u':
                // CYS-INFOPARITY 19/09: underline on/off markers (CY UI_CEGUI.dll 0x18004bc63/0x18004bc6b), so the
                // viewer draws the same line the game draws. Zero width, so width measurements do not move.
                out += (CEGUI::utf32)(underline ? 0xE7000000 : 0xE6000000);
                underline = !underline;
                i += 2;
                break;
            case 'n':
                out += (CEGUI::utf32)0xE1000000;  // CY 0x18004bcb9: blink off + underline off, state untouched
                out += (CEGUI::utf32)0xE7000000;
                i += 2;
                break;
            case 'r': out += (CEGUI::utf32)'\n'; i += 2; break;
            case '#': out += (CEGUI::utf32)'#'; i += 2; break;
            case 'a':
                if (i + 2 < n && s[i + 2] == 'B') out += (CEGUI::utf32)0xFD000000;
                else if (i + 2 < n && s[i + 2] == 'E') out += (CEGUI::utf32)0xFE000000;
                i += 3;
                break;
            case '{':
                {
                    size_t end = s.find('}', i + 2);
                    if (end == std::string::npos)
                        i += 3;
                    else
                    {
                        resolveKey(s.substr(i + 2, end - (i + 2)), out, depth);
                        i = end + 1;
                    }
                }
                break;
            case '-':
                if (i + 3 < n && s[i + 2] >= '0' && s[i + 2] <= '9' && s[i + 3] >= '0' && s[i + 3] <= '9')
                {
                    unsigned num = (unsigned)((s[i + 2] - '0') * 10 + (s[i + 3] - '0'));
                    if (num != 1)
                    {
                        out += (CEGUI::utf32)(0xE3000000u | num);
                        i += 4;
                    }
                    else
                        i += 2;
                }
                else
                    i += 2;
                break;
            default:
                if (k >= '0' && k <= '9')
                {
                    unsigned num = (unsigned)(k - '0');
                    if (i + 2 < n && s[i + 2] >= '0' && s[i + 2] <= '9')
                    {
                        num = num * 10 + (unsigned)(s[i + 2] - '0');
                        i += 3;
                    }
                    else
                        i += 2;
                    out += (CEGUI::utf32)(0xFA000000u | num);
                }
                else
                {
                    ++m_markup[std::string("#") + k]; // unknown command: drop the '#', keep the character (0.85)
                    i += 1;
                }
                break;
            }
        }
        appendRun(out, run);
        if (blink)
            out += (CEGUI::utf32)0xE1000000;
        if (underline)
            out += (CEGUI::utf32)0xE7000000;  // CY 0x180054005: close an unbalanced "#u"
        return out;
    }

    CEGUI::String sampleText(const std::string& customUtf8)
    {
        if (!customUtf8.empty())
            return CEGUI::String((const CEGUI::utf8*)customUtf8.c_str());
        // "Thien Long Bat Bo -- Tieng Viet co dau: ..." with {HEX} code points, so that this file stays ASCII (the
        // narrow execution charset of this tree is GBK, which has no Vietnamese).
        static const char kSample[] =
            "Thi{EA}n Long B{E1}t B{1ED9} {2014} Ti{1EBF}ng Vi{1EC7}t c{F3} d{1EA5}u: "
            "{1EAF} {1EB1} {1EB3} {1EB5} {1EB7} {1A1} {1B0} {111}";
        CEGUI::String out;
        for (const char* p = kSample; *p; ++p)
        {
            if (*p == '{')
            {
                const char* q = std::strchr(p, '}');
                if (q)
                {
                    out += (CEGUI::utf32)hexValue(std::string(p + 1, (size_t)(q - p - 1)));
                    p = q;
                    continue;
                }
            }
            out += (CEGUI::utf32)(unsigned char)*p;
        }
        return out;
    }

    bool loadInterfaceTable(const std::string& path, std::map<std::string, std::string>& layoutToWindow)
    {
        std::string data;
        if (!readWholeFile(path, data))
            return false;
        std::vector<std::string> lines;
        splitLines(data, lines);
        for (size_t i = 2; i < lines.size(); ++i)
        {
            std::vector<std::string> cols;
            size_t p = 0;
            const std::string& l = lines[i];
            while (p <= l.size() && cols.size() < 4)
            {
                size_t q = l.find('\t', p);
                cols.push_back(l.substr(p, q == std::string::npos ? std::string::npos : q - p));
                if (q == std::string::npos)
                    break;
                p = q + 1;
            }
            if (cols.size() >= 3 && !cols[2].empty())
                layoutToWindow[lowerAscii(slashes(cols[2], '/'))] = cols[1];
        }
        return true;
    }
}
