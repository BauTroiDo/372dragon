// CY equipment instance data and real skill-operation hosts. Main thread only.
#include "StdAfx.h"
#include "CysHost_EquipmentSkills.h"
#include "LuaPlus.h"
#include "../WXClient/Network/CysModernGame.h"
#include "../WXClient/Network/CysModernHandlers.h"
#include "../WXClient/Network/CysSkillNet.h"
#include "../WXClient/Script/GMScriptSystem.h"
#include "../WXClient/DataPool/GMDataPool.h"
#include "../WXClient/DataPool/GMDP_Struct_Pet.h"
#include "../WXClient/Object/Item/Obj_Item.h"
#include "../WXClient/Object/ObjectManager.h"
#include "../WXClient/Object/Character/Obj_PlayerMySelf.h"
#include "../WXClient/DBC/GMDataBase.h"
#include "../WXClient/Event/GMEventSystem.h"
#include "PgPackets_misc.h"
#include "PgPackets_mission.h"
#include "PgPackets_core.h"
#include "PgPackets_item.h"
#include "../WXClient/Script/CysCheckedScriptLua.h"
#include "TDUtil.h"
#include "TDDBC_Struct.h"
#include <map>
#include <memory>
#include <array>
#include <string>
#include <cstring>
#include <cmath>
namespace CysEquipmentSkills {
namespace {
struct Instance {
    int id=0,type=0,level=0,grow=0,life=0,compound=0,slots=0;
    unsigned exp=0;
    std::string creator;
    std::array<int,3> skills{{-1,-1,-1}};
    std::array<int,10> attrs{};
};
struct Pending { uint64_t guid=0; int id=0; bool applying=false; std::array<int,3> skills{{-1,-1,-1}}; };
std::map<uint64_t,Instance> instances;
Pending pendingKfs,pendingDark;
unsigned rlLearned=0;
bool rlAsked=false;
int minorUnlocked=-1; // unknown until GCMinorPasswd; never permit on a missing reply
bool minorAsked=false;
const char* probeShot=nullptr;
DWORD minorAskedAt=0;
void AskMinor() {
    if(!CysModernGame::IsInWorld() || (minorAsked && GetTickCount()-minorAskedAt<5000))return;
    std::unique_ptr<pg::CGMinorPasswd> p(new pg::CGMinorPasswd);p->flag=1;
    minorAsked=CysModernGame::SendModern(std::move(p));minorAskedAt=GetTickCount();
}
uint64_t Key(unsigned world,unsigned server,unsigned serial) {
    return serial?((uint64_t(world)<<40)|(uint64_t(server)<<32)|serial):0;
}
uint64_t Key(CObject_Item* item) {
    if(!item)return 0;
    USHORT w=0,s=0;UINT id=0;item->GetGUID(w,s,id);return Key(w,s,id);
}
CObject_Item* Item(int slot,bool equipped=false) {
    auto pool=CDataPool::GetMe();if(!pool || slot<0 || slot>254)return nullptr;
    return static_cast<CObject_Item*>(equipped?pool->UserEquip_GetItem((HUMAN_EQUIP)slot):pool->UserBag_GetItem(slot));
}
const Instance* Find(CObject_Item* item,int kind) {
    if(!item)return nullptr;
    auto found=instances.find(Key(item));
    if(found==instances.end() || found->second.id!=item->GetIdTable()) {
        if(item->GetTypeOwner()==tObject_Item::IO_MYSELF_PACKET)RequestBagDetails(item->GetPosIndex());
        return nullptr;
    }
    if(kind && found->second.type!=kind)return nullptr;
    return &found->second;
}
DBC::DBCFile* Table(const char* name,int fields) {
    static std::map<std::string,std::unique_ptr<DBC::DBCFile>> tables;
    auto found=tables.find(name);
    if(found==tables.end()) {
        std::unique_ptr<DBC::DBCFile> t(new DBC::DBCFile(0));
        if(!CDataBase::Util_OpenDBCFromTxt(name,t.get()) || (fields && (int)t->GetFieldsNum()!=fields)) t.reset();
        found=tables.emplace(name,std::move(t)).first;
    }
    return found->second.get();
}
int Row(DBC::DBCFile* t,int id) {
    if(t)for(int i=0;i<(int)t->GetRecordsNum();++i)if(t->Search_Posistion(i,0)->iValue==id)return i;
    return -1;
}
int Number(DBC::DBCFile* t,int row,int col,int absent=-1) {
    return t && row>=0 && col>=0 && col<(int)t->GetFieldsNum()?t->Search_Posistion(row,col)->iValue:absent;
}
std::string DisplayText(const char* p) {
    if(!p || !*p)return "";
    std::string source(p);
    if(MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,source.data(),(int)source.size(),nullptr,0)>0)return source;
    // Some untouched CY string pools are still GBK; Lua/CEGUI expects UTF-8.
    const int count=MultiByteToWideChar(936,0,source.data(),(int)source.size(),nullptr,0);
    if(count<=0)return source;
    std::wstring wide((size_t)count,L'\0');
    MultiByteToWideChar(936,0,source.data(),(int)source.size(),&wide[0],count);
    const int bytes=WideCharToMultiByte(CP_UTF8,0,wide.data(),count,nullptr,0,nullptr,nullptr);
    if(bytes<=0)return source;
    std::string out((size_t)bytes,'\0');
    WideCharToMultiByte(CP_UTF8,0,wide.data(),count,&out[0],bytes,nullptr,nullptr);
    return out;
}
const _DBC_SKILL_DATA* SkillTemplate(int id) {
    DBC_DEFINEHANDLE(s_pSkillDBC,DBC_SKILL_DATA);
    return s_pSkillDBC?(const _DBC_SKILL_DATA*)s_pSkillDBC->Search_Index_EQU(id):nullptr;
}
std::string Text(DBC::DBCFile* t,int row,int col) {
    if(!t || row<0 || col<0 || col>=(int)t->GetFieldsNum())return "";
    return DisplayText(t->Search_Posistion(row,col)->pString);
}
int Arg(LuaPlus::LuaStack& a,int i,int fallback=-1) { return a[i].IsNumber()?a[i].GetInteger():fallback; }
int Push(LuaPlus::LuaState* s,int n){s->PushInteger(n);return 1;}
int CheckEquipmentProtection(LuaPlus::LuaState* s) {
    if(!CysModernGame::IsInWorld())return Push(s,0);
    if(minorUnlocked<0)AskMinor();
    if(minorUnlocked!=1 && CEventSystem::GetMe()){
        CEventSystem::GetMe()->PushEventByName("NEW_DEBUGMESSAGE",{minorUnlocked<0?
            u8"Đang kiểm tra khóa bảo vệ. Vui lòng mở lại chức năng sau khi nhận phản hồi.":
            u8"Cần mở khóa mật khẩu cấp hai trước khi thao tác trang bị."});
        if(minorUnlocked==0)AskMinor();
    }
    return Push(s,minorUnlocked==1?1:0);
}
int IsKfs(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);return Push(s,Find(Item(Arg(a,2)),18)?1:0);}
int IsDark(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);return Push(s,Find(Item(Arg(a,2)),17)?1:0);}
int SkillCount(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);auto p=Find(Item(Arg(a,2)),18);int n=0;if(p)for(int id:p->skills)if(id>0)++n;return Push(s,n);}
int Skill(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);auto p=Find(Item(18,true),18);int i=Arg(a,2);return Push(s,p&&i>=0&&i<3?p->skills[i]:-1);}
int BagSkill(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);auto p=Find(Item(Arg(a,2)),18);int i=Arg(a,3);return Push(s,p&&i>=0&&i<3?p->skills[i]:-1);}
int SkillUp(LuaPlus::LuaState* s,int col){LuaPlus::LuaStack a(s);auto p=Find(Item(Arg(a,2)),18);int i=Arg(a,3);auto t=Table("KFSSkillLevelup.txt",5);int row=p&&i>=0&&i<3?Row(t,p->skills[i]):-1;return Push(s,Number(t,row,col));}
int SkillUpId(LuaPlus::LuaState* s){return SkillUp(s,1);}
int SkillUpItem(LuaPlus::LuaState* s){return SkillUp(s,2);}
int SkillUpMoney(LuaPlus::LuaState* s){return SkillUp(s,3);}
int KfsData(LuaPlus::LuaState* s,bool bag) {
    LuaPlus::LuaStack a(s);auto item=Item(bag?Arg(a,2):18,!bag);auto p=Find(item,18);
    int keyArg=bag?3:2;if(!p || !a[keyArg].IsString())return 0;
    std::string k=a[keyArg].GetString();
    if(k=="NAME"){s->PushString(item->GetName()?item->GetName():"");return 1;}
    if(k=="NEEDLEVEL")return Push(s,item->GetNeedLevel());
    if(k=="LEVEL")return Push(s,p->level);
    if(k=="EXP")return Push(s,p->exp);
    if(k=="LIFE")return Push(s,p->life);
    if(k=="GROW" || k=="GROWRATE" || k=="GROW_RATE")return Push(s,p->grow);
    if(k=="EXTRALEVEL" || k=="COMPOUNDLEVEL" || k=="COMPOUND_LEVEL")return Push(s,p->compound);
    if(k=="SLOT" || k=="SLOTNUM" || k=="EXATTRNUM")return Push(s,p->slots);
    auto base=Table("KFSBase.txt",35);int row=Row(base,p->id);
    if(k=="ATTACT")return Push(s,Number(base,row,1));
    if(k=="MAXLIFE")return Push(s,Number(base,row,9));
    if(k=="Grade") {int grade=0;for(int i=3;i<=7;++i)if(p->grow>=Number(base,row,i,2147483647))++grade;return Push(s,(std::min)(4,grade));}
    if(k=="NEEDEXP"){auto t=Table("KFSLevelupExp.txt",2);return Push(s,Number(t,Row(t,p->level),1));}
    return 0;
}
int SelfData(LuaPlus::LuaState* s){return KfsData(s,false);}
int BagData(LuaPlus::LuaState* s){return KfsData(s,true);}
// Use the same cumulative table and rounding as human_attrib:kfs_base_effect_flush.
int BaseValue(const Instance* p,int attribute,bool fixed) {
    if(!p||attribute<0||attribute>=5||p->level<0||p->level>120)return 0;
    const int group=p->id-10156001;if(group<0||group>=5)return 0;
    auto t=Table("KFSAttrLevelUp.txt",26);int col=1+group*5+attribute,total=0;
    for(int lv=0;lv<=p->level;++lv){int row=Row(t,lv);if(row<0)return 0;total+=Number(t,row,col,0);}
    if(fixed){if(Number(t,Row(t,1),col,0)==1)total=(int)std::ceil(total*(p->grow+850)/1000.0);total=(int)std::ceil(total*p->grow/1000.0);}
    return total;
}
int SelfBase(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);auto p=Find(Item(18,true),18);if(!p)return 0;return Push(s,BaseValue(p,Arg(a,2),false));}
int SelfFixedBase(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);auto p=Find(Item(18,true),18);if(!p)return 0;return Push(s,BaseValue(p,Arg(a,2),true));}
int AttrId(const Instance* p,int slot){return p&&slot>=0&&slot<p->slots&&slot<10?p->attrs[slot]:0;}
int AttrDescription(LuaPlus::LuaState* s,const Instance* p,int slot,bool fixed){
    auto t=Table("KFSAttrEx.txt",70);int row=Row(t,AttrId(p,slot));if(!p||row<0)return 0;
    std::string name=Text(t,row,1);int value=0;
    // One extended property selects one nonzero attribute column, after the six metadata fields.
    for(int c=6;c<70;++c)if(Number(t,row,c,0)>0){value=Number(t,row,c,0);break;}
    const double divisor[]={1,1,1.902857142857143,2.697297297297297,3.375634517766497,3.967142857142857,4.435555555555556,4.8176};
    if(fixed){int level=p->compound;value=level>=1&&level<=7?(int)std::ceil(value*p->grow/1000.0*level/divisor[level]):0;}
    s->PushString(name.c_str());s->PushInteger(value);return 2;
}
int SelfAttr(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);return AttrDescription(s,Find(Item(18,true),18),Arg(a,2),true);}
int BagAttr(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);return AttrDescription(s,Find(Item(Arg(a,2)),18),Arg(a,3),false);}
int AttrCount(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);auto p=Find(Item(Arg(a,2)),18);int count=0;if(p)for(int i=0;i<p->slots&&i<10;++i)if(p->attrs[i]>0)++count;return Push(s,count);}
int AttrCost(LuaPlus::LuaState* s,int col){LuaPlus::LuaStack a(s);auto p=Find(Item(Arg(a,2)),18);auto t=Table("KFSAttrEx.txt",70);return Push(s,Number(t,Row(t,AttrId(p,Arg(a,3))),col,0));}
int AttrUpItem(LuaPlus::LuaState* s){return AttrCost(s,3);}
int AttrUpMoney(LuaPlus::LuaState* s){return AttrCost(s,4);}
int SlotMoney(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);auto p=Find(Item(Arg(a,2)),18);auto t=Table("KFSSlot.txt",0);return Push(s,p?Number(t,Row(t,p->compound-1),3,0):0);}
int IsLw(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);return Push(s,Find(Item(Arg(a,2)),19)?1:0);}
bool LwIds(const Instance* p,std::array<int,3>& ids) {
    if(!p)return false;ids={{0,0,0}};
    auto at=p->creator.find("&LW");if(at==std::string::npos)return true;
    if(at+11>p->creator.size())return false;
    const char* q=p->creator.c_str()+at+3;for(int i=0;i<8;++i)if(q[i]<'0'||q[i]>'9')return false;
    int hp=(q[0]-'0')*10+q[1]-'0',r=q[2]-'0',rl=(q[3]-'0')*10+q[4]-'0';
    int b=q[5]-'0',bl=(q[6]-'0')*10+q[7]-'0';
    if(hp>10||r>4||rl>10||b>4||bl>10||(r==0)!=(rl==0)||(b==0)!=(bl==0))return false;
    const int resist[]={0,21,31,41,51},buff[]={0,11,61,71,81};
    ids={{hp,r?resist[r]+rl-1:0,b?buff[b]+bl-1:0}};return true;
}
int LwData(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);std::array<int,3> ids;
    if(!a[3].IsString()||!LwIds(Find(Item(Arg(a,2)),19),ids))return 0;
    std::string key=a[3].GetString();
    if(key=="HP")return Push(s,ids[0]);if(key=="RESIST")return Push(s,ids[1]);if(key=="BUFF")return Push(s,ids[2]);return 0;
}
int LwAttrInfo(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);std::array<int,3> ids;int id=Arg(a,3);
    if(!a[4].IsString()||!LwIds(Find(Item(Arg(a,2)),19),ids))return 0;
    if(id<=0||(ids[0]!=id&&ids[1]!=id&&ids[2]!=id))return 0;
    std::string key=a[4].GetString();int col=key=="LEVELUPTO"?8:key=="LEVELUPMONEY"?11:key=="LEVELUPITEMNUM"?10:-1;
    auto t=Table("LongWenAddAttr.txt",21);return Push(s,Number(t,Row(t,id),col));
}
int LwOperate(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);int op=Arg(a,2),pos=Arg(a,3),select=Arg(a,4,0);
    if(!CysModernGame::IsInWorld()||!Find(Item(pos),19)||op<4||op>9)return Push(s,0);
    std::unique_ptr<pg::CGExecuteScript> p(new pg::CGExecuteScript);
    p->m_ScriptID=809273;p->set_m_szFunName("Lw_Op_Do");p->m_uParamCount=3;p->m_aParam={op,pos,select};
    return Push(s,CysModernGame::SendModern(std::move(p))?1:0);
}
bool RlState(const Instance* p,int& star,int& group) {
    if(!p)return false;auto at=p->creator.find("&LP");
    if(at==std::string::npos||at+23>p->creator.size())return false;
    star=p->creator[at+3]-'0';char ch=p->creator[at+22];group=ch=='0'?0:ch-'A'+1;
    return star>=1&&star<=9&&(group==0||Row(Table("RSSkill.txt",23),group)>=0);
}
void AskRl() {
    if(rlAsked||!CysModernGame::IsInWorld())return;
    std::unique_ptr<pg::CGExecuteScript> p(new pg::CGExecuteScript);
    p->m_ScriptID=880001;p->set_m_szFunName("RL_QuerySkills");p->m_uParamCount=0;
    rlAsked=CysModernGame::SendModern(std::move(p));
}
int IsRl(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);return Push(s,Find(Item(Arg(a,2)),20)?1:0);}
int RlGrade(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);auto p=Find(Item(Arg(a,2)),20);auto t=Table("RLBase.txt",8);return Push(s,p?Number(t,Row(t,p->id),1,0):0);}
int RlGroup(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);int star=0,group=0;RlState(Find(Item(Arg(a,2)),20),star,group);return Push(s,group);}
int RlStar(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);int star=0,group=0;if(!RlState(Find(Item(Arg(a,2)),20),star,group))return 0;
    auto t=Table("RLStar.txt",5);int row=Row(t,star),next=Row(t,star+1);
    s->PushInteger(star);s->PushInteger(Number(t,row,1,0));
    auto odds=std::to_string(Number(t,next,3,0)/10)+"%";s->PushString(odds.c_str());
    s->PushInteger(Number(t,next,4,0));s->PushInteger(next>=0?star+1:star);s->PushInteger(Number(t,next,1,0));return 6;
}
int RlCount(LuaPlus::LuaState* s){AskRl();auto t=Table("RSSkill.txt",23);return Push(s,t?(int)t->GetRecordsNum():0);}
int RlBuff(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);auto t=Table("RSSkill.txt",23);int index=Arg(a,1),star=Arg(a,2,0);
    if(!t||index<0||index>=(int)t->GetRecordsNum()||star<0||star>9)return 0;
    s->PushInteger(Number(t,index,0));s->PushInteger(Number(t,index,2));
    auto name=Text(t,index,12),desc=Text(t,index,star?12+star:22);s->PushString(name.c_str());s->PushString(desc.c_str());return 4;
}
int RlName(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);auto t=Table("RSSkill.txt",23);auto name=Text(t,Row(t,Arg(a,1)),12);s->PushString(name.c_str());return 1;}
int RlLearned(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);int flag=Arg(a,2);return Push(s,flag>=0&&flag<24&&(rlLearned&(1u<<flag))?1:0);}
int Operate(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);int op=Arg(a,2),pos=Arg(a,3),b=Arg(a,4,0),c=Arg(a,5,0);
    if(!CysModernGame::IsInWorld() || !Find(Item(pos),18) || b<0 || b>254 || c<-128 || c>127)return Push(s,0);
    if(Arg(a,6,0)!=0){
        CEventSystem::GetMe()->PushEventByName("NEW_DEBUGMESSAGE",{u8"Chưa hỗ trợ tự mua nguyên liệu bằng nguyên bảo. Bỏ chọn ô nguyên bảo để dùng vật phẩm trong túi."});
        return Push(s,0);
    }
    // Only operations implemented and validated by the server may be sent.
    if(op<1 || op>13 || op==10 || op==11)return Push(s,0);
    std::unique_ptr<pg::CGKfsOperate> p(new pg::CGKfsOperate);
    p->operate=op;p->arg_1=(uint8_t)pos;p->arg_2=(uint8_t)b;p->arg_3=(int8_t)c;
    const bool sent=CysModernGame::SendModern(std::move(p));
    if(sent && op==13 && pendingKfs.guid==Key(Item(pos)))pendingKfs.applying=true;
    return Push(s,sent?1:0);
}
std::string DarkDescription(int id){auto t=Table("DarkImpackStr.txt",2);return Text(t,Row(t,id),1);}
int DarkDesc(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);auto p=Find(Item(Arg(a,2)),17);
    for(int i=0;i<3;++i){auto text=p&&p->skills[i]>0?DarkDescription(p->skills[i]):std::string(u8"Chưa lĩnh ngộ");s->PushString(text.c_str());}return 3;
}
int DarkNewDesc(LuaPlus::LuaState* s){
    bool valid=false;for(int slot=0;slot<255;++slot){auto item=Item(slot);if(item&&Key(item)==pendingDark.guid&&item->GetIdTable()==pendingDark.id){valid=true;break;}}
    for(int id:pendingDark.skills){auto text=valid&&id>0?DarkDescription(id):std::string(u8"Chưa lĩnh ngộ");s->PushString(text.c_str());}return 3;
}
std::string SkillName(int id) {
    auto def=SkillTemplate(id);auto text=def?DisplayText(def->m_lpszName):std::string();
    if(text.empty()){auto t=Table("SkillTemplate_V1.txt",102);text=Text(t,Row(t,id),2);}
    return text;
}
int KfsDesc(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);auto p=Find(Item(Arg(a,2)),18);int i=Arg(a,3);
    auto text=p&&i>=0&&i<3?SkillName(p->skills[i]):std::string();s->PushString(text.c_str());return 1;
}
int KfsNewDesc(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);auto item=Item(Arg(a,2));int i=Arg(a,3);
    if(!item || Key(item)!=pendingKfs.guid || item->GetIdTable()!=pendingKfs.id || i<0 || i>2){s->PushString("");return 1;}
    auto text=SkillName(pendingKfs.skills[i]);
    s->PushString(text.c_str());return 1;
}
void Event(const char* name,int pos=-1){if(CEventSystem::GetMe())CEventSystem::GetMe()->PushEventByName(name,{std::to_string(pos)});}
LuaPlus::LuaObject Receiver(LuaPlus::LuaObject& g,const char* name){auto t=g.GetByName(name);if(t.IsUserData()){auto m=t.GetMetaTable();auto i=m.GetByName("__index");return i.IsTable()?i:m;}return t;}
}
bool IsWuhunSkill(int id){return Row(Table("KFSSkillLevelup.txt",5),id)>=0;}
void RequestBagDetails(int slot) {
    if(minorUnlocked<0)AskMinor();
    auto item=Item(slot);if(!item)return;
    // CY's compact bag list carries only GUID/template/count. These four
    // equipment families need the full instance before their Lua frames open.
    // The existing pool coalesces requests until GCItemInfo arrives.
    const int family=item->GetIdTable()/1000;
    if(family>=10155&&family<=10158)CDataPool::GetMe()->UserBag_AskExtraInfo(slot);
}
bool Preview(int position,int& skill,std::string& name,std::string& icon) {
    if(position<0)return false;
    auto item=static_cast<CObject_Item*>(CObject_Item::FindItem(position/3));
    if(!item || item->GetTypeOwner()!=tObject_Item::IO_MYSELF_PACKET)return false;
    auto p=Find(item,18);if(!p)return false;skill=p->skills[position%3];
    if(!IsWuhunSkill(skill))return false;
    auto def=SkillTemplate(skill);
    name=def?DisplayText(def->m_lpszName):std::string();icon=def?DisplayText(def->m_lpszIconName):std::string();
    if(name.empty()||icon.empty()){
        auto t=Table("SkillTemplate_V1.txt",102);int row=Row(t,skill);
        if(name.empty())name=Text(t,row,2);if(icon.empty())icon=Text(t,row,3);
    }
    return !name.empty() && !icon.empty();
}
void Remember(const pg::ItemInfo_bos& in) {
    auto key=Key(in.guid.world,in.guid.server,in.guid.series);if(!key)return;
    auto old=instances.find(key);
    // A tooltip may request the same item while a paid roll is being previewed.
    // Re-reading unchanged data must not discard that result.
    const auto changed=[&](bool kfs){
        if(old==instances.end()||old->second.id!=in.item_index)return true;
        const auto& previous=old->second;
        if(previous.level!=(kfs?in.wh_level:in.aq_xiulian)||previous.grow!=(kfs?in.wh_grow_rate:in.aq_grow_rate))return true;
        for(int i=0;i<3;++i)if(previous.skills[i]!=(kfs?in.wh_skill[i]:in.aq_skill[i]))return true;
        return false;
    };
    if(pendingKfs.guid==key && (pendingKfs.applying||changed(true)))pendingKfs=Pending();
    if(pendingDark.guid==key && changed(false))pendingDark=Pending();
    instances.erase(key);
    int kind=in.item_index==10157001||in.item_index==10157002?19:
        in.item_index>=10158001&&in.item_index<=10158005?20:in.equip_type==1?17:in.equip_type==2?18:0;if(!kind)return;
    Instance p;p.id=in.item_index;p.type=kind;
    p.creator=in.creator_text();
    if(kind==17){p.level=in.aq_xiulian;p.exp=in.aq_exp;p.grow=in.aq_grow_rate;for(int i=0;i<3;++i)p.skills[i]=in.aq_skill[i];}
    else if(kind==18){p.level=in.wh_level;p.exp=in.wh_exp;p.grow=in.wh_grow_rate;p.life=in.wh_life;p.compound=in.wh_hecheng_level;p.slots=in.wh_ex_attr_number;for(int i=0;i<3;++i)p.skills[i]=in.wh_skill[i];for(int i=0;i<10;++i)p.attrs[i]=in.wh_ex_attr[i];}
    instances[key]=p;
}
void Reset(){instances.clear();pendingKfs=Pending();pendingDark=Pending();rlLearned=0;rlAsked=false;minorUnlocked=-1;minorAsked=false;minorAskedAt=0;}
bool IsWorldPacket(uint16_t id){return id==pg::GCRefreshKFSSkill::PACKET_ID || id==pg::GCRefreshDarkSkill::PACKET_ID || id==pg::GCMinorPasswd::PACKET_ID;}
bool Dispatch(const pg::Packet& packet) {
    if(packet.packetId()==pg::GCMinorPasswd::PACKET_ID){
        const auto& p=static_cast<const pg::GCMinorPasswd&>(packet);
        if(p.m_Type==1)minorUnlocked=p.m_ReturnSetup_m_uFlag==0?1:0;
        else if(p.m_Type==3 || p.m_Type==11)minorUnlocked=0;
        else if(p.m_Type==5 || p.m_Type==7)minorUnlocked=1;
        return true;
    }
    if(packet.packetId()==pg::GCUICommand::PACKET_ID){
        const auto& p=static_cast<const pg::GCUICommand&>(packet);
        if(p.m_nUIIndex==8000341)pendingDark=Pending(); // replacement acknowledgement, including an identical roll
        if(p.m_nUIIndex==201406284&&p.m_Param_m_IntCount==2&&p.m_Param_m_aIntValue.size()>=2&&p.m_Param_m_aIntValue[0]==371)
            rlLearned=(unsigned)p.m_Param_m_aIntValue[1]&0xFFFFFFu;
        return false; // Inventory dispatch still sends the CY UI refresh event.
    }
    if(!IsWorldPacket(packet.packetId()))return false;
    int pos;Pending result;bool kfs=packet.packetId()==pg::GCRefreshKFSSkill::PACKET_ID;
    if(kfs){auto& p=static_cast<const pg::GCRefreshKFSSkill&>(packet);pos=p.bag_index;for(int i=0;i<3;++i)result.skills[i]=p.skills[i];}
    else {auto& p=static_cast<const pg::GCRefreshDarkSkill&>(packet);pos=(int)p.bag_pos;for(int i=0;i<3;++i)result.skills[i]=p.skills[i];}
    auto item=Item(pos);if(!Find(item,kfs?18:17))return true;
    result.guid=Key(item);result.id=item->GetIdTable();
    if(kfs){pendingKfs=result;Event("KFS_SKILL_UPDATE_RECOIN",pos);}else{pendingDark=result;Event("DARK_SKILL_UPDATE_RECOIN",pos);}return true;
}
void RegisterHost() {
    auto scripts=CScriptSystem::GetMe();auto s=scripts?scripts->GetLuaState():nullptr;if(!s)return;
    auto g=s->GetGlobals();auto pp=Receiver(g,"PlayerPackage"),dp=Receiver(g,"DataPool");
    g.Register("Lua_GetALLRlBuffNum",RlCount);g.Register("Lua_GetRlBuffFromTable",RlBuff);g.Register("Lua_GetRlBuffNameByID",RlName);
    g.Register("CheckPhoneMibaoAndMinorPassword",CheckEquipmentProtection);
    g.Register("CheckPhoneMibaoAndMinorPasswordForCYJ",CheckEquipmentProtection);
    if(pp.IsTable()){
        pp.Register("IsBagItemKFS",IsKfs);pp.Register("GetBagKfsSkillNum",SkillCount);pp.Register("GetBagKfsSkill",BagSkill);
        pp.Register("GetBagKfsSkillUpSkill",SkillUpId);pp.Register("GetBagKfsSkillUpItem",SkillUpItem);pp.Register("GetBagKfsSkillUpMoney",SkillUpMoney);
        pp.Register("GetBagKfsData",BagData);pp.Register("Kfs_Op_Do",Operate);
        pp.Register("GetKfsAttrEx",BagAttr);pp.Register("GetBagKfsAttrExNum",AttrCount);
        pp.Register("GetBagKfsAttrExUpItem",AttrUpItem);pp.Register("GetBagKfsAttrExUpMoney",AttrUpMoney);pp.Register("GetBagKfsSlotMoney",SlotMoney);
        pp.Register("IsBagItemLW",IsLw);pp.Register("GetBagLWData",LwData);pp.Register("GetBagLWAttrExInfo",LwAttrInfo);pp.Register("Lw_Op_Do",LwOperate);
        pp.Register("Lua_IsBagItemRL",IsRl);pp.Register("Lua_GetBagItemRl_Grade",RlGrade);pp.Register("Lua_GetBagItemRl_BuffGroupID",RlGroup);pp.Register("Lua_GetBagItemRl_StarInfo",RlStar);
    }
    if(dp.IsTable()){
        dp.Register("GetKfsSkill",Skill);dp.Register("GetKfsData",SelfData);
        dp.Register("GetKfsBase",SelfBase);dp.Register("GetFixKfsBase",SelfFixedBase);dp.Register("GetKfsFixAttrEx",SelfAttr);
        dp.Register("GetDarkSkillDesc",DarkDesc);dp.Register("GetDarkSkillNewDesc",DarkNewDesc);dp.Register("GetKFSNewSkillDesc",KfsNewDesc);
        dp.Register("GetKFSSkillDesc",KfsDesc);
        dp.Register("Lua_IsHumanLearnedRlSkill",RlLearned);
    }
}
const char* ProbeShotName(){const char* name=probeShot;probeShot=nullptr;return name;}
bool ProbeTick() {
    static const int mode=[](){char v[8]={};GetEnvironmentVariableA("CYS_EQUIPMENT_SKILLS_LIVE",v,8);return atoi(v);}();
    if(!mode)return true;
    static int step=0;static DWORD then=GetTickCount();
    if(step>=12)return true;
    if(GetTickCount()-then<4000)return false;
    then=GetTickCount();
    char account[32]={};GetEnvironmentVariableA("CYS_BOT_ACCOUNT",account,32);
    if(strcmp(account,"test15")){TDU_Log("CYS equipment-live FAIL account guard");step=12;return true;}
    auto eval=[&](const char* code,const char* env="SelfEquip"){auto r=CScriptSystem::GetMe()->EvaluateScript(std::string(env)+"_Env",code);TDU_Log("CYS equipment-live step=%d env=%s lua=%d phase=%s error=%s",step,env,r.ok()?1:0,CysCheckedScriptLua::PhaseName(r.phase),r.error);if(!r.ok())step=12;return r.ok();};
    auto open=[](int id,std::vector<int32_t> args){pg::GCUICommand p;p.m_nUIIndex=id;p.m_Param_m_IntCount=(uint8_t)args.size();p.m_Param_m_aIntValue=args;bool changed=false;CysModernHandlers::Dispatch(p,1,changed);};
    // Keep a valid cared object during this GUI-only probe; NPC discovery is a separate test.
    const int cared=CObjectManager::GetMe()->GetMySelf()->GetServerID();
    auto script=[](int group){std::unique_ptr<pg::CGExecuteScript> p(new pg::CGExecuteScript);p->m_ScriptID=880001;p->set_m_szFunName("RL_SwitchSkill");p->m_uParamCount=2;p->m_aParam={16,group};CysModernGame::SendModern(std::move(p));};
    if(mode==4){
        if(step==0){
            if(!eval("for i=-1,10 do local n,p=Pet:GetPetList_Appoint(i); assert(type(n)=='string' and type(p)=='string','pet slot '..i..' missing strings'); if not Pet:IsPresent(i) then assert(n=='','phantom pet '..i) end end"))return true;
            // Exercise an occupied slot without changing server/DB state. No
            // events are dispatched while this temporary client record exists.
            auto pet=CDataPool::GetMe()->Pet_GetPet(0);
            if(!pet){TDU_Log("CYS equipment-live FAIL pet pool");step=12;return true;}
            const SDATA_PET saved=*pet;
            pet->m_nIsPresent=1;pet->m_GUID.m_uHighSection=0xC0DE;pet->m_GUID.m_uLowSection=0x1234;
            pet->m_nDataID=1;pet->m_szName="CY pet contract";
            const bool ok=eval("local n,p=Pet:GetPetList_Appoint(0); assert(n=='CY pet contract' and p=='on_packa','occupied pet contract')");
            *pet=saved;if(!ok)return true;
            CEventSystem::GetMe()->PushEventByName("TOGLE_PET_PAGE",{});
            CEventSystem::GetMe()->PushEventByName("OPEN_XIULIAN_PAGE",{});
            ++step;return false;
        }
        if(!eval("local old=arg0; arg0=nil; PetBankMain_OnEvent('TOGLE_PET_PAGE'); arg0='0'; PetBankMain_OnEvent('TOGLE_PET_PAGE'); arg0=old", "PetBankMain"))return true;
        if(!eval("Xiulian_SetHappyMonth(); Xiulian_SetMergeMonth(); this:Hide()", "Xiulian"))return true;
        TDU_Log("CYS equipment-live residual contracts PASS");step=12;return true;
    }
    if(mode==2){
        if(step==0){AskRl();++step;return false;}
        eval("assert(PlayerPackage:GetBagLWData(15,'HP')==2); assert(PlayerPackage:Lua_GetBagItemRl_BuffGroupID(16)==7); assert(DataPool:Lua_IsHumanLearnedRlSkill(6)==1)");
        TDU_Log("CYS equipment-live persistence %s",step==12?"FAIL":"PASS");step=12;return true;
    }
    if(mode==3){
        switch(step){
        case 0:
            {const int saved=minorUnlocked;
            minorUnlocked=0;const bool locked=eval("assert(CheckPhoneMibaoAndMinorPassword()==0,'locked gate allowed')");
            minorUnlocked=-1;const bool unknown=eval("assert(CheckPhoneMibaoAndMinorPassword()==0,'unknown gate allowed')");
            minorUnlocked=saved;if(!locked||!unknown)break;}
            if(!eval("assert(CheckPhoneMibaoAndMinorPassword()==1,'test15 protection status not ready')"))break;
            open(201405044,{-1});break;
        case 1:
            eval("assert(this:IsVisible()); EquipLingPai_SkillQH_OnItemDragedDropFromBag(16); EquipLingPai_SkillQH_SkillZiKuang:SetItemSelect(6)","EquipLingPai_SkillQH");
            rlAsked=false;AskRl();break;
        case 2:
            {static bool captured=false;if(!captured){captured=true;probeShot="equipment-rl-selected";return false;}}
            if(!eval("assert(EquipLingPai_SkillQH_SkillZiKuang:GetFirstSelectItem()==6,'RL selected='..tostring(EquipLingPai_SkillQH_SkillZiKuang:GetFirstSelectItem())); assert(EquipLingPai_SkillQH_CurrentSkillNameText:GetProperty('Text')==Lua_GetRlBuffNameByID(7)); EquipLingPai_SkillQH_CleanUp(); this:Hide()","EquipLingPai_SkillQH"))break;
            open(20110730,{cared,0});break;
        case 3:
            if(!eval("assert(this:IsVisible(),'LW not visible'); LongwenExtraPropertyUp_Item_Change(15); assert(tonumber(LongwenExtraPropertyUp_NeedMoney:GetProperty('MoneyNumber'))>0,'LW cost missing'); LongwenExtraPropertyUp_Item_Change(-1); this:Hide()","LongwenExtraPropertyUp"))break;
            open(20090722,{cared,2,0});break;
        case 4:
            eval("assert(this:IsVisible()); NewWuhunSkillStudy_Update(19); assert(NewWuhunSkillStudy_Bk1_Text2:GetProperty('Text')~='','old WH skill 1 missing'); assert(NewWuhunSkillStudy_Bk1_Text4:GetProperty('Text')~='','old WH skill 2 missing'); assert(NewWuhunSkillStudy_Bk1_Text6:GetProperty('Text')~='','old WH skill 3 missing'); NewWuhunSkillStudy_Blank_Queren:SetCheck(0); NewWuhunSkillStudy_Queren_Clicked(); NewWuhunSkillStudy_OK_Clicked()","NewWuhunSkillStudy");break;
        case 5: {
            if(pendingKfs.guid!=Key(Item(19))){TDU_Log("CYS equipment-live FAIL UI Wuhun roll");step=12;break;}
            static bool queried=false;if(!queried){queried=true;probeShot="equipment-wuhun-roll";CDataPool::GetMe()->UserBag_AskExtraInfo(19);return false;}
            eval("assert(NewWuhunSkillStudy_Bk2_Text2:GetProperty('Text')~=''); NewWuhunSkill_SaveChange_OK()","NewWuhunSkillStudy");break;
        }
        case 6:
            if(pendingKfs.guid){TDU_Log("CYS equipment-live FAIL UI Wuhun replace");step=12;break;}
            if(!eval("NewWuhunSkillStudy_Clear(1); this:Hide()","NewWuhunSkillStudy"))break;
            open(800034,{6,cared});break;
        case 7:
            eval("AnqiShuxingNEW_InitDlg(); AnqiShuxingNEW_Update(13); AnqiShuxingNEW_OK_Clicked()","AnqiShuxingNEW");break;
        case 8: {
            if(pendingDark.guid!=Key(Item(13))){TDU_Log("CYS equipment-live FAIL UI Dark roll");step=12;break;}
            static bool queried=false;if(!queried){queried=true;probeShot="equipment-dark-roll";CDataPool::GetMe()->UserBag_AskExtraInfo(13);return false;}
            eval("assert(AnqiShuxingNEW_AfterAttrFirst:GetProperty('Text')~=''); AnqiShuxingNEW_SaveChange_Clicked(0)","AnqiShuxingNEW");break;
        }
        case 9: {
            auto dark=Find(Item(13),17);
            if(pendingDark.guid||!dark||dark->skills[0]<=0||dark->skills[1]<=0||dark->skills[2]<=0){TDU_Log("CYS equipment-live FAIL UI Dark replace");step=12;break;}
            if(!eval("AnqiShuxingNEW_Reset(1); this:Hide()","AnqiShuxingNEW"))break;
            std::unique_ptr<pg::CGUseEquip> p(new pg::CGUseEquip);p->bagIndex=13;p->equipPoint=17;CysModernGame::SendModern(std::move(p));break;
        }
        case 10: {
            bool good=true;for(int id=274;id<=276;++id)good=good&&CysSkillNet::SkillLevel(id)>0;
            if(!good){TDU_Log("CYS equipment-live FAIL Dark equip skills");step=12;break;}
            std::unique_ptr<pg::CGUnEquip> p(new pg::CGUnEquip);p->equipPoint=17;CysModernGame::SendModern(std::move(p));break;
        }
        case 11: {
            bool good=true;for(int id=274;id<=276;++id)good=good&&CysSkillNet::SkillLevel(id)<0;
            TDU_Log("CYS equipment-live UI and Dark %s",good?"PASS":"FAIL");step=12;return true;
        }
        }
        if(step<12)++step;return step>=12;
    }
    switch(step){
    case 0:
        for(int slot:{13,15,16,17,18,19}){auto it=Item(slot);auto cached=Find(it,0);TDU_Log("CYS equipment-live fixture slot=%d item=%u cached=%d kind=%d",slot,it?it->GetIdTable():0,cached?1:0,cached?cached->type:0);}
        if(!eval("assert(PlayerPackage:IsBagItemKFS(13)==1); assert(PlayerPackage:GetBagKfsSkillNum(13)==3); assert(PlayerPackage:GetBagLWData(15,'HP')==0); assert(PlayerPackage:Lua_GetBagItemRl_Grade(16)==5); assert(PlayerPackage:IsBagItemKFS(254)==0); assert(Lua_GetALLRlBuffNum()==23)"))return true;
        eval("assert(PlayerPackage:Lw_Op_Do(4,15,0)==1)");break;
    case 1:eval("assert(PlayerPackage:GetBagLWData(15,'HP')==1); assert(PlayerPackage:Lw_Op_Do(7,15,0)==1)");break;
    case 2:if(eval("assert(PlayerPackage:GetBagLWData(15,'HP')==2)"))script(7);break;
    case 3:
        if(eval("assert(PlayerPackage:Lua_GetBagItemRl_BuffGroupID(16)==0); assert(DataPool:Lua_IsHumanLearnedRlSkill(6)==0)")){
            std::unique_ptr<pg::CGUseItem> p(new pg::CGUseItem);p->bagIndex=19;p->item_index=38000971;CysModernGame::SendModern(std::move(p));
        }break;
    case 4:if(eval("assert(DataPool:Lua_IsHumanLearnedRlSkill(6)==1)"))script(7);break;
    case 5:eval("assert(PlayerPackage:Lua_GetBagItemRl_BuffGroupID(16)==7); assert(PlayerPackage:Kfs_Op_Do(6,13,0,0)==1)");break;
    case 6:
        if(pendingKfs.guid!=Key(Item(13))){TDU_Log("CYS equipment-live FAIL pending GUID");step=12;break;}
        eval("assert(PlayerPackage:Kfs_Op_Do(13,13,0,0)==1)");break;
    case 7:
        if(pendingKfs.guid){TDU_Log("CYS equipment-live FAIL pending consumed");step=12;break;}
        if(eval("assert(PlayerPackage:GetBagKfsSkillNum(13)==3)")){
            std::unique_ptr<pg::CGUseEquip> p(new pg::CGUseEquip);p->bagIndex=13;p->equipPoint=18;CysModernGame::SendModern(std::move(p));
        }break;
    case 8:
        if(eval("assert(DataPool:GetKfsData('LEVEL')==90); assert(DataPool:GetKfsSkill(0)>0); assert(DataPool:GetKfsSkill(1)>0); assert(DataPool:GetKfsSkill(2)>0)")){
            std::unique_ptr<pg::CGUnEquip> p(new pg::CGUnEquip);p->equipPoint=18;CysModernGame::SendModern(std::move(p));
        }break;
    case 9:
        if(eval("assert(DataPool:GetKfsSkill(0)==-1); assert(PlayerPackage:GetBagLWData(15,'HP')==2); assert(PlayerPackage:Lua_GetBagItemRl_BuffGroupID(16)==7)"))TDU_Log("CYS equipment-live operations PASS");
        step=12;return true;
    }
    if(step<12)++step;return step>=12;
}
}
