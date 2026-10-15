#pragma once
// Opt-in owned test15 fixture. Drives real Lua/packets and waits for GC512.
#include "CysInventoryIntegrityProbe.h"
#include "Network/CysPetNet.h"
namespace CysPetMechanicsProbe {
struct State {bool checked=false;int mode=0,step=0,pet=-1,skill=-1;DWORD at=0;};
inline State& S(){static State v;return v;}
inline void Check(bool ok,const char* why){if(!ok){TDU_Log("CYS-PET-MECHANICS FAIL step=%d %s",S().step,why);throw std::runtime_error(why);}}
inline void Go(int step){S().step=step;S().at=GetTickCount();}
inline void Lua(const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript("Pet_Env",code);Check(r.ok(),r.error);}
inline int Skill(int id){for(int i=0;i<12;++i)if(CysPetNet::SkillIdAt(S().pet,i)==id)return i;return -1;}
inline void Points(){auto p=CDataPool::GetMe()->Pet_GetPet(S().pet);Check(p->m_nPot==5&&p->m_nAttrStr==11&&p->m_nAttrSpr==12&&p->m_nAttrDex==13&&p->m_nAttrCon==14&&p->m_nAttrInt==15,"five attribute mapping/budget mismatch");}
inline void Study(){char b[128];sprintf_s(b,"Pet:SkillStudy_Do(1,%d,0)",S().pet);Lua(b);}
inline void Script(int id,const char* method,int n,int v2=0,int v3=0,int v4=0){char b[512];sprintf_s(b,"Clear_XSCRIPT();Set_XSCRIPT_ScriptID(%d);Set_XSCRIPT_Function_Name('%s');Set_XSCRIPT_Parameter(0,200016);Set_XSCRIPT_Parameter(1,22092201);Set_XSCRIPT_Parameter(2,%d);Set_XSCRIPT_Parameter(3,%d);Set_XSCRIPT_Parameter(4,%d);Set_XSCRIPT_ParamCount(%d);Send_XSCRIPT()",id,method,v2,v3,v4,n);Lua(b);}
inline void PetAction(const char* method){char b[128];sprintf_s(b,"Pet:%s(%d)",method,S().pet);Lua(b);}
inline bool Tick(){auto& s=S();
 if(!s.checked){s.checked=true;char b[8]={};GetEnvironmentVariableA("CYS_PET_MECHANICS_LIVE",b,8);s.mode=atoi(b);if(!s.mode)return true;
  char account[32]={};GetEnvironmentVariableA("CYS_BOT_ACCOUNT",account,32);Check(!strcmp(account,"test15")&&CysBagProbe::Env("CYS_GL_LOGIN_SMOKE"),"owned fixture required");
  for(int i=0;i<10;++i){auto p=CDataPool::GetMe()->Pet_GetPet(i);if(p&&p->m_GUID.m_uHighSection==200016&&p->m_GUID.m_uLowSection==22092201)s.pet=i;}
  Check(s.pet>=0,"fixture Pet absent");TDU_Log("CYS-PET-MECHANICS BEGIN mode=%d slot=%d legacy=%d",s.mode,s.pet,CysBagProbe::Env("CYS_PET_ITEM_LEGACY"));Go(0);
 }
 if(!s.mode||s.step==99)return true;
 if(GetTickCount()-s.at<2000)return false;
 switch(s.step){
 case 0:
  if(s.mode==3){Check(Skill(656)<0,"awakening fixture must start without skills");Study();Go(50);break;}
  if(s.mode==2){Check(Skill(1197)>=0&&CysPetNet::Wuxing(s.pet)==10&&CysPetNet::Lingxing(s.pet)==110,"skill/savvy/lingxing not persisted");Points();TDU_Log("CYS-PET-MECHANICS PASS relogin");Go(99);break;}
  Check(Skill(656)<0&&CysBagProbe::Quantity(30402005)==2,"fixture initial book/skill");Study();Go(1);break;
 case 1:
  if(CysBagProbe::Env("CYS_PET_ITEM_LEGACY")){Check(Skill(656)<0&&CysBagProbe::Quantity(30402005)==2,"negative target GUID control mutated Pet/book");TDU_Log("CYS-PET-MECHANICS NEGATIVE PASS missing target GUID detected");Go(99);break;}
  s.skill=Skill(656);Check(s.skill>=0&&CysBagProbe::Quantity(30402005)==1,"book did not learn exactly once");Study();Go(2);break;
 case 2:Check(Skill(656)==s.skill&&CysBagProbe::Quantity(30402005)==1,"duplicate book consumed");Script(311112,"PetSkillLevelup",5,s.skill,1);Go(3);break;
 case 3:Check(Skill(1197)==s.skill&&CysBagProbe::Quantity(30503043)==1,"skill upgrade not applied");{char b[128];sprintf_s(b,"Pet:Add_Attribute(%d,1,2,3,4,5)",s.pet);Lua(b);}Go(4);break;
 case 4:Points();PetAction("PossessionPet");Go(5);break;
 case 5:Check(CysPetNet::PossessionIndex()==s.pet,"possession state not synchronized");Study();Go(6);break;
 case 6:Check(CysBagProbe::Quantity(30402005)==1&&Skill(1197)==s.skill,"possessed Pet accepted study");PetAction("RestorePet");Go(7);break;
 case 7:Check(CysPetNet::PossessionIndex()==-1,"separation state not synchronized");Script(800106,"PetSavvy",3,0);Go(8);break;
 case 8:Check(CysPetNet::Wuxing(s.pet)==1&&CysBagProbe::Quantity(30502000)==1,"first savvy/material incorrect");Script(800124,"Quick_Pet_LXUP",2);Go(9);break;
 case 9:Check(CysPetNet::Lingxing(s.pet)==110,"quick lingxing not applied");Script(800106,"QuickPetSavvy",2);Go(10);break;
 case 10:Check(CysPetNet::Wuxing(s.pet)==10,"quick savvy not applied");PetAction("Go_Fight");Go(11);break;
 case 11:Check(CysPetNet::Get().newPets>0,"summoned Pet never appeared");PetAction("Go_Relax");Go(12);break;
 case 12:TDU_Log("CYS-PET-MECHANICS PASS book duplicate upgrade points possession separation savvy lingxing summon recall");Go(99);break;
 case 50:
  Check(CysPetNet::Lingxing(s.pet)==0&&CysPetNet::Wuxing(s.pet)==5&&Skill(656)>=0&&CysBagProbe::Quantity(30402005)==1,"awakening fixture state/book learning");
  {char b[512];sprintf_s(b,"local a,b,c,d,e,f=Pet:GetPetSkillLevelupInfo(656,%d);assert(a==1197 and b==30503043 and c==30 and d==20000 and e==1200 and f==4724);assert(Pet:GetType(%d)==0)",s.pet,s.pet);Lua(b);}
  Script(800124,"Pet_HH",3,1);Go(51);break;
 case 51:Check(CysPetNet::Lingxing(s.pet)==100&&CysBagProbe::Quantity(30502005)==1,"awakening failed/consumed incorrectly");Script(800124,"Pet_HH",3,1);Go(52);break;
 case 52:
  Check(CysBagProbe::Quantity(30502005)==1,"repeated awakening consumed item");
  {char b[256];sprintf_s(b,"assert(Pet:GetType(%d)==100);assert(Pet:GetRate_LxUp(%d)>0);assert(Pet:GetPercent_LxUp(%d)>0)",s.pet,s.pet,s.pet);Lua(b);}
  Script(800124,"Pet_LXUP",2);Go(53);break;
 case 53:Check(CysPetNet::Lingxing(s.pet)>=100&&CysPetNet::Lingxing(s.pet)<=101&&CysBagProbe::Quantity(20310116)==1,"normal lingxing resources/result");Script(311112,"PetSkillLevelup",5,Skill(656),-1,1);Go(54);break;
 case 54:Check(Skill(1200)>=0,"quick skill upgrade failed");TDU_Log("CYS-PET-MECHANICS PASS awakening replay normal_lingxing quick_skill UI_tables");Go(99);break;
 }
 return s.step==99;
}
}
