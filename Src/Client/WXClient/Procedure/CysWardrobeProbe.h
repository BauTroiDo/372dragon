#pragma once
#include "CysUiInputBridge.h"
#include "CysWardrobeCatalog.h"
#include "../Event/GMEventSystem.h"
#include "../Network/CysWorldReplay.h"
#include "../Network/CysRideNet.h"
#include "../Script/GMScriptSystem.h"
#include "../Script/CysCheckedScriptLua.h"
#include "../Object/ObjectManager.h"
#include "../FakeObject/GMFakeObjSystem.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "TDEventDefine.h"
#include "TDUtil.h"
#include "TDGfxSystem.h"
#include "../DataPool/CysOrnamentData.h"
#include "../DataPool/CysExteriorWeaponData.h"
#include "../DataPool/CysHjProbeData.h"
#include <cmath>
namespace CysWardrobeProbe {
struct State {
 bool checked=false,enabled=false,mountOnly=false; int step=0,after=0,cat=1,mode=0,errors=0,item=1,pages=0;
 DWORD at=0,down=0; float x=0,y=0,fromX=0,fromZ=0;
 int before[5]={}; const char* shot=nullptr; char shotBuffer[64]={};
 int positionBefore=0, axis=0, weaponExtra=0; bool adjustOnly=false,relogPosition=false;
 int actionId=0, physicalWeapon=0; STRING animationBefore,bodyMesh,bodyMaterial;
 int hjIndex=0,hjEnd=0,hjCount=0,hjAfter=0,hjRideCase=0; bool hjFunctional=false,hjRelogin=false,hjRideTest=false;
 CysUiInputBridge::SmokePointer pointer=nullptr;
 CysUiInputBridge::GetWindowRectUtf8 rect=nullptr;
};
inline State& S(){static State s;return s;}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline void Check(bool yes,const char* what){if(!yes)++S().errors;TDU_Log("CYS-WARDROBE-PROBE: check=%s cat=%d pass=%d",what,S().cat,yes?1:0);}
inline void Shot(const char* phase){_snprintf(S().shotBuffer,64,"ward-%s-%d",phase,S().cat);S().shot=S().shotBuffer;}
inline void Click(const char* name,int next){
 float r[4]={}; auto& s=S();
 if(s.rect(name,r)!=1){Check(false,name);Go(80);return;}
 s.x=r[0]+r[2]/2;s.y=r[1]+r[3]/2;s.after=next;s.pointer(0,s.x,s.y);Go(90);
 TDU_Log("CYS-WARDROBE-PROBE: click %s",name);
}
inline bool AppearanceMatches(CCharacterData* d,int cat) {
 int v=CysWardrobeCatalog::PreviewVisual();
 switch(cat) {
 case 1:return d->Get_DressVisual()==v;
 case 2:return d->Get_FaceMesh()==v;
 case 3:return d->Get_HairMesh()==v;
 case 4:return d->Get_PortraitID()==v;
 case 5:case 6:return d->Get_OrnamentId(cat-5)==10000+v;
 case 7:return d->Get_WeaponAppearance()==v;
 }
 return false;
}
inline CObject_Character* Portrait(){return (CObject_Character*)CFakeObjSystem::GetMe()->FindFakeObject("Exterior_Player");}
inline void Query(const char* text){char code[160];_snprintf(code,160,"CysWard_Search:SetText('%s'); CysWard_DoSearch()",text);auto r=CScriptSystem::GetMe()->EvaluateScript("NewExterior_DressBox_Env",code);Check(r.ok(),"search-entry");}
inline int ExpectedPosition(){auto d=CObjectManager::GetMe()->GetMySelf()->GetCharacterData();auto r=CysOrnamentData::Find(S().cat,10002);return r?r->position[d->Get_RaceID()==0?0:1]+1+256+65536:-1;}
inline void WeaponReport(){
 auto f=Portrait();STRING right,left;
 if(f&&f->GetRenderInterface()) {f->GetRenderInterface()->Actor_GetObjectProperty("RightWeaponObj",right);f->GetRenderInterface()->Actor_GetObjectProperty("LeftWeaponObj",left);}
 Check(f&&(!right.empty()||!left.empty()),"weapon-model-attached");
 TDU_Log("CYS-WARDROBE-PROBE: weapon item=%d type=%d right=%s left=%s",f?f->GetCharacterData()->Get_Equip(HEQUIP_WEAPON):-1,f?(int)f->GetWeaponType():-1,right.c_str(),left.c_str());
}
inline void WorldWeaponReport(){
 auto world=CObjectManager::GetMe()->GetMySelf();STRING right,left;
 world->GetRenderInterface()->Actor_GetObjectProperty("RightWeaponObj",right);
 world->GetRenderInterface()->Actor_GetObjectProperty("LeftWeaponObj",left);
 auto physical=CDataPool::GetMe()->UserEquip_GetItem(HEQUIP_WEAPON);
 Check((physical?physical->GetParticularID():-1)==S().physicalWeapon,"physical-weapon-preserved");
 Check(world->GetCharacterData()->Get_WeaponAppearance()<0 ? right.empty()&&left.empty() : !right.empty()||!left.empty(),"world-weapon-model-matches-appearance");
 TDU_Log("CYS-WARDROBE-PROBE: world weapon=%d physical=%d right=%s left=%s",world->GetCharacterData()->Get_WeaponAppearance(),physical?physical->GetParticularID():-1,right.c_str(),left.c_str());
}
inline bool Tick(){
 auto& s=S();
 if(!s.checked){
  s.checked=true; char v[8]={};GetEnvironmentVariableA("CYS_WARDROBE_LIVE",v,8);s.mode=atoi(v);s.enabled=s.mode>0;
  if(!s.enabled)return true;
  if(s.mode>=16&&s.mode<=19){
   char range[24]={};const int count=(int)(sizeof(CysHjProbeData::rows)/sizeof(CysHjProbeData::rows[0]));
   GetEnvironmentVariableA("CYS_HJ_START",range,24);s.hjIndex=(std::max)(0,atoi(range));
   GetEnvironmentVariableA("CYS_HJ_COUNT",range,24);int limit=atoi(range);s.hjEnd=(std::min)(count,s.hjIndex+(limit>0?limit:200));
   range[0]=0;GetEnvironmentVariableA("CYS_HJ_AFTER_MODE",range,24);s.hjAfter=atoi(range);
   if(s.hjAfter!=17&&s.hjAfter!=18&&s.hjAfter!=19)s.hjAfter=0;
   s.hjFunctional=s.mode>=17;s.hjRelogin=s.mode==18;s.hjRideTest=s.mode==19;
   if(s.hjFunctional){s.cat=s.hjRideTest?9:1;s.hjEnd=count;}
  }
  if(s.mode==6||s.mode==7){s.adjustOnly=true;s.relogPosition=s.mode==7;s.cat=7;}
  char selected[8]={};GetEnvironmentVariableA("CYS_WARDROBE_ITEM",selected,8);s.item=atoi(selected)==2?2:1;
  if(s.mode==4||s.mode==5) {
   s.mountOnly=true;s.cat=9;s.mode=s.mode==5?3:2;
   GetEnvironmentVariableA("CYS_WARDROBE_MOUNT_ITEM",selected,8);
   s.item=atoi(selected);if(s.item<1||s.item>297)s.item=2;
  }
  HMODULE ui=GetModuleHandleA("UI_CEGUI.dll");
  s.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(ui,"CysUiSmokePointer");
  s.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(ui,"CysUiGetWindowRectUtf8");
  if(!s.pointer||!s.rect){Check(false,"bridge");return true;}
  TDU_Log("CYS-WARDROBE-PROBE: BEGIN mode=%d",s.mode);Go(1);
 }
 if(!s.enabled||s.step==99)return true;
 DWORD age=GetTickCount()-s.at;
 auto d=CObjectManager::GetMe()->GetMySelf()->GetCharacterData();
 int id=s.cat==1?10123999+s.item:s.item;
 char name[96]={};
 switch(s.step){
 case 1:CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP,"1");Go(2);break;
 case 2:if(age>700)Click("SelfEquip_Yirong_Icon",3);break;
 case 3:
  if(age<1500)break;
  Check(CGameProcedure::s_pUISystem->IsWindowShow("NewExterior_DressBox")!=FALSE,"opened-via-player-button");
  if(s.mode>=16&&s.mode<=19){Go(s.hjFunctional?810:800);break;}
   if(s.mode==14||s.mode==15){s.cat=7;Go(700);break;}
  if(s.mode==12||s.mode==13){s.cat=7;Click("CysWard_Tab7",600);} else if(s.mode==11){Go(500);} else if(s.mode==10){s.pages=27;s.item=1;Go(400);} else if(s.mode==9) {Go(340);} else if(s.mode==8) {s.cat=7;Click("CysWard_Tab7",300);} else if(s.adjustOnly)Click("CysWard_Tab7",200);else if(s.mountOnly)Click("CysWard_Tab9",4);else Go(4);break;
 case 4:
  if(!CysWardrobeCatalog::Ready(s.cat)||CysWardrobeCatalog::Busy()){
   if(age>12000){Check(false,"server-snapshot");Shot("timeout");Go(80);}break;
  }
  Check(true,"server-snapshot");Shot("catalog");
  if(s.cat==8){Go(50);break;}
  s.before[0]=d->Get_DressVisual();s.before[1]=d->Get_FaceMesh();s.before[2]=d->Get_HairMesh();s.before[3]=d->Get_Equip(HEQUIP_WEAPON);s.before[4]=d->Get_MountID();
  s.pages=(s.item-1)/16;Go(6);break;
 case 6:
  if(age<300)break;
  if(s.pages>0){--s.pages;Click("CysWard_Next",6);break;}
  if(s.cat==9){Click((s.item-1)%16==0?"CysWard_Item2":"CysWard_Item1",7);break;}
  _snprintf(name,96,"CysWard_Item%d",(s.item-1)%16+1);Click(name,5);break;
 case 7:
  if(age<1200)break;
  {auto fake=(CObject_Character*)CFakeObjSystem::GetMe()->FindFakeObject("Exterior_Ride");
   Check(fake&&fake->GetRenderInterface(),"alternate-mount-preview-entity");Shot("preview-alternate");}
  _snprintf(name,96,"CysWard_Item%d",(s.item-1)%16+1);Click(name,5);break;
 case 5:
  if(age<1000)break;
  if(s.cat==9){auto fake=(CObject_Character*)CFakeObjSystem::GetMe()->FindFakeObject("Exterior_Ride");Check(fake&&fake->GetRenderInterface(),"mount-preview-entity");}
  Check(s.before[0]==d->Get_DressVisual()&&s.before[1]==d->Get_FaceMesh()&&s.before[2]==d->Get_HairMesh()&&s.before[3]==d->Get_Equip(HEQUIP_WEAPON)&&s.before[4]==d->Get_MountID(),"preview-keeps-world");Shot("preview");
  if(s.mode==1){Go(40);break;}
  if(s.mode==3){Check(CysWardrobeCatalog::Owned(s.cat,id),"owned-after-relogin");Check(CysWardrobeCatalog::Current(s.cat)==id,"current-after-relogin");if(s.cat!=9)Check(AppearanceMatches(d,s.cat),"world-appearance-after-relogin");Go(s.cat==9?60:40);break;}
  if(CysWardrobeCatalog::Owned(s.cat,id)){Go(20);break;}
  Click("CysWard_Own",10);break;
 case 10:
  if(age<800||CysWardrobeCatalog::Busy()){if(age>12000){Check(false,"acquire-timeout");Go(80);}break;}
  Check(CysWardrobeCatalog::Owned(s.cat,id),"acquired");Shot("owned");
  if(!CysWardrobeCatalog::Owned(s.cat,id)){Go(40);break;}Go(20);break;
 case 20:
  if(CysWardrobeCatalog::Current(s.cat)==id){Go(s.cat==9?60:40);break;}
  Click("CysWard_Wear",21);break;
 case 21:
  if(age<1500||CysWardrobeCatalog::Busy()){if(age>12000){Check(false,"wear-timeout");Go(80);}break;}
  Check(CysWardrobeCatalog::Current(s.cat)==id,"applied");if(s.cat!=9)Check(AppearanceMatches(d,s.cat),"world-appearance-applied");Shot("applied");Go(s.cat==9?60:40);break;
 case 40:
  if(age<500)break;
  if(s.hjRideTest){if(++s.hjRideCase<4)Go(810);else Go(80);break;}
  if(s.hjFunctional){++s.cat;if(s.cat==8)s.cat=9;if(s.cat>9){Go(80);break;}Go(810);break;}
  s.cat=s.cat==9?8:s.cat+1;_snprintf(name,96,"CysWard_Tab%d",s.cat);Click(name,4);break;
 case 50:
  if(age<800)break;
  Shot("event-only");Click("CysWard_Tab1",51);s.cat=1;break;
 case 51:if(age>800)Click("CysWard_Next",52);break;
 case 52:if(age>500){Shot("page2");Click("CysWard_Prev",53);}break;
 case 53:if(age>500){Click("CysWard_Filter",54);}break;
 case 54:if(age>500){Shot("owned-filter");Click("CysWard_Filter",80);}break;
 case 60:
  if(age<7000)break;
  Click("CysWard_Ride",d->Get_MountID()>=0?61:62);break;
 case 61:
  if(age<7000)break;
  Check(d->Get_MountID()==-1&&!CysRideNet::Pending(),"initial-dismount");Go(60);break;
 case 62:
  if(age<7000)break;
  Check(d->Get_MountID()==CysWardrobeCatalog::PreviewVisual(),"mounted-model");
  Check(!CysRideNet::Pending()&&CysRideNet::Get().timeouts==0,"mount-ack");
  Click("NewExterior_DressBox_Close",63);break;
 case 63:
  if(age<800)break;
  if(s.hjRideTest){
   TDU_Log("CYS-HJ-PROBE: rider case=%d mount=%d sex=%d",s.hjRideCase,d->Get_MountID(),d->Get_RaceID());
   _snprintf(s.shotBuffer,64,"hj-rider-%d",d->Get_MountID());s.shot=s.shotBuffer;
   CysWorldReplay::LiveGroundClick(3);
  }else Shot("mounted-world");
  CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP,"1");Go(64);break;
 case 64:if(age>(s.hjRideTest?2500u:700u))Click("SelfEquip_Yirong_Icon",65);break;
 case 65:if(age>700)Click("CysWard_Tab9",66);break;
 case 66:if(age>1000&&!CysWardrobeCatalog::Busy())Click("CysWard_Ride",67);break;
 case 67:
  if(age<7000)break;
  Check(d->Get_MountID()==-1,"dismounted-model");
  Check(!CysRideNet::Pending()&&CysRideNet::Get().timeouts==0,"dismount-ack");
  Shot("dismounted");Go(40);break;
 case 200:
  if(age<700||CysWardrobeCatalog::Busy())break;
  Check(CysWardrobeCatalog::Ready(7),"weapon-snapshot");
  s.before[3]=d->Get_Equip(HEQUIP_WEAPON);Click("CysWard_Item1",201);break;
 case 201:
  if(age<1300)break;
  WeaponReport();Check(d->Get_Equip(HEQUIP_WEAPON)==s.before[3],"weapon-preview-keeps-world");Shot("weapon-first");Go(202);break;
 case 202:if(age>500)Click("CysWard_Item6",203);break;
 case 203:
  if(age<1500)break;
  WeaponReport();Check(d->Get_Equip(HEQUIP_WEAPON)==s.before[3],"weapon-switch-keeps-world");Shot("weapon-second");Go(204);break;
 case 204:
  if(age<500)break;
  if(s.weaponExtra<4){const int ids[]={279,609,629,634};_snprintf(name,96,"%d",ids[s.weaponExtra]);Query(name);Click("CysWard_Item1",205);}
  else {Query("");s.cat=5;Click("CysWard_Tab5",210);}break;
 case 205:
  if(age<1300)break;
  WeaponReport();Check(d->Get_Equip(HEQUIP_WEAPON)==s.before[3],"extra-weapon-preview-keeps-world");
  _snprintf(name,96,"weapon-extra-%d",s.weaponExtra);Shot(name);++s.weaponExtra;Go(204);break;
 case 210:
  if(age<800||CysWardrobeCatalog::Busy())break;
  Check(CysWardrobeCatalog::Ready(s.cat),"position-snapshot");Click("CysWard_Item2",211);break;
 case 211:
  if(age<800)break;
  Check(CysWardrobeCatalog::Owned(s.cat,2),"position-owned");
  if(s.relogPosition){Check(CysWardrobeCatalog::SavedPosition(s.cat,2)==ExpectedPosition(),"saved-position-relogin");Check(Portrait()->GetCharacterData()->Get_OrnamentPos(s.cat-5)==ExpectedPosition(),"preview-position-relogin");Check(d->Get_OrnamentPos(s.cat-5)==ExpectedPosition(),"world-position-relogin");Shot("position-relogin");Go(230);break;}
  s.positionBefore=d->Get_OrnamentPos(s.cat-5);Click("CysWard_PosDefault",212);break;
 case 212:
  if(age<600)break;
  {auto row=CysOrnamentData::Find(s.cat,10002);Check(Portrait()->GetCharacterData()->Get_OrnamentPos(s.cat-5)==row->position[d->Get_RaceID()==0?0:1],"position-reset-default");}
  s.axis=0;Shot("position-default");Go(213);break;
 case 213:
  if(age<500)break;
  _snprintf(name,96,"CysWard_Pos%cPlus","XYZ"[s.axis]);Click(name,214);break;
 case 214:
  if(age<500)break;
  {auto row=CysOrnamentData::Find(s.cat,10002);int add=s.axis==0?1:(s.axis==1?257:65793);Check(Portrait()->GetCharacterData()->Get_OrnamentPos(s.cat-5)==row->position[d->Get_RaceID()==0?0:1]+add,"position-axis-preview");}
  Check(d->Get_OrnamentPos(s.cat-5)==s.positionBefore,"position-preview-keeps-world");
  if(++s.axis<3)Go(213);else {Shot("position-adjusted");Go(215);}break;
 case 215:if(age>500)Click("CysWard_PosSave",216);break;
 case 216:
  if(age<1200||CysWardrobeCatalog::Busy())break;
  Check(CysWardrobeCatalog::Result(s.cat)==0&&CysWardrobeCatalog::SavedPosition(s.cat,2)==ExpectedPosition(),"position-save-ack");
  Check(d->Get_OrnamentPos(s.cat-5)==ExpectedPosition(),"position-world-updated");
  Shot("position-saved");Go(217);break;
 case 217:if(age>500)Click("CysWard_Item1",218);break;
 case 218:if(age>600)Click("CysWard_Item2",219);break;
 case 219:
  if(age<700)break;
  Check(Portrait()->GetCharacterData()->Get_OrnamentPos(s.cat-5)==ExpectedPosition(),"position-reselect-saved");Go(230);break;
 case 230:
  if(age<500)break;
  if(s.cat==5){s.cat=6;Click("CysWard_Tab6",210);}else Click("NewExterior_DressBox_Close",231);break;
 case 231:if(age>500){CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP,"1");Go(232);}break;
 case 232:if(age>600)Click("SelfEquip_Yirong_Icon",233);break;
 case 233:if(age>700)Click("CysWard_Tab6",234);break;
 case 234:if(age>800&&!CysWardrobeCatalog::Busy())Click("CysWard_Item2",235);break;
 case 235:
  if(age<800)break;
  Check(Portrait()->GetCharacterData()->Get_OrnamentPos(1)==ExpectedPosition(),"position-reopen-saved");Shot("position-reopen");Go(80);break;
 case 340:
  if(age<1500||CysWardrobeCatalog::Busy())break;
  Check(d->Get_DressVisual()==63,"dye-relogin-world");
  Check(CysWardrobeCatalog::Owned(1,10124067),"dye-relogin-owned");
  Check(Portrait()->GetCharacterData()->Get_DressVisual()==63,"dye-relogin-preview");
  Shot("dye-relogin");Go(80);break;
 case 330:if(age>700)Click("CysWard_Item1",301);break;
 case 331:if(age>700)Click("CysWard_Item1",306);break;
 case 332:if(age>700)Click("CysWard_Item1",311);break;
 case 333:if(age>700)Click("CysWard_Item1",315);break;
 case 334:if(age>700)Click("CysWard_Item1",321);break;
 case 300:
  if(age<800||CysWardrobeCatalog::Busy())break;
  Query("=5");Shot("search-level5");Go(330);break;
 case 301:
  if(age<2500)break;
  Check(Portrait()->GetCharacterData()->Get_Equip(HEQUIP_WEAPON)==10100037,"family-level5");WeaponReport();Shot("fx-level5-t1");Go(302);break;
 case 302:if(age>1800){Shot("fx-level5-t2");Go(303);}break;
 case 303:if(age>400)Click("CysWard_LevelPrev",304);break;
 case 304:
  if(age<1000)break;
  Check(Portrait()->GetCharacterData()->Get_Equip(HEQUIP_WEAPON)==10100036,"family-level4");Shot("fx-level4");Go(305);break;
 case 305:if(age>500){Query("=634");Go(331);}break;
 case 306:if(age>2300){WeaponReport();Shot("fx-dragon");s.cat=1;Click("CysWard_Tab1",310);}break;
 case 310:
  if(age<700||CysWardrobeCatalog::Busy())break;
  Query("=10124067");Go(332);break;
 case 311:
  if(age<1400)break;
  Check(Portrait()->GetCharacterData()->Get_DressVisual()==33,"dress-original");Shot("dress-original");Click("CysWard_ColorNext",312);break;
 case 312:
  if(age<1400)break;
  Check(Portrait()->GetCharacterData()->Get_DressVisual()==63,"dress-dye-without-shop-item");Shot("dress-blue");
  if(!CysWardrobeCatalog::Owned(1,10124067))Click("CysWard_Own",313);else Go(313);break;
 case 313:if(age>800&&!CysWardrobeCatalog::Busy())Click("CysWard_Wear",314);break;
 case 314:
  if(age<1400||CysWardrobeCatalog::Busy())break;
  Check(CysWardrobeCatalog::Result(1)==0&&d->Get_DressVisual()==63,"dress-dye-worn");
  Query("=10127578");Go(333);break;
 case 315:
  if(age<2300)break;
  Check(Portrait()->GetCharacterData()->Get_DressVisual()==886,"dress-special-effect-visual");Shot("dress-special-effect");s.cat=8;Click("CysWard_Tab8",320);break;
 case 320:
  if(age<700||CysWardrobeCatalog::Busy())break;
  Query("=2");Go(334);break;
 case 321:
  if(age<1800)break;
  {STRING model;Portrait()->GetRenderInterface()->Actor_GetObjectProperty("PETObj",model);Check(!model.empty(),"soul-model-attached");}
  Shot("soul-color1-level1");Click("CysWard_ColorNext",322);break;
 case 322:if(age>1800){Check(CysWardrobeCatalog::PreviewVisual()==3,"soul-color2");Shot("soul-color2-level1");Click("CysWard_LevelNext",323);}break;
 case 323:if(age>1800){Shot("soul-color2-level2");Click("CysWard_LevelNext",324);}break;
 case 324:if(age>500)Click("CysWard_LevelNext",325);break;
 case 325:if(age>500)Click("CysWard_LevelNext",326);break;
 case 326:
  if(age<2200)break;
  {STRING model;Portrait()->GetRenderInterface()->Actor_GetObjectProperty("PETObj2",model);Check(!model.empty(),"soul-level5-slot");}
  Shot("soul-color2-level5");Check(!CysWardrobeCatalog::Owned(8,2),"soul-preview-not-unlock");s.axis=0;s.item=3;Go(350);break;
 case 350:
  if(age<500)break;
  Query(s.item==3?"=3":"=5");Go(351);break;
 case 351:if(age>700)Click("CysWard_Item1",352);break;
 case 352:if(age>500)Click("CysWard_LevelNext",353);break;
 case 353:
  if(age<500)break;
  if(++s.axis<4) {Go(352);break;}
  Go(354);break;
 case 354:
  if(age<2000)break;
  {STRING model;Portrait()->GetRenderInterface()->Actor_GetObjectProperty("PETObj2",model);Check(!model.empty(),s.item==3?"soul-butterfly-level5-repaired":"soul-wings-level5-repaired");}
  Shot(s.item==3?"soul-butterfly-level5":"soul-wings-level5");
  if(s.item==3){s.axis=0;s.item=5;Go(350);}else Go(80);break;
 case 400:
  if(age<200||CysWardrobeCatalog::Busy())break;
  if(s.pages>0){--s.pages;Click("CysWard_Next",400);}else Click("CysWard_Item8",401);break;
 case 401:
  if(age<2000)break;
  {STRING mesh;Portrait()->GetRenderInterface()->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MESH,mesh);
   Check(mesh=="W_cloth_2026七夕虞姬.mesh","page28-custom-skeleton-mesh");
   Check(Portrait()->GetCharacterData()->Get_DressVisual()==1051,"page28-custom-visual");}
  Shot("page28-custom-pose1");Go(402);break;
 case 402:if(age>1700){Shot("page28-custom-pose2");Go(403);}break;
 case 403:
  if(age<300)break;
  _snprintf(name,96,"CysWard_Item%d",s.item);Click(name,404);break;
 case 404:
  if(age<1300)break;
  {const int expected[]={1046,1047,1048,1049,1050,1054,1053,1051,1052};
   Check(Portrait()->GetCharacterData()->Get_DressVisual()==expected[s.item-1],"page28-each-visual");
   STRING mesh;Portrait()->GetRenderInterface()->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MESH,mesh);
   Check(!mesh.empty(),"page28-each-mesh");
   if(s.item>=8)Check(mesh=="W_cloth_2026七夕虞姬.mesh","page28-reloaded-custom-mesh");}
  _snprintf(name,96,"page28-item%d",s.item);Shot(name);
  if(++s.item<=9)Go(403);else Click("CysWard_Item8",405);break;
 case 405:
  if(age<700||CysWardrobeCatalog::Busy())break;
  if(!CysWardrobeCatalog::Owned(1,10128856))Click("CysWard_Own",406);else Go(406);break;
 case 406:
  if(age<900||CysWardrobeCatalog::Busy())break;
  Check(CysWardrobeCatalog::Owned(1,10128856),"page28-owned");Click("CysWard_Wear",407);break;
 case 407:
  if(age<1800||CysWardrobeCatalog::Busy())break;
  Check(d->Get_DressVisual()==1051,"page28-world-dress");
  {STRING mesh;CObjectManager::GetMe()->GetMySelf()->GetRenderInterface()->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MESH,mesh);Check(mesh=="W_cloth_2026七夕虞姬.mesh","page28-world-mesh");}
  Shot("page28-worn");Click("NewExterior_DressBox_Close",408);break;
 case 408:
  if(age<500)break;
  s.fromX=CObjectManager::GetMe()->GetMySelf()->GetPosition().x;s.fromZ=CObjectManager::GetMe()->GetMySelf()->GetPosition().z;
  CysWorldReplay::LiveGroundClick(4);Go(409);break;
 case 409:
  if(age<1600)break;
  Shot("page28-worn-moving");Go(410);break;
 case 410:
  if(age<2000)break;
  {auto p=CObjectManager::GetMe()->GetMySelf()->GetPosition();Check(std::hypot(p.x-s.fromX,p.z-s.fromZ)>=0.5f,"page28-worn-movement");}
  CysWorldReplay::LiveGroundClick(3);
  CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP,"1");Go(411);break;
 case 411:if(age>800){Shot("page28-selfequip");Click("SelfEquip_Yirong_Icon",412);}break;
 case 412:if(age>800){Query("=10124067");Go(413);}break;
 case 413:if(age>700)Click("CysWard_Item1",414);break;
 case 414:if(age>700)Click("CysWard_ColorNext",415);break;
 case 415:if(age>700)Click("CysWard_Wear",416);break;
 case 416:
  if(age<1300||CysWardrobeCatalog::Busy())break;
  Check(d->Get_DressVisual()==63,"page28-restore-fixture");
  {auto actor=Portrait()->GetRenderInterface();STRING before,after,materialBefore,materialAfter;
   actor->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MESH,before);
   actor->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MAT,materialBefore);
   actor->Actor_SetObjectProperty(szIDSTRING_MAINBODY_MESH,"cys_missing_costume_probe.mesh");
   actor->Actor_SetObjectProperty(szIDSTRING_MAINBODY_MAT,"BaseWhite");
   actor->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MESH,after);
   actor->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MAT,materialAfter);
   Check(!before.empty()&&after==before&&materialAfter==materialBefore,"bad-resource-keeps-outfit");
   actor->Actor_SetObjectProperty(szIDSTRING_MAINBODY_MESH,"");
   actor->Actor_SetObjectProperty(szIDSTRING_MAINBODY_MAT,"BaseWhite");
   actor->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MESH,after);
   Check(after.empty(),"null-entity-material-no-crash");}
  Click("CysWard_Item1",417);break;
 case 417:if(age>700)Click("CysWard_ColorNext",418);break;
 case 418:
  if(age<900)break;
  {STRING mesh;Portrait()->GetRenderInterface()->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MESH,mesh);Check(!mesh.empty(),"preview-recovers-after-bad-resource");}
  Shot("page28-recovered");Go(80);break;
 case 500:Query("=10124067");Go(501);break;
 case 501:if(age>600)Click("CysWard_Item1",502);break;
 case 502:
  if(age<1800)break;
  Check(Portrait()->GetCharacterData()->Get_DressVisual()==33,"aspect-costume-selected");
  Shot("aspect-variants");s.axis=0;Go(503);break;
 case 503:
  if(age<900)break;
  {const int widths[]={355,355,500,355}; const int heights[]={505,350,350,505};
   char code[200];_snprintf(code,200,"NewExterior_DressBox_FakeObject:SetProperty('UnifiedSize','{{0,%d},{0,%d}}')",widths[s.axis],heights[s.axis]);
   auto result=CScriptSystem::GetMe()->EvaluateScript("NewExterior_DressBox_Env",code);Check(result.ok(),"aspect-resize-script");}
  Go(504);break;
 case 504:
  if(age<2000)break;
  {float r[4]={};const int widths[]={355,355,500,355};const int heights[]={505,350,350,505};
   Check(s.rect("NewExterior_DressBox_FakeObject",r)==1&&std::abs(r[2]-widths[s.axis])<1&&std::abs(r[3]-heights[s.axis])<1,"aspect-display-size");
   TDU_Log("CYS-WARDROBE-ASPECT: step=%d width=%.0f height=%.0f",s.axis,r[2],r[3]);}
  _snprintf(name,96,"aspect-size%d",s.axis);Shot(name);
  if(++s.axis<4)Go(503);else Go(505);break;
 case 505:if(age>900){Query("=10128856");Go(506);}break;
 case 506:if(age>600)Click("CysWard_Item1",507);break;
 case 507:
  if(age<2000)break;
  Check(Portrait()->GetCharacterData()->Get_DressVisual()==1051,"aspect-page28-costume");
  Shot("aspect-page28");Go(508);break;
 case 508:if(age>800){Query("=10124067");Go(509);}break;
 case 509:if(age>600)Click("CysWard_Item1",510);break;
 case 510:if(age>1800){Shot("aspect-variants-return");Go(511);}break;
 case 511:if(age>800)Click("NewExterior_DressBox_Close",512);break;
 case 512:if(age>800){CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP,"1");Go(513);}break;
 case 513:if(age>800)Click("SelfEquip_Yirong_Icon",514);break;
 case 514:
  if(age<1800)break;
  Check(CGameProcedure::s_pUISystem->IsWindowShow("NewExterior_DressBox")!=FALSE,"aspect-reopened");
  Shot("aspect-reopened");Go(80);break;
 case 600:
  if(age<1200||CysWardrobeCatalog::Busy())break;
  Check(CysWardrobeCatalog::Ready(s.cat),"action-snapshot");
  s.actionId=s.cat==7?6:s.cat==6?15:s.cat==5?(s.mode==13?18:2):(s.mode==13?10128856:10124067);
  if(s.cat==7){auto item=CDataPool::GetMe()->UserEquip_GetItem(HEQUIP_WEAPON);s.physicalWeapon=item?item->GetParticularID():-1;}
  if(s.mode==13&&s.cat==7){Check(CysWardrobeCatalog::Current(7)==6,"cosmetic-persisted-after-relog");Check(d->Get_WeaponAppearance()==10101018,"world-cosmetic-after-relog");WorldWeaponReport();Go(610);break;}
  _snprintf(name,96,"=%d",s.actionId);Query(name);Go(601);break;
 case 601:if(age>500)Click("CysWard_Item1",602);break;
 case 602:
  if(age<1200)break;
  if(CysWardrobeCatalog::Owned(s.cat,s.actionId))Go(604);else Click("CysWard_Own",603);break;
 case 603:
  if(age<1500||CysWardrobeCatalog::Busy())break;
  Check(CysWardrobeCatalog::Owned(s.cat,s.actionId),"action-item-owned");Go(604);break;
 case 604:
  if(age<800)break;
  if(CysWardrobeCatalog::Current(s.cat)==s.actionId)Go(605);else Click("CysWard_Wear",605);break;
 case 605:
  if(age<1800||CysWardrobeCatalog::Busy())break;
  Check(CysWardrobeCatalog::Current(s.cat)==s.actionId,"action-item-equipped");
  Check(AppearanceMatches(d,s.cat),"action-world-matches-preview");
  if(s.cat==7)WorldWeaponReport();
  Shot("equipped-world");
  if(s.cat==7||s.cat==6){Portrait()->GetRenderInterface()->Actor_GetObjectProperty(s.cat==7?"CysCurrentAnimation":"CysBackAnimation",s.animationBefore);Click("CysWard_Action1",606);}else Go(610);break;
 case 606:
  if(age<450)break;
  {STRING anim;Portrait()->GetRenderInterface()->Actor_GetObjectProperty(s.cat==7?"CysCurrentAnimation":"CysBackAnimation",anim);
   Check(!anim.empty()&&anim!=s.animationBefore,"authored-action-animation-changed");
   if(s.cat==7)Check(anim.find("金箍棒")!=STRING::npos,"weapon-authored-action-not-generic-idle");
   TDU_Log("CYS-WARDROBE-PROBE: action cat=%d before=%s after=%s",s.cat,s.animationBefore.c_str(),anim.c_str());}
  Shot("action-a");Go(607);break;
 case 607:if(age>700){Shot("action-b");Go(s.mode==13&&s.cat==6?620:610);}break;
 case 610:if(age>1500&&!CysWardrobeCatalog::Busy())Click("CysWard_Remove",611);break;
 case 611:
  if(age<2000||CysWardrobeCatalog::Busy())break;
  Check(CysWardrobeCatalog::Current(s.cat)==0,"removed-current-zero");
  Check(CysWardrobeCatalog::Owned(s.cat,s.actionId),"remove-preserves-ownership");
  if(s.cat==7){Check(d->Get_WeaponAppearance()==s.physicalWeapon,"remove-restores-physical-weapon");WorldWeaponReport();}
  else if(s.cat==1)Check(d->Get_DressVisual()==-1,"remove-restores-armor");
  else {Check(d->Get_OrnamentId(s.cat-5)==0,"ornament-removed-world");STRING object;CObjectManager::GetMe()->GetMySelf()->GetRenderInterface()->Actor_GetObjectProperty(s.cat==5?"HeadOrnamentsObj":"BackOrnamentsObj",object);Check(object.empty(),"ornament-model-detached");}
  Shot("removed-world");
  if(s.mode==13&&s.cat==7)s.actionId=961;
  if(s.cat==6)s.actionId=s.mode==13?24:2;
  _snprintf(name,96,"=%d",s.actionId);Query(name);Go(612);break;
 case 612:if(age>500)Click("CysWard_Item1",613);break;
 case 613:if(age>900)Click("CysWard_Wear",614);break;
 case 614:
  if(age<1800||CysWardrobeCatalog::Busy())break;
  Check(CysWardrobeCatalog::Current(s.cat)==s.actionId,"removed-item-can-reequip");
  Check(AppearanceMatches(d,s.cat),"reequip-world-matches-preview");
  if(s.cat==1){Go(80);break;}
  s.cat=s.cat==7?6:s.cat==6?5:1;_snprintf(name,96,"CysWard_Tab%d",s.cat);Click(name,600);break;
 case 620:
  {STRING anim;CObjectManager::GetMe()->GetMySelf()->GetRenderInterface()->Actor_GetObjectProperty("CysBackAnimation",anim);
   if(anim.find("休闲")!=STRING::npos){Check(true,"world-back-natural-idle");TDU_Log("CYS-WARDROBE-PROBE: natural back animation=%s wait_ms=%lu",anim.c_str(),age);Click("NewExterior_DressBox_Close",621);}
   else if(age>45000){Check(false,"world-back-natural-idle-timeout");Go(610);}}break;
 case 621:
  if(age<400)break;
  Shot("natural-back-world");CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP,"1");Go(622);break;
 case 622:if(age>700)Click("SelfEquip_Yirong_Icon",623);break;
 case 623:if(age>1000)Click("CysWard_Tab6",624);break;
 case 624:if(age>1000&&!CysWardrobeCatalog::Busy())Go(610);break;
 case 700:
  if(age<700)break;
  {auto fake=Portrait();Check(fake&&fake->GetRenderInterface(),"cosmetic audit preview");
   if(!fake||!fake->GetRenderInterface()){Go(80);break;}
   fake->GetRenderInterface()->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MESH,s.bodyMesh);
   fake->GetRenderInterface()->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MAT,s.bodyMaterial);
   Check(!s.bodyMesh.empty(),"body exists before cosmetic audit");s.item=0;}Go(701);break;
 case 701:
  if(age<80)break;
   if(s.item>=(s.mode==15?4:(int)(sizeof(CysExteriorWeaponData::rows)/sizeof(CysExteriorWeaponData::rows[0])))){TDU_Log("CYS-WARDROBE-PROBE: cosmetic body audit count=%d errors=%d",s.item,s.errors);Go(80);break;}
   {static const int redWeapons[]={10100037,10192035,10192220,10192307};
    int id=s.mode==15?redWeapons[s.item]:CysExteriorWeaponData::rows[s.item].item;auto fake=(CObject_PlayerOther*)Portrait();
   fake->GetCharacterData()->Set_Equip(HEQUIP_WEAPON,id);fake->RefreshPreviewWeapon(TRUE);
   STRING mesh,mat;fake->GetRenderInterface()->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MESH,mesh);fake->GetRenderInterface()->Actor_GetObjectProperty(szIDSTRING_MAINBODY_MAT,mat);
   if(mesh!=s.bodyMesh||mat!=s.bodyMaterial){Check(false,"cosmetic changed body");TDU_Log("CYS-WARDROBE-PROBE: bad body item=%d before=%s after=%s",id,s.bodyMesh.c_str(),mesh.c_str());}
    if(s.mode==15||id==10100033||id==10100037||id==10100049||id==10100053||id==10100070||id==10100074){s.actionId=id;Go(702);break;}
   ++s.item;Go(701);}break;
 case 702:
  if(age<900)break;
  _snprintf(s.shotBuffer,64,"round2-cosmetic-%d",s.actionId);s.shot=s.shotBuffer;++s.item;Go(701);break;
 case 800:
  if(s.hjIndex>=s.hjEnd){
   TDU_Log("CYS-HJ-PROBE: census count=%d errors=%d",s.hjCount,s.errors);
   if(s.hjAfter){s.hjFunctional=true;s.hjRelogin=s.hjAfter==18;s.hjRideTest=s.hjAfter==19;s.cat=s.hjRideTest?9:1;Go(810);}
   else Go(80);break;
  }
  {
   const auto& row=CysHjProbeData::rows[s.hjIndex];s.cat=row.cat;const int sex=d->Get_RaceID()==0?0:1;
   char code[180];_snprintf(code,180,"assert(CysWard_HJPreview(%d,%d,%d),'HJ preview not found')",row.cat,row.id,row.visual[sex]);
   auto result=CScriptSystem::GetMe()->EvaluateScript("NewExterior_DressBox_Env",code);
   Check(result.ok(),"HJ-preview-dispatch");Go(801);
  }break;
case 801:
  // Let RTT rebinding present the selected model before evidence captures,
  // especially the first mount after switching away from the player avatar.
  if(age<((s.hjCount%40==0||s.hjIndex==s.hjEnd-1)?900u:180u))break;
  {
   const auto& row=CysHjProbeData::rows[s.hjIndex];auto fake=s.cat==9?(CObject_Character*)CFakeObjSystem::GetMe()->FindFakeObject("Exterior_Ride"):Portrait();
   Check(fake&&fake->GetRenderInterface(),"HJ-preview-render-object");
   TDU_Log("CYS-HJ-PROBE: rendered index=%d cat=%d id=%d visual=%d sex=%d",s.hjIndex,s.cat,row.id,row.visual[d->Get_RaceID()==0?0:1],d->Get_RaceID());
   if(s.hjCount%40==0||s.hjIndex==s.hjEnd-1){_snprintf(s.shotBuffer,64,"hj-census-%d",s.hjIndex);s.shot=s.shotBuffer;}
   ++s.hjIndex;++s.hjCount;Go(800);
  }break;
 case 810:
  {
   int total=(int)(sizeof(CysHjProbeData::rows)/sizeof(CysHjProbeData::rows[0]));s.hjIndex=total-1;
   const int mounts[]={2087,2094,2097,2227};
   while(s.hjIndex>=0&&(CysHjProbeData::rows[s.hjIndex].cat!=s.cat||
    (s.hjRideTest&&CysHjProbeData::rows[s.hjIndex].visual[0]!=mounts[s.hjRideCase])))--s.hjIndex;
   if(s.hjIndex<0){Check(false,"HJ-functional-row");Go(80);break;}
   const auto& row=CysHjProbeData::rows[s.hjIndex];char code[180];
   _snprintf(code,180,"assert(CysWard_HJPreview(%d,%d,%d),'HJ selection missing')",s.cat,row.id,row.visual[d->Get_RaceID()==0?0:1]);
   Check(CScriptSystem::GetMe()->EvaluateScript("NewExterior_DressBox_Env",code).ok(),"HJ-functional-select");Go(811);
  }break;
 case 811:
  if(age<800||CysWardrobeCatalog::Busy()||!CysWardrobeCatalog::Ready(s.cat)){if(age>15000){Check(false,"HJ-snapshot-timeout");Go(80);}break;}
  {
   int item=CysHjProbeData::rows[s.hjIndex].id;
   if(s.hjRelogin){Check(CysWardrobeCatalog::Owned(s.cat,item),"HJ-owned-relogin");Go(815);break;}
   if(CysWardrobeCatalog::Owned(s.cat,item)){Go(813);break;}
   Click("CysWard_Own",812);
  }break;
 case 812:
  if(age<500||CysWardrobeCatalog::Busy()){if(age>15000){Check(false,"HJ-own-timeout");Go(80);}break;}
  Check(CysWardrobeCatalog::Owned(s.cat,CysHjProbeData::rows[s.hjIndex].id),"HJ-owned-ack");Go(813);break;
 case 813:Click("CysWard_Wear",814);break;
 case 814:
  if(age<1200||CysWardrobeCatalog::Busy()){if(age>15000){Check(false,"HJ-wear-timeout");Go(80);}break;}
  Go(815);break;
 case 815:
  {
   int item=CysHjProbeData::rows[s.hjIndex].id;Check(CysWardrobeCatalog::Current(s.cat)==item,"HJ-current-server");
   if(s.cat!=9)Check(AppearanceMatches(d,s.cat),"HJ-world-appearance");
   TDU_Log("CYS-HJ-PROBE: functional cat=%d id=%d result=%d current=%d relogin=%d",s.cat,item,CysWardrobeCatalog::Result(s.cat),CysWardrobeCatalog::Current(s.cat),s.hjRelogin?1:0);
   Shot(s.hjRelogin?"hj-relogin":"hj-equipped");Go(s.cat==9&&!s.hjRelogin?60:40);
  }break;
 case 80:
  if(age<500)break;
  Click("NewExterior_DressBox_Close",81);break;
 case 81:
  if(age<500)break;
  Check(CGameProcedure::s_pUISystem->IsWindowShow("NewExterior_DressBox")==FALSE,"closed");
  s.fromX=CObjectManager::GetMe()->GetMySelf()->GetPosition().x;s.fromZ=CObjectManager::GetMe()->GetMySelf()->GetPosition().z;
  CysWorldReplay::LiveGroundClick(4);Go(82);break;
 case 82:
  if(age<3500)break;
  {auto p=CObjectManager::GetMe()->GetMySelf()->GetPosition();float dist=std::sqrt((p.x-s.fromX)*(p.x-s.fromX)+(p.z-s.fromZ)*(p.z-s.fromZ));
   Check(dist>=0.5f,"movement-after-close");TDU_Log("CYS-WARDROBE-PROBE: RESULT errors=%d distance=%.3f",s.errors,dist);Go(99);}break;
 case 90:if(age>=300){s.pointer(1,s.x,s.y);s.down=GetTickCount();Go(91);}break;
 case 91:if(age>=90){DWORD held=GetTickCount()-s.down;s.pointer(2,s.x,s.y);Check(held<=190,"button-hold");s.pointer(0,1,1);Go(s.after);}break;
 }
 return s.step==99;
}
inline const char* ShotName(){const char* p=S().shot;S().shot=nullptr;return p;}
}
