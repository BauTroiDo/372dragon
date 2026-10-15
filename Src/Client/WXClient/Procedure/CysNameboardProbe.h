#pragma once
#include "CysTooltipContractProbe.h"
#include "../Object/Character/Obj_PlayerNPC.h"

namespace CysNameboardProbe {
struct State {int step=0;DWORD next=0;unsigned npc=0;const char* shot=nullptr;float r[8]={},x=0,z=0;};
inline State& S(){static State s;return s;}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Check(bool ok,const char* why){TDU_Log("CYS-NAMEBOARD: %s %s",ok?"PASS":"FAIL",why);if(!ok)throw std::runtime_error(why);}
inline int Run(CObject_Character* npc,int mode){
    using Fn=int(__cdecl*)(tCreatureBoard*,int,float*);
    auto fn=(Fn)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysNameboardFixtureRun");
    return fn && npc ? fn(npc->GetInfoBoard(),mode,S().r) : -1;
}
inline bool Tick(){
    auto& s=S();if(!CysTooltipContractProbe::Env("CYS_NAMEBOARD_LIVE")||s.step==99)return true;
    if(static_cast<LONG>(GetTickCount()-s.next)<0)return false;
    auto self=CObjectManager::GetMe()->GetMySelf();
    auto npc=static_cast<CObject_Character*>(CObjectManager::GetMe()->FindServerObject(s.npc));
    if(s.step==0){
        if(CGameProcedure::s_pUISystem->IsWindowShow("Quest"))CysTooltipContractProbe::Lua("Quest_Env","this:Hide()");
        unsigned ids[64]={};auto count=CysModernGame::ObjectsNear(self->GetPosition().x,self->GetPosition().z,50,ids,64);
        float best=100000;
        for(unsigned i=0;i<count;++i){auto obj=CObjectManager::GetMe()->FindServerObject(ids[i]);
            if(!obj || !g_theKernel.IsKindOf(obj->GetClass(),GETCLASS(CObject_PlayerNPC)))continue;
            auto candidate=static_cast<CObject_Character*>(obj);
            if(Run(candidate,0)<0 || s.r[5]<180 || s.r[5]>600)continue;
            float score=fabs(s.r[4]-640);
            if(score<best){best=score;s.npc=ids[i];}
        }
        Check(s.npc!=0,"visible live NPC board");
        auto chosen=static_cast<CObject_Character*>(CObjectManager::GetMe()->FindServerObject(s.npc));
        Check(Run(chosen,7)==0,"runtime nameboard overlay loaded");Check(Run(chosen,0)==0,"original server labels fit");s.shot="nameboard-real";
    }
    else if(s.step==1){Check(Run(npc,1)>0,"negative control reproduces clipped long labels");}
    else if(s.step==2){s.shot="nameboard-before";}
    else if(s.step==3){Check(Run(npc,5)>0,"negative control reproduces short name height clipping");Check(Run(npc,6)>0,"negative control restores long labels");Check(Run(npc,2)==0,"long accented name and title fit text area");Check(s.r[0]>250 && s.r[0]<=600 && s.r[1]>=32 && s.r[2]<=600 && s.r[3]>=32,"expanded width and height");Check(s.r[6]==1 && s.r[7]==1,"stacked labels and mouse passthrough");}
    else if(s.step==4){s.shot="nameboard-after";}
    else if(s.step==5){Check(Run(npc,3)==0,"oversize labels wrap without clipping");Check(s.r[0]<=600 && s.r[2]<=600 && s.r[1]>32 && s.r[3]>32 && s.r[6]==1,"wrapped rows expand height without overlap");}
    else if(s.step==6){s.shot="nameboard-wrap";}
    else if(s.step==7){Check(Run(npc,4)==0,"original server labels restored");s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(8),"ground click after label checks");}
    else if(s.step==8){float dx=self->GetPosition().x-s.x,dz=self->GetPosition().z-s.z;Check(dx*dx+dz*dz>4,"movement after nameboards");TDU_Log("CYS-NAMEBOARD: RESULT cases=3 errors=0");s.step=99;return true;}
    ++s.step;s.next=GetTickCount()+(s.step==8?3500:750);return false;
}
}
