// Included once by CysHost_Wardrobe.cpp. Catalog RPC uses existing typed packets;
// no Lua source is accepted from the server, and owned state changes only on ACK.
#include "CysWardrobeCatalog.h"
#include "PgPackets_core.h"
#include "PgPackets_mission.h"
#include "../WXClient/DataPool/CysOrnamentData.h"
#include "../WXClient/FakeObject/GMFakeObjSystem.h"
#include "../WXClient/DBC/GMDataBase.h"
#include "../WXClient/DataPool/CysSoulVisualData.h"
#include <set>
#include <climits>
namespace CysWardrobeCatalog {
namespace {
struct State { std::set<int> owned; std::map<int,int> positions; int current=0, result=0; bool ready=false; unsigned revision=0; };
State states[10];
int serial=0, pending=0, pendingCat=0, pendingOp=0, pendingId=0;
DWORD sentAt=0;
int previewCat=0, previewVisual=-1;
int previewPosition=-1;
int Appearance(LuaPlus::LuaState* s) {
    auto self=CObjectManager::GetMe()->GetMySelf();
    auto d=self?self->GetCharacterData():nullptr;
    s->PushInteger(d&&d->Get_RaceID()==0?0:1);
    s->PushInteger(d?d->Get_DressVisual():-1);return 2;
}
struct SoulVisual { std::string model,slot; };
const SoulVisual* Soul(int color,int fusion) {
    static std::map<std::pair<int,int>,SoulVisual> visuals;
    static bool loaded=false;
    if(!loaded) {
        loaded=true;
        DBC::DBCFile colors(0),models(0);
        if(CDataBase::Util_OpenDBCFromTxt("PetPossColourRate.txt",&colors) && colors.GetFieldsNum()==43 &&
           CDataBase::Util_OpenDBCFromTxt("CharModelEx.txt",&models) && models.GetFieldsNum()>=2) {
            std::map<int,std::string> names;
            for(int i=0;i<(int)models.GetRecordsNum();++i)
                names[models.Search_Posistion(i,0)->iValue]=models.Search_Posistion(i,1)->pString;
            for(const auto& row:CysSoulVisualData::rows) names.emplace(row.id,row.name);
            const int levels[]={0,3,6,8,10};
            for(int i=0;i<(int)colors.GetRecordsNum();++i) for(int level:levels) {
                auto model=names.find(colors.Search_Posistion(i,9+3*level)->iValue);
                const char* slot=colors.Search_Posistion(i,10+3*level)->pString;
                if(model!=names.end() && slot && (strcmp(slot,"PETObj")==0 || strcmp(slot,"PETObj2")==0 || strcmp(slot,"PETObj3")==0 || strcmp(slot,"PETObj4")==0))
                    visuals[{colors.Search_Posistion(i,0)->iValue,level}]={model->second,slot};
            }
        }
    }
    auto found=visuals.find({color,fusion});return found==visuals.end()?nullptr:&found->second;
}
void Changed() {
    if (CEventSystem::GetMe()) CEventSystem::GetMe()->PushEventByName("CYS_WARDROBE_CHANGED", std::vector<STRING>{});
}
bool OldAcquire() { static const bool off=[](){char b[8]={}; return GetEnvironmentVariableA("CYS_WARDROBE_ACQUIRE_OFF",b,8)>0 && b[0]=='1';}(); return off; }
int Request(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);
    int op=a[1].IsNumber()?a[1].GetInteger():-1, cat=a[2].IsNumber()?a[2].GetInteger():0;
    int id=a[3].IsNumber()?a[3].GetInteger():0;
    if (pending && GetTickCount()-sentAt>10000) { states[pendingCat].result=8; pending=0; }
    if (pending || op<0 || op>4 || cat<1 || cat>9 || id<0 || (cat==8 && op!=0) || (op==3 && cat!=5 && cat!=6) || (op==4 && cat!=1 && cat!=5 && cat!=6 && cat!=7) || !CysModernGame::IsInWorld()) { s->PushInteger(0); return 1; }
    if (op==1 && OldAcquire()) { states[cat].result=9; ++states[cat].revision; Changed(); s->PushInteger(0); return 1; }
    std::unique_ptr<pg::CGExecuteScript> p(new pg::CGExecuteScript);
    if (serial==INT_MAX) serial=0;
    const int seq=++serial;
    p->m_ScriptID=990021; p->set_m_szFunName("Request");
    p->m_aParam={2,seq,op,cat,id};
    if(op==2 && cat==1) {
        if(!a[4].IsNumber() || a[4].GetInteger()<=0) {s->PushInteger(0);return 1;}
        p->m_aParam.push_back(a[4].GetInteger());
    }
    if ((op==2 || op==3) && (cat==5 || cat==6)) {
        const auto row=CysOrnamentData::Find(cat,10000+id);
        if(!row) { s->PushInteger(0); return 1; }
        for(int i=0;i<3;++i) {
            if(!a[4+i].IsNumber()) { s->PushInteger(0); return 1; }
            int value=a[4+i].GetInteger();
            if(value<row->bounds[2*i] || value>row->bounds[2*i+1]) { s->PushInteger(0); return 1; }
            p->m_aParam.push_back(value);
        }
    }
    p->m_uParamCount=(unsigned)p->m_aParam.size();
    if (!CysModernGame::SendModern(std::unique_ptr<pg::Packet>(p.release()))) { s->PushInteger(0); return 1; }
    pending=seq; pendingCat=cat; pendingOp=op; pendingId=id; sentAt=GetTickCount();
    states[cat].result=0;
    s->PushInteger(1); return 1;
}
int Owned(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s); int cat=a[1].IsNumber()?a[1].GetInteger():0, id=a[2].IsNumber()?a[2].GetInteger():0;
    s->PushInteger(cat>0&&cat<10&&states[cat].ready&&states[cat].owned.count(id)?1:0); return 1;
}
int Status(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s); int cat=a[1].IsNumber()?a[1].GetInteger():0;
    if (pending && GetTickCount()-sentAt>10000) { states[pendingCat].result=8; ++states[pendingCat].revision; pending=0; }
    const State& st=states[cat>0&&cat<10?cat:0];
    s->PushInteger(st.ready?1:0); s->PushInteger(pending?1:0); s->PushInteger(st.result);
    s->PushInteger(st.current); s->PushInteger(st.revision); s->PushInteger((int)st.owned.size()); return 6;
}
int PlayAction(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);
    auto fake=CFakeObjSystem::GetMe();
    auto obj=fake?(CObject_PlayerOther*)fake->FindFakeObject("Exterior_Player"):nullptr;
    bool ok=obj && a[1].IsNumber() && a[2].IsNumber() && a[3].IsNumber() &&
        obj->PlayExteriorAction(a[1].GetInteger(),a[2].GetInteger(),a[3].GetInteger());
    s->PushInteger(ok?1:0);return 1;
}
int SetPreview(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s); previewCat=a[1].IsNumber()?a[1].GetInteger():0;
    previewVisual=a[2].IsNumber()?a[2].GetInteger():-1;
    previewPosition=a[3].IsNumber()?a[3].GetInteger():-1;
    return 0;
}
int Position(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);
    int cat=a[1].IsNumber()?a[1].GetInteger():0, id=a[2].IsNumber()?a[2].GetInteger():0;
    const auto row=(cat==5||cat==6)?CysOrnamentData::Find(cat,10000+id):nullptr;
    auto self=CObjectManager::GetMe()->GetMySelf();
    int sex=self&&self->GetCharacterData()->Get_RaceID()==0?0:1;
    int pos=row?row->position[sex]:0x808080;
    if(row) { auto found=states[cat].positions.find(id); if(found!=states[cat].positions.end()) pos=found->second; }
    s->PushInteger(pos&255);s->PushInteger((pos>>8)&255);s->PushInteger((pos>>16)&255);return 3;
}
int AdjustPreview(LuaPlus::LuaState* s) {
    SetPreview(s);
    if(previewCat!=5 && previewCat!=6) return 0;
    auto fake=CFakeObjSystem::GetMe();
    auto obj=fake?(CObject_Character*)fake->FindFakeObject("Exterior_Player"):nullptr;
    const auto row=CysOrnamentData::Find(previewCat,10000+previewVisual);
    if(obj && row && previewPosition>=0 && previewPosition<=0xffffff)
        obj->GetCharacterData()->Set_Ornament(previewCat-5,row->id,previewPosition);
    return 0;
}
}
void Reset() { for(auto& s:states) s=State(); pending=0; previewCat=0; previewVisual=-1; previewPosition=-1; }
bool Ready(int cat) { return cat>0&&cat<10&&states[cat].ready; }
bool Busy() { return pending!=0; }
int PreviewVisual() { return previewVisual; }
int SavedPosition(int cat,int id) {
    if(cat!=5&&cat!=6) return -1;
    auto it=states[cat].positions.find(id);return it==states[cat].positions.end()?-1:it->second;
}
bool Owned(int cat,int id) { return Ready(cat)&&states[cat].owned.count(id)!=0; }
int Current(int cat) { return cat>0&&cat<10?states[cat].current:0; }
int Result(int cat) { return cat>0&&cat<10?states[cat].result:-1; }
void Register(LuaPlus::LuaState* s) {
    if(!s) return;
    auto g=s->GetGlobals(); g.Register("Lua_CysWardrobeRequest",Request); g.Register("Lua_CysWardrobeOwned",Owned);
    g.Register("Lua_CysWardrobeState",Status); g.Register("Lua_CysWardrobePreview",SetPreview);
    g.Register("Lua_CysWardrobePosition",Position);
    g.Register("Lua_CysWardrobeAdjustPreview",AdjustPreview);
    g.Register("Lua_CysWardrobeAppearance",Appearance);
    g.Register("Lua_CysWardrobeAction",PlayAction);
}
bool Dispatch(const pg::Packet& packet) {
    if(packet.packetId()!=pg::GCUICommand::PACKET_ID) return false;
    const auto& p=static_cast<const pg::GCUICommand&>(packet);
    if(p.m_nUIIndex!=990021) return false;
    const auto& v=p.m_Param_m_aIntValue;
    if(!pending||v.size()!=8||v[0]!=2||v[1]!=pending||v[2]!=pendingOp||v[3]!=pendingCat||v[4]!=pendingId||v[5]<0||v[5]>11||v[7]<0||v[7]>10000) return true;
    if(p.m_Param_m_StrCount!=1||p.m_Param_m_aStrOffset.size()!=1||p.m_Param_m_aStrValue.empty()||p.m_Param_m_aStrValue.back()!=0) return true;
    std::set<int> owned; int value=0; bool digit=false;
    const std::string& payload=p.m_Param_m_aStrValue;
    if(payload.size()>60001 || payload.find('\0')!=payload.size()-1) return true;
    const size_t split=payload.find('|');
    if(split==std::string::npos || payload.find('|',split+1)!=std::string::npos) return true;
    std::string str=payload.substr(0,split);str.push_back(0);
    for(size_t i=0;i<str.size();++i) {
        const char c=str[i];
        if(c>='0'&&c<='9') { if(value>(INT_MAX-(c-'0'))/10) return true; value=value*10+c-'0'; digit=true; }
        else if(c==',' || (c==0&&i==str.size()-1)) {
            if(digit) { if(value<=0||!owned.insert(value).second) return true; value=0; digit=false; }
            else if(c==','||i>0) return true;
        } else return true;
    }
    if(owned.size()!=(size_t)v[7]) return true;
    std::map<int,int> positions; int id=0; value=0; digit=false; bool colon=false;
    for(size_t i=split+1;i<payload.size();++i) {
        char c=payload[i];
        if(c>='0'&&c<='9') { if(value>(INT_MAX-(c-'0'))/10) return true; value=value*10+c-'0';digit=true; }
        else if(c==':' && digit && !colon && value>0) {id=value;value=0;digit=false;colon=true;}
        else if(c==',' || c==0) {
            if(digit && colon && value<=0xffffff && owned.count(id) && !positions.count(id)) positions[id]=value;
            else if(!(c==0 && i==split+1)) return true;
            id=value=0;digit=colon=false;
        } else return true;
    }
    if((v[3]==5||v[3]==6)?positions.size()!=owned.size():!positions.empty()) return true;
    State& st=states[v[3]]; st.owned.swap(owned); st.positions.swap(positions); st.current=v[6]; st.result=v[5]; st.ready=true; ++st.revision;
    TDU_Log("CYS-WARDROBE: ack seq=%d op=%d cat=%d id=%d result=%d current=%d owned=%d",v[1],v[2],v[3],v[4],v[5],v[6],v[7]);
    pending=0; Changed(); return true;
}
void Preview(CObject_Character* dst) {
    if(!dst||dst->GetCharacterType()!=CObject_Character::CT_PLAYEROTHER) return;
    auto d=dst->GetCharacterData(); if(!d) return;
    auto actor=dst->GetRenderInterface();
    if(actor) {
        for(const char* slot:{"PETObj","PETObj2","PETObj3","PETObj4"}) actor->Actor_SetObjectProperty(slot,"");
        if(previewCat==8) {
            const auto soul=Soul(previewVisual,previewPosition);
            if(soul) {
                actor->Actor_SetObjectProperty(soul->slot.c_str(),soul->model.c_str());
                actor->Actor_SetUIVisibleFlag();
                TDU_Log("CYS-WARDROBE: soul color=%d fusion=%d slot=%s model=%s",previewVisual,previewPosition,soul->slot.c_str(),soul->model.c_str());
            }
        }
    }
    // Resolve the weapon type before the action: UpdateEquip can be suppressed
    // by an idle animation's hide-weapon flag left on the fake actor.
    static const bool oldWeapon=[](){char b[8]={};return GetEnvironmentVariableA("CYS_WARDROBE_WEAPON_OLD",b,8)>0&&b[0]=='1';}();
    if(!oldWeapon) {
        if(previewCat==7 && previewVisual>=0) d->Set_Equip(HEQUIP_WEAPON,previewVisual);
        ((CObject_PlayerOther*)dst)->RefreshPreviewWeapon(previewCat==7 && previewVisual>=0);
    }
    if(previewVisual<0) return;
    switch(previewCat) {
    case 1:d->Set_DressVisual(previewVisual); break;
    case 2:d->Set_FaceMesh(previewVisual); break;
    case 3:d->Set_HairMesh(previewVisual); break;
    case 4:d->Set_PortraitID(previewVisual); break;
    case 5: case 6: {
        int sex=d->Get_RaceID()==0?0:1;
        const auto r=CysOrnamentData::Find(previewCat,10000+previewVisual);
        if(r) d->Set_Ornament(previewCat-5,r->id,previewPosition>=0&&previewPosition<=0xffffff?previewPosition:r->position[sex]);
        if(previewCat==6) dst->SetFaceDir(3.141592654f);
        break;
    }
    case 7:d->Set_Equip(HEQUIP_WEAPON,previewVisual); break;
    }
}
}
