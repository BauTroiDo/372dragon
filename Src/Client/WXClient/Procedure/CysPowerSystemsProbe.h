#pragma once
#include "CysQuickbarProbe.h"
#include "../Network/CysPetSoul.h"
#include "PgPackets_core.h"
#include "PgPackets_mission.h"
namespace CysPowerSystemsProbe {
struct State {int mode=-1,step=0,moves=0,con=0,ice=0,fire=0;DWORD at=0;float x=0,z=0,from[2]={},to[2]={};const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* why){if(!ok)throw std::runtime_error(why);TDU_Log("CYS-POWER-SYSTEMS: PASS %s",why);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline void Lua(const char* env,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(env,code);Check(r.ok(),r.error);}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline int Slot(int id){for(int i=0;i<100;++i){auto p=CDataPool::GetMe()->UserBag_GetItem(i);if(p&&p->GetIdTable()==id)return i;}return -1;}
inline int PetSlot(unsigned low){for(int i=0;i<10;++i){auto p=CDataPool::GetMe()->Pet_GetPet(i);if(p&&p->m_nIsPresent!=-1&&p->m_GUID.m_uHighSection==200016&&p->m_GUID.m_uLowSection==low)return i;}return -1;}
inline void BankSave(unsigned low,int kind,int to=-1){char code[160];sprintf_s(code,"Pet:SavePetIntoBank_PetBank(%d,%d,%d)",PetSlot(low),kind,to);Lua("PetBankList_Env",code);}
inline void Ui(int id,std::initializer_list<int32_t> args){pg::GCUICommand p;p.m_nUIIndex=id;p.m_Param_m_aIntValue=args;p.m_Param_m_IntCount=(uint8_t)p.m_Param_m_aIntValue.size();bool changed=false;Check(CysModernHandlers::Dispatch(p,1,changed),"native NPC window route");}
inline void Execute(int script,const char* fn,std::initializer_list<int32_t> args){
 std::unique_ptr<pg::CGExecuteScript> p(new pg::CGExecuteScript);p->m_ScriptID=script;p->m_szFunName=fn;p->m_aParam=args;p->m_uParamCount=(uint8_t)p->m_aParam.size();Check(CysModernGame::SendModern(std::move(p)),fn);
}
inline bool TickImpl(){auto& s=S();
 if(s.mode<0){const char* e=getenv("CYS_POWER_SYSTEMS_LIVE");s.mode=e?atoi(e):0;if(!s.mode)return true;
  Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"owned test15 fixture");
  auto mod=GetModuleHandleA("UI_CEGUI.dll");auto& b=CysBagProbe::S();
  b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(mod,"CysUiSmokePointer");
  b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(mod,"CysUiGetWindowRectUtf8");
  b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(mod,"CysUiReadActionButtonUtf8");Go(0);
 }
 if(!s.mode||s.step==99)return true;
 if(GetTickCount()-s.at<1200)return false;
 auto self=CObjectManager::GetMe()->GetMySelf();
 switch(s.step){
 case 0:if(s.mode>=5){Execute(892666,"open_pet_bank",{});Go(50);break;}if(s.mode>=3){Go(16);break;}s.con=self->GetCharacterData()->Get_CON();s.ice=self->GetCharacterData()->Get_AttCold();s.fire=self->GetCharacterData()->Get_AttFire();Lua("SelfEquip_Env","OpenShenDingPage()");Go(1);break;
 case 1:
  Check(CysBagProbe::Shown("SelfShenDing"),"ShenDing opens by native entry");
  if(s.mode==2){Lua("SelfShenDing_Env","assert(Player:GetData('LIANDANLUCONVALUE')==15);assert(Player:GetData('YaoChenValue')==4800);local i,f,l,p=Player:GetData('Attack_IFTPValue');assert(i==6 and f==4 and l==0 and p==0)");Go(7);break;}
  Lua("SelfShenDing_Env","assert(Player:GetData('YaoChenValue')==5000);CysShenDingAction(7)");Go(2);break;
 case 2:
  Check(CysBagProbe::Quantity(38000945)==1,"dust consumes one physical item");
  Lua("SelfShenDing_Env","assert(Player:GetData('YaoChenValue')==5200);SelfShenDing_NingLian()");Go(3);break;
 case 3:Check(self->GetCharacterData()->Get_CON()>=s.con+15,"ShenDing changes real character constitution");Lua("SelfShenDing_Env","assert(Player:GetData('LIANDANLUCONVALUE')==15);assert(Player:GetData('LianDanCount')==1);assert(Player:GetData('YaoChenValue')==5000);SelfShenDing2_NingLian()");Go(4);break;
 case 4:Lua("SelfShenDing_Env","assert(Player:GetData('Attack_QianNengPoint')==10);CysShenDingAction(5,6,4,0,0)");Go(5);break;
 case 5:Check(self->GetCharacterData()->Get_AttCold()>=s.ice+6&&self->GetCharacterData()->Get_AttFire()>=s.fire+4,"ShenDing changes real element attacks");Lua("SelfShenDing_Env","assert(Player:GetData('Attack_QianNengPoint')==0);local i,f,l,p=Player:GetData('Attack_IFTPValue');assert(i==6 and f==4 and l==0 and p==0);SelfShenDing_ChangeTabIndex(1)");s.shot="power-shending-attack";Go(7);break;
 case 7:Lua("SelfShenDing_Env","this:Hide();ToggleWuhunPage()");Go(8);break;
 case 8:
  Check(CysBagProbe::Shown("Wuhun"),"equipped Wuhun page opens");
  Lua("Wuhun_Env","assert(DataPool:GetKfsData('LEVEL')==90);local total=0;for i=0,4 do total=total+DataPool:GetFixKfsBase(i) end;assert(total>0);local n,v=DataPool:GetKfsFixAttrEx(0);assert(type(n)=='string' and string.len(n)>0 and v>0)");
  s.shot="power-wuhun-values";Go(9);break;
 case 9:Lua("Wuhun_Env","this:Hide()");if(s.mode==1){Ui(20090721,{self->GetServerID(),2,0});Go(801);}else Go(901);break;
 case 801:Check(CysBagProbe::Shown("WuhunMagicUp"),"native Wuhun compound window");Lua("WuhunMagicUp_Env","WuhunMagicUp_Update(4);WuhunMagicUp_Update_Sub(5)");Go(802);break;
 case 802:Lua("WuhunMagicUp_Env","assert(tonumber(WuhunMagicUp_DemandMoney:GetProperty('MoneyNumber'))==10000);WuhunMagicUp_OnCompound(1)");Go(803);break;
 case 803:Lua("WuhunMagicUp_Env","assert(PlayerPackage:GetBagKfsData(4,'EXTRALEVEL')==2);assert(PlayerPackage:IsBagItemKFS(5)==0);this:Hide()");Check(CysBagProbe::Quantity(10156001)==1,"compound consumes one material soul");CysInventoryIntegrityProbe::Unique();Go(901);break;
 case 901:Lua("Wuhun_Env","XiuLianPage()");Go(10);break;
 case 10:
  Check(CysBagProbe::Shown("Xiulian"),"cultivation opens");
  Lua("Xiulian_Env","for i=0,14 do assert(type(Player:GetXiuLianMiJiInfo(i,'Level'))=='number');assert(EnumAction(i,'xiulianmiji'):GetID()>0) end;assert(EnumAction(2,'xiulianbook'):GetID()>0)");
  if(s.mode==2){Lua("Xiulian_Env","assert(Player:GetXiuLianMiJiInfo(0,'Level')==10);assert(Player:GetXiuLianMiJiInfo(0,'MaxLevel')==20)");Go(16);break;}
  Ui(171717,{self->GetServerID(),1,0,0});Go(1001);break;
 case 1001:Check(CysBagProbe::Shown("XiulianStudy"),"native cultivation study window");Lua("XiulianStudy_Env","XiulianStudy_Skill_Clicked(1);XiulianStudy_UpLevel_Clicked()");Go(11);break;
 case 11:Lua("Xiulian_Env","assert(Player:GetXiuLianMiJiInfo(0,'Level')==10);assert(Player:GetData('POWER')==9967)");Ui(171717,{self->GetServerID(),2,0,0});Go(1101);break;
 case 1101:Lua("XiulianStudy_Env","XiulianStudy_Skill_Clicked(1);XiulianStudy_UpJingJie_Clicked()");Go(12);break;
 case 12:Lua("Xiulian_Env","assert(Player:GetXiuLianMiJiInfo(0,'MaxLevel')==20)");Lua("XiulianStudy_Env","this:Hide()");s.shot="power-cultivation";Go(13);break;
 case 13:Execute(900066,"ConsoleItemUse",{1,70600000,1,0,0,-1});Go(14);break;
 case 14:Check(CysBagProbe::Quantity(70600000)==1,"GM native generator creates real soul instance");Go(16);break;
 case 16:Lua("Xiulian_Env","this:Hide()");Ui(80012701,{1,self->GetServerID()});Go(17);break;
 case 17:
  Check(CysBagProbe::Shown("PetSoul_LevelUp"),"soul interface opens");
  if(s.mode>=3){Lua("Packet_Env","Packet_ChangeTabIndex(0)");s.shot="hj05-soul-before-drag";}
  {char name[96];Check(Slot(70600000)>=0,"soul in bag");CysBagProbe::ButtonName(Slot(70600000),name);CysQuickbarProbe::Center(name,s.from);CysQuickbarProbe::Center("CysSoul_Item",s.to);CysBagProbe::S().pointer(0,s.from[0],s.from[1]);Go(1701);}break;
 case 1701:CysBagProbe::S().pointer(1,s.from[0],s.from[1]);Go(1702);break;
 case 1702:++s.moves;CysBagProbe::S().pointer(0,s.from[0]+(s.to[0]-s.from[0])*s.moves/4,s.from[1]+(s.to[1]-s.from[1])*s.moves/4);if(s.moves==4)Go(1703);break;
 case 1703:CysBagProbe::S().pointer(2,s.to[0],s.to[1]);Go(18);break;
 case 18:
  if(s.mode==4){Lua("PetSoul_LevelUp_Env",u8"local a,b,t=CysPetSoulData();assert(a>=0);assert(string.find(t,'Thọ: 200 / 300',1,true))");Check(CysBagProbe::Quantity(38002520)==1,"life material persists after relogin");Go(25);break;}
  if(s.mode==3){Lua("PetSoul_LevelUp_Env",u8"local a,b,t=CysPetSoulData();assert(a>=0);assert(string.find(t,'Thọ: 100 / 300',1,true))");
   char name[96];Check(Slot(38002520)>=0,"life material in bag");CysBagProbe::ButtonName(Slot(38002520),name);CysQuickbarProbe::Center(name,s.from);CysQuickbarProbe::Center("CysSoul_Material",s.to);s.moves=0;CysBagProbe::S().pointer(0,s.from[0],s.from[1]);Go(1810);break;}
  if(s.mode==2){Lua("PetSoul_LevelUp_Env",u8"local a,b,t=CysPetSoulData();assert(a>=0);assert(string.find(t,'Cấp: 2 / 100',1,true));assert(string.find(t,'Kinh nghiệm: 20',1,true))");Go(25);break;}
  Lua("PetSoul_LevelUp_Env",u8"local a,b,t=CysPetSoulData();assert(a>=0);assert(string.find(t,'Cấp: 1 / 100',1,true));CysPetSoulAction(1)");Go(19);break;
 case 1810:CysBagProbe::S().pointer(1,s.from[0],s.from[1]);Go(1811);break;
 case 1811:++s.moves;CysBagProbe::S().pointer(0,s.from[0]+(s.to[0]-s.from[0])*s.moves/4,s.from[1]+(s.to[1]-s.from[1])*s.moves/4);if(s.moves==4)Go(1812);break;
 case 1812:CysBagProbe::S().pointer(2,s.to[0],s.to[1]);Go(1801);break;
 case 1801:Lua("PetSoul_LevelUp_Env","local a,b=CysPetSoulData();assert(a>=0 and b>=0)");CysQuickbarProbe::Center("CysSoul_Op5",s.to);CysBagProbe::S().pointer(1,s.to[0],s.to[1]);Go(1803);break;
 case 1803:CysBagProbe::S().pointer(2,s.to[0],s.to[1]);Go(1802);break;
 case 1802:Lua("PetSoul_LevelUp_Env",u8"local a,b,t=CysPetSoulData();assert(string.find(t,'Thọ: 200 / 300',1,true))");Check(CysBagProbe::Quantity(38002520)==1,"life restore consumes exactly one material");CysInventoryIntegrityProbe::Unique();Go(25);break;
 case 19:Lua("PetSoul_LevelUp_Env",u8"local a,b,t=CysPetSoulData();assert(string.find(t,'Cấp: 2 / 100',1,true))");Check(CysPetSoul::Drop(Slot(38002515),"CYS_SOUL_MATERIAL"),"material drop");Go(20);break;
 case 20:Lua("PetSoul_LevelUp_Env","CysPetSoulAction(2)");Go(21);break;
 case 21:Check(CysBagProbe::Quantity(38002515)==3,"blood feed consumes one");Lua("PetSoul_LevelUp_Env","CysPetSoulAction(3)");Go(22);break;
 case 22:Lua("PetSoul_LevelUp_Env","local a,b,t,p=CysPetSoulData();assert(p==1 and string.len(t)>200)");s.shot="power-soul-preview";Go(23);break;
 case 23:Lua("PetSoul_LevelUp_Env","CysPetSoulAction(4)");Go(24);break;
 case 24:Lua("PetSoul_LevelUp_Env","local a,b,t,p=CysPetSoulData();assert(p==0);assert(CysSoulPetIndex>=0)");Check(CysBagProbe::Quantity(38002532)==3,"wash uses one material");CysInventoryIntegrityProbe::Unique();s.shot="power-soul-applied";Lua("PetSoul_LevelUp_Env","CysPetSoulWear(CysSoulPetIndex,0)");Go(2401);break;
 case 2401:Check(CysBagProbe::Quantity(70600000)==0,"equipping removes soul from bag");Lua("PetSoul_LevelUp_Env","local n,id=CysPetSoulPetInfo(CysSoulPetIndex);assert(id==70600000)");Go(2402);break;
 case 2402:Lua("PetSoul_LevelUp_Env","CysPetSoulWear(CysSoulPetIndex,1)");Go(2403);break;
 case 2403:Check(CysBagProbe::Quantity(70600000)==1,"unequipping returns exactly one soul");Lua("PetSoul_LevelUp_Env","local n,id=CysPetSoulPetInfo(CysSoulPetIndex);assert(id<1)");CysInventoryIntegrityProbe::Unique();Check(CysPetSoul::Drop(Slot(70600000),"CYS_SOUL_ITEM"),"inspect returned soul");Go(25);break;
 case 50:
  Check(CysBagProbe::Shown("PetBankMain")&&CysBagProbe::Shown("PetBankList"),"bank opens through server VIP entry");
  Lua("PetBankMain_Env","assert(Bank:GetNpcId()==-1);assert(PetBankMain_StopWatch:IsVisible());assert(PetBankMain_Watch_Text:IsVisible())");
  s.shot="hj05-bank-main";Go(500);break;
 case 500:
  Lua("PetBankMain_Env","assert(Pet:GetPet_Count_PetBank()==2);assert(Pet:IsPresent_PetBank(0)==0);assert(Pet:IsPresent_PetBank(2)==1);assert(Pet:IsPresent_PetBank(7)==1);PetBankMain_List:SetItemSelectByItemID(7);PetBankMain_List_Selected();PetBankMain_Choose_Click()");Go(501);break;
 case 501:{
  Check(CysBagProbe::Shown("TargetPet"),"bank detail window visible");
  auto p=CDataPool::GetMe()->TargetPet_GetPet();Check(p&&p->m_GUID.m_uLowSection==22092804,"inspect selects exact bank GUID");
  Check(p->m_nAttrStrApt>0&&p->m_nAttrIntApt>p->m_nAttrStrApt,"bank inspect shows distinct real aptitude columns");
  Lua("TargetPet_Env","assert(TargetPet:GetGeneration()==100 and TargetPet:GetLixing()==0);assert(Pet:GetGeneration(0)==100 and Pet:GetLixing(0)==0);assert(TargetPet:GetSavvy()==0);assert(TargetPet:GetCriticalAttack()>0);assert(string.find(TargetPet_StrAptitude:GetText(),tostring(TargetPet:GetStrAptitude()),1,true));assert(string.find(TargetPet_NimbusAptitude:GetText(),tostring(TargetPet:GetIntAptitude()),1,true))");
  Lua("TargetPet_Env","assert(TargetPet:GetStrAptitude()==1237);assert(TargetPet:GetIntAptitude()==2348);assert(TargetPet:GetPFAptitude()==3459);assert(TargetPet:GetDexAptitude()==4570);assert(TargetPet:GetStaAptitude()==5681);assert(TargetPet:GetInt()==10 and TargetPet:GetPF()==4 and TargetPet:GetSta()==17)");
  s.shot="hj05-bank-inspect";
  if(s.mode==6){Check(PetSlot(22092801)>=0&&PetSlot(22092803)>=0&&PetSlot(22092802)<0&&PetSlot(22092804)<0,"bank ownership persists after relogin");Lua("PetBankMain_Env","local a,b=Pet:GetPetGUIDByIndex_PetBank(2);assert(a==200016 and b==22092802)");Go(55);break;}
  Lua("PetBankList_Env","PetBankList_List:SetItemSelectByItemID(0);PetBankList_List_Selected();PetBankList_Refuse_Click()");Go(51);break;}
 case 51:Check(PetSlot(22092801)<0&&PetSlot(22092802)>=0,"deposit removes exact source from bag");Lua("PetBankMain_Env","assert(Pet:GetPet_Count_PetBank()==3);local a,b=Pet:GetPetGUIDByIndex_PetBank(0);assert(a==200016 and b==22092801)");BankSave(22092802,2,2);Go(52);break;
 case 52:Check(PetSlot(22092802)<0&&PetSlot(22092803)>=0,"swap replaces exact pet");Lua("PetBankMain_Env","assert(Pet:GetPet_Count_PetBank()==3);local a,b=Pet:GetPetGUIDByIndex_PetBank(2);assert(b==22092802);PetBankMain_List:SetItemSelectByItemID(0);PetBankMain_List_Selected();PetBankMain_Refuse_Click()");Go(53);break;
 case 53:Check(PetSlot(22092801)>=0&&PetSlot(22092803)>=0&&PetSlot(22092802)<0,"withdraw restores exact pet once");Lua("PetBankMain_Env","assert(Pet:GetPet_Count_PetBank()==2);assert(Pet:IsPresent_PetBank(0)==0)");s.shot="hj05-bank-after-transfer";Go(531);break;
 case 531:BankSave(22092801,1);Go(532);break;
 case 532:Check(PetSlot(22092801)<0,"first empty-bag deposit acknowledged");BankSave(22092803,1);Go(533);break;
 case 533:Lua("PetBankList_Env","assert(Pet:GetPet_Count()==0);assert(Pet:GetFirstPetPosInPag()==-1);PetBankList_UpdateFrame()");Lua("PetBankMain_Env","assert(Pet:GetPet_Count_PetBank()==4);Pet:SavePetIntoBank_PetBank(0,0)");Go(534);break;
 case 534:Check(PetSlot(22092801)>=0,"withdraw from empty bag returns exact pet");Lua("PetBankMain_Env","Pet:SavePetIntoBank_PetBank(1,0)");Go(535);break;
 case 535:Check(PetSlot(22092801)>=0&&PetSlot(22092803)>=0&&PetSlot(22092802)<0,"empty-bag roundtrip restores ownership");Lua("PetBankMain_Env","assert(Pet:GetPet_Count_PetBank()==2);assert(Pet:IsPresent_PetBank(0)==0);assert(Pet:IsPresent_PetBank(1)==0)");Go(55);break;
 case 55:Lua("PetBankMain_Env","PetBankMain_Close_Click()");Go(26);break;
 case 25:s.shot="power-soul-applied";Lua("PetSoul_LevelUp_Env","this:Hide()");if(CysBagProbe::Shown("Packet"))CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);Go(26);break;
 case 26:s.x=self->GetPosition().x;s.z=self->GetPosition().z;Check(CysWorldReplay::LiveGroundClick(7),"movement input after power windows");Go(27);break;
 case 27:if(GetTickCount()-s.at<3000)break;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"character moves after UI closes");TDU_Log("CYS-POWER-SYSTEMS: RESULT mode=%d errors=0",s.mode);s.step=99;return true;
 }
 return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-POWER-SYSTEMS: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}

