// CY AutoAttackSkill.lua uses ten arrays (the older GL stub returned seven
// numbers). Definitions are read from the same CY ZdZdSkill/ZdZdPotion tables.
#include "PgPackets_mission.h"
#include "PgPackets_team.h"
#include "../Object/Item/Obj_Item.h"
#include "CysInventoryNet.h"
namespace CysBattleAssist {
namespace {
DBC::DBCFile* Table(const char* name) {
    static std::map<std::string,std::unique_ptr<DBC::DBCFile>> tables;
    auto it=tables.find(name);
    if(it==tables.end()) {
        std::unique_ptr<DBC::DBCFile> t(new DBC::DBCFile(0));
        if(!CDataBase::Util_OpenDBCFromTxt(name,t.get()))t.reset();
        it=tables.emplace(name,std::move(t)).first;
    }
    return it->second.get();
}
int Num(DBC::DBCFile* t,int row,int col){return t->Search_Posistion(row,col)->iValue;}
int Limit(LuaPlus::LuaState* s){s->PushInteger(50);return 1;}
void Array(LuaPlus::LuaState* s,const std::vector<int>& values){s->NewTable();for(size_t i=0;i<values.size();++i){s->PushInteger(values[i]);s->RawSetI(-2,(int)i+1);}}
const char* keys[]={"useskill","usepotiont","usepotion","usepotionc","useRecoverSkill","usePetSkill","useSwitch","usepotionofft","usepotionoff","usepotionoffc"};
std::vector<int> cfg[11], incoming[11];
int revision=0,inRevision=0;bool working=false,ready=false,busy=false,dirty=false,wantStart=false;
DWORD requested=0;
bool Send(const char* fn,const std::vector<int>& args={}) {
    if(!CysModernGame::IsInWorld())return false;
    std::unique_ptr<pg::CGExecuteScript> p(new pg::CGExecuteScript);
    p->m_ScriptID=990026;p->m_szFunName=fn;p->m_aParam.assign(args.begin(),args.end());p->m_uParamCount=(uint8_t)args.size();
    return CysModernGame::SendModern(std::move(p));
}
void Save(){
    if(!ready||busy){dirty=true;return;}busy=true;dirty=false;requested=GetTickCount();
    Send("Begin",{revision});
    for(int k=0;k<11;++k)for(size_t at=0;at<cfg[k].size();at+=8){
        std::vector<int> args={revision,k+1,(int)at+1};
        for(size_t i=at;i<cfg[k].size()&&i<at+8;++i)args.push_back(cfg[k][i]);
        Send("Chunk",args);
    }
    Send("Commit",{revision});
}
void Defaults(){
    cfg[0]=std::vector<int>(17,1);cfg[1]={0,0,0};cfg[2]={1,1,1};cfg[3]={50,50,50};cfg[4]={50,50,50,50};
    cfg[5]={1,1,50,50,0,0};cfg[6]={1,1,0,0,0,0,0,0,0,0};cfg[7]={0,0,0};cfg[8]={1,1,1};cfg[9]={50,50,50};
    cfg[10]={0,0,0};
}
int Config(LuaPlus::LuaState* s){for(int k=0;k<10;++k)Array(s,cfg[k]);return 10;}
int SetConfig(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);if(!a[2].IsTable())return 0;
    LuaPlus::LuaObject object(a[2]);
    for(int k=0;k<10;++k){
        auto row=object.GetByName(keys[k]);if(!row.IsTable())continue;
        for(size_t i=0;i<cfg[k].size();++i){
            auto value=k==5&&i>=2?object.GetByName(i<4?"usePetSkillc":"usePetSkillt").GetByIndex((int)i%2+1):row.GetByIndex((int)i+1);
            if(value.IsNumber()&&value.GetInteger()>=0&&value.GetInteger()<=100)cfg[k][i]=value.GetInteger();
        }
    }
    Save();
    return 0;
}
int Skills(LuaPlus::LuaState* s){
    s->NewTable();auto me=CObjectManager::GetMe()->GetMySelf();auto t=Table("ZdZdSkill.txt");int n=0;
    if(!me||!t||t->GetFieldsNum()!=10)return 1;
    for(int r=0;r<(int)t->GetRecordsNum();++r)if(Num(t,r,3)==me->GetCharacterData()->Get_MenPai()){
        Array(s,{Num(t,r,1),Num(t,r,4)});s->RawSetI(-2,++n);
    }
    return 1;
}
int Potions(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);int kind=a[2].IsNumber()?a[2].GetInteger():0;
    s->NewTable();auto t=Table("ZdZdPotion.txt");int n=0;if(!t||t->GetFieldsNum()!=5)return 1;
    for(int r=0;r<(int)t->GetRecordsNum();++r)if(Num(t,r,2)==kind){Array(s,{Num(t,r,0),Num(t,r,2),Num(t,r,3),0,Num(t,r,1)});s->RawSetI(-2,++n);}return 1;
}
int MaxNum(LuaPlus::LuaState* s){for(auto v:cfg[10])s->PushInteger(v);return 3;}
int SetMax(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);for(int i=0;i<3;++i)if(a[i+2].IsNumber())cfg[10][i]=(std::max)(0,(std::min)(i==2?200:9999999,a[i+2].GetInteger()));Save();return 0;}
int Working(LuaPlus::LuaState* s){s->PushString(working?"true":"false");return 1;}
int Start(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);if(!a[2].IsString()||strcmp(a[2].GetString(),"Farm")){s->PushInteger(0);return 1;}
    if(!ready){wantStart=true;Send("Open");}else if(busy||dirty){wantStart=true;if(!busy)Save();}else Send("Start",{revision});
    s->PushInteger(ready?1:0);return 1;
}
int Stop(LuaPlus::LuaState*){wantStart=false;Send("Stop");return 0;}
int Update(LuaPlus::LuaState*){return 0;} // SetConfigData immediately follows UI edits; only it owns the structured transaction.
int Available(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);s->PushBoolean(a[2].IsString()&&!strcmp(a[2].GetString(),"Farm"));return 1;}
int ItemCount(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);int id=a[2].IsNumber()?a[2].GetInteger():0,total=0;
    if(id>0&&CDataPool::GetMe())for(int i=0;i<CysInventoryNet::BagSize(0);++i){
        auto item=CDataPool::GetMe()->UserBag_GetItem(i);
        if(item&&item->GetIdTable()==id&&!item->IsLocked())total+=item->GetNumber();
    }
    s->PushInteger(total);return 1;
}
const std::pair<std::string,int>& ItemInfo(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);int id=a[2].IsNumber()?a[2].GetInteger():0;
    static std::map<int,std::pair<std::string,int>> cache;
    auto it=cache.find(id);if(it!=cache.end())return it->second;
    std::pair<std::string,int> value={"",-1};
    if(id>0){auto item=CObject_Item::NewItem(id);if(item){value={item->GetName()?item->GetName():"",item->GetNeedLevel()};CObject_Item::DestroyItem(item);}}
    return cache.emplace(id,std::move(value)).first->second;
}
int ItemName(LuaPlus::LuaState* s){s->PushString(ItemInfo(s).first.c_str());return 1;}
int ItemLevel(LuaPlus::LuaState* s){s->PushInteger(ItemInfo(s).second);return 1;}
}
void Tick(){
    if(!CysModernGame::IsInWorld()){ready=false;working=false;busy=false;dirty=false;wantStart=false;requested=0;return;}
    if(!ready&&(!requested||GetTickCount()-requested>5000)){requested=GetTickCount();Send("Open");}
    if(busy&&GetTickCount()-requested>10000){busy=false;dirty=false;ready=false;wantStart=false;Send("Open");}
}
bool TeamApply(const pg::Packet& packet){
    if(packet.packetId()!=pg::GCTeamAskApply::PACKET_ID||!working||cfg[6][6]!=1)return false;
    const auto& request=static_cast<const pg::GCTeamAskApply&>(packet);
    std::unique_ptr<pg::CGTeamRetApply> reply(new pg::CGTeamRetApply);
    reply->source_guid=request.source_guid;reply->return_type=1;
    return CysModernGame::SendModern(std::move(reply));
}
void Snapshot(const int* values,int count){
    if(count<2)return;int kind=values[0];
    if(kind==0&&count==3){inRevision=values[1];working=values[2]==1;for(auto& r:incoming)r.clear();}
    else if(kind>=1&&kind<=11){int at=values[1]-1;if(at<0||at+count-2>(int)cfg[kind-1].size())return;
        auto& row=incoming[kind-1];row.resize(cfg[kind-1].size(),-1);for(int i=2;i<count;++i)row[at+i-2]=values[i];
    }else if(kind==12&&values[1]==inRevision){
        for(int k=0;k<11;++k)if(incoming[k].size()!=cfg[k].size()||std::find(incoming[k].begin(),incoming[k].end(),-1)!=incoming[k].end())return;
        revision=inRevision;ready=true;busy=false;
        if(!dirty)for(int k=0;k<11;++k)cfg[k]=incoming[k];
        if(dirty){Save();return;}
        if(wantStart){wantStart=false;Send("Start",{revision});}
        CEventSystem::GetMe()->PushEventByName("BATTLE_ASSIST_EVENT",{});
        CEventSystem::GetMe()->PushEventByName("TRIGGER_ZIDONGZHANDOU",{"config_update"});
    }
}
void Register(LuaPlus::LuaState* s){
    Defaults();auto package=s->GetGlobals().GetByName("PlayerPackage");
    if(package.IsUserData()){package=package.GetMetaTable();auto index=package.GetByName("__index");if(index.IsTable())package=index;}
    if(package.IsTable()){package.Register("CountAvailableItemByIDTable",ItemCount);package.Register("GetItemName",ItemName);package.Register("GetItemNeedLvByIndex",ItemLevel);}
    auto o=s->GetGlobals().GetByName("BattleAssist");
    if(o.IsUserData()){o=o.GetMetaTable();auto index=o.GetByName("__index");if(index.IsTable())o=index;}
    if(!o.IsTable())return;
    o.Register("Farm_GetLimitLevel",Limit);o.Register("Farm_GetConfigData",Config);o.Register("Farm_SetConfigData",SetConfig);
    o.Register("Farm_GetSkillIds",Skills);o.Register("Farm_GetPotionIds",Potions);o.Register("Farm_GetCfgData_MaxNum",MaxNum);o.Register("IsWorking",Working);
    o.Register("Start",Start);
    o.Register("Stop",Stop);o.Register("Farm_UpdateConfig",Update);o.Register("Farm_SetCfgData_MaxNum",SetMax);
    // CY asks this before choosing dungeon routing versus ordinary Farm. The
    // generic null-object stub is truthy in Lua and incorrectly selected FB.
    o.Register("AskIsNeiGuaOpen",Available);
}
}
