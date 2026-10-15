#include "StdAfx.h"
#include "CysPlayerShopNet.h"
#include "CysModernGame.h"
#include "CysModernHandlers.h"
#include "CysPetNet.h"
#include "CysItemWireCount.h"
#include "PgPackets_shop.h"
#include "PgPackets_item.h"
#include "PgPackets_pet.h"
#include "PgPackets_pet_detail_types.h"
#include "PgPackets_misc.h"
#include "PgPackets_movement.h"
#include "CGPlayerShopAcquireShopList.h"
#include "CGPlayerShopAcquireItemList.h"
#include "CGPlayerShopApply.h"
#include "CGPlayerShopEstablish.h"
#include "CGPlayerShopOnSale.h"
#include "CGPlayerShopBuyItem.h"
#include "CGPlayerShopOpenStall.h"
#include "CGPlayerShopMoney.h"
#include "CGItemSynch.h"
#include "ItemSynchStructDefine.h"
#include "../DataPool/GMDataPool.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Object/Item/Obj_Item.h"
#include "../Event/GMEventSystem.h"
#include "../Action/GMActionSystem.h"
#include "../Script/GMScriptSystem.h"
#include "../DBC/GMDataBase.h"
#include "TDDBC_Struct.h"
#include "TDUtil.h"
#include <map>
#include <cstring>

namespace CysPlayerShopNet { namespace {
bool active[2]={};int selectedShop=-1,serverOpen=0;
int activeIds[2]={};
// Full CY instance details follow the native shop list. These display-only
// positions are outside every bag/bank range; they never become inventory slots.
constexpr unsigned DetailBase=1000,DetailSlots=2*MAX_STALL_NUM_PER_SHOP*STALL_BOX_SIZE;
pg::ItemGUID expected[DetailSlots]{};
std::map<uint64_t,pg::GCDetailAttrib_Pet> petDetails;
std::vector<unsigned> listIds;
std::vector<int> searchRows;
CDataPool* Pool(){return CDataPool::GetMe();}
template<class T>std::unique_ptr<T> New(){return std::unique_ptr<T>(new T);}
void Event(const char* n,const std::vector<STRING>& a={}){CEventSystem::GetMe()->PushEventByName(n,a);}
pg::PlayerShopGUID Guid(const _PLAYERSHOP_GUID& v){pg::PlayerShopGUID o;o.world=v.m_World;o.server=v.m_Server;o.scene=v.m_Scene;o.pollpos=v.m_PoolPos;return o;}
_PLAYERSHOP_GUID Guid(const pg::PlayerShopGUID& v){_PLAYERSHOP_GUID o;o.m_World=v.world;o.m_Server=v.server;o.m_Scene=v.scene;o.m_PoolPos=v.pollpos;return o;}
pg::PetGUID Guid(const PET_GUID_t& v){pg::PetGUID o;o.m_uHighSection=v.m_uHighSection;o.m_uLowSection=v.m_uLowSection;return o;}
PET_GUID_t Guid(const pg::PetGUID& v){PET_GUID_t o;o.m_uHighSection=v.m_uHighSection;o.m_uLowSection=v.m_uLowSection;return o;}
pg::ItemGUID Guid(const _ITEM_GUID& v){pg::ItemGUID o;o.world=v.m_World;o.server=v.m_Server;o.series=v.m_Serial;o.mask=CysModernHandlers::ItemGuidMask(o.world,o.server,o.series);return o;}
bool Same(const pg::PlayerShopGUID& a,const pg::PlayerShopGUID& b){return a.world==b.world&&a.server==b.server&&a.scene==b.scene&&a.pollpos==b.pollpos;}
bool Same(const pg::ItemGUID& a,const pg::ItemGUID& b){return a.world==b.world&&a.server==b.server&&a.series==b.series&&a.mask==b.mask;}
template<class T>bool Read(const std::string& bytes,T& out){pg::Reader r(bytes.data(),bytes.size());return out.read(r)&&r.remaining()==0;}
template<class T>std::string Bytes(const T& v){pg::Writer w;v.write(w);auto& b=w.buffer();return std::string((const char*)b.data(),b.size());}
bool Mine(const pg::PlayerShopGUID& g){
    if(active[1]&&Same(g,Guid(Pool()->PlayerShop_GetShopID(TRUE))))return true;
    auto me=CObjectManager::GetMe()->GetMySelf();if(!me)return false;
    for(int i=0;i<Pool()->PlayerShop_GetShopNum();++i)if(Same(g,Guid(Pool()->PlayerShop_GetIDByIndex(i))))
        return Pool()->PlayerShop_GetOwnerGuidByIndex(i)==me->GetServerGUID();
    return false;
}
void Refresh(bool mine){CActionSystem::GetMe()->UserPS_Self_Update();CActionSystem::GetMe()->UserPS_Other_Update();Event(mine?"PS_UPDATE_MY_SHOP":"PS_UPDATE_OTHER_SHOP");}
void Ask(const pg::PlayerShopGUID& guid,int stall,bool mine,int sign=2){
    if(stall<0||stall>=MAX_STALL_NUM_PER_SHOP)return;
    auto p=New<pg::CGPlayerShopAcquireItemList>();p->shop_id=guid;p->stall_index=stall;p->is_manager=mine;p->sign=sign;
    CysModernGame::SendModern(std::move(p));
}
void Clear(bool mine){
    for(int j=0;j<MAX_STALL_NUM_PER_SHOP;++j)for(int i=0;i<STALL_PET_BOX_SIZE;++i)Pool()->PlayerShop_SetPet(mine,j,i,nullptr);
    Pool()->PlayerShop_CleanObjItem(mine);Pool()->PlayerShop_CleanUp(mine);active[mine]=false;
    for(unsigned i=(mine?DetailSlots/2:0);i<(mine?DetailSlots:DetailSlots/2);++i)expected[i]={};
}
int Npc(int serverId){auto o=CObjectManager::GetMe()->FindServerObject(serverId);return o?o->GetID():-1;}
void OnList(const pg::GCPlayerShopAcquireShopList& p){
    if(p.shop_infos.size()>512)return;auto pool=Pool();pool->PlayerShop_SetShopNum((int)p.shop_infos.size());pool->PlayerShop_SetCommercialFactor(p.com_factor);
    pool->PlayerShop_SetNpcID(Npc(p.npc_id));listIds.clear();searchRows.clear();
    for(size_t i=0;i<p.shop_infos.size();++i){auto& s=p.shop_infos[i];
        listIds.push_back(s.id);
        searchRows.push_back((int)i);
        pool->PlayerShop_SetIDByIndex(i,Guid(s.guid));pool->PlayerShop_SetIsFavorByIndex(i,s.is_in_favor);
        pool->PlayerShop_SetShopNameByIndex(i,s.name_text().c_str());pool->PlayerShop_SetOwnerNameByIndex(i,s.owner_name_text().c_str());
        pool->PlayerShop_SetOwnerGuidByIndex(i,s.owner_guid);pool->PlayerShop_SetStallNumOnSale(i,s.stall_open_num);
        pool->PlayerShop_SetStallNumOpened(i,s.stall_open_num+s.stall_close_num);pool->PlayerShop_SetTypeByIndex(i,s.type==1?CDataPool::TYPE_PLAYER_SHOP_PET:CDataPool::TYPE_PLAYER_SHOP_ITEM);
        pool->PlayerShop_SetShopFoundedTimeByIndex(i,std::to_string(s.founded_day).c_str());pool->PlayerShop_SetShopDescByIndex(i,s.desc_text().c_str());
    }
    Event("PS_OPEN_SHOPLIST",{std::to_string(pool->PlayerShop_GetNpcID())});TDU_Log("CYS shop: list count=%u",(unsigned)p.shop_infos.size());
}
template<class E>void Metadata(const E& e,bool mine){
    Clear(mine);auto pool=Pool();active[mine]=true;
    activeIds[mine]=e.shop_id;
    pool->PlayerShop_SetShopID(mine,Guid(e.shop_guid));pool->PlayerShop_SetShopSerial(mine,e.serial);
    pool->PlayerShop_SetShopName(mine,e.shop_name_text().c_str());pool->PlayerShop_SetShopDesc(mine,e.desc_text().c_str());
    pool->PlayerShop_SetOwnerName(mine,e.owner_name_text().c_str());pool->PlayerShop_SetOwnerGuid(mine,e.owner_guid);
    pool->PlayerShop_SetBaseMoney(mine,e.base_money);pool->PlayerShop_SetProfitMoney(mine,e.profit_money);
    pool->PlayerShop_SetIsSaleOut(mine,e.is_sale_out);pool->PlayerShop_SetSaleOutPrice(mine,e.sale_out_price);
    pool->PlayerShop_SetOpenStallNum(mine,e.stall_num);pool->PlayerShop_SetShopType(mine,e.is_item_list?1:2);pool->PlayerShop_SetShopSubType(mine,e.type);
    for(int i=0;i<MAX_STALL_NUM_PER_SHOP;++i)pool->PlayerShop_SetStallEnableByIndex(mine,i,e.stall_is_open[i]);
    auto me=CObjectManager::GetMe()->GetMySelf();if(mine)pool->PlayerShop_SetMeIsOwner(me&&e.owner_guid==me->GetServerGUID());
}
void OnItems(const pg::GCItemList& p){
    // CY sends distinct headers: manager has record counts/commercial factor,
    // while the customer header has neither. Decode the selected schema fully.
    if(p.opt!=2||p.extra_data.empty()||p.item_list.size()>STALL_BOX_SIZE)return;
    if((unsigned char)p.extra_data[0]!=1&&(unsigned char)p.extra_data[0]!=2)return;
    bool mine=(unsigned char)p.extra_data[0]==2;int sign=0,kind=0;
    if(mine){pg::GCPlayerShopItemListForSelf_t_bos e;if(!Read(p.extra_data,e))return;Metadata(e,true);sign=e.ui_flag;kind=e.is_item_list?1:2;
        Pool()->PlayerShop_SetExRecNum(true,e.ex_rec_list_num);Pool()->PlayerShop_SetMaRecNum(true,e.ma_rec_list_num);Pool()->PlayerShop_SetCommercialFactor(e.com_factor);
    }else{pg::GCPlayerShopItemListForOther_t_bos e;if(!Read(p.extra_data,e)||e.flag!=1)return;Metadata(e,false);sign=e.ui_flag;kind=e.is_item_list?1:2;}
    for(auto& row:p.item_list){
        if(row.index>=STALL_BOX_SIZE)continue;int stall=-1,serial=0,price=0,sale=0;
        if(row.type==2){pg::GCPlayerShopItemListEachSerialForSelf_t e;if(!Read(row.extra_info,e))continue;stall=e.stall_index;serial=e.item_serial;}
        else if(row.type==0){
            if(mine){pg::GCPlayerShopItemListEachItemForSelf_t e;if(!Read(row.extra_info,e))continue;stall=e.stall_index;serial=e.item_serial;price=e.item_price;sale=e.is_on_sale;}
            else{pg::GCPlayerShopItemListEachItemForOther_t e;if(!Read(row.extra_info,e))continue;stall=e.stall_index;serial=e.item_serial;price=e.item_price;sale=1;}
        }
        if(stall<0||stall>=MAX_STALL_NUM_PER_SHOP)continue;
        Pool()->PlayerShop_SetItemSerial(mine,stall,row.index,serial);Pool()->PlayerShop_SetPetSerial(mine,stall,row.index,serial);
        Pool()->PlayerShop_SetItemPrice(mine,stall,row.index,price);Pool()->PlayerShop_SetItemOnSale(mine,stall,row.index,sale);
        if(row.type==0){pg::Reader r(row.data.data(),row.data.size());pg::ItemGUID g;if(g.read(r))expected[(mine?DetailSlots/2:0)+stall*STALL_BOX_SIZE+row.index]=g;}
    }
    if(sign==1){
        bool manage=mine&&!serverOpen;
        Event(mine?"PS_OPEN_MY_SHOP":"PS_OPEN_OTHER_SHOP",{std::to_string(Pool()->PlayerShop_GetNpcID()),std::to_string(kind)});
        if(manage&&kind==2)Event("OPEN_PET_LIST");
    }
    else Refresh(mine);
    TDU_Log("CYS shop: snapshot mine=%d kind=%d rows=%u serial=%d",mine,kind,(unsigned)p.item_list.size(),Pool()->PlayerShop_GetShopSerial(mine));
}
bool OnPet(const pg::GCDetailAttrib_Pet& p){
    if(p.unknow_6!=16||p.unknow_7.size()!=16||p.unknow_7[0]!=3)return false;
    int mine=p.unknow_7[12],stall=p.unknow_7[13];unsigned pos=p.m_nTradeIndex;
    if(mine>1||!active[mine]||stall>=MAX_STALL_NUM_PER_SHOP||pos>=STALL_PET_BOX_SIZE)return true;
    auto pet=new SDATA_PET;CysPetNet::FillExternal(p,*pet);Pool()->PlayerShop_SetPet(mine,stall,pos,pet);
    petDetails[(uint64_t(p.guid.m_uHighSection)<<32)|p.guid.m_uLowSection]=p;
    unsigned price=0,serial=0;memcpy(&price,p.unknow_7.data()+4,4);memcpy(&serial,p.unknow_7.data()+8,4);
    Pool()->PlayerShop_SetPetPrice(mine,stall,pos,price);Pool()->PlayerShop_SetPetSerial(mine,stall,pos,serial);
    Pool()->PlayerShop_SetItemOnSale(mine,stall,pos,p.unknow_7[14]);Refresh(mine);
    TDU_Log("CYS shop: pet mine=%d stall=%d slot=%u guid=%u:%u price=%u",mine,stall,pos,p.guid.m_uHighSection,p.guid.m_uLowSection,price);return true;
}
void OnMove(const pg::GCItemSynch& p){
    if(p.opt!=0)return;bool pet=p.from_type==2||p.from_type==5;bool deposit=p.to_type==(pet?5:4);
    pg::PlayerShopGUID guid;int stall=-1,serial=0;bool mine=deposit;
    if(pet){if(deposit){pg::GCMovePetFromBagToPlayerShop_t_bos e;if(!Read(p.extra_data,e))return;guid=e.shop_guid;stall=e.stall_index;serial=e.shop_serial;}
        else{pg::GCMovePetFromPlayerShopToBag_t_bos e;if(!Read(p.extra_data,e))return;guid=e.shop_guid;stall=e.stall_index;serial=e.shop_serial;mine=e.flag!=0;}}
    else{if(deposit){pg::GCMoveItemFromBagToPlayerShop_t_bos e;if(!Read(p.extra_data,e))return;guid=e.shop_guid;stall=e.stall_index;serial=e.shop_serial;}
        else{pg::GCMoveItemFromPlayerShopToBag_t_bos e;if(!Read(p.extra_data,e))return;guid=e.shop_guid;stall=e.stall_index;serial=e.shop_serial;mine=e.flag!=0;}}
    if(stall<0||stall>=MAX_STALL_NUM_PER_SHOP||!Same(guid,Guid(Pool()->PlayerShop_GetShopID(mine))))return;
    Pool()->PlayerShop_SetShopSerial(mine,serial);
    if(pet&&deposit){pg::GCRemovePet removed;removed.guid=p.pet_guid;CysPetNet::Dispatch(removed);}
    Ask(guid,stall,mine);TDU_Log("CYS shop: move pet=%d deposit=%d mine=%d to=%d serial=%d",pet,deposit,mine,p.to_index,serial);
}
int Number(LuaPlus::LuaState* s,int i,int def=0){LuaPlus::LuaStack a(s);return a[i].IsNumber()?int(a[i].GetNumber()):def;}
int MapIndex(LuaPlus::LuaState* s){int i=Number(s,2,-1);s->PushInteger(i>=0&&i<MAX_STALL_NUM_PER_SHOP?i:-1);return 1;}
int ServerOpen(LuaPlus::LuaState* s){s->PushInteger(serverOpen);return 1;}
int SetServerOpen(LuaPlus::LuaState* s){serverOpen=Number(s,2);return 0;}
int GetSelected(LuaPlus::LuaState* s){s->PushInteger(selectedShop);return 1;}
int SetSelected(LuaPlus::LuaState* s){selectedShop=Number(s,2,-1);return 0;}
int GetSaleType(LuaPlus::LuaState* s){s->PushInteger(0);return 1;}
int ShopCount(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);s->PushInteger(a[2].IsString()&&!strcmp(a[2].GetString(),"search")?(int)searchRows.size():Pool()->PlayerShop_GetShopNum());return 1;}
int SearchRow(LuaPlus::LuaState* s){int i=Number(s,2,-1);s->PushInteger(i>=0&&i<(int)searchRows.size()?searchRows[i]:-1);return 1;}
int FindShop(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);if(!a[2].IsString())return 0;const char* key=a[2].GetString();int value=Number(s,3,-1);searchRows.clear();
    for(int i=0;i<Pool()->PlayerShop_GetShopNum();++i){bool pet=Pool()->PlayerShop_GetTypeByIndex(i)==CDataPool::TYPE_PLAYER_SHOP_PET;
        if((!strcmp(key,"pet")&&pet)||(!strcmp(key,"item")&&!pet)||(!strcmp(key,"shopid")&&i<(int)listIds.size()&&listIds[i]==value))searchRows.push_back(i);
    }
    Event("PS_UPDATE_SEARCH_SHOPLIST");return 0;
}
int ListInfo(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);int i=Number(s,3,-1);if(!a[2].IsString()||i<0||i>=Pool()->PlayerShop_GetShopNum())return 0;const char* key=a[2].GetString();
    if(!strcmp(key,"ownerid")||!strcmp(key,"ownerguid"))s->PushNumber(Pool()->PlayerShop_GetOwnerGuidByIndex(i));
    else if(!strcmp(key,"shopindex"))s->PushInteger(i<(int)listIds.size()?listIds[i]:i+1);
    else if(!strcmp(key,"ownername"))s->PushString(Pool()->PlayerShop_GetOwnerNameByIndex(i));
    else if(!strcmp(key,"since"))s->PushString(Pool()->PlayerShop_GetShopFoundedTimeByIndex(i));
    else s->PushString(Pool()->PlayerShop_GetShopDescByIndex(i));return 1;
}
int EnumPet(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);bool mine=a[2].IsString()&&!strcmp(a[2].GetString(),"self");int stall=Number(s,3,-1),slot=Number(s,4,-1);
    auto p=stall>=0&&stall<MAX_STALL_NUM_PER_SHOP&&slot>=0&&slot<STALL_PET_BOX_SIZE?Pool()->PlayerShop_GetPet(mine,stall,slot):nullptr;
    s->PushString(p?p->m_szName.c_str():"");if(mine)s->PushInteger(p?Pool()->PlayerShop_GetItemOnSale(mine,stall,slot):0);
    auto db=CDataBaseSystem::GetMe()->GetDataBase(DBC_PET_EX_ATT);
    auto row=p&&db?(const _DBC_PET_EX_ATT*)db->Search_Index_EQU(p->m_nDataID):nullptr;
    s->PushString(row&&row->m_Name?row->m_Name:"");return mine?3:2;
}
int ShopType(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);bool mine=a[2].IsString()&&!strcmp(a[2].GetString(),"self");s->PushInteger(Pool()->PlayerShop_GetShopType(mine)==2?6:1);return 1;}
int SelfPlace(LuaPlus::LuaState* s){s->PushString(active[1]?(Pool()->PlayerShop_GetMeIsOwner()?"boss":"partner"):"");return 1;}
int CloseManager(LuaPlus::LuaState* s){Event("PS_CLOSE_ALL_SHOP");Event("CLOSE_PET_LIST");return 0;}
int EnumShop(LuaPlus::LuaState* s){
    int i=Number(s,2,-1);if(i<0||i>=Pool()->PlayerShop_GetShopNum())return 0;
    s->PushString(Pool()->PlayerShop_GetShopNameByIndex(i));
    s->PushInteger(Pool()->PlayerShop_GetStallNumOpened(i));s->PushInteger(Pool()->PlayerShop_GetStallNumOnSale(i));
    s->PushString(Pool()->PlayerShop_GetTypeByIndex(i)==CDataPool::TYPE_PLAYER_SHOP_PET?u8"Trân thú":u8"Vật phẩm");
    s->PushInteger(Pool()->PlayerShop_GetIsFavorByIndex(i));s->PushInteger(0);s->PushInteger(0);
    s->PushInteger(i<(int)listIds.size()?listIds[i]:i+1);return 8;
}
int ShopInfo(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);if(!a[2].IsString()||!a[3].IsString())return 0;
    bool mine=!strcmp(a[2].GetString(),"self");const char* key=a[3].GetString();
    if(!strcmp(key,"ownerid"))s->PushNumber(Pool()->PlayerShop_GetOwnerGuid(mine));
    else if(!strcmp(key,"shopindex"))s->PushInteger(activeIds[mine]);
    else if(!strcmp(key,"ownername"))s->PushString(Pool()->PlayerShop_GetOwnerName(mine));
    else if(!strcmp(key,"shopname"))s->PushString(Pool()->PlayerShop_GetShopName(mine));
    else if(!strcmp(key,"desc"))s->PushString(Pool()->PlayerShop_GetShopDesc(mine));
    else s->PushString("");return 1;
}
int OpenShop(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);bool cy=a[2].IsString();
    int i=Number(s,cy?3:2,-1);if(i<0||i>=Pool()->PlayerShop_GetShopNum())return 0;
    if(cy&&strcmp(a[2].GetString(),"buy")&&strcmp(a[2].GetString(),"manage"))return 0;
    auto guid=Guid(Pool()->PlayerShop_GetIDByIndex(i));bool mine=Mine(guid);
    serverOpen=mine&&cy&&!strcmp(a[2].GetString(),"buy")?1:0;
    Clear(false);Clear(true);petDetails.clear();Ask(guid,0,mine,1);return 0;
}
int ViewPet(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);bool mine=a[2].IsString()&&!strcmp(a[2].GetString(),"self");int i=Number(s,3,-1);
    int stall=mine?Pool()->PlayerShop_GetMySelectConTa():Pool()->PlayerShop_GetOtSelectConTa();
    if(stall<0||stall>=MAX_STALL_NUM_PER_SHOP||i<0||i>=STALL_PET_BOX_SIZE)return 0;
    auto pet=Pool()->PlayerShop_GetPet(mine,stall,i);if(!pet)return 0;
    auto it=petDetails.find((uint64_t(pet->m_GUID.m_uHighSection)<<32)|pet->m_GUID.m_uLowSection);if(it==petDetails.end())return 0;
    auto p=it->second;p.unknow_6=1;p.unknow_7={4};CysPetNet::Dispatch(p);return 0;
}
LuaPlus::LuaObject Table(LuaPlus::LuaObject g,const char* name){auto o=g.GetByName(name);if(o.IsTable())return o;if(o.IsUserData()){auto m=o.GetMetaTable();auto i=m.GetByName("__index");return i.IsTable()?i:m;}return g.CreateTable(name);}
}
void RegisterHost(){
    Clear(false);Clear(true);petDetails.clear();selectedShop=-1;serverOpen=0;
    auto scripts=CScriptSystem::GetMe();auto s=scripts?scripts->GetLuaState():nullptr;if(!s)return;auto t=Table(s->GetGlobals(),"PlayerShop");
    t.Register("UIIndexToLogicIndex",MapIndex);t.Register("GetServerOpen",ServerOpen);t.Register("SetServerOpen",SetServerOpen);
    t.Register("GetCurSelShopIdx",GetSelected);t.Register("SetCurSelShopIdx",SetSelected);t.Register("GetSaleType",GetSaleType);t.Register("LuaFnGetSaleType",GetSaleType);
    t.Register("ViewPetDesc",ViewPet);
    t.Register("GetSelfPlace",SelfPlace);
    t.Register("EnumShop",EnumShop);t.Register("GetShopInfo",ShopInfo);t.Register("AskOpenShop",OpenShop);
    t.Register("GetShopNum",ShopCount);t.Register("EnumSearchShopIndex",SearchRow);t.Register("FindShop",FindShop);
    t.Register("EnumShopInfo",ListInfo);t.Register("EnumPet",EnumPet);t.Register("GetCurShopType",ShopType);t.Register("CloseShopMag",CloseManager);
}
bool ItemInfo(const pg::GCItemInfo& p){
    if(p.bagIndex<DetailBase||p.bagIndex>=DetailBase+DetailSlots)return false;unsigned k=p.bagIndex-DetailBase;
    bool mine=k>=DetailSlots/2;unsigned slot=k%(DetailSlots/2),stall=slot/STALL_BOX_SIZE;slot%=STALL_BOX_SIZE;
    if(!active[mine]||p.unknow_1!=0||p.item.item_index<=0||!Same(expected[k],p.item.guid))return true;
    _ITEM legacy;CysModernHandlers::ItemInfoToLegacy(p.item,legacy);auto item=CObject_Item::NewItem(legacy.m_ItemIndex);if(!item)return true;
    item->SetGUID(legacy.m_ItemGUID.m_World,legacy.m_ItemGUID.m_Server,legacy.m_ItemGUID.m_Serial);item->SetExtraInfo(&legacy);item->SetNumber(CysItemWireCount::Get(p.item));
    Pool()->PlayerShop_SetItem(mine,stall,slot,item);Pool()->PlayerShop_SetItemExtraInfo(mine,stall,slot,FALSE,&legacy);Refresh(mine);return true;
}
bool IsWorldPacket(uint16_t id){switch(id){
    case pg::GCPlayerShopAcquireShopList::PACKET_ID:case pg::GCItemList::PACKET_ID:case pg::GCItemSynch::PACKET_ID:
    case pg::GCPlayerShopApply::PACKET_ID:case pg::GCPlayerShopEstablish::PACKET_ID:case pg::GCPlayerShopOnSale::PACKET_ID:
    case pg::GCPlayerShopMoney::PACKET_ID:case pg::GCPlayerShopOpenStall::PACKET_ID:case pg::GCPlayerShopError::PACKET_ID:return true;
    default:return false;}}
bool Dispatch(const pg::Packet& packet){switch(packet.packetId()){
    case pg::GCPlayerShopAcquireShopList::PACKET_ID:OnList(static_cast<const pg::GCPlayerShopAcquireShopList&>(packet));return true;
    case pg::GCItemList::PACKET_ID:OnItems(static_cast<const pg::GCItemList&>(packet));return true;
    case pg::GCDetailAttrib_Pet::PACKET_ID:return OnPet(static_cast<const pg::GCDetailAttrib_Pet&>(packet));
    case pg::GCItemSynch::PACKET_ID:OnMove(static_cast<const pg::GCItemSynch&>(packet));return true;
    case pg::GCPlayerShopOnSale::PACKET_ID:{auto& p=static_cast<const pg::GCPlayerShopOnSale&>(packet);Pool()->PlayerShop_SetShopSerial(true,p.shop_serial);Ask(p.shop_guid,p.stall_index,true);return true;}
    case pg::GCPlayerShopOpenStall::PACKET_ID:{auto& p=static_cast<const pg::GCPlayerShopOpenStall&>(packet);Pool()->PlayerShop_SetShopSerial(true,p.serial);Ask(p.shop_id,p.stall_index,true);return true;}
    case pg::GCPlayerShopMoney::PACKET_ID:{auto& p=static_cast<const pg::GCPlayerShopMoney&>(packet);if(!Same(p.shop_id,Guid(Pool()->PlayerShop_GetShopID(true))))return true;
        Pool()->PlayerShop_SetShopSerial(true,p.serial);if(p.type==0)Pool()->PlayerShop_SetBaseMoney(true,p.amount);else if(p.type==1)Pool()->PlayerShop_SetProfitMoney(true,p.amount);Refresh(true);return true;}
    case pg::GCPlayerShopApply::PACKET_ID:{auto& p=static_cast<const pg::GCPlayerShopApply&>(packet);Pool()->PlayerShop_SetNpcID(Npc(p.npc_id));Pool()->PlayerShop_SetCommercialFactor(p.com_factor);Pool()->PlayerShop_SetCost(p.cost);Pool()->PlayerShop_SetType(p.type);Event("PS_OPEN_CREATESHOP",{std::to_string(Pool()->PlayerShop_GetNpcID())});return true;}
    case pg::GCPlayerShopEstablish::PACKET_ID:{auto& p=static_cast<const pg::GCPlayerShopEstablish&>(packet);Ask(p.shop_id,0,true,1);return true;}
    case pg::GCPlayerShopError::PACKET_ID:{auto& p=static_cast<const pg::GCPlayerShopError&>(packet);Event("NEW_DEBUGMESSAGE",{u8"Giao dịch cửa hàng không thành công. Hãy tải lại quầy và kiểm tra tiền, chỗ trống hoặc quyền quản lý."});TDU_Log("CYS shop: error=%u",p.error_code);return true;}
    default:return false;}}
std::unique_ptr<pg::Packet> Translate(Packet* packet){using namespace Packets;switch(packet->GetPacketID()){
    case PACKET_CG_PLAYERSHOPACQUIRESHOPLIST:return New<pg::CGPlayerShopAcquireShopList>();
    case PACKET_CG_PLAYERSHOPAPPLY:return New<pg::CGPlayerShopApply>();
    case PACKET_CG_PLAYERSHOPACQUIREITEMLIST:{auto p=static_cast<CGPlayerShopAcquireItemList*>(packet);auto q=New<pg::CGPlayerShopAcquireItemList>();q->shop_id=Guid(p->GetShopID());q->stall_index=p->GetStallIndex();q->sign=p->GetSign();q->is_manager=Mine(q->shop_id);return std::move(q);}
    case PACKET_CG_PLAYERSHOPESTABLISH:{auto p=static_cast<CGPlayerShopEstablish*>(packet);auto q=New<pg::CGPlayerShopEstablish>();q->type=p->GetType();q->name=p->GetShopName();q->shop_name_len=(uint8_t)q->name.size();return std::move(q);}
    case PACKET_CG_PLAYERSHOPBUYITEM:{auto p=static_cast<CGPlayerShopBuyItem*>(packet);auto q=New<pg::CGPlayerShopBuyItem>();q->shop_id=Guid(p->GetShopID());q->stall_index=p->GetStallIndex();q->item_guid=Guid(p->GetObjGUID());q->pet_guid=Guid(p->GetPetGuid());q->serial=p->GetSerial();return std::move(q);}
    case PACKET_CG_PLAYERSHOPONSALE:{auto p=static_cast<CGPlayerShopOnSale*>(packet);auto q=New<pg::CGPlayerShopOnSale>();q->shop_id=Guid(p->GetShopID());q->stall_index=p->GetStallIndex();q->item_guid=Guid(p->GetObjGUID());q->pet_guid=Guid(p->GetPetGuid());q->serial=p->GetSerial();q->price=p->GetPrice();q->is_on_sale=p->GetIsOnSale();q->shop_serial=Pool()->PlayerShop_GetShopSerial(true);return std::move(q);}
    case PACKET_CG_PLAYERSHOPMONEY:{auto p=static_cast<CGPlayerShopMoney*>(packet);auto q=New<pg::CGPlayerShopMoney>();q->shop_id=Guid(p->GetShopID());q->type=p->GetType();q->opt=p->GetOpt();q->amount=p->GetAmount();q->serial=Pool()->PlayerShop_GetShopSerial(true);return std::move(q);}
    case PACKET_CG_PLAYERSHOPOPENSTALL:{auto p=static_cast<CGPlayerShopOpenStall*>(packet);auto q=New<pg::CGPlayerShopOpenStall>();q->shop_id=Guid(p->GetShopID());q->stall_index=p->GetStallIndex();q->open=p->GetOpen();q->serial=Pool()->PlayerShop_GetShopSerial(true);return std::move(q);}
    case PACKET_CG_ITEMSYNCH:{auto p=static_cast<CGItemSynch*>(packet);auto q=New<pg::CGItemSynch>();q->from_type=p->GetFromType();q->to_type=p->GetToType();q->opt=p->GetOpt();q->to_index=p->GetToIndex();q->pet_guid=Guid(p->GetPetGUID());q->item_guid=Guid(p->GetItemGUID());
        using namespace ITEM_SYNCH_STRUCT;
        if(q->opt!=CGItemSynch::OPT_MOVE_ITEM_AUTO)return nullptr;
        if(q->from_type==2&&q->to_type==5){CGAutoMovePetFromBagToPlayerShop_t e;if(p->GetExtraInfoLength()!=sizeof(e))return nullptr;memcpy(&e,p->GetExtraInfoData(),sizeof(e));pg::CGAutoMoveItemFromBagToPlayerShop_t x;x.shop_guid=Guid(e.m_ShopGuid);x.stall_index=e.m_nStallIndex;x.shop_serial=Pool()->PlayerShop_GetShopSerial(true);q->extra_data=Bytes(x);}
        else if(q->from_type==5&&q->to_type==2){CGAutoMovePetFromPlayerShopToBag_t e;if(p->GetExtraInfoLength()!=sizeof(e))return nullptr;memcpy(&e,p->GetExtraInfoData(),sizeof(e));pg::CGAutoMovePetFromPlayerShopToBag_t x;x.shop_guid=Guid(e.m_ShopGuid);x.stall_index=e.m_nStallIndex;x.serial=(uint8_t)e.m_uSerial;x.shop_serial=Pool()->PlayerShop_GetShopSerial(true);q->extra_data=Bytes(x);}
        else return nullptr;
        return std::move(q);}
    default:return nullptr;}}
}
