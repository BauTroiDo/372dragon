#pragma once
#include <set>
namespace CysPvp {
struct Human {
    int mode=0,level=0,team=-1,guild=-1,alliance=-1,raid=-1,server=0,camp=0,pk=0,guid=0;
    std::set<int> attackers,declarations,wars;
};
// Prediction for targeting only. The scene still validates every skill request.
inline bool Enemy(const Human& a,const Human& b,int rule,int minimum) {
    if((rule&14)==0 || a.level<minimum || b.level<minimum || !a.guid || !b.guid || a.guid==b.guid)return false;
    if(a.attackers.count(b.guid))return true;
    if((rule&8) && (a.declarations.count(b.guid)||b.declarations.count(a.guid)))return true;
    if(a.wars.count(b.guild)||b.wars.count(a.guild))return true;
    if((rule&4) && (a.camp==-1 || b.camp==-1 || a.camp!=b.camp))return true;
    if(!(rule&2))return false;
    switch(a.mode){
    case 1:return true;
    case 2:return b.pk>0;
    case 3:return a.team<0 || a.team!=b.team;
    case 4:return a.server!=b.server || a.guild<0 || (a.guild!=b.guild && (a.alliance<0 || a.alliance!=b.alliance));
    case 5:return a.raid<0 || a.raid!=b.raid;
    default:return false;
    }
}
}
