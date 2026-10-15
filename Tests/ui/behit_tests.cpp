#include "../../Src/Client/CEGUISystem/CysBeHitConfig.h"
#include <fstream>
#include <iostream>
#include <functional>

int passed = 0, failed = 0;
void check(bool ok, const char* name) {
    std::cout << (ok ? "PASS " : "FAIL ") << name << '\n';
    ok ? ++passed : ++failed;
}
bool near(float a, float b) { return std::fabs(a-b) < 0.0001f; }
bool rejects(const std::function<void()>& f) { try { f(); return false; } catch (const std::exception&) { return true; } }
std::string changed(std::string data, const std::string& from, const std::string& to) {
    size_t at = data.find(from); if (at == std::string::npos) throw std::runtime_error("fixture token missing");
    data.replace(at, from.size(), to); return data;
}
int main(int argc, char** argv) {
    if (argc != 2) return 2;
    std::ifstream in(argv[1], std::ios::binary);
    std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    cys::BeHitTable t; t.load(bytes);
    check(t.size() == 14, "Canonical 14 rows, raw GBK / CRCRLF accepted");
    const cys::BeHitConfig r = *t.find(0, false);
    check(r.x==-10 && r.y==70 && r.ax==72 && r.ay==-10 && r.vx==-120 && r.vy==30, "healing positions / acceleration / velocity match B offsets");
    check(r.holdMs==1000 && r.fadeMs==1000 && r.colour==0xff009f3c && r.border==0xffffff, "healing durations and colours");
    check(t.find(0,true)->id==100 && t.find(0,true)->y==60, "alternate healing row 100");
    check(t.find(7,true)==t.find(7,false), "alternate lookup falls back to base");
    check(t.find(-1,true)==nullptr && t.find(999,false)==nullptr, "unknown type never indexes an array");
    check(t.find(13,false) && t.find(14,false), "modern piercing ids retained");
    check(t.find(1,false)->colour==0x00ff00b4, "six digit foreground preserves B alpha interpretation");
    cys::BeHitMotion m; m.reset(r,false,300,400);
    check(near(m.x,290) && near(m.y,470) && m.life==2000, "initial position and total lifetime");
    m.tick(r,100);
    check(near(m.vx,-112.8f) && near(m.vy,29) && near(m.x,278.72f) && near(m.y,472.9f), "100 ms semi-implicit Euler golden");
    check(m.life==1900 && near(m.alpha,1) && near(m.scale,1), "hold phase has full alpha and normal scale");
    m.reset(r,false,0,0); m.tick(r,1000);
    check(near(m.alpha,1), "alpha at fade boundary");
    m.tick(r,500); check(m.life==500 && near(m.alpha,.5f), "half of fade duration");
    check(!m.tick(r,500) && m.life==0 && near(m.alpha,0), "expires exactly at zero");
    m.reset(r,true,0,0); m.tick(r,100); check(near(m.scale,2.5f), "critical rising midpoint");
    m.tick(r,100); check(near(m.scale,4), "critical peak at 200 ms");
    m.tick(r,100); check(near(m.scale,3), "critical falling midpoint");
    m.tick(r,100); check(near(m.scale,2), "critical end at 400 ms");
    m.tick(r,100); check(near(m.scale,2), "critical end held after transition");
    cys::BeHitConfig zero=r; zero.peakMs=0; zero.endMs=0;
    m.reset(zero,true,0,0); m.tick(zero,0); check(std::isfinite(m.scale) && near(m.scale,4), "zero peak and zero delta avoid divide by zero");
    m.tick(zero,1); check(near(m.scale,2), "zero transition ends on first elapsed tick");
    zero.holdMs=100; zero.fadeMs=0; m.reset(zero,false,0,0);
    check(m.tick(zero,99) && near(m.alpha,1) && !m.tick(zero,1), "zero fade remains opaque until expiry");
    const auto disabled=*t.find(2,false); m.reset(disabled,false,0,0);
    check(!m.tick(disabled,0), "zero duration row is deliberately disabled");
    check(rejects([&]{m.tick(r,-1);}) && rejects([&]{m.tick(r,NAN);}), "invalid frame durations rejected");
    const std::vector<std::pair<std::string,std::string>> invalid = {
        {"INT\tSTRING", "FLOAT\tSTRING"},
        {"-10\t70\t72", "-10\t70\t72x"},
        {"-10\t70\t72", "-10\t70"},
        {"1000\t1000", "-1\t1000"},
        {"1000\t1000", "2147483647\t1"},
        {"FF009f3c", "ZZ009f3c"},
        {"ffffff\tFFfa1004", "ffffffff\tFFfa1004"},
        {"1\t1\t4\t2\t200\t400", "nan\t1\t4\t2\t200\t400"},
        {"1\t1\t4\t2\t200\t400", "0\t1\t4\t2\t200\t400"},
        {"200\t400", "400\t200"},
        {"\n1\t", "\n0\t"},
        {"\n1\t", "\n99\t"}
    };
    for (const auto& bad : invalid) {
        check(rejects([&]{t.load(changed(bytes,bad.first,bad.second));}), ("reject malformed: "+bad.second).c_str());
    }
    check(rejects([&]{t.load("");}) && rejects([&]{t.load("INT\nINT\n");}), "empty and wrong schemas rejected");
    check(t.size()==14 && t.find(0,false)->y==70, "failed reload preserves previous valid table");
    std::cout << passed << '/' << passed+failed << " passed\n";
    return failed ? 1 : 0;
}
