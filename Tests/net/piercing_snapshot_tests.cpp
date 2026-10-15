#include "../../Src/Client/WXClient/Network/CysPiercingData.h"
#include <cassert>
#include <cstdio>
int main(){
 assert(CysPiercingData::Damage(-100630)==630);assert(CysPiercingData::Damage(-100000)==0);
 assert(CysPiercingData::Damage(-99999)==0);assert(CysPiercingData::Damage(210)==0);
 assert(CysPiercingData::Damage((-2147483647-1))==2147383648);
 CysPiercingData::Snapshot s;uint32_t v=77;
 assert(!s.Query(false,v)&&v==77);assert(!s.Apply(601,999));assert(!s.Apply(604,999));
 assert(s.Apply(602,42)&&s.Query(false,v)&&v==42);assert(!s.Query(true,v));
 assert(s.Apply(603,0)&&s.Query(true,v)&&v==0);assert(!s.Apply(602,42));
 assert(s.Apply(602,0)&&s.Query(false,v)&&v==0);s.Clear();assert(!s.Query(false,v)&&!s.Query(true,v));
 puts("PASS piercing snapshot boundaries, partial update, zero, duplicate, new session");
}
