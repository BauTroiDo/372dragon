#pragma once
// Opt-in, isolated test15 only. Real Lua/buttons + network; never forces a refresh.
#include "CysBagProbe.h"
#include "PgPackets_item.h"
#include "PgPackets_misc.h"
#include <set>
#include <sstream>

namespace CysInventoryIntegrityProbe {
struct State {
    int step=0, mode=0, after=0; DWORD at=0; bool checked=false, right=false;
    float x=0,y=0; unsigned packs=0,splits=0; std::string before;
    unsigned __int64 tail=0; const char* shot=nullptr;
};
inline State& S(){static State s;return s;}
inline void Check(bool value,const char* why){if(!value){TDU_Log("CYS-INVENTORY-LIVE FAIL step=%d %s",S().step,why);throw std::runtime_error(why);}}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline CDataPool* Pool(){return CDataPool::GetMe();}
inline void Lua(const char* code){const auto r=CScriptSystem::GetMe()->EvaluateScript("Packet_Env",code);Check(r.ok(),r.error);}
inline int Find(int id){for(int i=0;i<100;++i){auto p=Pool()->UserBag_GetItem(i);if(p&&p->GetIdTable()==id)return i;}return -1;}
inline std::string Fingerprint(){std::ostringstream out;for(int i=0;i<220;++i){auto p=Pool()->UserBag_GetItem(i);if(p)out<<i<<':'<<p->GetGUID()<<':'<<p->GetIdTable()<<':'<<p->GetNumber()<<';';}return out.str();}
inline void Unique(){std::set<unsigned __int64> ids;for(int i=0;i<220;++i){auto p=Pool()->UserBag_GetItem(i);if(p)Check(ids.insert(p->GetGUID()).second,"duplicate GUID in client bag");}}
inline void Swap(int from,int to){std::unique_ptr<pg::CGPackage_SwapItem> p(new pg::CGPackage_SwapItem);p->index_from=from;p->index_to=to;p->count=0;Check(CysModernGame::SendModern(std::move(p)),"swap send failed");}
inline void Unequip(int point){std::unique_ptr<pg::CGUnEquip> p(new pg::CGUnEquip);p->equipPoint=point;Check(CysModernGame::SendModern(std::move(p)),"unequip send failed");}
inline void Click(const char* name,bool right,int next){auto& s=S();float r[4]={};Check(CysBagProbe::S().rect(name,r)==1,"button not visible");s.x=r[0]+r[2]/2;s.y=r[1]+r[3]/2;s.right=right;s.after=next;Check(CysBagProbe::S().pointer(0,s.x,s.y)==1,"hover failed");TDU_Log("CYS-INVENTORY-LIVE click=%s right=%d",name,right);Go(90);}
inline void EquipSlot(int index,int next){Check(index>=0,"equipment missing in bag");char name[96];CysBagProbe::ButtonName(index,name);Click(name,true,next);}
inline void Snapshot(const char* phase,int tab){CysBagProbe::Snapshot(phase,tab);Check(CysBagProbe::S().errors==0,"rendered slots differ from authoritative bag");Unique();TDU_Log("CYS-INVENTORY-LIVE snapshot=%s prop=%d material=%d fingerprint=%s",phase,CysInventoryNet::BagSize(0),CysInventoryNet::BagSize(1),Fingerprint().c_str());S().shot=phase;}
inline bool Tick(){
 auto& s=S();
 if(!s.checked){
  s.checked=true;char mode[8]={};GetEnvironmentVariableA("CYS_INVENTORY_INTEGRITY_LIVE",mode,8);s.mode=atoi(mode);if(!s.mode)return true;
  char account[32]={};GetEnvironmentVariableA("CYS_BOT_ACCOUNT",account,32);Check(!strcmp(account,"test15")&&CysBagProbe::Env("CYS_GL_LOGIN_SMOKE"),"owned test15 required");
  HMODULE ui=GetModuleHandleA("UI_CEGUI.dll");auto& b=CysBagProbe::S();
  b.pointer=reinterpret_cast<CysUiInputBridge::SmokePointer>(GetProcAddress(ui,"CysUiSmokePointer"));
  b.rect=reinterpret_cast<CysUiInputBridge::GetWindowRectUtf8>(GetProcAddress(ui,"CysUiGetWindowRectUtf8"));
  b.read=reinterpret_cast<CysUiInputBridge::ReadActionButtonUtf8>(GetProcAddress(ui,"CysUiReadActionButtonUtf8"));
  Check(b.pointer&&b.rect&&b.read,"UI bridge unavailable");
  TDU_Log("CYS-INVENTORY-LIVE BEGIN mode=%d old_pack=%d",s.mode,CysBagProbe::Env("CYS_BAG_PACK_OLD"));Go(0);
 }
 if(!s.mode||s.step==99)return true;
 DWORD age=GetTickCount()-s.at;auto counters=CysInventoryNet::Get();
 if(s.step<90 && age<1400)return false;
 switch(s.step){
 case 0:
  if(!CysBagProbe::Shown("Packet"))CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);
  Go(s.mode==2?50:1);break;
 case 1:
  Check(CysInventoryNet::BagSize(0)==20&&CysInventoryNet::BagSize(1)==20,"fixture initial size must be 20/20");Snapshot("inventory-base20",0);EquipSlot(0,2);break;
 case 2:
  Check(CysInventoryNet::BagSize(0)==40,"wearing bag did not expand to 40");Snapshot("inventory-base40",0);EquipSlot(1,3);break;
 case 3:
  Check(CysInventoryNet::BagSize(1)==40,"wearing material box did not expand to 40");Click("Packet_Stall",false,4);break;
 case 4:
  Snapshot("inventory-material40",1);Click("Packet_Material",false,5);break;
 case 5:
  Check(Pool()->UserBag_GetItem(19)!=nullptr,"fixture tail item absent");s.tail=Pool()->UserBag_GetItem(19)->GetGUID();Swap(19,39);Go(6);break;
 case 6:
  Check(Pool()->UserBag_GetItem(39)&&Pool()->UserBag_GetItem(39)->GetGUID()==s.tail,"expanded tail move lost GUID");s.before=Fingerprint();Unequip(9);Go(7);break;
 case 7:
  Check(s.before==Fingerprint()&&CysInventoryNet::BagSize(0)==40&&Pool()->UserEquip_GetItem((HUMAN_EQUIP)9),"occupied tail allowed bag shrink");Snapshot("inventory-shrink-rejected",0);Swap(39,19);Go(8);break;
 case 8:Unequip(9);Go(9);break;
 case 9:
  Check(CysInventoryNet::BagSize(0)==20&&!Pool()->UserEquip_GetItem((HUMAN_EQUIP)9),"valid shrink with retained slot19 occupied rejected");Snapshot("inventory-shrink20",0);EquipSlot(Find(10141025),10);break;
 case 10:
  Check(CysInventoryNet::BagSize(0)==40,"re-expansion failed");EquipSlot(Find(10141021),11);break;
 case 11:
  Check(CysInventoryNet::BagSize(0)==24,"smaller bag swap did not yield 24");Snapshot("inventory-base24",0);Unequip(9);Go(12);break;
 case 12:
  Check(CysInventoryNet::BagSize(0)==20,"smaller bag removal failed");s.before=Fingerprint();Swap(19,99);Swap(19,100);Swap(19,19);Go(13);break;
 case 13:
  Check(s.before==Fingerprint(),"invalid/self/cross-region move changed inventory");Snapshot("inventory-invalid-rejected",0);s.packs=counters.packs;s.before=Fingerprint();Click("Packet_Classify",false,14);break;
 case 14:
  if(CysBagProbe::Env("CYS_BAG_PACK_OLD")){
   Check(counters.packs==s.packs&&s.before==Fingerprint(),"negative pack control unexpectedly executed");
   TDU_Log("CYS-INVENTORY-LIVE NEGATIVE PASS missing pack transport detected");Go(98);break;
  }
  Check(counters.packs==s.packs+1,"sort server acknowledgement absent");
  {int last=0;bool empty=false;for(int i=0;i<20;++i){auto p=Pool()->UserBag_GetItem(i);if(!p){empty=true;continue;}Check(!empty&&int(p->GetIdTable())>=last,"server did not pack/sort slots");last=p->GetIdTable();}}
  Snapshot("inventory-sorted",0);s.splits=counters.splits;
  Pool()->Split_SetItemConta(tObject_Item::IO_MYSELF_PACKET);Pool()->Split_SetItemPos(Find(30602002));Lua("PlayerPackage:SplitItem(2)");Go(15);break;
 case 15:
  Check(counters.splits==s.splits+1&&CysBagProbe::Quantity(30602002)==16,"split changed total quantity or lacked reply");Snapshot("inventory-split",0);EquipSlot(Find(10141025),16);break;
 case 16:
  Check(CysInventoryNet::BagSize(0)==40&&CysInventoryNet::BagSize(1)==40,"final expanded sizes incorrect");Snapshot("inventory-final40",0);
  TDU_Log("CYS-INVENTORY-LIVE PASS expanded/shrink/sort/split/invalid packets");Go(98);break;
 case 50:
  Check(CysInventoryNet::BagSize(0)==40&&CysInventoryNet::BagSize(1)==40,"expanded sizes not persisted");
  Check(CysBagProbe::Quantity(30602002)==16,"quantity not persisted");Snapshot("inventory-relogin-base40",0);Click("Packet_Stall",false,51);break;
 case 51:
  Snapshot("inventory-relogin-material40",1);TDU_Log("CYS-INVENTORY-LIVE PASS relogin expanded inventory");Go(98);break;
 case 90:
  if(age<300)break;Check(CysBagProbe::S().pointer(s.right?3:1,s.x,s.y)==1,"mouse down failed");Go(91);break;
 case 91:
  Check(CysBagProbe::S().pointer(s.right?4:2,s.x,s.y)==1,"mouse up failed");Go(s.after);break;
 case 98:
  if(CysBagProbe::Shown("Packet"))CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);
  Go(99);break;
 }
 return s.step==99;
}
inline const char* ShotName(){const char* p=S().shot;S().shot=nullptr;return p;}
}
