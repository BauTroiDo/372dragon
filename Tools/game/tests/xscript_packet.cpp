#include "PgPackets_mission.h"
#include <cassert>
#include <cstdio>
int main() {
    for(unsigned n : {0u,6u,8u,10u,255u}) {
        pg::CGExecuteScript sent;
        sent.m_ScriptID=999261;sent.set_m_szFunName("GmPetChoosePet");
        sent.m_uParamCount=(uint8_t)n;
        for(unsigned i=0;i<n;++i) sent.m_aParam.push_back(i==0?-1:8888-(int)i);
        pg::Writer w;sent.write(w);
        const auto& bytes=w.buffer();
        pg::Reader r(bytes.data(),bytes.size());pg::CGExecuteScript got;
        assert(got.read(r)&&got.m_ScriptID==sent.m_ScriptID&&got.m_szFunName==sent.m_szFunName);
        assert(got.m_uParamCount==n&&got.m_aParam==sent.m_aParam);
        if(n>6) {
            pg::Reader truncated(bytes.data(),bytes.size()-4);pg::CGExecuteScript bad;
            assert(!bad.read(truncated));
        }
    }
    puts("PASS CY XSCRIPT signed parameters 0/6/8/10/255 and truncated tail rejection");
}
