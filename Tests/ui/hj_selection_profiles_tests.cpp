#include "CysCreateRoleAppearance.h"
#include "CysHjProbeData.h"
#include <fstream>
#include <iostream>
#include <iterator>
#include <stdexcept>
using namespace CysCreateRoleAppearance;
static std::string context;
#define check(pass) do { if(!(pass)) throw std::runtime_error("HJ selection assertion line "+std::to_string(__LINE__)+" "+context); } while(0)
static Catalog load(const std::string& stage) {
    Catalog c;std::string error;
    for(int k=0;k<TableCount;++k) {
        auto kind=static_cast<TableKind>(k);
        context=stage+" "+ResourceName(kind);
        std::ifstream f(stage+"/Overlay/Post/ConfigFolder/"+ResourceName(kind),std::ios::binary);
        check(bool(f));std::string raw((std::istreambuf_iterator<char>(f)),std::istreambuf_iterator<char>());
        check(c.Load(kind,raw.data(),raw.size(),error));
    }
    check(c.Ready());return c;
}
int main(int argc,char** argv) {
    try {
        check(argc==3);Catalog baseline=load(argv[1]),current=load(argv[2]);unsigned cases=0;
        for(int sex=0;sex<2;++sex) {
            for(auto kind:{Face,Hair,Portrait,Outfit}) {
                context="creation options sex="+std::to_string(sex)+" kind="+std::to_string(kind);
                auto a=baseline.Options(kind,sex),b=current.Options(kind,sex);check(a.size()==b.size());
                for(size_t i=0;i<a.size();++i)check(a[i].id==b[i].id&&a[i].flags==b[i].flags);
            }
            for(const auto& row:CysHjProbeData::rows) {
                context="sex="+std::to_string(sex)+" cat="+std::to_string(row.cat)+" visual="+std::to_string(row.visual[sex]);
                Recipe recipe;std::string error,image;
                if(row.cat==2) {
                    check(current.Resolve(sex,row.visual[sex],sex?5:1,0,recipe,error));
                    check(!current.Resolve(1-sex,row.visual[sex],sex?1:5,0,recipe,error));++cases;
                } else if(row.cat==3) {
                    check(current.Resolve(sex,sex?100:1,row.visual[sex],0,recipe,error));
                    check(!current.Resolve(1-sex,sex?1:100,row.visual[sex],0,recipe,error));++cases;
                } else if(row.cat==4) {
                    check(current.PortraitImage(sex,row.visual[sex],image));
                    check(image.find("set:CysHJ")==0);
                    check(!current.PortraitImage(1-sex,row.visual[sex],image));++cases;
                }
            }
        }
        // Final HJ native portrait IDs exercised by the persisted live fixture.
        std::string image;check(current.PortraitImage(1,20080,image));
        check(current.PortraitImage(0,20079,image));
        check(image.find("set:CysHJ")==0);
        std::cout<<"PASS "<<cases<<" HJ face/hair/portrait selection cases, opposite-sex rejection and unchanged creation options\n";
        return 0;
    } catch(const std::exception& e){std::cerr<<e.what()<<"\n";return 1;}
}
