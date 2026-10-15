#include "../../Src/Client/WXClient/Network/CysUiCommandParams.h"
#include "../../Src/Client/CEGUISystem/CysUiCommandRoutes.h"
#include <vector>
#include <fstream>
#include <iterator>
#include <iostream>
#include <limits>
struct Packet {
    unsigned char m_Param_m_IntCount=0,m_Param_m_StrCount=0;
    std::vector<int32_t> m_Param_m_aIntValue;
    std::vector<uint16_t> m_Param_m_aStrOffset;
    std::string m_Param_m_aStrValue;
};
struct Params {
    unsigned char m_IntCount,m_StrCount;
    int32_t m_aIntValue[16]; int16_t m_aStrOffset[16]; char m_aStrValue[512];
    void CleanUp(){std::memset(this,0,sizeof(*this));}
};
int checks=0,errors=0;
void Check(bool ok,const char* what){++checks;if(!ok){++errors;std::cerr<<"FAIL "<<what<<"\n";}}
bool Copy(const Packet& p){Params out;out.CleanUp();out.m_IntCount=7;const auto before=out;bool ok=CysUiCommandParams::Copy(p,out);if(!ok)Check(std::memcmp(&out,&before,sizeof(out))==0,"reject keeps destination unchanged");return ok;}
int main(int argc,char** argv){
    Packet p; Check(Copy(p),"empty");
    p.m_Param_m_IntCount=3;p.m_Param_m_aIntValue={-1,INT32_MIN,INT32_MAX};
    p.m_Param_m_StrCount=3;p.m_Param_m_aStrValue=std::string("abc\0\0xy\0",8);p.m_Param_m_aStrOffset={3,4,7};
    Params out;Check(CysUiCommandParams::Copy(p,out),"three strings including empty");
    Check(out.m_IntCount==3&&out.m_StrCount==3&&out.m_aIntValue[1]==INT32_MIN&&out.m_aIntValue[2]==INT32_MAX,"signed integer fidelity");
    Check(out.m_aStrOffset[1]==4&&std::memcmp(out.m_aStrValue,p.m_Param_m_aStrValue.data(),8)==0,"string offsets fidelity");
    auto q=p;q.m_Param_m_aStrOffset={3,3,7};Check(!Copy(q),"repeated offset");
    q=p;q.m_Param_m_aStrOffset={3,2,7};Check(!Copy(q),"decreasing offset");
    q=p;q.m_Param_m_aStrOffset[2]=65535;Check(!Copy(q),"offset outside payload");
    q=p;q.m_Param_m_aStrValue[7]='x';Check(!Copy(q),"unterminated string");
    q=p;q.m_Param_m_aStrValue[1]=0;Check(!Copy(q),"embedded premature NUL");
    q=p;q.m_Param_m_aStrValue+='x';Check(!Copy(q),"trailing bytes");
    q=p;q.m_Param_m_aIntValue.pop_back();Check(!Copy(q),"integer count mismatch");
    q=p;q.m_Param_m_StrCount=2;Check(!Copy(q),"string count mismatch");
    q=Packet{};q.m_Param_m_IntCount=16;q.m_Param_m_aIntValue.resize(16);Check(!Copy(q),"16 integers rejected by wire contract");
    q=Packet{};q.m_Param_m_IntCount=15;q.m_Param_m_aIntValue.resize(15);Check(Copy(q),"15 integers");
    q=Packet{};q.m_Param_m_StrCount=1;q.m_Param_m_aStrValue=std::string(511,'a')+'\0';q.m_Param_m_aStrOffset={511};Check(Copy(q),"512 byte payload");
    q.m_Param_m_aStrValue.insert(0,"a");q.m_Param_m_aStrOffset={512};Check(!Copy(q),"513 byte payload rejected");
    CysUiCommandRoutes::Table routes;
    routes.Load("INT\tINT\tINT\nINT\tINT\tINT\n0\t23\t334\n1\t23\t122\n2\t24\t19\n");
    Check(routes.Allows(23,334)&&routes.Allows(23,122)&&!routes.Allows(23,19),"multiple route targets");
    Check(!routes.Allows(999,122),"unmapped command does not broadcast");
    Check(!routes.Allows(24,122)&&routes.Allows(24,19),"commands remain separate");
    if(argc!=2){std::cerr<<"expected actual UICommandIndex.txt\n";return 2;}
    std::ifstream f(argv[1],std::ios::binary);std::string bytes((std::istreambuf_iterator<char>(f)),{});
    routes.Load(bytes);Check(routes.Size()>3000,"actual CY routing table");
    Check(routes.Allows(20100716,124)&&!routes.Allows(20100716,122),"CY AcceptBox route");
    Check(routes.Allows(19810313,137)&&routes.Allows(19810313,122),"CY repair plus bag route");
    bool rejected=false;try{routes.Load(bytes.substr(0,bytes.size()-1));}catch(const std::exception&){rejected=true;}
    Check(rejected&&routes.Allows(20100716,124),"truncated reload rejected atomically");
    std::cout<<"checks="<<checks<<" errors="<<errors<<"\n";return errors?1:0;
}
