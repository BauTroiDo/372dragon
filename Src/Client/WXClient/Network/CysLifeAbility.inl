// CY packet layouts are generated from the running server. Reuse native action
// and progress handlers after translating fields; never reinterpret wire bytes.
#include "PgPackets_combat.h"
#include "CGUseAbility.h"
#include "CGAskDetailAbilityInfo.h"
#include "GCAbilityAction.h"
#include "GCAbilityResult.h"
#include "GCAbilitySucc.h"
#include "GCNewPlatform.h"
#include "PgPackets_misc.h"
#include "CysCraftingMetadata.h"
#include "../Interface/GMGameInterface.h"
namespace CysLifeAbility {
static int specialSlot=-1;
inline LuaPlus::LuaObject Receiver(LuaPlus::LuaObject globals,const char* name) {
    auto o=globals.GetByName(name);if(o.IsTable())return o;
    if(o.IsUserData()){auto m=o.GetMetaTable();if(m.IsTable()){auto i=m.GetByName("__index");return i.IsTable()?i:m;}}
    return LuaPlus::LuaObject();
}
inline const _DBC_LIFEABILITY_ITEMCOMPOSE* Recipe(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack args(s);if(!args[2].IsNumber())return nullptr;
    DBC_DEFINEHANDLE(db,DBC_LIFEABILITY_ITEMCOMPOSE);
    return db ? reinterpret_cast<const _DBC_LIFEABILITY_ITEMCOMPOSE*>(db->Search_Index_EQU(args[2].GetInteger())) : nullptr;
}
inline int RecipeProfession(LuaPlus::LuaState* s){auto r=Recipe(s);s->PushInteger(r?r->nLifeAbility:-1);s->PushInteger(r?r->NOTCARE:-1);return 2;}
inline int RecipeLevel(LuaPlus::LuaState* s){auto r=Recipe(s);s->PushInteger(r?r->nLifeAbility_Level:0);return 1;}
inline int RecipeEnergy(LuaPlus::LuaState* s){auto r=Recipe(s);s->PushInteger(r?(std::max)(0,r->nAttribute_ID1):0);s->PushInteger(r?(std::max)(0,r->unk_17):0);return 2;}
inline int RecipeContribution(LuaPlus::LuaState* s){auto r=Recipe(s);s->PushInteger(r?(std::max)(0,r->unk_18):0);return 1;}
inline int RecipeSpecial(LuaPlus::LuaState* s){auto r=Recipe(s);s->PushInteger(r && r->nLifeAbility>=46 && r->nLifeAbility<=48?r->nLifeAbility-46:-1);return 1;}
inline int RecipeKind(LuaPlus::LuaState* s){LuaPlus::LuaStack args(s);s->PushString(args[2].IsNumber()?CysRecipeKind(args[2].GetInteger()):"");return 1;}
inline int AbilityLimit(LuaPlus::LuaState* s){LuaPlus::LuaStack args(s);s->PushInteger(args[2].IsNumber()&&args[3].IsNumber()?CysAbilityExpLimit(args[2].GetInteger(),args[3].GetInteger()):0);return 1;}
inline int MaterialTooltip(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack args(s);
    auto item=args[2].IsNumber() && args[2].GetInteger()>0 ? CObject_Item::NewItem(args[2].GetInteger()) : nullptr;
    s->PushString(item ? item->GetName() : "");
    s->PushString(item ? item->GetItemTableTypeDesc() : "");
    char level[48]={};if(item && item->GetNeedLevel()>0)sprintf_s(level,u8"Cấp yêu cầu: %d",item->GetNeedLevel());
    s->PushString(level);
    if(item)CObject_Item::DestroyItem(item);
    return 3;
}
inline int MaterialIcon(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack args(s);
    auto item=args[2].IsNumber() && args[2].GetInteger()>0 ? CObject_Item::NewItem(args[2].GetInteger()) : nullptr;
    s->PushString(item ? item->GetName() : "");s->PushString(item ? item->GetIconName() : "");
    if(item)CObject_Item::DestroyItem(item);
    return 2;
}
inline int RecipeMaximum(LuaPlus::LuaState* s) {
    auto r=Recipe(s);if(!r){s->PushInteger(0);return 1;}
    const int ids[]={r->nStuff1ID,r->nStuff2ID,r->nStuff3ID,r->nStuff4ID,r->nStuff5ID};
    const int nums[]={r->nStuff1num,r->nStuff2num,r->nStuff3num,r->nStuff4num,r->nStuff5num};
    std::map<int,int> needs;int maximum=-1;
    for(int i=0;i<5;++i)if(ids[i]>0){if(nums[i]<=0){s->PushInteger(0);return 1;}needs[ids[i]]+=nums[i];}
    for(const auto& n:needs){int count=CDataPool::GetMe()->UserBag_CountItemByIDTable(n.first)/n.second;maximum=maximum<0?count:(std::min)(maximum,count);}
    // Number of recipe executions; ResultNum is the output of EACH execution.
    s->PushInteger(maximum);return 1;
}
inline int Compose(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack args(s);if(!args[1].IsNumber() || !args[2].IsNumber())return 0;
    auto self=CObjectManager::GetMe()->GetMySelf();
    TDU_Log("CYS crafting: Lua Compose recipe=%d count=%d logic=%d",args[1].GetInteger(),args[2].GetInteger(),self?self->CharacterLogic_Get():-1);
    if(!self || self->CharacterLogic_Get()==CObject_Character::CHARACTER_LOGIC_ABILITY_ACTION)return 0;
    int count=args[2].GetInteger();if(count<1 || count>250)return 0;
    specialSlot=args[3].IsNumber()?args[3].GetInteger():-1;
    if(specialSlot<0 || specialSlot>=200)specialSlot=-1;
    CGameProcedure::s_pGameInterface->Player_UseLifeAbility(args[1].GetInteger(),count);return 0;
}
inline void Register(LuaPlus::LuaState* s) {
    auto globals=s->GetGlobals();auto data=Receiver(globals,"DataPool"),life=Receiver(globals,"LifeAbility");
    if(data.IsTable()){data.Register("GetPrescrList_Item_LifeAbility",RecipeProfession);data.Register("GetPrescrList_Item_LifeAbilityLevel",RecipeLevel);}
    if(life.IsTable()){
        life.Register("GetPrescr_Consume_Vigor_Energy",RecipeEnergy);life.Register("GetPrescr_Consume_ContriAttr",RecipeContribution);
        life.Register("GetPrescr_Item_IsNeedSpecial",RecipeSpecial);life.Register("GetPrescr_Item_Maximum",RecipeMaximum);
        life.Register("GetPrescription_Kind",RecipeKind);life.Register("GetLifeAbility_LimitExp",AbilityLimit);
        life.Register("GetPrescr_Material_Tooltip",MaterialTooltip);life.Register("GetPrescr_Material",MaterialIcon);
    }
    globals.Register("ComposeItem_Begin",Compose);
}
inline bool Owns(uint16_t id) {
    return id==pg::GCDetailAbilityInfo::PACKET_ID || id==pg::GCAbilityExp::PACKET_ID
        || id==pg::GCAbilityLevel::PACKET_ID || id==pg::GCAbilityAction::PACKET_ID
        || id==pg::GCAbilityResult::PACKET_ID || id==pg::GCAbilitySucc::PACKET_ID
        || id==pg::GCPrescription::PACKET_ID || id==pg::GCNewPlatform::PACKET_ID;
}
inline bool Dispatch(const pg::Packet& packet) {
    if (!Owns(packet.packetId())) return false;
    auto self=CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : nullptr;
    if (!self) return true;
    auto data=self->GetCharacterData();
    switch(packet.packetId()) {
    case pg::GCNewPlatform::PACKET_ID: {
        const auto& p=static_cast<const pg::GCNewPlatform&>(packet);
        GCNewPlatform old;WORLD_POS pos;pos.m_fX=p.world_pos_x;pos.m_fZ=p.world_pos_y;
        old.setObjID(p.m_objID);old.setWorldPos(pos);old.setDir(p.dir);old.setType(p.class_);old.Execute(nullptr);
        TDU_Log("CYS crafting: platform=%d type=%u x=%.1f z=%.1f",p.m_objID,p.class_,p.world_pos_x,p.world_pos_y);
        return true;
    }
    case pg::GCPrescription::PACKET_ID: {
        const auto& p=static_cast<const pg::GCPrescription&>(packet);
        if(p.id<2048)data->Set_Prescr(p.id,p.learn_or_abandon!=0);
        return true;
    }
    case pg::GCDetailAbilityInfo::PACKET_ID: {
        const auto& p=static_cast<const pg::GCDetailAbilityInfo&>(packet);
        if(p.m_objID!=static_cast<uint32_t>(self->GetServerID()))return true;
        for(size_t i=0;i<p.m_uAbilityIDList.size() && i<p.m_aAbility.size();++i)
            data->Set_LifeAbility(p.m_uAbilityIDList[i],p.m_aAbility[i].m_Level,p.m_aAbility[i].m_Exp);
        for(size_t i=0;i<p.m_aPrescr.size()*8;++i)
            data->Set_Prescr(static_cast<int>(i),(p.m_aPrescr[i/8]&(1<<(i%8)))!=0);
        TDU_Log("CYS crafting: learned abilities=%u recipe bitmap=%u",unsigned(p.m_aAbility.size()),unsigned(p.m_aPrescr.size()));
        return true;
    }
    case pg::GCAbilityLevel::PACKET_ID: {
        const auto& p=static_cast<const pg::GCAbilityLevel&>(packet);
        data->Set_LifeAbility(p.id,p.level,-1);return true;
    }
    case pg::GCAbilityExp::PACKET_ID: {
        const auto& p=static_cast<const pg::GCAbilityExp&>(packet);
        data->Set_LifeAbility(p.ability,-1,p.exp);return true;
    }
    case pg::GCAbilityAction::PACKET_ID: {
        const auto& p=static_cast<const pg::GCAbilityAction&>(packet);
        GCAbilityAction old;old.setObjID(p.m_objID);old.setLogicCount(p.logic_count);
        old.setAction(p.ability);old.setPrescriptionID(p.prescription);
        old.setTargetID(p.target_obj_id);old.setBeginOrEnd(p.begin_or_end);
        old.Execute(nullptr);return true;
    }
    case pg::GCAbilityResult::PACKET_ID: {
        const auto& p=static_cast<const pg::GCAbilityResult&>(packet);
        GCAbilityResult old;old.SetAbilityID(p.ability);old.SetPrescriptionID(p.prescription);old.setResult(p.result);
        old.Execute(nullptr);
        if(p.result!=0) CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_HIDE);
        TDU_Log("CYS crafting: result ability=%u recipe=%d result=%d",p.ability,p.prescription,p.result);
        return true;
    }
    case pg::GCAbilitySucc::PACKET_ID: {
        const auto& p=static_cast<const pg::GCAbilitySucc&>(packet);
        GCAbilitySucc old;old.SetAbilityID(p.ability);old.SetPrescriptionID(p.prescription);old.SetItemSerial(p.item_index);
        old.Execute(nullptr);
        TDU_Log("CYS crafting: success ability=%u recipe=%d item=%d count=%u",p.ability,p.prescription,p.item_index,p.num);
        return true;
    }
    }
    return true;
}
inline std::unique_ptr<pg::Packet> Translate(Packet* packet) {
    if(packet->GetPacketID()==PACKET_CG_USEABILITY) {
        auto p=static_cast<CGUseAbility*>(packet);
        std::unique_ptr<pg::CGUseAbility> out(new pg::CGUseAbility);
        out->ability=p->GetAbilityID();out->prescription=p->GetPrescriptionID();out->platform=p->GetPlatformGUID();
        out->mat_index=out->ability>=46 && out->ability<=48 && specialSlot>=0?static_cast<uint8_t>(specialSlot):255;
        TDU_Log("CYS crafting: request ability=%u recipe=%d platform=%u",out->ability,out->prescription,out->platform);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    if(packet->GetPacketID()==PACKET_CG_ASKDETAILABILITYINFO) {
        std::unique_ptr<pg::CGAskDetailAbilityInfo> out(new pg::CGAskDetailAbilityInfo);
        out->m_objID=static_cast<CGAskDetailAbilityInfo*>(packet)->getTargetID();
        return std::unique_ptr<pg::Packet>(out.release());
    }
    return nullptr;
}
}
