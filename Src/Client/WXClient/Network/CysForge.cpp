#include "StdAfx.h"
#include "CysForge.h"
#include "CysModernGame.h"
#include "CysInventoryNet.h"
#include "../Script/GMScriptSystem.h"
#include "../Script/CysCheckedScriptLua.h"
#include "../DataPool/GMDataPool.h"
#include "../Object/Item/Obj_Item.h"
#include "../Input/GMInputSystem.h"
#include "../Procedure/CysAccelTable.h"
#include "CysUiInputBridge.h"
#include "TDUtil.h"
#include <cstring>

namespace CysForge {
namespace {
bool capture=false, held=false;
bool Visible() {
    auto m=GetModuleHandleA("UI_CEGUI.dll");
    auto rect=m?reinterpret_cast<CysUiInputBridge::GetWindowRectUtf8>(GetProcAddress(m,"CysUiGetWindowRectUtf8")):nullptr;
    float r[4]={};return rect && rect("EquipStrengthen_Frame",r)==1;
}
void Eval(const char* text) {
    auto script=CScriptSystem::GetMe();if(!script)return;
    auto result=script->EvaluateScript("EquipStrengthen_Env",text);
    CysCheckedScriptLua::ThrowIfUnusable(result);
    if(!result.ok())TDU_Log("CYS-FORGE: Lua error %s",result.error);
}
int Clock(LuaPlus::LuaState* s){s->PushNumber(static_cast<double>(GetTickCount()));return 1;}
int Capture(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);capture=a[1].IsNumber()&&a[1].GetInteger()!=0;return 0;}
int FindMaterial(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);int id=a[1].IsNumber()?a[1].GetInteger():0;int found=-1;
    auto pool=CDataPool::GetMe();
    if(pool && id>0)for(int i=0;i<CysInventoryNet::BagSize(0);++i){
        auto item=pool->UserBag_GetItem(i);
        if(item&&item->GetIdTable()==id&&!item->IsLocked()){found=i;break;}
    }
    s->PushInteger(found);return 1;
}
}
void RegisterHost() {
    capture=false;held=false;
    auto scripts=CScriptSystem::GetMe();auto s=scripts?scripts->GetLuaState():nullptr;if(!s)return;
    auto globals=s->GetGlobals();globals.Register("CysForge_Clock",Clock);
    globals.Register("CysForge_Capture",Capture);globals.Register("CysForge_FindMaterial",FindMaterial);
}
bool Drop(int bagSlot,const char* target) {
    if(getenv("CYS_FORGE_LIVE"))TDU_Log("CYS-FORGE: drop slot=%d target=%s visible=%d",bagSlot,target?target:"nil",Visible()?1:0);
    if(!target || (strcmp(target,"CYSFORGE0") && strcmp(target,"CYSFORGE1")))return false;
    if(Visible()&&CysModernGame::IsInWorld()){
        char code[96];_snprintf(code,sizeof(code),"CysForge_Drop(%d,%d)",target[8]-'0',bagSlot);Eval(code);
    }
    return true;
}
bool Key(int code,bool down) {
    if(code!=KC_SPACE)return false;
    const bool was=held;held=down;
    if(!capture||!Visible()||!CysModernGame::IsInWorld()||CysAccel::AnyEditActive())return false;
    if(down&&!was)Eval("CysForge_Strike()");
    return true;
}
}
