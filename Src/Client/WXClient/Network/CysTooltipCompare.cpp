#include "StdAfx.h"
#include "CysTooltipCompare.h"
#include "../Interface/CysSettings.h"
#include "../Action/GMActionSystem.h"
#include "../Interface/GMInterface_Script_Tooltip.h"
#include "../Object/Item/Obj_Item_Equip.h"
#include "../DataPool/GMDataPool.h"
#include "../Input/GMInputSystem.h"
#include "../Script/GMScriptSystem.h"
#include "../Event/GMEventSystem.h"
#include "TDUtil.h"
#include <string>
#include <vector>
namespace CysTooltipCompare {
namespace {
int actions[2]={INVALID_ID,INVALID_ID};
void Event(const char* name,const std::vector<STRING>& params={}) {CEventSystem::GetMe()->PushEventByName(name,params);}
int Forward(lua_State* L) {
    const int index=static_cast<int>(lua_tonumber(L,lua_upvalueindex(1)));
    auto action=static_cast<CActionItem*>(CActionSystem::GetMe()->GetAction(actions[index]));
    auto& tooltip=SCRIPT_SANDBOX::SuperTooltips::s_SupperTooltip;
    auto original=tooltip.GetActionItem();const int originalId=original?original->GetID():INVALID_ID;
    tooltip.SetActionItem(action);
    const int args=lua_gettop(L);
    lua_pushvalue(L,lua_upvalueindex(2));lua_getglobal(L,"SuperTooltips");
    for(int i=2;i<=args;++i)lua_pushvalue(L,i);
    const int result=lua_pcall(L,args,LUA_MULTRET,0);
    tooltip.SetActionItem(static_cast<CActionItem*>(CActionSystem::GetMe()->GetAction(originalId)));
    if(result) {TDU_Log("CYS tooltip compare: method failed %s",lua_tostring(L,-1));return lua_error(L);}
    return lua_gettop(L)-args;
}
int CloseMain(LuaPlus::LuaState*) {Close();return 0;}
int CloseSub(LuaPlus::LuaState*) {Event("CLOSE_SP_CMP2");return 0;}
int Show(LuaPlus::LuaState* s,bool second) {
    LuaPlus::LuaStack a(s);
    if(!a[5].IsNumber()||a[5].GetInteger()<(second?2:1)||!CActionSystem::GetMe()->GetAction(actions[second?1:0])) {
        if(second)Event("CLOSE_SP_CMP2");else Close();return 0;
    }
    std::vector<STRING> params;
    for(int i=2;i<=6;++i) {if(!a[i].IsNumber())return 0;params.push_back(std::to_string(a[i].GetInteger()));}
    params.push_back("0");Event(second?"SHOW_SP_CMP2":"SHOW_SP_CMP1",params);return 0;
}
int ShowMain(LuaPlus::LuaState* s){return Show(s,false);}
int ShowSub(LuaPlus::LuaState* s){return Show(s,true);}
LuaPlus::LuaObject Table(LuaPlus::LuaObject globals,const char* name) {
    auto o=globals.GetByName(name);if(o.IsTable())return o;
    auto m=o.GetMetaTable();auto i=m.GetByName("__index");return i.IsTable()?i:m;
}
}
void Close() {Event("CLOSE_SP_CMP1");Event("CLOSE_SP_CMP2");}
int Prepare(CActionItem* hovered) {
    actions[0]=actions[1]=INVALID_ID;Close();auto input=CInputSystem::GetMe();
    if(!input||(CysSettings::Value(19)!=0&&!input->IsKeyDown(KC_LMENU)&&!input->IsKeyDown(KC_RMENU))||!hovered||
       (hovered->GetType()!=AOT_ITEM&&hovered->GetType()!=AOT_EQUIP))return 0;
    auto item=static_cast<tObject_Item*>(hovered->GetImpl());if(!item||item->GetItemClass()!=ICLASS_EQUIP)return 0;
    const int point=static_cast<CObject_Item_Equip*>(item)->GetItemType();int points[2]={point,-1};
    if(point==6||point==11){points[0]=6;points[1]=11;}if(point==12||point==13){points[0]=12;points[1]=13;}
    int count=0;
    for(int slot:points) {
        if(slot<0||slot>=CYS_CLIENT_EQUIP_SLOTS)continue;
        auto worn=CDataPool::GetMe()->UserEquip_GetItem(static_cast<HUMAN_EQUIP>(slot));if(!worn||worn==item)continue;
        auto action=CActionSystem::GetMe()->GetAction_ItemID(worn->GetID());if(action)actions[count++]=action->GetID();
    }
    return count;
}
void RegisterHost() {
    auto s=CScriptSystem::GetMe()->GetLuaState();if(!s)return;
    auto globals=s->GetGlobals();auto main=Table(globals,"SuperTooltips");
    main.Register("ShowCmpWindowMain",ShowMain);main.Register("CloseCmpWindowMain",CloseMain);main.Register("CloseCmpWindowSub",CloseSub);
    auto sub=Table(globals,"SuperTooltips2");sub.Register("ShowCmpWindowSub",ShowSub);sub.Register("CloseCmpWindowSub",CloseSub);
    lua_State* L=s->GetCState();const int top=lua_gettop(L);
    lua_getglobal(L,"SuperTooltips");
    if(!lua_istable(L,-1)) {
        lua_getmetatable(L,-1);lua_remove(L,-2);
        lua_pushstring(L,"__index");lua_gettable(L,-2);
        if(lua_istable(L,-1))lua_remove(L,-2);else lua_pop(L,1);
    }
    const int source=lua_gettop(L);
    if(!lua_istable(L,source)){lua_settop(L,top);return;}
    for(int index=0;index<2;++index) {
        // The catalog aliases boxed tooltip receivers to one metatable. Give
        // comparison receivers their own method table; never mutate the shared one.
        lua_newtable(L);lua_pushvalue(L,-1);lua_setglobal(L,index==0?"SuperTooltips_Cmp1":"SuperTooltips_Cmp2");
        const int table=lua_gettop(L);lua_pushnil(L);
        while(lua_next(L,source)) {
            if(lua_type(L,-2)==LUA_TSTRING && lua_isfunction(L,-1)) {
                lua_pushvalue(L,-2);lua_pushnumber(L,index);lua_pushvalue(L,-3);
                lua_pushcclosure(L,Forward,2);lua_settable(L,table);
            }
            lua_pop(L,1);
        }
        lua_pop(L,1);
    }
    lua_settop(L,top);
}
}
