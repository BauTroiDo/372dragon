// CYS-INFOLINK: unit tests for CysInfoLink (CY 3.71 UI_CEGUI.dll #{_INFOxxx..} coordinate hyperlinks).
// Expected strings are written from the CY templates read out of .rdata (0x18008f3f8, 0x18008f498,
// 0x18008fb70 ... see CysInfoLink.h), NOT produced by the implementation.
// argv[1] = CanonicalCY StrDictionary.txt (optional whole-file section).
#include "CysInfoLink.h"

#include <cstdio>
#include <fstream>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>

namespace
{
    unsigned passed = 0;
    unsigned failed = 0;

    template<class F> void Test(const char* name, F run)
    {
        try { run(); ++passed; std::printf("PASS %s\n", name); }
        catch (const std::exception& e) { ++failed; std::printf("FAIL %s: %s\n", name, e.what()); }
    }
    void Equal(const std::string& got, const std::string& want, const char* what)
    {
        if (got != want) throw std::runtime_error(std::string(what) + ": got [" + got + "] want [" + want + "]");
    }
    void EqualInt(int got, int want, const char* what)
    {
        if (got != want)
        {
            char buf[128] = { 0 };
            _snprintf(buf, sizeof(buf) - 1, "%s: got %d want %d", what, got, want);
            throw std::runtime_error(buf);
        }
    }
    void True(bool cond, const char* what)
    {
        if (!cond) throw std::runtime_error(std::string("expected true: ") + what);
    }

    std::string Expand(const std::string& id)
    {
        std::string out = "stale";
        if (!CysInfoLink::Expand(id, out)) return std::string();
        return out;
    }
}

int main(int argc, char** argv)
{
    // ---- 1. The two tags of XSRWGZ_110917_27, the row that proved the tags were being dropped -------------
    Test("_INFOAIM = CY template 0x18008f3f8 with type 0", []()
    {
        Equal(Expand("_INFOAIM160,159,2,\xE8\xB5\xB5\xE5\xA4\xA9\xE5\xB8\x88"),
              "#aB{160,159,2,0,\xE8\xB5\xB5\xE5\xA4\xA9\xE5\xB8\x88}#u[160,159]#u#aE", "_INFOAIM");
    });
    Test("_INFOUSEITEM = CY template 0x18008fb70 with type 2", []()
    {
        Equal(Expand("_INFOUSEITEM160,93,2,38000173"),
              "#aB{160,93,2,2,38000173}#u[160,93]#u#aE", "_INFOUSEITEM");
    });

    // ---- 2. Every tag maps to the type read at its own _snprintf in CY -----------------------------------
    Test("tag -> link type table matches CY", []()
    {
        struct Case { const char* id; const char* want; };
        const Case cases[] = {
            { "_INFOMAP131,121,2,x",     "#aB{131,121,2,0,x}#u[131,121]#u#aE" },   // 0x18004e652 template ",0,"
            { "_INFOKILL81,99,8,x",      "#aB{81,99,8,1,x}#u[81,99]#u#aE"     },   // 0x18004f535 template ",1,"
            { "_GETITEM282,261,2,x",     "#aB{282,261,2,3,x}#u[282,261]#u#aE" },   // 0x18004f6f3 template ",3,"
            { "_GETPET90,70,123,x",      "#aB{90,70,123,4,x}#u[90,70]#u#aE"   },   // 0x18004f8b1 template ",4,"
            { "_INFOCITY93,60,0,x",      "#aB{93,60,0,5,x}#u[93,60]#u#aE"     },   // 0x18004e85f  $0x5
            { "_INFO2CITY45,47,-1,x",    "#aB{45,47,-1,5,x}#u[45,47]#u#aE"    },   // 0x18004ea6b  $0x5
            { "_INFOHOME133,147,-1,x",   "#aB{133,147,-1,6,x}#u[133,147]#u#aE"},   // 0x18004ec93  $0x6
            { "_INFO2HOME1,2,3,x",       "#aB{1,2,3,6,x}#u[1,2]#u#aE"         },   // 0x18004ee9f  $0x6
            { "_INFO2LINE1,2,3,x",       "#aB{1,2,3,7,x}#u[1,2]#u#aE"         },   // 0x18004f2fe  $0x7
            { "_INFO2WYXZ1,2,3,9,x",     "#aB{1,2,3,8,9,x}#u[1,2]#u#aE"       },   // 0x18004f0d6  $0x8, 5 fields
        };
        for (size_t i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i)
            Equal(Expand(cases[i].id), cases[i].want, cases[i].id);
    });

    // ---- 3. Keys that are NOT coordinate links must stay untouched ---------------------------------------
    Test("non-link keys are refused", []()
    {
        const char* ids[] = { "_INFOMSG003bhello", "_INFOID12", "_INFOUSR", "_INFOACHV", "_INFOPNE",
                              "_INFOXZ", "_INFOSER", "_INFOTZZ1,2,3", "_BUYFROMYBSHOP1,2,3,4,5,x",
                              "_ITEM10100005", "_TIME0507211233", "_MONEY8583045", "XSRWGZ_110917_27", "" };
        for (size_t i = 0; i < sizeof(ids) / sizeof(ids[0]); ++i)
        {
            std::string out;
            if (CysInfoLink::Expand(ids[i], out))
                throw std::runtime_error(std::string("must not expand: ") + ids[i]);
        }
    });

    // ---- 4. Shapes that really occur in StrDictionary.txt -------------------------------------------------
    Test("three-field tag keeps an empty target, like CY's memset buffer", []()
    {
        Equal(Expand("_INFOAIM208,313,579"), "#aB{208,313,579,0,}#u[208,313]#u#aE", "3 fields");
    });
    Test("float coordinates truncate instead of poisoning the rest (CY %d stops at '.')", []()
    {
        Equal(Expand("_INFOAIM133.5,259.9,0,x"), "#aB{133,259,0,0,x}#u[133,259]#u#aE", "float coords");
    });
    Test("unresolved packed-format slots are refused, not half-parsed", []()
    {
        std::string out;
        True(!CysInfoLink::Expand("_INFOUSEITEM%s1,%s2,%s3,40004507", out), "%s1 slots");
        True(!CysInfoLink::Expand("_INFO2LINE%s1,%s2,%s3,%s4", out), "%s slots");
    });
    Test("'#', '{' and '}' never reach the link key", []()
    {
        Equal(Expand("_INFOAIM1,2,3,a#b{c}d"), "#aB{1,2,3,0,abcd}#u[1,2]#u#aE", "unsafe target bytes");
    });

    // ---- 4b. CYS-INFOPARITY 19/09: the _INFOMAP colour bracket flag and the 8-digit item id rule -----------
    Test("only _INFOMAP asks for the 0xE8 colour bracket", []()
    {
        std::string out;
        CysInfoLink::Link l;
        True(CysInfoLink::Expand("_INFOMAP131,121,2,x", out, &l) && l.mapTag, "_INFOMAP sets mapTag");
        Equal(out, "#aB{131,121,2,0,x}#u[131,121]#u#aE", "_INFOMAP text unchanged");
        True(CysInfoLink::Expand("_INFOAIM160,159,2,x", out, &l) && !l.mapTag, "_INFOAIM clears mapTag");
        True(CysInfoLink::Expand("_INFOUSEITEM160,93,2,38000173", out, &l) && !l.mapTag, "_INFOUSEITEM clears mapTag");
        True(CysInfoLink::Expand("_INFOMAP1,2,3,x", out, (CysInfoLink::Link*)0), "null out-parameter tolerated");
    });
    Test("UseItemID mirrors CY 0x18007191d: exactly 8 digits, first 1..9", []()
    {
        EqualInt(CysInfoLink::UseItemID("38000173"), 38000173, "8 digits");
        EqualInt(CysInfoLink::UseItemID("40004716"), 40004716, "8 digits (quest item range)");
        EqualInt(CysInfoLink::UseItemID("48058"), 0, "5 digits shipped in 3 rows -> walk only");
        EqualInt(CysInfoLink::UseItemID("08000173"), 0, "leading zero");
        EqualInt(CysInfoLink::UseItemID("3800017x"), 0, "non-digit");
        EqualInt(CysInfoLink::UseItemID(""), 0, "empty");
    });

    // ---- 5. Click side: the key layout CY's handleHyperLinkLeftActive parses ------------------------------
    Test("ParseKey reads x,y,scene,type,target", []()
    {
        CysInfoLink::Link l;
        True(CysInfoLink::ParseKey("160,159,2,0,\xE8\xB5\xB5\xE5\xA4\xA9\xE5\xB8\x88", l), "parse aim key");
        EqualInt(l.x, 160, "x"); EqualInt(l.y, 159, "y"); EqualInt(l.scene, 2, "scene"); EqualInt(l.type, 0, "type");
        Equal(l.target, "\xE8\xB5\xB5\xE5\xA4\xA9\xE5\xB8\x88", "target");

        True(CysInfoLink::ParseKey("160,93,2,2,38000173", l), "parse item key");
        EqualInt(l.type, 2, "item type"); Equal(l.target, "38000173", "item id");

        True(CysInfoLink::ParseKey("1,2,-1,6,", l), "empty target still parses");
        EqualInt(l.scene, -1, "negative scene");
    });
    Test("ParseKey refuses the 0.85 key layouts", []()
    {
        CysInfoLink::Link l;
        True(!CysInfoLink::ParseKey("1052,124,166##w", l), "old #w key");
        True(!CysInfoLink::ParseKey("12,10100005##z", l), "old #z key");
        True(!CysInfoLink::ParseKey("CYTest00", l), "chat player name");
        True(!CysInfoLink::ParseKey("1,2,3", l), "only three fields");
    });

    // ---- 6. Round trip: expand a tag, then read the key the font layer would collect ----------------------
    Test("expand -> key round trip", []()
    {
        const std::string expanded = Expand("_INFOHOME133,147,-1,\xE9\xB2\x81\xE5\xAE\xB6\xE8\xB4\xA2");
        const size_t open = expanded.find('{'), close = expanded.find('}');
        True(open != std::string::npos && close != std::string::npos && close > open, "braces present");
        CysInfoLink::Link l;
        True(CysInfoLink::ParseKey(expanded.substr(open + 1, close - open - 1), l), "key parses back");
        EqualInt(l.x, 133, "x"); EqualInt(l.y, 147, "y"); EqualInt(l.scene, -1, "scene"); EqualInt(l.type, 6, "type");
    });

    // ---- 7. Whole-file sweep over the shipped StrDictionary ----------------------------------------------
    if (argc > 1)
    {
        Test("StrDictionary.txt sweep", [&]()
        {
            std::ifstream in(argv[1], std::ios::binary);
            if (!in) throw std::runtime_error(std::string("cannot open ") + argv[1]);
            std::string line;
            unsigned rows = 0, tags = 0, expanded = 0, refused = 0, addedChars = 0;
            std::map<int, unsigned> byType;
            std::vector<std::string> refusedSamples;
            while (std::getline(in, line))
            {
                ++rows;
                for (size_t i = 0; i + 1 < line.size(); ++i)
                {
                    if (line[i] != '#' || line[i + 1] != '{') continue;
                    const size_t close = line.find('}', i + 2);
                    if (close == std::string::npos) break;
                    const std::string id = line.substr(i + 2, close - i - 2);
                    i = close;
                    if (id.compare(0, 5, "_INFO") != 0 && id.compare(0, 4, "_GET") != 0) continue;
                    // the non-coordinate members of the family
                    if (id.compare(0, 8, "_INFOMSG") == 0 || id.compare(0, 7, "_INFOID") == 0 ||
                        id.compare(0, 8, "_INFOUSR") == 0 || id.compare(0, 9, "_INFOACHV") == 0 ||
                        id.compare(0, 8, "_INFOPNE") == 0 || id.compare(0, 7, "_INFOXZ") == 0 ||
                        id.compare(0, 8, "_INFOSER") == 0 || id.compare(0, 8, "_INFOTZZ") == 0) continue;
                    ++tags;
                    CysInfoLink::Link parsed;
                    std::string out;
                    if (CysInfoLink::Parse(id, parsed) && CysInfoLink::Expand(id, out))
                    {
                        ++expanded;
                        ++byType[parsed.type];
                        // what the player gains on screen is exactly the visible "[x,y]"
                        const size_t open = out.find('{'), close2 = out.find('}');
                        addedChars += (unsigned)(out.size() - close2 - 1 - 2 /*#u*/ - 2 /*#u*/ - 3 /*#aE*/);
                        CysInfoLink::Link back;
                        if (!CysInfoLink::ParseKey(out.substr(open + 1, close2 - open - 1), back))
                            throw std::runtime_error("key does not parse back: " + out);
                        if (back.x != parsed.x || back.y != parsed.y || back.scene != parsed.scene || back.type != parsed.type)
                            throw std::runtime_error("round trip changed the link: " + out);
                    }
                    else
                    {
                        ++refused;
                        if (refusedSamples.size() < 5) refusedSamples.push_back(id);
                    }
                }
            }
            std::printf("  rows=%u coordinate tags=%u expanded=%u refused=%u visible chars added=%u\n",
                rows, tags, expanded, refused, addedChars);
            for (std::map<int, unsigned>::const_iterator it = byType.begin(); it != byType.end(); ++it)
                std::printf("    type %d -> %u tags\n", it->first, it->second);
            for (size_t i = 0; i < refusedSamples.size(); ++i)
                std::printf("    refused sample: %s\n", refusedSamples[i].c_str());
            if (tags < 12000) throw std::runtime_error("far fewer coordinate tags than the 12.200 measured");
            if (expanded * 100u < tags * 96u) throw std::runtime_error("less than 96% of the tags expand");
        });
    }

    std::printf("RESULT passed=%u failed=%u\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
