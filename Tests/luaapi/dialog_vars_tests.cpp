


#include "CysDialogVars.h"

#include <cstdio>
#include <fstream>
#include <map>
#include <stdexcept>
#include <string>

namespace
{
    unsigned passed = 0;
    unsigned failed = 0;
    typedef std::map<std::string, std::string> Dictionary;

    template<class F> void Test(const char* name, F run)
    {
        try { run(); ++passed; std::printf("PASS %s\n", name); }
        catch (const std::exception& e) { ++failed; std::printf("FAIL %s: %s\n", name, e.what()); }
    }
    void Equal(const std::string& got, const std::string& want, const char* what)
    {
        if (got != want) throw std::runtime_error(std::string(what) + ": got [" + got + "] want [" + want + "]");
    }

    class Fake : public CysDialogVars::Provider
    {
    public:
        std::string self, target, user;
        int selfSex, targetSex;
        Dictionary dictionary;
        int calls;
        Fake() : self("CYTest00"), target(""), user(""), selfSex(1), targetSex(-1), calls(0) {}
        virtual std::string Name(int who) { ++calls; return who == 0 ? self : target; }
        virtual int Sex(int who) { ++calls; return who == 0 ? selfSex : targetSex; }
        virtual std::string UserString() { ++calls; return user; }
        virtual bool Lookup(const std::string& key, std::string& value)
        {
            Dictionary::const_iterator it = dictionary.find(key);
            if (it == dictionary.end()) return false;
            value = it->second;
            return true;
        }
    };

    std::string Run(const std::string& src, CysDialogVars::Provider* p)
    {
        std::string out = "stale";
        CysDialogVars::Expand(src, p, CysDialogVars::ProtectedRanges(src), out);
        return out;
    }

    void FillSexKeys(Fake& f)
    {
        f.dictionary["GMGameInterface_Script_Talk_Info_G_Man"] = "G-man";
        f.dictionary["GMGameInterface_Script_Talk_Info_G_Woman"] = "G-woman";
        f.dictionary["GMGameInterface_Script_Talk_Info_g_Man"] = "g-man";
        f.dictionary["GMGameInterface_Script_Talk_Info_g_Woman"] = "g-woman";
        f.dictionary["GMGameInterface_Script_Talk_Info_R_Man"] = "R-man";
        f.dictionary["GMGameInterface_Script_Talk_Info_R_Woman"] = "R-woman";
        f.dictionary["GMGameInterface_Script_Talk_Info_r_Man"] = "r-man";
        f.dictionary["GMGameInterface_Script_Talk_Info_r_Woman"] = "r-woman";
    }
}

int main(int argc, char** argv)
{
    Test("N_self_name", [] { Fake f; Equal(Run("Chao mung $N Thieu hiep", &f), "Chao mung CYTest00 Thieu hiep", "N"); });
    Test("N_repeated_and_edges", [] { Fake f; Equal(Run("$N,$N.$N", &f), "CYTest00,CYTest00.CYTest00", "N*3"); });
    Test("n_target_character", [] { Fake f; f.target = "Trieu Thien Su"; Equal(Run("[$n]", &f), "[Trieu Thien Su]", "n"); });
    Test("n_no_target_is_empty", [] { Fake f; Equal(Run("[$n]", &f), "[]", "n empty"); });
    Test("U_user_string", [] { Fake f; f.user = "khu1"; Equal(Run("<$U>", &f), "<khu1>", "U"); });
    Test("U_empty_as_0_85", [] { Fake f; Equal(Run("<$U>", &f), "<>", "U empty"); });
    Test("G_R_r_use_self_sex_male", [] { Fake f; FillSexKeys(f); f.selfSex = 1; f.targetSex = 0;
        Equal(Run("$G|$R|$r|$g", &f), "G-man|R-man|r-man|g-woman", "male self, female target"); });
    Test("G_R_r_use_self_sex_female", [] { Fake f; FillSexKeys(f); f.selfSex = 0; f.targetSex = 1;
        Equal(Run("$G|$R|$r|$g", &f), "G-woman|R-woman|r-woman|g-man", "female self, male target"); });
    Test("sex_unknown_drops_variable", [] { Fake f; FillSexKeys(f); f.selfSex = -1; f.targetSex = 2;
        Equal(Run("a$Gb$gc$Rd$re", &f), "abcde", "sex -1/2"); });
    Test("missing_dictionary_key_is_empty", [] { Fake f; Equal(Run("x$Ry", &f), "xy", "no key"); });
    Test("unknown_variable_drops_only_dollar", [] { Fake f; Equal(Run("$X $C 5$ $1", &f), "X C 5 1", "unknown"); });
    Test("dollar_dollar_N", [] { Fake f; Equal(Run("$$N", &f), "CYTest00", "$$N"); });
    Test("trailing_dollar", [] { Fake f; Equal(Run("100$", &f), "100", "tail"); Equal(Run("$", &f), "", "alone"); });
    Test("lowercase_and_other_letters_untouched", [] { Fake f; Equal(Run("$u$a$z", &f), "uaz", "u a z"); });
    Test("no_dollar_no_provider_calls", [] { Fake f; Equal(Run("#{OBJ_dali_0055}#r #GTen#W", &f), "#{OBJ_dali_0055}#r #GTen#W", "plain");
        if (f.calls != 0) throw std::runtime_error("provider called"); });
    Test("null_provider_copies", [] { Equal(Run("$N $G", NULL), "$N $G", "null"); });
    Test("utf8_around_variable", [] { Fake f; Equal(Run("\xE1\xBA\xA0i $N, ng\xC6\xB0\xE1\xBB\x9Di", &f),
        "\xE1\xBA\xA0i CYTest00, ng\xC6\xB0\xE1\xBB\x9Di", "utf8"); });
    Test("infomsg_range_protects_payload", [] {
        Fake f;
        const std::string s = "a#{_INFOMSG004$N$n}$N";
        const std::vector<CysDialogVars::Range> r = CysDialogVars::ProtectedRanges(s);
        if (r.size() != 1 || r[0].lo != 0 || r[0].hi != 18) throw std::runtime_error("range [0,18] expected");
        Equal(Run(s, &f), "a#{_INFOMSG004$N$n}CYTest00", "infomsg");
    });
    Test("infomsg_range_starts_one_before_hash", [] { Fake f; Equal(Run("$#{_INFOMSG000}$N", &f), "$#{_INFOMSG000}CYTest00", "lo=#-1"); });
    Test("infomsg_malformed_stops_ranges", [] {
        Fake f;
        const std::string s = "#{_INFOMSG009$N} #{_INFOMSG002$N}";
        if (!CysDialogVars::ProtectedRanges(s).empty()) throw std::runtime_error("no range expected");
        Equal(Run(s, &f), "#{_INFOMSG009CYTest00} #{_INFOMSG002CYTest00}", "malformed");
    });
    Test("star_length_range_protects", [] {
        Fake f;
        const std::string s = std::string("#{I*x\x05$N}$N");
        const std::vector<CysDialogVars::Range> r = CysDialogVars::ProtectedRanges(s);
        if (r.size() != 1 || r[0].lo != -1 || r[0].hi != 8) throw std::runtime_error("range [-1,8] expected");
        Equal(Run(s, &f), std::string("#{I*x\x05$N}CYTest00"), "star");
    });
    Test("star_wrong_length_not_protected", [] { Fake f; Equal(Run(std::string("#{I*x\x09$N}"), &f), std::string("#{I*x\x09") + "CYTest00}", "star bad"); });
    Test("output_cleared_before_write", [] { std::string out = "old"; Fake f;
        CysDialogVars::Expand("", &f, std::vector<CysDialogVars::Range>(), out); Equal(out, "", "clear"); });

    if (argc > 1)
    {
        const std::string path = argv[1];
        Test("canonical_dictionary_sex_keys_and_N", [&path] {
            std::ifstream in(path.c_str(), std::ios::binary);
            if (!in) throw std::runtime_error("cannot open " + path);
            Fake f; std::string line; unsigned withN = 0, leftN = 0;
            std::map<std::string, std::string> withNText;
            while (std::getline(in, line))
            {
                if (!line.empty() && line[line.size() - 1] == '\r') line.erase(line.size() - 1);
                if (line.size() >= 3 && line.compare(0, 3, "\xEF\xBB\xBF") == 0) line.erase(0, 3);
                const size_t tab = line.find('\t');
                if (tab == std::string::npos) continue;
                f.dictionary[line.substr(0, tab)] = line.substr(tab + 1);
            }
            const char* man[] = { "G_Man", "g_Man", "R_Man", "r_Man", "G_Woman", "g_Woman", "R_Woman", "r_Woman" };
            for (size_t i = 0; i < 8; ++i)
                if (f.dictionary.find(std::string("GMGameInterface_Script_Talk_Info_") + man[i]) == f.dictionary.end())
                    throw std::runtime_error(std::string("missing key ") + man[i]);
            for (Dictionary::const_iterator it = f.dictionary.begin(); it != f.dictionary.end(); ++it)
            {
                if (it->second.find("$N") == std::string::npos) continue;
                ++withN;
                const std::string out = Run(it->second, &f);
                if (out.find("$N") != std::string::npos) ++leftN;
            }
            f.selfSex = 1;
            Equal(Run("$R", &f), f.dictionary["GMGameInterface_Script_Talk_Info_R_Man"], "R man = dictionary");
            f.selfSex = 0;
            Equal(Run("$R", &f), f.dictionary["GMGameInterface_Script_Talk_Info_R_Woman"], "R woman = dictionary");
            const std::string wuliang = Run(f.dictionary["Mis_K_Wuliang_1000000"], &f);
            if (wuliang.compare(0, 17, "CYTest00, ng\xC6\xB0\xC6\xA1i") != 0) throw std::runtime_error("Mis_K_Wuliang_1000000: " + wuliang.substr(0, 40));
            std::printf("  dictionary entries=%u with $N=%u left after expand=%u R_Man=[%s] R_Woman=[%s]\n",
                (unsigned)f.dictionary.size(), withN, leftN,
                f.dictionary["GMGameInterface_Script_Talk_Info_R_Man"].c_str(), f.dictionary["GMGameInterface_Script_Talk_Info_R_Woman"].c_str());
            if (withN == 0 || leftN != 0) throw std::runtime_error("$N not expanded everywhere");
        });
    }

    std::printf("RESULT passed=%u failed=%u\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
