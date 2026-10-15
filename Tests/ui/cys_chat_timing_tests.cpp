#include "../../Src/Client/WXClient/Interface/CysChatTiming.h"
#include <iostream>
#include <stdexcept>
static void Require(bool ok, const char* reason) { if (!ok) throw std::runtime_error(reason); }
int main()
{
    try
    {
        using CysChatTiming::Passed;
        // Independent live CY ChatConfig: near=3000 ms; team=1000; world=180000.
        Require(!Passed(2999,3000,false) && !Passed(3000,3000,false), "near cooldown permits early or exact-boundary send");
        Require(Passed(3001,3000,false) && Passed(4500,3000,false), "near cooldown uses seconds instead of milliseconds");
        Require(!Passed(1000,1000,false) && Passed(1001,1000,false), "team boundary differs from strict CY comparison");
        Require(!Passed(180000,180000,false) && Passed(180001,180000,false), "world interval changed scale");
        Require(!Passed(0,0,false) && Passed(1,0,false), "zero interval boundary differs from CY");
        Require(!Passed(4500,3000,true) && !Passed(3000000,3000,true) && Passed(3001000,3000,true), "same-binary old control does not reproduce the observed unit bug");
        std::cout << "PASS near/team/world strict millisecond boundaries and legacy-seconds control\n";
        return 0;
    }
    catch (const std::exception& e) { std::cerr << "FAIL " << e.what() << '\n'; return 1; }
}
