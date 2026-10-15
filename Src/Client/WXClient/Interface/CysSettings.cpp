#include "StdAfx.h"
#include "CysSettings.h"
#include "../Variable/GMVariable.h"
#include "../Procedure/CysAccelTable.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Event/GMEventSystem.h"
#include "../Procedure/GameProcedure.h"
#include "LuaPlus.h"
#include <cmath>
namespace CysSettings {
namespace {
const int flagBits[]={-1,1,0,2,17,3,18,16};
std::string Key(int index){auto self=CObjectManager::GetMe()?CObjectManager::GetMe()->GetMySelf():nullptr;return "CysSetup_"+std::to_string(self?self->GetServerGUID():0)+"_"+std::to_string(index);}
double Default(int i){return i==8||i==9||i==10||i==17||i==26||i==29||i==33||i==35||i==38?1:0;}
void Put(int i,double value){CVariableSystem::GetMe()->SetAs_Float(Key(i).c_str(),(float)value,FALSE);}
int Changed(LuaPlus::LuaState* s){s->PushInteger(CysAccel::IsChanged()?1:0);return 1;}
int SetChanged(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);CysAccel::SetChanged(a[2].IsNumber()&&a[2].GetNumber()!=0);return 0;}
int Capture(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);if(a[2].IsBoolean()&&a[2].GetBoolean()&&a[4].IsNumber())CysAccel::BeginCapture(a[4].GetInteger(),a[3].IsBoolean()&&a[3].GetBoolean());else CysAccel::EndCapture();return 0;}
int InputData(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);char plain[48]={},chat[48]={};if(a[2].IsNumber())CysAccel::RowText((int)a[2].GetNumber(),plain,sizeof(plain),chat,sizeof(chat));s->PushString(plain);s->PushString(chat);return 2;}
int Defaults(LuaPlus::LuaState*){CysAccel::RestoreDefaults();return 0;}
int Snapshot(LuaPlus::LuaState*){CysAccel::Snapshot();return 0;}
int Revert(LuaPlus::LuaState*){CysAccel::Revert();return 0;}
int Commit(LuaPlus::LuaState*){if(!CysAccel::Commit())CEventSystem::GetMe()->PushEventByName("NEW_DEBUGMESSAGE",{u8"Không lưu được cấu hình phím."});return 0;}
int ChatAction(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);if(a[2].IsString()&&(a[3].IsNumber()||a[3].IsString()))CEventSystem::GetMe()->PushEventByName("CHAT_MENUBAR_ACTION",{a[2].GetString(),a[3].IsNumber()?std::to_string(a[3].GetNumber()):a[3].GetString()});return 0;}
int TrackAlpha(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);if(a[2].IsNumber()||a[2].IsString())CEventSystem::GetMe()->PushEventByName("TRACK_ALPHA_ACTION",{a[2].IsNumber()?std::to_string(a[2].GetNumber()):a[2].GetString()});return 0;}
int SaveFile(LuaPlus::LuaState*){CVariableSystem::GetMe()->SaveNow();return 0;}
int NonChat(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);CysAccel::SetChatting(a[2].IsNumber()&&a[2].GetNumber()==0);return 0;}
int Classic(LuaPlus::LuaState* s){s->PushInteger(1);return 1;}
int SubBar(LuaPlus::LuaState* s){s->PushInteger((int)Value(24));return 1;}
int SetSubBar(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);if(a[2].IsNumber()){Put(24,a[2].GetNumber()!=0?1:0);CVariableSystem::GetMe()->SaveNow();}return 0;}
LuaPlus::LuaObject Receiver(LuaPlus::LuaObject g,const char* n){auto o=g.GetByName(n);if(o.IsTable())return o;auto m=o.GetMetaTable();auto i=m.GetByName("__index");return i.IsTable()?i:m;}
}
double Value(int index){BOOL have=FALSE;auto value=CVariableSystem::GetMe()->GetAs_Float(Key(index).c_str(),&have);return have?value:Default(index);}
void ApplyRuntime(unsigned flags){
    CGameProcedure::s_pUISystem->SetPaoPaoActive((flags&(1u<<18))==0);
    CysAccel::SetChatting(Value(9)==0);
    auto vars=CVariableSystem::GetMe();
    vars->SetAs_Int("CysQuickbarLocked",(int)Value(12),FALSE);
    vars->SetAs_Int("CysQuickbarNoTooltip",(int)Value(11),FALSE);
    CEventSystem::GetMe()->PushEventByName("CHAT_MENUBAR_ACTION",{"chatbkg",std::to_string(Value(10))});
    CEventSystem::GetMe()->PushEventByName("TRACK_ALPHA_ACTION",{std::to_string(Value(17))});
}
int Get(LuaPlus::LuaState* s,unsigned flags){for(int i=1;i<=39;++i)s->PushNumber(i<=7?((flags>>flagBits[i])&1u):i==16?((flags>>24)&1u):Value(i));return 39;}
unsigned Save(LuaPlus::LuaState* s,unsigned flags){LuaPlus::LuaStack a(s);
    // Validate the complete CY tuple before changing anything. Sliders are REALs.
    for(int i=1;i<=39;++i)if(!a[i+1].IsNumber()||!std::isfinite(a[i+1].GetNumber()))return flags;
    for(int i=1;i<=39;++i){double value=a[i+1].GetNumber();value=(i==10||i==17)?(std::max)(0.0,(std::min)(1.0,value)):(value!=0?1:0);
        if(i<=7||i==16){int bit=i==16?24:flagBits[i];flags=(flags&~(1u<<bit))|(value!=0?(1u<<bit):0);}else Put(i,value);
    }
    ApplyRuntime(flags);
    CVariableSystem::GetMe()->SaveNow();
    CEventSystem::GetMe()->PushEventByName("CYS_SETTINGS_APPLIED",{});
    return flags;
}
void Register(LuaPlus::LuaState* s){Receiver(s->GetGlobals(),"Talk").Register("HandleMainBarAction",ChatAction);Receiver(s->GetGlobals(),"DataPool").Register("HandleGameSetupAction",TrackAlpha);auto t=Receiver(s->GetGlobals(),"SystemSetup");t.Register("GetInputSetup",InputData);t.Register("GetIsConfigChanged",Changed);t.Register("SetIsConfigChanged",SetChanged);t.Register("InputSetup_OnOff",Capture);t.Register("ComeBackAcce",Defaults);t.Register("SaveCurAcceCustom",Snapshot);t.Register("RevertAcceCustom",Revert);t.Register("UseAcceCustomKey",Commit);t.Register("Lua_ViewSetupToFile",SaveFile);t.Register("Lua_SetNonChatActive",NonChat);t.Register("IsClassic",Classic);t.Register("GetSubMenubarState",SubBar);t.Register("SetSubMenubarState",SetSubBar);}
}
