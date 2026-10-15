#include "CysLoginRoleList.h"
#include <climits>
#include <cstdio>
#include <cstring>
#include <stdexcept>

static unsigned passed=0,failed=0;
static void require(bool value) { if(!value) throw std::runtime_error("assertion"); }
template<class F> static void test(const char* name,F f) {
    try { f();++passed;std::printf("PASS %s\n",name); }
    catch(...) { ++failed;std::printf("FAIL %s\n",name); }
}
static pg::LCRetCharList list(unsigned count=3) {
    pg::LCRetCharList value;value.charnum=static_cast<uint8_t>(count);
    for(unsigned i=0;i<count;++i) {
        CysLoginRoleList::Role role;role.guid=200101+i;role.sex=static_cast<int>(i%2);
        role.set_nickname(i==0?u8"Việt中文":i==1?"Second":"Third");
        role.level=static_cast<int>(i+10);role.hair=static_cast<uint8_t>(i+5);
        role.head=static_cast<int16_t>(i+100);role.portrait_id=static_cast<int>(i+20);
        role.new_player_set=static_cast<int>(i);role.equips[18]=1000+static_cast<int>(i);
        role.visuals[18]=static_cast<int16_t>(i+200);role.gems[18]=static_cast<int>(i+300);
        role.exterior_head_id=static_cast<int16_t>(i+400);value.charlist.push_back(role);
    }
    return value;
}
static void rawName(CysLoginRoleList::Role& role,const std::string& bytes) {
    require(bytes.size()<=role.nickname.size());role.nickname.fill(0);
    std::memcpy(role.nickname.data(),bytes.data(),bytes.size());
}
static void rejectPreserving(pg::LCRetCharList bad) {
    CysLoginRoleList store;const auto baseline=list();require(store.assign(baseline));
    const auto* original=store.at(0);
    require(!store.assign(bad));require(store.size()==3 && store.at(0)==original);
    require(store.at(0)->guid==200101 && store.at(0)->nickname_text()==u8"Việt中文");
    require(store.at(2)->equips[18]==1002 && store.findGuid(200103)==2);
}
int main() {
    test("native full appearance IDs and compact replay compatibility",[] {
        auto packet=list(1);auto& role=packet.charlist[0];
        role.hair=0;role.hair_2=20299;role.head=20202;role.head_2=20202;
        CysLoginRoleList store;require(store.assign(packet));
        require(CysLoginRoleList::Hair(*store.at(0))==20299);
        require(CysLoginRoleList::Face(*store.at(0))==20202);
        role.hair_2=0;role.head_2=0;role.hair=5;role.head=100;
        require(CysLoginRoleList::Hair(role)==5 && CysLoginRoleList::Face(role)==100);
        role.hair=0;require(CysLoginRoleList::Hair(role)==0);
    });
    test("empty state and signed index boundaries",[] {
        CysLoginRoleList store;require(store.size()==0 && !store.at(0) && !store.at(-1));
        require(!store.at(INT_MIN) && !store.at(INT_MAX) && store.findGuid(0)==-1);
    });
    test("three slots preserve all appearance and equipment values",[] {
        CysLoginRoleList store;require(store.assign(list()));require(store.size()==3);
        require(store.at(0)->nickname_text()==u8"Việt中文" && store.at(1)->sex==1);
        require(store.at(2)->head==102 && store.at(2)->hair==7 && store.at(2)->portrait_id==22);
        require(store.at(2)->new_player_set==2 && store.at(2)->equips[18]==1002);
        require(store.at(2)->visuals[18]==202 && store.at(2)->gems[18]==302 && store.at(2)->exterior_head_id==402);
        require(!store.at(3) && !store.at(-1) && !store.at(INT_MAX));
    });
    test("assign owns vector and fixed array data",[] {
        CysLoginRoleList store;
        { auto packet=list();require(store.assign(packet));packet.charlist[0].set_nickname("changed");
          packet.charlist[0].guid=9;packet.charlist[0].equips[18]=9;packet.charlist.clear();packet.charlist.shrink_to_fit(); }
        require(store.size()==3 && store.at(0)->guid==200101 && store.at(0)->nickname_text()==u8"Việt中文" && store.at(0)->equips[18]==1000);
    });
    test("zero and duplicate GUID reject atomically",[] {
        auto bad=list();bad.charlist[2].guid=0;rejectPreserving(bad);
        bad=list();bad.charlist[2].guid=bad.charlist[0].guid;rejectPreserving(bad);
    });
    test("count mismatch and fourth slot preserve prior state",[] {
        auto bad=list();bad.charnum=2;rejectPreserving(bad);
        bad=list();bad.charnum=255;rejectPreserving(bad);rejectPreserving(list(4));
    });
    test("unknown race is rejected before replacing prior state",[] {
        auto bad=list();bad.charlist[2].sex=2;rejectPreserving(bad);
        bad.charlist[2].sex=-1;rejectPreserving(bad);
    });
    test("refused list cannot clear good visible roles",[] {
        auto bad=list(0);bad.unknow=1;rejectPreserving(bad);
    });
    test("lookup is by GUID not current index",[] {
        CysLoginRoleList store;auto packet=list();std::swap(packet.charlist[0],packet.charlist[2]);require(store.assign(packet));
        require(store.findGuid(200101)==2 && store.findGuid(200103)==0 && store.findGuid(5)==-1 && store.findGuid(0)==-1);
    });
    test("valid UTF8 one through four byte sequences",[] {
        for(const std::string& name:std::vector<std::string>{"ASCII",u8"Việt",u8"中文",std::string("\xf0\x9f\x98\x80",4),std::string("\xf4\x8f\xbf\xbf",4)}) {
            auto packet=list(1);rawName(packet.charlist[0],name);CysLoginRoleList store;
            require(store.assign(packet) && store.at(0)->nickname_text()==name);
        }
    });
    test("full 30 byte receive field does not need NUL",[] {
        auto packet=list(1);const std::string name(30,'x');rawName(packet.charlist[0],name);CysLoginRoleList store;
        require(store.assign(packet) && store.at(0)->nickname_text()==name);
        const std::string multibyte=std::string(27,'x')+u8"中";rawName(packet.charlist[0],multibyte);
        require(store.assign(packet) && store.at(0)->nickname_text()==multibyte);
    });
    test("invalid UTF8 lead continuation truncation and range preserve old state",[] {
        const std::vector<std::string> badNames={std::string("\x80",1),std::string("\xc0\x80",2),std::string("\xc1\xbf",2),
            std::string("\xc2",1),std::string("\xc2\x41",2),std::string("\xe0\x80\x80",3),std::string("\xe4\xb8",2),
            std::string("\xed\xa0\x80",3),std::string("\xed\xbf\xbf",3),std::string("\xf0\x80\x80\x80",4),
            std::string("\xf4\x90\x80\x80",4),std::string("\xf5\x80\x80\x80",4),std::string("\xff",1),
            std::string(29,'x')+std::string("\xe4",1)};
        for(const auto& name:badNames) { auto bad=list();rawName(bad.charlist[2],name);rejectPreserving(bad); }
    });
    test("empty and ASCII controls rejected atomically",[] {
        for(const std::string& name:std::vector<std::string>{"",std::string("\x01",1),"a\nb",std::string("x\x7f",2)}) {
            auto bad=list();rawName(bad.charlist[2],name);rejectPreserving(bad);
        }
    });
    test("valid replacement removes obsolete GUIDs",[] {
        CysLoginRoleList store;require(store.assign(list()));auto replacement=list(1);replacement.charlist[0].guid=300001;
        require(store.assign(replacement) && store.size()==1 && store.findGuid(200101)==-1 && store.findGuid(300001)==0 && !store.at(1));
    });
    test("empty success and explicit clear release visible records",[] {
        CysLoginRoleList store;require(store.assign(list()) && store.assign(list(0)) && store.size()==0);
        require(store.assign(list()));store.clear();require(store.size()==0 && !store.at(0) && store.findGuid(200101)==-1);
    });
    test("created GUID in middle wins over last slot",[] {
        CysLoginRoleList old,next;require(old.assign(list(2)));
        auto reply=list();std::swap(reply.charlist[0],reply.charlist[1]);
        std::swap(reply.charlist[1],reply.charlist[2]); // [B,C,A]
        require(next.assign(reply));int selected=-9;
        require(next.replacementSelection(old,0,true,selected) && selected==1);
        require(next.at(selected)->guid==200103 && old.at(0)->guid==200101);
    });
    test("created GUID first wins in reversed reply",[] {
        CysLoginRoleList old,next;require(old.assign(list(2)));
        auto reply=list();std::swap(reply.charlist[0],reply.charlist[2]); // [C,B,A]
        require(next.assign(reply));int selected=-9;
        require(next.replacementSelection(old,1,true,selected) && selected==0);
        require(next.at(selected)->guid==200103);
    });
    test("ordinary refresh preserves selected GUID across reorder",[] {
        CysLoginRoleList old,next;require(old.assign(list()));
        auto reply=list();std::swap(reply.charlist[0],reply.charlist[2]);
        require(next.assign(reply));int selected=-9;
        require(next.replacementSelection(old,0,false,selected) && selected==2);
        require(next.at(selected)->guid==old.at(0)->guid);
    });
    test("removed selection falls back to first remaining record",[] {
        CysLoginRoleList old,next;require(old.assign(list()));
        require(next.assign(list(1)));int selected=-9;
        require(next.replacementSelection(old,2,false,selected) && selected==0);
        require(next.replacementSelection(old,INT_MAX,false,selected) && selected==0);
    });
    test("initial empty login differs from successful first creation",[] {
        CysLoginRoleList old,next;int selected=-9;
        require(next.replacementSelection(old,0,false,selected) && selected==-1);
        require(next.assign(list(1)));
        require(next.replacementSelection(old,0,true,selected) && selected==0);
        require(next.replacementSelection(old,0,false,selected) && selected==0);
    });
    test("pending create rejects missing prior identity atomically",[] {
        CysLoginRoleList old,next;require(old.assign(list(2)));
        auto reply=list();reply.charlist[0].guid=500001;
        require(next.assign(reply));int selected=77;
        require(!next.replacementSelection(old,0,true,selected) && selected==77);
        require(old.at(0)->guid==200101 && next.at(0)->guid==500001);
    });
    test("pending create rejects no growth or multiple new roles",[] {
        CysLoginRoleList old,next;require(old.assign(list(2)) && next.assign(list(2)));
        int selected=77;require(!next.replacementSelection(old,0,true,selected) && selected==77);
        old.clear();require(!next.replacementSelection(old,0,true,selected) && selected==77);
    });
    // CYS-REVIEW 18/09: mot nhan vat hong du lieu ngoai hinh KHONG duoc lam hong ca danh sach.
    // Ca that: attrib.model (sex) khong khop face_style/hair_style -> Resolve() false cho rieng o do.
    test("one unresolvable slot of three drops only that slot, both vectors in step",[] {
        CysLoginRoleList store;require(store.assign(list()));
        std::vector<int> appearance{10,11,12};           // dai dien appearances[] song song
        std::vector<bool> keep{true,false,true};          // o giua hong
        require(store.retainWith(keep,appearance));
        require(store.size()==2 && appearance.size()==2);
        // con dung hai nhan vat tot, DUNG thu tu, va ngoai hinh van di theo dung nguoi
        require(store.at(0)->guid==200101 && appearance[0]==10);
        require(store.at(1)->guid==200103 && appearance[1]==12);
        require(store.findGuid(200102)==-1 && !store.at(2));
    });
    test("retainWith refuses mismatched sizes and changes nothing",[] {
        CysLoginRoleList store;require(store.assign(list()));
        std::vector<int> appearance{10,11,12};
        std::vector<bool> shortKeep{true,false};
        require(!store.retainWith(shortKeep,appearance));
        require(store.size()==3 && appearance.size()==3 && store.at(1)->guid==200102);
        std::vector<int> shortParallel{10,11};
        std::vector<bool> keep{true,true,true};
        require(!store.retainWith(keep,shortParallel));
        require(store.size()==3 && shortParallel.size()==2);
    });
    test("every slot unresolvable leaves an empty list, not a stale one",[] {
        CysLoginRoleList store;require(store.assign(list()));
        std::vector<int> appearance{10,11,12};
        std::vector<bool> keep{false,false,false};
        require(store.retainWith(keep,appearance));
        require(store.size()==0 && appearance.empty() && !store.at(0) && store.findGuid(200101)==-1);
    });
    // Ngu nghia TAO nhan vat sau khi loc: o hong bi loc o CA hai lan dang nhap, nen phep kiem
    // "danh sach moi = danh sach cu + dung mot" van dung, va o duoc chon la nhan vat vua tao.
    test("create after filtering still selects the new role by identity",[] {
        CysLoginRoleList previous;                        // lan dang nhap truoc: [A, B(hong)] -> [A]
        { auto reply=list(2);require(previous.assign(reply));
          std::vector<int> appearance{10,11};std::vector<bool> keep{true,false};
          require(previous.retainWith(keep,appearance));require(previous.size()==1); }
        CysLoginRoleList next;                            // sau khi tao C: [A, B(hong), C] -> [A, C]
        { auto reply=list(3);require(next.assign(reply));
          std::vector<int> appearance{10,11,12};std::vector<bool> keep{true,false,true};
          require(next.retainWith(keep,appearance));require(next.size()==2); }
        int selected=77;
        require(next.replacementSelection(previous,0,true,selected));
        require(selected==1 && next.at(selected)->guid==200103);   // C, khong phai A
    });
    test("ordinary refresh keeps the selected identity across filtering",[] {
        CysLoginRoleList previous;require(previous.assign(list()));
        CysLoginRoleList next;require(next.assign(list()));
        std::vector<int> appearance{10,11,12};std::vector<bool> keep{true,false,true};
        require(next.retainWith(keep,appearance));
        int selected=77;
        // dang chon nhan vat thu 3 (200103) truoc khi loc -> sau khi loc no la o 1
        require(next.replacementSelection(previous,2,false,selected) && selected==1);
        require(next.at(selected)->guid==200103);
        // dang chon dung nhan vat bi loc -> roi ve o dau, khong phai chi so rac
        require(next.replacementSelection(previous,1,false,selected) && selected==0);
    });
    std::printf("RESULT passed=%u failed=%u actual_header=1 sockets=0\n",passed,failed);
    return failed?1:0;
}
