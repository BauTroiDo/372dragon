#pragma once
#include "CysEquipmentTooltipData.h"
#include "CysEquipmentTooltipTables.h"
#include "CysEnhanceBonuses.h"
#include <cstdlib>

namespace CysEquipmentTooltip {
struct CreatorInfo {std::string name; int fit=0, amplify=0, spirit=0;};
inline CreatorInfo ParseCreator(const std::string& source) {
    CreatorInfo out; out.name=source;
    const auto w=out.name.find("&W");
    if(w!=std::string::npos && w+4<=out.name.size() &&
       out.name.substr(w+2,2).find_first_not_of("0123456789")==std::string::npos &&
       (w+4==out.name.size()||out.name[w+4]=='&')) {
        out.spirit=std::atoi(out.name.substr(w+2,2).c_str());out.name.erase(w,4);
    }
    // item.lua:set_qihedu writes exactly three decimal digits. This is NOT hand-made ShengLing.
    const auto sq=out.name.find("&SQ");
    if(sq!=std::string::npos && sq+6<=out.name.size()) {
        const auto digits=out.name.substr(sq+3,3);
        if(digits.find_first_not_of("0123456789")==std::string::npos &&
           (sq+6==out.name.size() || out.name[sq+6]=='&')) {
            out.fit=std::atoi(digits.c_str());out.name.erase(sq,6);
        }
    }
    // human_attrib:get_zengfu_level parses the entire suffix, not just a digit prefix.
    const auto zf=source.find("&ZF");
    if(zf!=std::string::npos) {
        const auto suffix=source.substr(zf+3);
        if(!suffix.empty() && suffix.size()<=6 && suffix.find_first_not_of("0123456789")==std::string::npos)
            out.amplify=std::atoi(suffix.c_str());
        auto p=out.name.find("&ZF");if(p!=std::string::npos)out.name.erase(p);
    }
    // No formatting/control sequences from a character's name enter CEGUI markup.
    for(char& c:out.name)if(c=='#'||static_cast<unsigned char>(c)<32)c=' ';
    return out;
}
inline void Line(std::string& text,const std::string& value) {if(value.empty())return;if(!text.empty())text+='\n';text+=value;}
// GL SystemColour 2000..2003; a star count is unrelated to this table quality.
inline const char* TitleColour(int quality) {
    static const char* colours[]={"#cC8C8C8","#c00FF00","#c00CCFF","#cFF53FF"};
    return colours[quality<0?0:quality>3?3:quality];
}
inline const char* AmplifyColour(int level) {
    return level>=18?"#cff8a00":level>=15?"#cfff263":level>=10?"#c00ccff":"#c5bc257";
}
inline int SpiritPercent(int raw) {
    static const int values[2][10]={{0,1,2,4,6,8,10,13,16,19},{25,28,31,34,37,40,43,46,50,54}};
    return raw>=60?60:values[raw>19?1:0][raw%10];
}
inline int AmplifyPercent(int level) {
    static const int values[]={0,10,20,30,40,50,60,70,80,90,100,120,150,190,240,300,420,600,840,1140,1500};
    return values[level<=0?0:level>=20?20:level];
}
inline int AmplifyAdded(int value,int level) {return int((int64_t(value)*AmplifyPercent(level)+50)/100);}
inline bool Amplifies(unsigned bit) {
    // Exact excluded CY IA values from human_attrib:is_zengfu_blocked_attr.
    return bit!=1 && bit!=7 && bit!=10 && bit!=13 && bit!=16 && bit!=18 && !(bit>=54&&bit<=57);
}
struct BaseValue {int base=0,enhance=0,engrave=0,apt=0,amplify=0,aptPercent=0;int Total()const{return base+enhance+engrave+apt+amplify;}};
inline BaseValue CalculateBase(const Snapshot& s,int slot,unsigned index,int value) {
    BaseValue r;r.base=value;
    const auto e=CysEnhanceBonuses::Find(slot,s.enhancement);
    r.enhance=e?int(int64_t(value)*e->percent[index]/100):0;
    r.engrave=(s.status&0x40)?value/10:0;
    // Server qualifications wire order is attack P, defence P, attack M, defence M, hit, miss.
    static const unsigned wire[]={0,2,1,3,4,5};
    r.aptPercent=CysTooltipTables::AptPercent(s.qualifications[wire[index]],index);
    r.apt=int((int64_t(value+r.enhance+r.engrave)*r.aptPercent+50)/100);
    r.amplify=AmplifyAdded(value+r.enhance+r.engrave+r.apt,ParseCreator(s.creator).amplify);
    return r;
}
inline std::string Properties(const Snapshot& s,int slot,const std::array<int,6>& baseValues) {
    const auto meta=ParseCreator(s.creator);std::string text;
    if(s.enhancement)Line(text,u8"#c5bc257Cường hóa +"+std::to_string(s.enhancement)+"#W");
    if(s.status&0x40)Line(text,u8"#c5bc257Đã khắc minh · cơ bản +10%#W");
    if(meta.fit>0)Line(text,u8"#c00ccffThông linh · Khế hợp "+std::to_string(meta.fit%100)+"#W");
    if(meta.spirit>0) {
        const std::string stage=meta.spirit>=60?u8"Thiên Đạo":meta.spirit>19?u8"Vương Quyền":u8"Chí Tôn";
        const std::string progress=meta.spirit>=60?"":u8" · Thăng Linh "+std::to_string(meta.spirit%10)+"/9";
        Line(text,"#c00ccff"+stage+progress+u8" · Thuộc tính +"+std::to_string(SpiritPercent(meta.spirit))+"%#W");
    }
    if(meta.amplify>0)Line(text,std::string(AmplifyColour(meta.amplify))+u8"Tăng phúc +"+std::to_string(meta.amplify)+"#W");
    if(s.reshuffles)Line(text,u8"Tẩy luyện: "+std::to_string(s.reshuffles)+u8" lần");
    static const char* labels[]={u8"Công vật lý",u8"Công pháp thuật",u8"Phòng vật lý",u8"Phòng pháp thuật",u8"Chính xác",u8"Né tránh"};
    for(unsigned i=0;i<6;++i) {
        int v=baseValues[i];
        if(s.equipType==1 && i<2)v=32+(int(s.darkLevel)/10-1)*85; // human_attrib Anqi base
        if(v<=0)continue;
        const auto r=CalculateBase(s,slot,i,v);
        Line(text,std::string(labels[i])+" +"+std::to_string(r.Total()));
        std::string detail;
        if(r.enhance)detail+=u8"Cường hóa +"+std::to_string(r.enhance);
        if(r.engrave){if(!detail.empty())detail+="; ";detail+=u8"khắc minh +"+std::to_string(r.engrave);}
        if(r.aptPercent){if(!detail.empty())detail+="; ";detail+=u8"tư chất "+std::to_string(r.aptPercent)+"% (+"+std::to_string(r.apt)+")";}
        if(r.amplify){if(!detail.empty())detail+="; ";detail+=u8"tăng phúc +"+std::to_string(r.amplify);}
        if(!detail.empty())Line(text,"#c5bc257"+detail+"#W");
    }
    if(s.itemIndex && !(s.status&2))Line(text,u8"#cfff263Chưa giám định thuộc tính#W");
    else {
        // Values already include QHD upgrades on the server; do not apply QHD again.
        for(unsigned bit=0;bit<s.values.size();++bit)if((s.mask&(uint64_t(1)<<bit))&&s.values[bit]) {
            const int spirit=Amplifies(bit)?int(int64_t(s.values[bit])*SpiritPercent(meta.spirit)/100):0;
            Snapshot one;one.mask=uint64_t(1)<<bit;one.values[bit]=s.values[bit];std::string attr;AppendAttributes(attr,one);
            if(spirit)attr+=u8" #c00ccff(Thăng Linh +"+std::to_string(spirit)+")";
            const int extra=Amplifies(bit)?AmplifyAdded(s.values[bit]+spirit,meta.amplify):0;
            if(extra)attr+=u8" #H(tăng phúc +"+std::to_string(extra)+(IsPercent(bit)?"%":"")+")#W";
            Line(text,"#cFFCC00"+attr+"#W");
        }
    }
    for(unsigned slotIndex=0;slotIndex<s.gems.size();++slotIndex) {
        if(s.gems[slotIndex]<=0)continue;
        const auto gem=CysTooltipTables::Gem(s.gems[slotIndex]);
        Line(text,u8"#cB3DB35Ngọc "+std::to_string(slotIndex+1)+": "+(gem?gem->name:std::to_string(s.gems[slotIndex]))+"#W");
        if(gem)for(const auto& e:gem->attrs)if(e.value>0){Snapshot one;one.mask=uint64_t(1)<<e.bit;one.values[e.bit]=e.value;std::string attr;AppendAttributes(attr,one);Line(text,attr);}
    }
    if(s.diaowen) {
        const auto dw=CysTooltipTables::Diaowen(s.diaowen);
        Line(text,"#c00ccff"+std::string(dw?dw->name:u8"Điêu văn chưa có trong bảng dữ liệu")+"#W");
        if(dw)for(const auto& e:dw->attrs)if(e.value>0) {
            int v=e.value;auto rank=CysTooltipTables::Advance(s.advance);
            if(rank){if(e.bit>=42&&e.bit<=48)v+=rank->one;else if((e.bit>=54&&e.bit<=57)||e.bit==6||e.bit==9||e.bit==12||e.bit==15||e.bit==7||e.bit==10||e.bit==13||e.bit==16)v+=rank->element;}
            Snapshot one;one.mask=uint64_t(1)<<e.bit;one.values[e.bit]=v;std::string attr;AppendAttributes(attr,one);Line(text,attr);
        }
        if(s.advance)Line(text,u8"Tinh khắc: "+std::to_string(s.advance)+u8" · Điểm: "+std::to_string(s.advanceExp));
        if(s.feature)Line(text,u8"Hiệu ứng điêu văn: "+std::to_string(s.feature));
    }
    return text;
}
inline std::string Author(const Snapshot& s) {const auto m=ParseCreator(s.creator);return m.name.empty()?"":u8"Người chế tạo: "+m.name;}
inline std::string Status(const Snapshot& s) {
    if(!s.itemIndex)return "";
    std::string text=(s.status&1)?u8"Đã khóa":u8"Chưa khóa";
    if(s.status&0x40)text+=u8" · Đã khắc minh";
    if(s.reshuffles)text+=u8" · Tẩy luyện: "+std::to_string(s.reshuffles);
    return text;
}
}
