#include "CysEquipmentTooltipFormat.h"
#include <cassert>
#include <cstdio>
int main() {
    CysEquipmentTooltip::Cache cache; CysEquipmentTooltip::Snapshot a,b;
    const int id=10102001;
    assert(cache.Remember(1,2,100,id,1ULL<<42,1,{12}));
    assert(cache.Remember(1,2,101,id,1ULL<<42,1,{34}));
    cache.Metadata(1,2,100,7,4,9,{{1,0,3,0}},"Smith A");
    cache.Metadata(1,2,101,3,2,0,{{0,2,0,0}},"Smith B");
    assert(cache.Find(1,2,100,id,a)&&cache.Find(1,2,101,id,b));
    assert(a.values[42]==12&&a.quality==7&&a.gemSlots==4&&a.creator=="Smith A"&&a.gems[2]==3);
    cache.Details(1,2,100,0x73,{{100,50,200,150,1,255}},19,7,5,12,3);
    assert(cache.Find(1,2,100,id,a)&&a.qualifications[2]==200&&a.diaowen==19&&a.advance==5);
    assert(cache.Find(1,2,101,id,b)&&b.diaowen==0&&b.status==0);
    using namespace CysEquipmentTooltip;
    assert(std::string(TitleColour(0))=="#cC8C8C8" && std::string(TitleColour(2))=="#c00CCFF" && std::string(TitleColour(3))=="#cFF53FF");
    const auto spirit=ParseCreator("Smith&W09&SQ119&ZF3");assert(spirit.spirit==9 && spirit.fit==119 && spirit.amplify==3 && spirit.name=="Smith");
    assert(SpiritPercent(1)==1 && SpiritPercent(9)==19 && SpiritPercent(39)==54);
    assert(std::string(AmplifyColour(3))=="#c5bc257" && std::string(AmplifyColour(18))=="#cff8a00");
    const auto cp=ParseCreator("Smith A&SQ119&ZF3");assert(cp.name=="Smith A"&&cp.fit==119&&cp.amplify==3);
    assert(ParseCreator("&SQ009").name.empty());
    assert(ParseCreator("Smith&ZF3&SQ009").amplify==0); // matches server whole-suffix tonumber
    assert(ParseCreator("#Rname\n").name.find('#')==std::string::npos);
    auto r=CalculateBase(a,0,0,117);
    const int ap=CysTooltipTables::AptPercent(100,0);
    assert(r.enhance==228&&r.engrave==11&&r.apt==((117+228+11)*ap+50)/100);
    assert(CalculateBase(a,0,1,117).aptPercent==CysTooltipTables::AptPercent(200,1));
    assert(CalculateBase(a,0,2,100).aptPercent==CysTooltipTables::AptPercent(50,2));
    a.creator="Smith&SQ119&ZF3";a.gems={{50101001,0,50101002,0}};
    std::string formatted=Properties(a,0,{{117,117,0,0,0,0}});
    assert(formatted.find(u8"Cường hóa +9")!=std::string::npos);
    assert(formatted.find(u8"Đã khắc minh")!=std::string::npos);
    assert(formatted.find(u8"Khế hợp 19")!=std::string::npos);
    assert(formatted.find(u8"Ngọc 3:")!=std::string::npos&&formatted.find(u8"Ngọc 2:")==std::string::npos);
    assert(formatted.find("&SQ")==std::string::npos&&Author(a)==u8"Người chế tạo: Smith");
    assert(!Amplifies(1)&&!Amplifies(18)&&!Amplifies(54)&&Amplifies(42)&&AmplifyAdded(12,3)==4);
    assert(Status(a).find(u8"Tẩy luyện: 7")!=std::string::npos);
    a.creator="&SQ119";a.gems={};a.diaowen=0;a.advance=0;a.feature=0;a.enhancement=0;a.status=2;a.qualifications={};
    formatted=Properties(a,0,{{117,117,0,0,0,0}});
    assert(formatted.find(u8"Sức mạnh +12")!=std::string::npos); // QHD values are already final: never multiply again
    assert(b.values[42]==34&&b.quality==3&&b.gemSlots==2&&b.creator=="Smith B"&&b.gems[1]==2);
    assert(!cache.Find(1,2,100,id+1,a));
    assert(!cache.Remember(1,2,100,id,1ULL<<42,0,{}));
    assert(!cache.Find(1,2,100,id,a)); // malformed refresh cannot retain metadata
    assert(cache.Remember(1,2,101,id,0,0,{}));
    assert(cache.Find(1,2,101,id,b)&&b.creator.empty()&&b.quality==0&&b.gems[1]==0);
    cache.ConnectionOpened(2);assert(cache.Find(1,2,101,id,b));
    cache.ConnectionOpened(1);assert(!cache.Find(1,2,101,id,b));
    puts("PASS tooltip identity, independent metadata, sparse gems, malformed update, refresh, reconnect");
}
