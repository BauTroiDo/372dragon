#include "../../Src/Client/WXClient/Network/CysPvpRules.h"
#include <cassert>
#include <iostream>
using CysPvp::Human;
int main(){
    Human a,b;a.guid=1;b.guid=2;a.level=b.level=95;
    auto enemy=[&](int rule=11,int min=20){return CysPvp::Enemy(a,b,rule,min);};
    assert(!enemy());a.mode=1;assert(enemy());assert(!enemy(0));assert(!enemy(11,100));
    a.level=19;assert(!enemy());a.level=95;b.level=19;assert(!enemy());b.level=95;
    a.mode=2;assert(!enemy());b.pk=1;assert(enemy());b.pk=0;
    a.mode=3;a.team=b.team=7;assert(!enemy());b.team=8;assert(enemy());
    a.mode=4;a.guild=b.guild=7;assert(!enemy());b.guild=8;a.alliance=b.alliance=9;assert(!enemy());b.alliance=10;assert(enemy());
    a.mode=5;a.raid=b.raid=7;assert(!enemy());b.raid=8;assert(enemy());
    a.mode=0;a.attackers.insert(2);assert(enemy());assert(!enemy(0));a.attackers.clear();
    a.declarations.insert(2);assert(enemy());assert(!enemy(2));a.declarations.clear();
    a.wars.insert(8);assert(enemy());a.wars.clear();
    a.camp=10;b.camp=11;assert(enemy(4));b.camp=10;assert(!enemy(4));
    a.camp=b.camp=-1;assert(enemy(4));a.camp=b.camp=10;
    a.mode=1;assert(!enemy(4));b.guid=1;assert(!enemy());b.guid=0;assert(!enemy());
    std::cout<<"PASS client PvP permissions, modes, relation lists and protected levels\n";
}
