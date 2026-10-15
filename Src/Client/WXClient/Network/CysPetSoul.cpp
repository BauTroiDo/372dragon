#include "StdAfx.h"
#include "CysPetSoul.h"
#include "CysModernGame.h"
#include "PgPackets_core.h"
#include "PgPackets_misc.h"
#include "PgPackets_mission.h"
#include "PgPackets_pet.h"
#include "PgPackets_item.h"
#include "PgPackets_pet_detail_types.h"
#include "../DataPool/GMDataPool.h"
#include "../DataPool/GMDP_Struct_Pet.h"
#include "../Script/GMScriptSystem.h"
#include "../Event/GMEventSystem.h"
#include "TDUtil.h"
#include "TDObjectSystem.h"
#include <map>
#include <cstring>
namespace CysPetSoul {
namespace {
int revision=0,slot=-1,material=-1,lockMask=0,colorMaterial=-1,lastOp=0;bool busy=false;DWORD sent=0;std::string description;
int snapshot[13]={};
std::map<unsigned long long,pg::ItemInfo_bos> items;
std::map<unsigned long long,int> worn;
DWORD lastWear=0;
std::string DisplayText(const char* p){
    std::string in=p?p:"";
    if(in.empty()||MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,in.data(),(int)in.size(),nullptr,0)>0)return in;
    int count=MultiByteToWideChar(936,0,in.data(),(int)in.size(),nullptr,0);
    if(count<=0)return in;
    std::wstring wide(count,L'\0');MultiByteToWideChar(936,0,in.data(),(int)in.size(),&wide[0],count);
    int bytes=WideCharToMultiByte(CP_UTF8,0,wide.data(),count,nullptr,0,nullptr,nullptr);
    if(bytes<=0)return in;
    std::string out(bytes,'\0');WideCharToMultiByte(CP_UTF8,0,wide.data(),count,&out[0],bytes,nullptr,nullptr);return out;
}
bool Ask(int op,int pos){
    if(getenv("CYS_POWER_SYSTEMS_LIVE"))TDU_Log("CYS-POWER-ASK: op=%d pos=%d revision=%d busy=%d elapsed=%u world=%d",op,pos,revision,busy,GetTickCount()-sent,CysModernGame::IsInWorld());
    if(!CysModernGame::IsInWorld()||(busy&&GetTickCount()-sent<5000))return false;
    if(op!=0&&revision<1)return false;
    std::unique_ptr<pg::CGExecuteScript> p(new pg::CGExecuteScript);
    p->m_ScriptID=990028;p->m_szFunName="Action";p->m_aParam={op,pos,revision,material,lockMask,colorMaterial};p->m_uParamCount=6;
    busy=CysModernGame::SendModern(std::move(p));if(busy)lastOp=op;sent=GetTickCount();return busy;
}
int Open(LuaPlus::LuaState*){lockMask=0;colorMaterial=-1;Ask(0,-1);return 0;}
int Action(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);if(a[1].IsNumber()){int op=a[1].GetInteger();if(op>=1&&op<=5)Ask(op,slot);}return 0;}
int Data(LuaPlus::LuaState* s){s->PushInteger(slot);s->PushInteger(material);s->PushString(description.c_str());s->PushInteger(snapshot[12]);s->PushInteger(busy?1:0);s->PushInteger(lockMask);s->PushInteger(colorMaterial);return 7;}
void Changed(){if(auto e=CEventSystem::GetMe())e->PushEventByName("CYS_PETSOUL_UPDATE",{});}
int RowUnit(int row){static const int units[]={100000,10000,1000,100,10,1};return row>=1&&row<=6?units[row-1]:0;}
bool RowValid(int row){
    if(!RowUnit(row)||slot<0||snapshot[3]<=0)return false;
    int count=snapshot[5]==0?4:snapshot[5]==1?5:6;
    auto info=Details(CDataPool::GetMe()->UserBag_GetItem(slot));
    return info&&row<=count&&info->pet_soul_attr[row-1].type>=0&&info->pet_soul_attr[row-1].type<=22;
}
int LockInfo(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);int row=a[1].IsNumber()?a[1].GetInteger():0;int unit=RowUnit(row);s->PushInteger(RowValid(row)?1:0);s->PushInteger(unit?(lockMask/unit)%10:0);return 2;}
int Lock(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);int row=a[1].IsNumber()?a[1].GetInteger():0;if(!busy&&RowValid(row)){int unit=RowUnit(row);lockMask+=((lockMask/unit)%10)?-unit:unit;Changed();}return 0;}
int ClearColor(LuaPlus::LuaState*){if(!busy){colorMaterial=-1;Changed();}return 0;}
SDATA_PET* PetAt(int index){
 if(index<0||index>=HUMAN_PET_MAX_COUNT||!CDataPool::GetMe())return nullptr;
 auto p=CDataPool::GetMe()->Pet_GetPet(index);return p&&p->m_nIsPresent!=INVALID_ID?p:nullptr;
}
int PetInfo(LuaPlus::LuaState* s){
 LuaPlus::LuaStack a(s);auto p=a[1].IsNumber()?PetAt(a[1].GetInteger()):nullptr;
 if(!p){s->PushString("");s->PushInteger(-1);return 2;}
 auto it=worn.find(((unsigned long long)p->m_GUID.m_uHighSection<<32)|p->m_GUID.m_uLowSection);
 s->PushString(p->m_szName.c_str());s->PushInteger(it==worn.end()?-1:it->second);return 2;
}
int Wear(LuaPlus::LuaState* s){
 LuaPlus::LuaStack a(s);auto pet=a[1].IsNumber()?PetAt(a[1].GetInteger()):nullptr;
 if(!pet||!a[2].IsNumber()||!CysModernGame::IsInWorld()||GetTickCount()-lastWear<1500)return 0;
 if(a[2].GetInteger()==1){
  std::unique_ptr<pg::CGPetUnEquip> p(new pg::CGPetUnEquip);p->from=5;p->to=-1;
  p->pet_guid.m_uHighSection=pet->m_GUID.m_uHighSection;p->pet_guid.m_uLowSection=pet->m_GUID.m_uLowSection;
  CysModernGame::SendModern(std::move(p));
 }else{
  auto item=slot>=0?CDataPool::GetMe()->UserBag_GetItem(slot):nullptr;
  if(!item||item->GetItemClass()!=7||item->GetIdTable()!=snapshot[3])return 0;
  std::unique_ptr<pg::CGPetUseEquip> p(new pg::CGPetUseEquip);p->from=(uint8_t)slot;p->to=5;
  p->pet_guid.m_uHighSection=pet->m_GUID.m_uHighSection;p->pet_guid.m_uLowSection=pet->m_GUID.m_uLowSection;
  CysModernGame::SendModern(std::move(p));
 }
 lastWear=GetTickCount();return 0;
}
}
void RegisterHost(){revision=0;slot=-1;material=-1;busy=false;description.clear();items.clear();worn.clear();lastWear=0;memset(snapshot,0,sizeof(snapshot));
    lockMask=0;colorMaterial=-1;lastOp=0;
    auto script=CScriptSystem::GetMe();auto state=script?script->GetLuaState():nullptr;if(!state)return;
    auto g=state->GetGlobals();g.Register("CysPetSoulOpen",Open);g.Register("CysPetSoulAction",Action);g.Register("CysPetSoulData",Data);
    g.Register("CysPetSoulPetInfo",PetInfo);g.Register("CysPetSoulWear",Wear);
    g.Register("CysPetSoulLockInfo",LockInfo);g.Register("CysPetSoulLock",Lock);g.Register("CysPetSoulClearColor",ClearColor);
}
void RememberPet(const pg::GCDetailAttrib_Pet& p){
 int64_t flags[11]={};bool rage=false,max=false,elf=false;pg::deriveDetailAttribPetFlags(p.nf.data(),flags,&rage,&max,&elf);
 if(!p.unknow_7.empty()||!(flags[8]&2))return;
 worn[((unsigned long long)p.guid.m_uHighSection<<32)|p.guid.m_uLowSection]=p.equip_list_6.item_index;
 if(auto e=CEventSystem::GetMe())e->PushEventByName("CYS_PETSOUL_UPDATE",{});
}
void Remember(const pg::ItemInfo_bos& p){
 if(p.item_index/10000000!=7||p.pet_equip_type!=1)return;
 auto key=((unsigned long long)p.guid.world<<48)|((unsigned long long)p.guid.server<<32)|p.guid.series;
 items[key]=p;
}
const pg::ItemInfo_bos* Details(const tObject_Item* item){
 if(!item)return nullptr;USHORT w=0,s=0;UINT id=0;item->GetGUID(w,s,id);
 auto p=items.find(((unsigned long long)w<<48)|((unsigned long long)s<<32)|id);
 return p!=items.end()&&p->second.item_index==item->GetIdTable()?&p->second:nullptr;
}
bool Drop(int bag,const char* target){
    if(!target||strncmp(target,"CYS_SOUL_",9))return false;
    if(busy&&GetTickCount()-sent<5000)return true;
    if(!strcmp(target,"CYS_SOUL_ITEM")){material=-1;colorMaterial=-1;lockMask=0;Ask(0,bag);}
    else if(!strcmp(target,"CYS_SOUL_MATERIAL")){material=bag;if(auto e=CEventSystem::GetMe())e->PushEventByName("CYS_PETSOUL_UPDATE",{});}
    else if(!strcmp(target,"CYS_SOUL_COLOR")){colorMaterial=bag;Changed();}
    return true;
}
bool Dispatch(const pg::Packet& packet){
    if(packet.packetId()==pg::GCPetUseEquipResult::PACKET_ID||packet.packetId()==pg::GCPetUnEquipResult::PACKET_ID){
        const int result=packet.packetId()==pg::GCPetUseEquipResult::PACKET_ID?static_cast<const pg::GCPetUseEquipResult&>(packet).result:static_cast<const pg::GCPetUnEquipResult&>(packet).result;
        TDU_Log("CYS petsoul wear packet=%d result=%d",packet.packetId(),result);
        if(result==1){
            std::unique_ptr<pg::CGAskMyBagList> list(new pg::CGAskMyBagList);list->unknow_1=0;list->size=0;CysModernGame::SendModern(std::move(list));
            busy=false;Ask(0,-1);
        }
        return true;
    }
    if(packet.packetId()!=pg::GCUICommand::PACKET_ID)return false;
    const auto& p=static_cast<const pg::GCUICommand&>(packet);
    if(p.m_nUIIndex==80012701||p.m_nUIIndex==80012702||p.m_nUIIndex==80012708){
        if(!p.m_Param_m_aIntValue.empty()&&p.m_Param_m_aIntValue[0]==1){Ask(0,-1);return true;}return false;
    }
    if(p.m_nUIIndex!=990028)return false;
    if(p.m_Param_m_aIntValue.size()<4)return true;
    memset(snapshot,0,sizeof(snapshot));for(size_t i=0;i<p.m_Param_m_aIntValue.size()&&i<13;++i)snapshot[i]=p.m_Param_m_aIntValue[i];
    revision=snapshot[0];slot=snapshot[3]>0?snapshot[1]:-1;busy=false;
    if(slot<0||lastOp==4)lockMask=0;
    description=DisplayText(p.m_Param_m_aStrValue.c_str());
    TDU_Log("CYS petsoul revision=%d slot=%d item=%d level=%d quality=%d blood=%d exp=%d pending=%d",revision,slot,snapshot[3],snapshot[4],snapshot[5],snapshot[6],snapshot[7],snapshot[12]);
    if(auto e=CEventSystem::GetMe())e->PushEventByName("CYS_PETSOUL_UPDATE",{snapshot[2]?"1":"0"});
    return true;
}
}
