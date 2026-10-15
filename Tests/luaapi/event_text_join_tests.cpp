// CYS-QUEST: unit tests for CysEventTextJoin (client side of the 255-byte event-list text split).
#include "CysEventTextJoin.h"

#include <cstdio>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace
{
    unsigned passed = 0, failed = 0;
    typedef std::vector<std::pair<int, std::string> > Events;
    template<class F> void Test(const char* name, F run)
    {
        try { run(); ++passed; std::printf("PASS %s\n", name); }
        catch (const std::exception& e) { ++failed; std::printf("FAIL %s: %s\n", name, e.what()); }
    }
    void Require(bool v, const char* what) { if (!v) throw std::runtime_error(what); }
    Events E(std::initializer_list<std::pair<int, std::string> > l) { return Events(l); }
    const std::string M(1, CysEventTextJoin::kContinuation);
}

int main()
{
    using CysEventTextJoin::Join;
    Test("plain_items_unchanged", [] {
        const auto j = Join(E({ { 2, "  Chao" }, { 1, "Ve loi dai" }, { 0, "Muc" }, { 2, "Ket" } }));
        Require(j.size() == 4 && j[0].text == "  Chao" && j[1].flag == 1 && j[2].flag == 0 && j[3].first == 3, "4 items");
    });
    Test("two_chunks_joined", [] {
        const std::string a(254, 'a');
        const auto j = Join(E({ { 2, a + M }, { 2, "bb" }, { 1, "opt" } }));
        Require(j.size() == 2 && j[0].text == a + "bb" && j[0].first == 0 && j[1].first == 2, "joined");
    });
    Test("three_chunks_with_utf8_and_colour_codes", [] {
        const std::string p1 = "  #G$N#W anh h\xC3\xB9ng! ", p2 = "#GTr\xC6\xB0\xE1\xBB\x9B\x63 khi ", p3 = "v\xC3\xA0o#W";
        const auto j = Join(E({ { 2, p1 + M }, { 2, p2 + M }, { 2, p3 } }));
        Require(j.size() == 1 && j[0].text == p1 + p2 + p3, "three joined");
    });
    Test("exactly_255_without_mark_not_joined", [] {
        const auto j = Join(E({ { 2, std::string(255, 'x') }, { 2, "y" } }));
        Require(j.size() == 2, "not joined");
    });
    Test("mark_on_option_ignored", [] {
        const auto j = Join(E({ { 1, "opt" + M }, { 2, "t" } }));
        Require(j.size() == 2 && j[0].text == "opt" + M, "option untouched");
    });
    Test("mark_before_option_stripped_not_joined", [] {
        const auto j = Join(E({ { 2, "cut" + M }, { 1, "opt" } }));
        Require(j.size() == 2 && j[0].text == "cut" && j[1].text == "opt", "stripped");
    });
    Test("trailing_mark_at_end_stripped", [] {
        const auto j = Join(E({ { 2, "last" + M } }));
        Require(j.size() == 1 && j[0].text == "last", "stripped");
    });
    Test("different_flag_not_joined", [] {
        const auto j = Join(E({ { 0, "sec" + M }, { 2, "text" } }));
        Require(j.size() == 2 && j[0].text == "sec" && j[1].text == "text", "section/text kept apart");
    });
    Test("mark_inside_text_kept", [] {
        const auto j = Join(E({ { 2, "a" + M + "b" } }));
        Require(j.size() == 1 && j[0].text == "a" + M + "b", "only a trailing mark counts");
    });
    Test("sixteen_items_long_joined_first", [] {
        Events ev;
        ev.push_back(std::make_pair(2, std::string(254, 'a') + M));
        ev.push_back(std::make_pair(2, std::string(100, 'b')));
        for (int i = 0; i < 14; ++i) ev.push_back(std::make_pair(1, "o" + std::to_string(i)));
        const auto j = Join(ev);
        Require(j.size() == 15 && j[0].text.size() == 354 && j[14].first == 15, "15 joined items from 16");
    });
    Test("empty", [] { Require(Join(Events()).empty(), "empty"); });
    std::printf("RESULT passed=%u failed=%u\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
